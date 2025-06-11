variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "eu-west-2"
}

variable "name" {
  default = "jenkins-eks"
}

variable "k8s_version" {
  default = "1.32"
}

variable "vpc_cidr_block" {
  default = "172.16.0.0/16"
}
variable "private_subnet_cidr_blocks" {
  default = ["172.16.0.0/20", "172.16.16.0/20", "172.16.32.0/20"]
}
variable "public_subnet_cidr_blocks" {
  default = ["172.16.48.0/20", "172.16.64.0/20", "172.16.80.0/20"]
}

# variable "tags" {
#   default = {
#     App = "jenkins-eks-cluster"
#   }
# }

# variable "ecr_repo" {
#   default = "jenkins-repo"
# }
