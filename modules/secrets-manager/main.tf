resource "aws_secretsmanager_secret" "this" {
  name                    = var.secret_name
  recovery_window_in_days = var.recovery_window_in_days

  tags = var.tags
}

resource "aws_secretsmanager_secret_version" "this" {
  secret_id     = aws_secretsmanager_secret.this.id
  secret_string = var.placeholder_value

  lifecycle {
    # The app team fills in the real value out-of-band; don't let Terraform
    # revert it back to the placeholder on subsequent applies.
    ignore_changes = [secret_string]
  }
}
