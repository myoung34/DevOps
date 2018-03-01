resource "aws_iam_role" "elasticache_snapshot_copier_lambda" {
  name = "elasticache_snapshot_copier_lambda"
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

resource "aws_iam_role_policy" "elasticache_snapshot_copier_lambda" {
  name = "elasticache_snapshot_copier_lambda"
  role = "${aws_iam_role.elasticache_snapshot_copier_lambda.id}"

  policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
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
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticache:Describe*",
                "elasticache:List*",
                "elasticache:AddTagsToResource",
                "elasticache:CopyClusterSnapshot",
                "elasticache:CreateSnapshot",
                "elasticache:CopySnapshot"
            ],
            "Resource": "*",
            "Condition": {
                "ForAllValues:StringEquals": {
                    "elasticache:RequestTag/Managed_by": "lambda"
                }
            }
        },
        {
            "Effect": "Allow",
            "Action": [
                "elasticache:DeleteClusterSnapshot",
                "elasticache:DeleteSnapshot"
            ],
            "Resource": [
                "arn:aws:elasticache:us-east-1::snapshot:*/manual-*"
            ],
            "Condition": {
                "ForAllValues:StringEquals": {
                    "elasticache:ResourceTag/Managed_by": "lambda"
                }
            }
        }
    ]
}
EOF
}

resource "aws_iam_instance_profile" "elasticache_snapshot_copier_lambda" {
  name = "elasticache_snapshot_copier_lambda"
  role = "${aws_iam_role.elasticache_snapshot_copier_lambda.name}"
}

resource "aws_iam_role_policy_attachment" "lambda_basic" {
  role       = "${aws_iam_role.elasticache_snapshot_copier_lambda.name}"
  policy_arn = "${data.terraform_remote_state.lambda_basic_policy.policy_arn}"
}
