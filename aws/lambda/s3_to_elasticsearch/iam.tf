resource "aws_iam_role" "s3_to_elasticsearch" {
  name = "s3_to_elasticsearch"

  assume_role_policy = <<POLICY
{
  "Version": "2008-10-17",
  "Statement": [
    {
      "Action": "sts:AssumeRole",
      "Principal": {
        "Service": "lambda.amazonaws.com"
      },
      "Effect": "Allow"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "bucket" {
  name = "logging_s3_permissions"
  role = "${aws_iam_role.s3_to_elasticsearch.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":[
        {
             "Effect": "Allow",
             "Action": [
                 "s3:Get*"
             ],
             "Resource": [
                 "arn:aws:s3:::*",
                 "arn:aws:s3:::*/*"
             ]
        },
        {
            "Effect": "Allow",
            "Action": [
                "logs:CreateLogGroup",
                "logs:CreateLogStream",
                "logs:PutLogEvents"
            ],
            "Resource": "arn:aws:logs:*:*:*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ec2:CreateNetworkInterface",
                "ec2:DescribeNetworkInterfaces",
                "ec2:DeleteNetworkInterface"
            ],
            "Resource": "*"
        }
     ]
}
EOF
}
