variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "vpc_name" {
  description = "Name of the VPC"
  type        = string
  default     = "prod-vpc"
}

variable "vpc_cidr" {
  description = "CIDR block for VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "azs" {
  description = "Availability zones"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b", "us-east-1c"]
}

variable "private_subnets" {
  description = "Private subnets CIDR blocks"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24", "10.0.3.0/24"]
}

variable "public_subnets" {
  description = "Public subnets CIDR blocks"
  type        = list(string)
  default     = ["10.0.101.0/24", "10.0.102.0/24", "10.0.103.0/24"]
}

variable "allowed_ssh_cidr" {
  description = "Allowed CIDR blocks for SSH"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "allowed_udp_cidr" {
  description = "Allowed CIDR blocks for UDP 1194"
  type        = list(string)
  default     = ["0.0.0.0/0"]
}

variable "cluster_name" {
  description = "EKS cluster name"
  type        = string
  default     = "prod-eks"
}

variable "cluster_version" {
  description = "EKS cluster version"
  type        = string
  default     = "1.31"
}

variable "instance_types" {
  description = "EC2 instance types for EKS nodes"
  type        = list(string)
  default     = ["t3.medium"]
}

# Add these new variables
variable "node_min_size" {
  description = "Minimum number of nodes in autoscaling group"
  type        = number
  default     = 1
}

variable "node_max_size" {
  description = "Maximum number of nodes in autoscaling group"
  type        = number
  default     = 3
}

variable "node_desired_size" {
  description = "Desired number of nodes in autoscaling group"
  type        = number
  default     = 2
}

variable "aws_profile" {
  description = "AWS CLI profile name"
  type        = string
  default     = "default"
}
