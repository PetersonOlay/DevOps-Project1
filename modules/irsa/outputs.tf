# Role identifiers to annotate onto the matching Kubernetes service account.
output "iam_role_arn" {
  value = module.irsa.iam_role_arn
}

output "iam_role_name" {
  value = module.irsa.iam_role_name
}
