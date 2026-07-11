module "vpc" {
  source = "../../modules/vpc"

  name         = local.cluster_name
  cidr         = var.vpc_cidr
  azs          = var.azs
  cluster_name = local.cluster_name

  private_subnets    = var.private_subnet_cidrs
  public_subnets     = var.public_subnet_cidrs
  single_nat_gateway = var.single_nat_gateway

  tags = local.common_tags
}

module "eks" {
  source = "../../modules/eks"

  cluster_name    = local.cluster_name
  cluster_version = var.cluster_version

  vpc_id     = module.vpc.vpc_id
  subnet_ids = module.vpc.private_subnet_ids

  cluster_enabled_log_types = var.cluster_enabled_log_types
  log_retention_days        = var.log_retention_days

  node_group_instance_types = var.node_group_instance_types
  node_group_capacity_type  = var.node_group_capacity_type
  node_group_min_size       = var.node_group_min_size
  node_group_max_size       = var.node_group_max_size
  node_group_desired_size   = var.node_group_desired_size

  tags = local.common_tags
}

module "ecr" {
  source = "../../modules/ecr"

  repository_name = var.ecr_repository_name

  tags = local.common_tags
}

module "app_bucket" {
  source = "../../modules/s3-app-bucket"

  bucket_name   = var.app_s3_bucket_name
  force_destroy = var.app_s3_force_destroy

  tags = local.common_tags
}

module "app_secret" {
  source = "../../modules/secrets-manager"

  secret_name = var.secret_placeholder_name

  tags = local.common_tags
}

module "cloudwatch" {
  source = "../../modules/cloudwatch"

  log_group_names = {
    node_group = "/aws/eks/${local.cluster_name}/node-group"
  }
  retention_in_days = var.log_retention_days

  tags = local.common_tags
}

module "ci_deployer" {
  source = "../../modules/ci-deployer"

  user_name = "${local.cluster_name}-ci-deployer"

  ecr_repository_arn = module.ecr.repository_arn
  eks_cluster_arn    = module.eks.cluster_arn
  eks_cluster_name   = module.eks.cluster_name

  kubernetes_namespace = var.app_namespace

  tags = local.common_tags
}

module "rds" {
  source = "../../modules/rds"

  identifier = "${local.cluster_name}-db"

  vpc_id                     = module.vpc.vpc_id
  subnet_ids                 = module.vpc.private_subnet_ids
  allowed_security_group_ids = [module.eks.node_security_group_id]

  db_name  = var.db_name
  username = var.db_username

  instance_class          = var.rds_instance_class
  allocated_storage       = var.rds_allocated_storage
  multi_az                = var.rds_multi_az
  backup_retention_period = var.rds_backup_retention_days
  deletion_protection     = var.rds_deletion_protection
  skip_final_snapshot     = var.rds_skip_final_snapshot

  tags = local.common_tags
}

# --- IRSA roles (depend on the cluster's OIDC provider) ---

module "irsa_vpc_cni" {
  source = "../../modules/irsa"

  role_name                  = "${local.cluster_name}-vpc-cni"
  oidc_provider_arn          = module.eks.oidc_provider_arn
  namespace_service_accounts = ["kube-system:aws-node"]
  attach_vpc_cni_policy      = true

  tags = local.common_tags
}

module "irsa_ebs_csi" {
  source = "../../modules/irsa"

  role_name                  = "${local.cluster_name}-ebs-csi"
  oidc_provider_arn          = module.eks.oidc_provider_arn
  namespace_service_accounts = ["kube-system:ebs-csi-controller-sa"]
  attach_ebs_csi_policy      = true

  tags = local.common_tags
}

module "irsa_cluster_autoscaler" {
  source = "../../modules/irsa"

  role_name                        = "${local.cluster_name}-cluster-autoscaler"
  oidc_provider_arn                = module.eks.oidc_provider_arn
  namespace_service_accounts       = ["kube-system:cluster-autoscaler"]
  attach_cluster_autoscaler_policy = true
  cluster_autoscaler_cluster_names = [local.cluster_name]

  tags = local.common_tags
}

module "irsa_lb_controller" {
  source = "../../modules/irsa"

  role_name                              = "${local.cluster_name}-lb-controller"
  oidc_provider_arn                      = module.eks.oidc_provider_arn
  namespace_service_accounts             = ["kube-system:aws-load-balancer-controller"]
  attach_load_balancer_controller_policy = true

  tags = local.common_tags
}

# Single IRSA role for the application service account. IRSA only supports one
# IAM role per service account (one eks.amazonaws.com/role-arn annotation), so
# all app-facing permissions (S3, the placeholder secret, and the RDS-managed
# DB credentials secret) are combined into one policy here.
module "irsa_app" {
  source = "../../modules/irsa"

  role_name                  = "${local.cluster_name}-app"
  oidc_provider_arn          = module.eks.oidc_provider_arn
  namespace_service_accounts = ["${var.app_namespace}:${var.app_service_account_name}"]

  custom_policy_json = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = ["secretsmanager:GetSecretValue"]
        Resource = [
          module.app_secret.secret_arn,
          module.rds.master_user_secret_arn,
        ]
      },
      {
        Effect = "Allow"
        Action = ["s3:GetObject", "s3:PutObject", "s3:DeleteObject", "s3:ListBucket"]
        Resource = [
          module.app_bucket.bucket_arn,
          "${module.app_bucket.bucket_arn}/*",
        ]
      }
    ]
  })

  tags = local.common_tags
}

module "irsa_cloudwatch_observability" {
  source = "../../modules/irsa"

  role_name         = "${local.cluster_name}-cloudwatch-observability"
  oidc_provider_arn = module.eks.oidc_provider_arn
  namespace_service_accounts = [
    "amazon-cloudwatch:cloudwatch-agent",
    "amazon-cloudwatch:fluent-bit",
  ]
  managed_policy_arns = ["arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"]

  tags = local.common_tags
}

# --- EKS add-ons (need node group Ready + IRSA roles) ---

module "eks_addons" {
  source = "../../modules/eks-addons"

  cluster_name                      = module.eks.cluster_name
  vpc_cni_role_arn                  = module.irsa_vpc_cni.iam_role_arn
  ebs_csi_role_arn                  = module.irsa_ebs_csi.iam_role_arn
  cloudwatch_observability_role_arn = module.irsa_cloudwatch_observability.iam_role_arn

  tags = local.common_tags

  depends_on = [module.eks]
}
