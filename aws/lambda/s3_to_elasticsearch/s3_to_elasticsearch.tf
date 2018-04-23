resource "aws_lambda_function" "s3_to_elasticsearch" {
  filename         = "lambda_s3_to_elasticsearch.zip"
  function_name    = "s3_to_elasticsearch"
  role             = "${data.terraform_remote_state.s3_to_elasticsearch_iam_role.role_arn}"
  handler          = "lambda_function.lambda_handler"
  source_code_hash = "${base64sha256(file("lambda_s3_to_elasticsearch.zip"))}"
  runtime          = "python3.6"
  timeout          = "60"

  environment {
    variables = {
      ES_HOST="elasticsearch"
      ES_AUTH_ENABLED="False"
      ES_PORT="9200"
      ES_PROTOCOL="http"
    }
  }
}

resource "aws_lambda_permission" "allow_s3_to_call_s3_to_elasticsearch" {
  statement_id  = "AllowExecutionFromS3ToESShipperLambda"
  action        = "lambda:InvokeFunction"
  function_name = "${aws_lambda_function.s3_to_elasticsearch.function_name}"
  principal     = "s3.amazonaws.com"
}
