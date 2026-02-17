# Run before instance recreation: terraform apply -target="module.backup"
resource "null_resource" "backup_xui" {
  triggers = {
    instance_id = var.instance_id
    instance_ip = var.instance_ip
    timestamp   = timestamp()
  }

  provisioner "local-exec" {
    command     = "${path.module}/backup.sh"
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
    command     = "${path.module}/backup.ps1"
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
