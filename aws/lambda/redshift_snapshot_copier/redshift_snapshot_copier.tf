provider "aws" {
  version = "1.2"
  region  = "${var.region}"
}

data "terraform_remote_state" "redshift_snapshot_copier_iam_role" {
  backend = "s3"

  config {
    bucket = "com-stratasan-terraform"
    key    = "iam/roles/redshift_snapshot_copier/terraform.tfstate"
    region = "${var.region}"
  }
}

resource "aws_lambda_function" "redshift_snapshot_copier" {
  filename         = "lambda_redshift_snapshot_copier.zip"
  function_name    = "redshift_snapshot_copier"
  role             = "${aws_iam_role.redshift_snapshot_copier_lambda.arn}"
  handler          = "lambda_function.lambda_handler"
  source_code_hash = "${base64sha256(file("lambda_redshift_snapshot_copier.zip"))}"
  runtime          = "python3.6"
  timeout          = "30"
}

resource "aws_cloudwatch_event_rule" "redshift_snapshot_copier_schedule" {
  name                = "redshift_snapshot_copier_schedule"
  description         = "Run every day"
  schedule_expression = "rate(1 day)"
}

resource "aws_cloudwatch_event_target" "redshift_snapshot_copier_lambda" {
  rule = "${aws_cloudwatch_event_rule.redshift_snapshot_copier_schedule.name}"
  arn  = "${aws_lambda_function.redshift_snapshot_copier.arn}"
}

resource "aws_lambda_permission" "allow_cloudwatch_to_call_redshift_snapshot_copier" {
  statement_id  = "AllowExecutionFromCloudWatchToBeanstalkGarbageCollector"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.redshift_snapshot_copier.function_name}"
  principal     = "events.amazonaws.com"
  source_arn    = "${aws_cloudwatch_event_rule.redshift_snapshot_copier_schedule.arn}"
}
