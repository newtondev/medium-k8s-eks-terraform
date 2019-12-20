variable "aws_region" {
  type        = string
  description = "AWS Region."
  default     = "eu-west-1"
}

variable "cluster_name" {
  type        = string
  description = "The name of the Kubernetes Cluster."
  default     = "my-eks"
}

variable "key_pair_name" {
  type        = string
  description = "SSH Key/Pair name."
  default     = "my-eks"
}

variable "eks_worker_ami_id" {
  type        = string
  description = "Amazon Machine Image for EKS Nodes."
  default     = "ami-00ac2e6b3cb38a9b9"
}
