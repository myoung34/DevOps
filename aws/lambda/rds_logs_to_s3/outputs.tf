output "function_arn" {
  value = "${aws_lambda_function.rds_logs_to_s3.arn}"
}

output "function_name" {
  value = "rds_logs_to_s3"
}
