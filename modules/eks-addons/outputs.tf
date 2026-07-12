# Names of every add-on this module installed.
output "addon_names" {
  value = [
    aws_eks_addon.vpc_cni.addon_name,
    aws_eks_addon.coredns.addon_name,
    aws_eks_addon.kube_proxy.addon_name,
    aws_eks_addon.metrics_server.addon_name,
    aws_eks_addon.ebs_csi_driver.addon_name,
    aws_eks_addon.cloudwatch_observability.addon_name,
  ]
}
