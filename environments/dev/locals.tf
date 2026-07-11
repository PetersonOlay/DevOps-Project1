locals {
  cluster_name = "k8s-platform-${var.environment}"

  # Friendly, environment-scoped namespace name for the app (avoids deploying
  # into the cluster's built-in "default" namespace).
  app_namespace = "expense-tracker-${var.environment}"

  common_tags = {
    Project     = "k8s-platform"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
