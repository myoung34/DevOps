output "cloud_custodian_task_definition_arn" {
  value = "${aws_ecs_task_definition.cloud-custodian.arn}"
}

output "cloud_custodian_repository_arn" {
  value = "${aws_ecr_repository.cloud-custodian.arn}"
}

output "cloud_custodian_repository_url" {
  value = "${aws_ecr_repository.cloud-custodian.repository_url}"
}

output "cluster" {
  variable "cloud-custodian"
}
