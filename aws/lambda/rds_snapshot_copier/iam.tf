resource "aws_iam_role" "rds_snapshot_copier_lambda" {
  name = "rds_snapshot_copier_lambda"
  path = "/lambda/"

  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Sid": "",
      "Effect": "Allow",
      "Principal": {
        "Service": [
          "lambda.amazonaws.com"
        ]
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy" "rds_snapshot_copier_lambda" {
  name = "rds_snapshot_copier_lambda"
  role = "${aws_iam_role.rds_snapshot_copier_lambda.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "rds:DescribeDBInstances",
                "rds:DescribeDBSnapshots",
                "rds:CopyDBSnapshot",
                "rds:ListTagsForResource"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "rds:DeleteDBSnapshot"
            ],
            "Resource": "arn:aws:rds:us-east-1:*:snapshot:manual-*",
            "Condition": {
                "ForAllValues:StringEquals": {
                    "rds:ResourceTag/Managed_By": "lambda"
                }
            }
        }
    ]
}
EOF
}
