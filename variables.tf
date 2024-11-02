variable "aws_region" {
  description = "AWS region to deploy resources"
  default     = "us-west-2"
}

variable "ecs_cluster_name" {
  description = "ECS Cluster name"
  type        = string
}

variable "ecs_service_name" {
  description = "ECS Service name"
  type        = string
}

variable "ecr_repository" {
  description = "ECR Repository URL for the Docker image"
  type        = string
}

variable "image_tag" {
  description = "Tag for the Docker image"
  type        = string
}
