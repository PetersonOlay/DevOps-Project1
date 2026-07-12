# Thin wrapper around terraform-aws-modules/eks/aws: cluster + managed node
# group only (no add-ons — see modules/eks-addons for why they're separate).
module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.0"

  cluster_name    = var.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = var.vpc_id
  subnet_ids = var.subnet_ids

  # Both the aws-auth ConfigMap and the newer EKS Access Entries API are honored.
  authentication_mode = "API_AND_CONFIG_MAP"

  # The principal running Terraform gets an admin access entry immediately,
  # otherwise kubectl/Helm calls against the new cluster 403 right after apply.
  enable_cluster_creator_admin_permissions = true

  cluster_endpoint_public_access = true

  create_cloudwatch_log_group            = true
  cloudwatch_log_group_retention_in_days = var.log_retention_days
  cluster_enabled_log_types              = var.cluster_enabled_log_types

  # Add-ons are intentionally NOT configured here. Their IRSA roles need
  # module.eks.oidc_provider_arn, which doesn't exist until the cluster does,
  # so they're created afterwards via modules/irsa + modules/eks-addons.
  cluster_addons = {}

  eks_managed_node_groups = {
    default = {
      instance_types = var.node_group_instance_types
      capacity_type  = var.node_group_capacity_type

      min_size     = var.node_group_min_size
      max_size     = var.node_group_max_size
      desired_size = var.node_group_desired_size

      subnet_ids = var.subnet_ids
    }
  }

  tags = var.tags
}
