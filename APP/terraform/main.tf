# This null_resource is used to invoke the SSH-based deployment script.
# The remote monitoring host is bootstrapped using native systemd units.
# Docker is not required for the monitoring runtime.
resource "null_resource" "deploy_monitoring" {
  provisioner "local-exec" {
    command     = "bash ../deploy-monitoring-ssh.sh"
    working_dir = path.module
    interpreter = ["bash", "-c"]
    environment = {
      MON_HOST               = var.monitoring_host
      SSH_USER               = var.ssh_user
      SSH_PASSWORD           = var.ssh_password
      SUDO_PASSWORD          = var.sudo_password
      APP_HOST               = var.app_host
      SLACK_WEBHOOK_URL      = var.slack_webhook_url
      GITHUB_REPOSITORY      = var.github_repository
      GITHUB_TOKEN           = var.github_token
      GRAFANA_ADMIN_USER     = var.grafana_admin_user
      GRAFANA_ADMIN_PASSWORD = var.grafana_admin_password
      SSH_KEY_PATH           = var.ssh_private_key_path
    }
  }

  triggers = {
    monitoring_host   = var.monitoring_host
    ssh_user          = var.ssh_user
    app_host          = var.app_host
    github_repository = var.github_repository
    always_run        = timestamp()
  }
}
