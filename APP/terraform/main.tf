# This null_resource is used to invoke the SSH-based deployment script.
# The remote monitoring host is bootstrapped using native systemd units.
# Docker is not required for the monitoring runtime.
resource "null_resource" "deploy_monitoring" {
  provisioner "local-exec" {
    command = <<-EOT
      MON_HOST='${var.monitoring_host}' \
      SSH_USER='${var.ssh_user}' \
      APP_HOST='${var.app_host}' \
      SLACK_WEBHOOK_URL='${var.slack_webhook_url}' \
      GITHUB_REPOSITORY='${var.github_repository}' \
      GITHUB_TOKEN='${var.github_token}' \
      GRAFANA_ADMIN_USER='${var.grafana_admin_user}' \
      GRAFANA_ADMIN_PASSWORD='${var.grafana_admin_password}' \
      bash ../deploy-monitoring-ssh.sh
    EOT
    working_dir = path.module
    interpreter = ["bash", "-c"]
  }

  triggers = {
    monitoring_host   = var.monitoring_host
    ssh_user          = var.ssh_user
    app_host          = var.app_host
    github_repository = var.github_repository
    always_run        = timestamp()
  }
}
