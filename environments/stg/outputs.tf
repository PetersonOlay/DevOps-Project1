output "cluster_name" {
  value = module.eks.cluster_name
}

output "cluster_endpoint" {
  value = module.eks.cluster_endpoint
}

output "vpc_id" {
  value = module.vpc.vpc_id
}

output "ecr_repository_url" {
  value = module.ecr.repository_url
}

output "frontend_ecr_repository_url" {
  value = module.frontend_ecr.repository_url
}

output "app_s3_bucket_name" {
  value = module.app_bucket.bucket_name
}

output "app_secret_arn" {
  value = module.app_secret.secret_arn
}

output "irsa_role_arns" {
  value = {
    vpc_cni                  = module.irsa_vpc_cni.iam_role_arn
    ebs_csi                  = module.irsa_ebs_csi.iam_role_arn
    cluster_autoscaler       = module.irsa_cluster_autoscaler.iam_role_arn
    lb_controller            = module.irsa_lb_controller.iam_role_arn
    app                      = module.irsa_app.iam_role_arn
    cloudwatch_observability = module.irsa_cloudwatch_observability.iam_role_arn
    grafana_cloudwatch       = module.irsa_grafana_cloudwatch.iam_role_arn
  }
}

output "irsa_grafana_cloudwatch_role_arn" {
  value = module.irsa_grafana_cloudwatch.iam_role_arn
}

output "irsa_app_role_arn" {
  value = module.irsa_app.iam_role_arn
}

output "rds_endpoint" {
  value = module.rds.db_instance_address
}

output "rds_port" {
  value = module.rds.db_instance_port
}

output "rds_db_name" {
  value = module.rds.db_name
}

output "rds_master_user_secret_arn" {
  value = module.rds.master_user_secret_arn
}

output "ci_deployer_access_key_id" {
  value = module.ci_deployer.access_key_id
}

output "ci_deployer_secret_access_key" {
  value     = module.ci_deployer.secret_access_key
  sensitive = true
}

output "app_namespace" {
  value = local.app_namespace
}

output "update_kubeconfig_command" {
  value = "aws eks update-kubeconfig --name ${module.eks.cluster_name} --region ${var.region}"
}
