locals {
  cluster_name = "k8s-platform-${var.environment}"

  common_tags = {
    Project     = "k8s-platform"
    Environment = var.environment
    ManagedBy   = "terraform"
  }
}
