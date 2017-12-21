resource "aws_iam_role" "redshift_snapshot_copier_lambda" {
  name = "redshift_snapshot_copier_lambda"
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

resource "aws_iam_role_policy" "redshift_snapshot_copier_lambda" {
  name = "redshift_snapshot_copier_lambda"
  role = "${aws_iam_role.redshift_snapshot_copier_lambda.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "redshift:DescribeClusters",
                "redshift:DescribeClusterSnapshots",
                "redshift:CreateTags",
                "redshift:DeleteTags",
                "redshift:DescribeTags",
                "redshift:UpdateTags",
                "redshift:CopyClusterSnapshot"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "redshift:DeleteClusterSnapshot"
            ],
            "Resource": [
                "arn:aws:redshift:us-east-1:*:snapshot:*/manual-*"
            ]
        }
    ]
}
EOF
}
