resource "aws_iam_user" "this" {
  name = var.user_name
  tags = var.tags
}

resource "aws_iam_access_key" "this" {
  user = aws_iam_user.this.name
}

data "aws_iam_policy_document" "permissions" {
  statement {
    sid       = "EcrAuth"
    effect    = "Allow"
    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "EcrPush"
    effect = "Allow"
    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:InitiateLayerUpload",
      "ecr:UploadLayerPart",
      "ecr:CompleteLayerUpload",
      "ecr:PutImage",
      "ecr:BatchGetImage",
      "ecr:GetDownloadUrlForLayer",
    ]
    resources = var.ecr_repository_arns
  }

  statement {
    sid       = "EksDescribe"
    effect    = "Allow"
    actions   = ["eks:DescribeCluster"]
    resources = [var.eks_cluster_arn]
  }
}

resource "aws_iam_user_policy" "this" {
  name   = "${var.user_name}-policy"
  user   = aws_iam_user.this.name
  policy = data.aws_iam_policy_document.permissions.json
}

resource "aws_eks_access_entry" "this" {
  cluster_name  = var.eks_cluster_name
  principal_arn = aws_iam_user.this.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "this" {
  cluster_name  = var.eks_cluster_name
  principal_arn = aws_iam_user.this.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSEditPolicy"

  access_scope {
    type       = "namespace"
    namespaces = [var.kubernetes_namespace]
  }
}
