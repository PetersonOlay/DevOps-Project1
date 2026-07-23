locals {
  cluster_name = "expense-platform-${var.environment}"

  # Friendly, environment-scoped namespace name for the app (avoids deploying
  # into the cluster's built-in "default" namespace).
  app_namespace = "expense-tracker-${var.environment}"

  common_tags = {
    Project     = "expense-platform"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
