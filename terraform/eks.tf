# ==================================================
# EKS CLUSTER IAM ROLE
# ==================================================

resource "aws_iam_role" "eks_cluster_role" {

  name = "ShopNow-EKS-Cluster-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "eks.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "ShopNow-EKS-Cluster-Role"
  }
}


# ==================================================
# EKS CLUSTER IAM POLICY
# ==================================================

resource "aws_iam_role_policy_attachment" "eks_cluster_policy" {

  role = aws_iam_role.eks_cluster_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
}


# ==================================================
# EKS CLUSTER
# ==================================================

resource "aws_eks_cluster" "shopnow" {

  name = var.eks_cluster_name

  role_arn = aws_iam_role.eks_cluster_role.arn

  version = var.eks_kubernetes_version

  vpc_config {

    subnet_ids = [
      aws_subnet.private.id,
      aws_subnet.private_2.id
    ]

    endpoint_private_access = true

    endpoint_public_access = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy
  ]

  tags = {
    Name        = "ShopNow-EKS"
    Environment = "Development"
    Project     = "ShopNow"
  }
}