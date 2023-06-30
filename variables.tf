variable "vpc_id" {
  description = "ID of the existing VPC"
  default     = "vpc-0fc2aca84309a0add"
}

variable "subnet_private_tag" {
  description = "Tag of existing private subnets"
  default     = "private_ecs"
}

variable "subnet_public_tag" {
  description = "Tag of existing public subnets"
  default     = "public_ecs"
}
