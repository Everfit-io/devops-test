resource "aws_ecr_repository" "devops_test" {
  name                 = "devops-test"
  image_tag_mutability = "IMMUTABLE"
}
