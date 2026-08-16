variable "aws_region" {
  default = "ap-south-2"
}

variable "vpc_cidr" {
  default = "10.0.0.0/16"
}

variable "public_subnet" {
  default = "10.0.1.0/24"
}

variable "private_subnet" {
  default = "10.0.2.0/24"
}

variable "instance_type" {
  default = "t3.large"
}

variable "ami_id" {
  default = "ami-0199ac7c9fbf9ed83" //ubuntu 26.04LTS
}

variable "key_name" {
  description = "EC2 key pair name"
  type        = string
  default = "demo"
}

variable "public_subnet_2" {
  description = "CIDR block for the second public subnet"
  type        = string
  default     = "10.0.3.0/24"
}

variable "private_subnet_2" {
  description = "CIDR block for the second private subnet"
  type        = string
  default     = "10.0.4.0/24"
}

variable "availability_zone_1" {
  description = "Primary Availability Zone"
  type        = string
  default     = "ap-south-2a"
}

variable "availability_zone_2" {
  description = "Secondary Availability Zone"
  type        = string
  default     = "ap-south-2b"
}

# ==================================================
# EKS CONFIGURATION
# ==================================================

variable "eks_cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "shopnow-eks"
}

variable "eks_kubernetes_version" {
  description = "Kubernetes version for EKS"
  type        = string
  default     = "1.34"
}

variable "eks_node_group_name" {
  description = "Name of the EKS managed node group"
  type        = string
  default     = "shopnow-node-group"
}

variable "eks_node_instance_type" {
  description = "EC2 instance type for EKS worker nodes"
  type        = string
  default     = "t3.medium"
}

variable "eks_node_desired_size" {
  description = "Desired number of EKS worker nodes"
  type        = number
  default     = 2
}

variable "eks_node_min_size" {
  description = "Minimum number of EKS worker nodes"
  type        = number
  default     = 2
}

variable "eks_node_max_size" {
  description = "Maximum number of EKS worker nodes"
  type        = number
  default     = 3
}