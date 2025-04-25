variable "kong_cluster_prefix" {
  type = string
  description = "The Konnect cluster prefix" # Example 123456a1b2
}

variable "kong_cluster_region" {
  type = string
  description = "The Konnect cluster region" # Example us, eu
  default = "eu"
}

variable "aws_secretsmanager_kong_cert_arn" {
  type = string
  description = "Amazon Resource Name (ARN) of AWS secrets manager cert (PEM-encoded)"
}

variable "aws_secretsmanager_kong_cert_key_arn" {
  type = string
  description = "Amazon Resource Name (ARN) of AWS secrets manager cert key"
}

variable "aws_acm_certificate_arn" {
  type = string
  description = "ARN of the ACM certificate for the ALB"
}