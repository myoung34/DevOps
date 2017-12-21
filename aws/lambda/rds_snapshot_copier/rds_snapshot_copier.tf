provider "aws" {
  version = "1.2"
  region  = "${var.region}"
}

resource "aws_lambda_function" "rds_snapshot_copier" {
  filename         = "lambda_rds_snapshot_copier.zip"
  function_name    = "rds_snapshot_copier"
  role             = "${aws_iam_role.rds_snapshot_copier_lambda.arn}"
  handler          = "lambda_function.lambda_handler"
  source_code_hash = "${base64sha256(file("lambda_rds_snapshot_copier.zip"))}"
  runtime          = "python3.6"
  timeout          = "30"
}

resource "aws_cloudwatch_event_rule" "rds_snapshot_copier_schedule" {
  name                = "rds_snapshot_copier_schedule"
  description         = "Run every day"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "rds_snapshot_copier_lambda" {
  rule = "${aws_cloudwatch_event_rule.rds_snapshot_copier_schedule.name}"
  arn  = "${aws_lambda_function.rds_snapshot_copier.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_rds_snapshot_copier" {
  statement_id  = "AllowExecutionFromCloudWatchToBeanstalkGarbageCollector"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.rds_snapshot_copier.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.rds_snapshot_copier_schedule.arn}"
}
