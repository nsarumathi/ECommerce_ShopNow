# ==================================================
# EKS NODE GROUP IAM ROLE
# ==================================================

resource "aws_iam_role" "eks_node_role" {

  name = "ShopNow-EKS-Node-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "ec2.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })

  tags = {
    Name = "ShopNow-EKS-Node-Role"
  }
}


# ==================================================
# EKS NODE IAM POLICIES
# ==================================================

resource "aws_iam_role_policy_attachment" "eks_worker_node_policy" {

  role = aws_iam_role.eks_node_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
}


resource "aws_iam_role_policy_attachment" "eks_cni_policy" {

  role = aws_iam_role.eks_node_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
}


resource "aws_iam_role_policy_attachment" "eks_container_registry_policy" {

  role = aws_iam_role.eks_node_role.name

  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryPullOnly"
}


# ==================================================
# EKS MANAGED NODE GROUP
# ==================================================

resource "aws_eks_node_group" "shopnow" {

  cluster_name = aws_eks_cluster.shopnow.name

  node_group_name = var.eks_node_group_name

  node_role_arn = aws_iam_role.eks_node_role.arn

  subnet_ids = [
    aws_subnet.private.id,
    aws_subnet.private_2.id
  ]

  instance_types = [
    var.eks_node_instance_type
  ]

  capacity_type = "ON_DEMAND"

  scaling_config {

    desired_size = var.eks_node_desired_size

    min_size = var.eks_node_min_size

    max_size = var.eks_node_max_size
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_worker_node_policy,
    aws_iam_role_policy_attachment.eks_cni_policy,
    aws_iam_role_policy_attachment.eks_container_registry_policy
  ]

  tags = {
    Name        = "ShopNow-EKS-Node"
    Environment = "Development"
    Project     = "ShopNow"
  }
}