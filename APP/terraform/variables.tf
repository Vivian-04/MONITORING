variable "app_host" {
  description = "IP or hostname of the application server to monitor from the monitoring server."
  type        = string
  default     = "127.0.0.1"
}

variable "slack_webhook_url" {
  description = "Slack incoming webhook URL for Alertmanager notifications."
  type        = string
  default     = ""
}

variable "grafana_admin_user" {
  description = "Grafana admin username."
  type        = string
  default     = "admin"
}

variable "grafana_admin_password" {
  description = "Grafana admin password."
  type        = string
  default     = "admin"
}
