output "function_arn" {
  value = "${aws_lambda_function.s3_to_elasticsearch.arn}"
}

output "function_name" {
  value = "s3_to_elasticsearch"
}
