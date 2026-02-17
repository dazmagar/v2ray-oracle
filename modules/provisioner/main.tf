# Disable host firewall; OCI NSG + Security List handle filtering.
resource "null_resource" "open_firewall" {
  triggers = {
    instance_ip = var.instance_ip
  }

  connection {
    host        = var.instance_ip
    type        = "ssh"
    user        = var.user
    timeout     = "120s"
    private_key = file(var.privatekeypath)
  }

  provisioner "remote-exec" {
    inline = [
      "set -e",
      "if command -v ufw &>/dev/null || [ -x /usr/sbin/ufw ]; then",
      "  sudo /usr/sbin/ufw disable 2>/dev/null || true",
      "  echo 'ufw disabled'",
      "fi",
      "sudo iptables -P INPUT ACCEPT 2>/dev/null || true",
      "sudo iptables -P FORWARD ACCEPT 2>/dev/null || true",
      "sudo iptables -F INPUT 2>/dev/null || true",
      "sudo iptables -F FORWARD 2>/dev/null || true",
      "echo 'Host firewall off; OCI NSG/SL only'"
    ]
  }
}

resource "null_resource" "install_docker" {
  depends_on = [null_resource.open_firewall]

  triggers = {
    instance_ip = var.instance_ip
    user        = var.user
  }

  connection {
    host        = var.instance_ip
    type        = "ssh"
    user        = var.user
    timeout     = "500s"
    private_key = file(var.privatekeypath)
  }

  provisioner "file" {
    source      = "${path.module}/startup.sh"
    destination = "/tmp/startup.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "if sudo docker --version &> /dev/null && sudo systemctl is-active --quiet docker; then",
      "  echo 'Docker already installed and running'",
      "else",
      "  chmod +x /tmp/startup.sh",
      "  bash /tmp/startup.sh '${var.user}'",
      "  if ! sudo docker --version &> /dev/null; then",
      "    if [ ! -f /usr/bin/docker ]; then",
      "      echo 'Error: Docker installation failed'",
      "      exit 1",
      "    fi",
      "  fi",
      "  echo 'Docker installed successfully'",
      "fi"
    ]
  }
}

resource "null_resource" "restore_backup" {
  depends_on = [null_resource.install_docker]

  triggers = {
    instance_ip = var.instance_ip
    backup_path = var.backup_path
  }

  connection {
    host        = var.instance_ip
    type        = "ssh"
    user        = var.user
    timeout     = "500s"
    private_key = file(var.privatekeypath)
  }

  provisioner "local-exec" {
    command     = "${path.root}/modules/backup/restore.sh"
    interpreter = ["/bin/sh"]
    environment = {
      PRIVATE_KEY_PATH = var.privatekeypath
      USER             = var.user
      INSTANCE_IP      = var.instance_ip
      BACKUP_PATH      = var.backup_path
    }
    on_failure = continue
  }

  provisioner "local-exec" {
    command     = "${path.root}/modules/backup/restore.ps1"
    interpreter = ["PowerShell", "-File"]
    environment = {
      PRIVATE_KEY_PATH = var.privatekeypath
      USER             = var.user
      INSTANCE_IP      = var.instance_ip
      BACKUP_PATH      = var.backup_path
    }
    on_failure = continue
  }
}

resource "null_resource" "run_3x_ui" {
  depends_on = [null_resource.install_docker, null_resource.restore_backup]

  triggers = {
    instance_ip     = var.instance_ip
    user            = var.user
    v2ray_host      = var.v2ray_host
    panel_port      = var.panel_port
    panel_base_path = var.panel_base_path
  }

  connection {
    host        = var.instance_ip
    type        = "ssh"
    user        = var.user
    timeout     = "500s"
    private_key = file(var.privatekeypath)
  }

  provisioner "file" {
    source      = "${path.module}/run-3x-ui.sh"
    destination = "/home/${var.user}/run-3x-ui.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/${var.user}/run-3x-ui.sh",
      "bash /home/${var.user}/run-3x-ui.sh '${replace(var.v2ray_host, "'", "'\"'\"'")}' ${var.panel_port} '${replace(var.panel_base_path, "'", "'\"'\"'")}' 2>&1 | tee /tmp/3x-ui-startup.log || {",
      "  RC=$?",
      "  echo '=== Container startup failed (exit code: $RC) ===' >&2",
      "  cat /tmp/3x-ui-container-deploy.log >&2 2>/dev/null || true",
      "  sudo docker logs 3x-ui >&2 2>&1 || true",
      "  exit $RC",
      "}"
    ]
  }
}

resource "null_resource" "install_caddy" {
  count      = var.enable_caddy_tls ? 1 : 0
  depends_on = [null_resource.run_3x_ui]

  triggers = {
    instance_ip           = var.instance_ip
    v2ray_host            = var.v2ray_host
    panel_port            = var.panel_port
    caddy_use_internal_tls = var.caddy_use_internal_tls
  }

  connection {
    host        = var.instance_ip
    type        = "ssh"
    user        = var.user
    timeout     = "500s"
    private_key = file(var.privatekeypath)
  }

  provisioner "file" {
    source      = "${path.module}/install-caddy.sh"
    destination = "/tmp/install-caddy.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/install-caddy.sh",
      "bash /tmp/install-caddy.sh '${replace(var.v2ray_host, "'", "'\"'\"'")}' ${var.panel_port} ${var.caddy_use_internal_tls} 2>&1 | tee /tmp/caddy-install.log || { echo 'Caddy install failed' >&2; exit 1; }"
    ]
  }
}

resource "null_resource" "setup_cron_restart" {
  depends_on = [null_resource.install_docker, null_resource.run_3x_ui]

  triggers = {
    instance_ip           = var.instance_ip
    cron_restart_schedule = var.cron_restart_schedule
  }

  connection {
    host        = var.instance_ip
    type        = "ssh"
    user        = var.user
    timeout     = "500s"
    private_key = file(var.privatekeypath)
  }

  provisioner "file" {
    source      = "${path.module}/setup-cron-restart.sh"
    destination = "/home/${var.user}/setup-cron-restart.sh"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod +x /home/${var.user}/setup-cron-restart.sh",
      "bash /home/${var.user}/setup-cron-restart.sh '${var.cron_restart_schedule}' || {",
      "  echo 'ERROR: Failed to setup cron job' >&2",
      "  exit 1",
      "}",
      "crontab -l | grep -q '3x-ui' && echo 'Cron job verified' || echo 'WARNING: Cron job not found'"
    ]
  }
}
