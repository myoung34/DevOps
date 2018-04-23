resource "aws_lambda_function" "rds_logs_to_s3" {
  filename         = "lambda_rds_logs_to_s3.zip"
  function_name    = "rds_logs_to_s3"
  role             = "${data.terraform_remote_state.rds_logs_to_s3_iam_role.role_arn}"
  handler          = "lambda_function.lambda_handler"
  source_code_hash = "${base64sha256(file("lambda_rds_logs_to_s3.zip"))}"
  runtime          = "python3.6"
  timeout          = "300"

  environment {
    variables = {
      S3BUCKET = "${data.terraform_remote_state.somebucket.bucket}"
    }
  }
}

resource "aws_cloudwatch_event_rule" "rds_logs_to_s3_schedule" {
  name                = "rds_logs_to_s3_schedule"
  description         = "Run every hour"
  schedule_expression = "rate(1 hour)"
}

resource "aws_cloudwatch_event_target" "rds_logs_to_s3_lambda" {
  rule = "${aws_cloudwatch_event_rule.rds_logs_to_s3_schedule.name}"
  arn  = "${aws_lambda_function.rds_logs_to_s3.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_rds_logs_to_s3" {
  statement_id  = "AllowExecutionFromCloudWatchToRDSLogShipper"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.rds_logs_to_s3.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.rds_logs_to_s3_schedule.arn}"
}

