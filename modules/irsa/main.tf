# Generic IRSA role: one Kubernetes service account -> one scoped IAM role,
# via built-in policies (attach_* flags), an AWS-managed policy ARN, or a
# custom inline policy document.
resource "aws_iam_policy" "custom" {
  count = var.custom_policy_json != null ? 1 : 0

  name   = "${var.role_name}-policy"
  policy = var.custom_policy_json
  tags   = var.tags
}

module "irsa" {
  source  = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  version = "~> 5.39"

  role_name = var.role_name

  attach_vpc_cni_policy                  = var.attach_vpc_cni_policy
  vpc_cni_enable_ipv4                    = var.attach_vpc_cni_policy ? var.vpc_cni_enable_ipv4 : false
  attach_ebs_csi_policy                  = var.attach_ebs_csi_policy
  attach_cluster_autoscaler_policy       = var.attach_cluster_autoscaler_policy
  cluster_autoscaler_cluster_names       = var.cluster_autoscaler_cluster_names
  attach_load_balancer_controller_policy = var.attach_load_balancer_controller_policy

  role_policy_arns = merge(
    var.custom_policy_json != null ? { custom = aws_iam_policy.custom[0].arn } : {},
    { for idx, arn in var.managed_policy_arns : "managed_${idx}" => arn }
  )

  oidc_providers = {
    main = {
      provider_arn               = var.oidc_provider_arn
      namespace_service_accounts = var.namespace_service_accounts
    }
  }

  tags = var.tags
}
