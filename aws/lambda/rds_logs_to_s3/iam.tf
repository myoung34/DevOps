resource "aws_iam_role" "rds_logs_to_s3" {
  name = "rds_logs_to_s3"

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

resource "aws_iam_role_policy" "perms" {
  name = "perms"
  role = "${aws_iam_role.rds_logs_to_s3.id}"

  policy = <<EOF
{
  "Version": "2012-10-17",
  "Statement":[
        {
             "Effect": "Allow",
             "Action": [
                 "s3:GetObject",
                 "s3:PutObject",
                 "s3:List*"
             ],
             "Resource": [
                 "arn:aws:s3:::*",
                 "arn:aws:s3:::*/*"
             ]
        },
        {
            
            "Effect": "Allow",
            "Action": [
                "rds:DescribeDBLogFiles",
                "rds:DownloadDBLogFilePortion",
                "rds:DescribeDBInstances"
            ],
            "Resource": [
                "*"
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
