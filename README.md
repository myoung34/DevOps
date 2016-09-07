# DevOps
Things I've written that I don't want to disappear

# Files

1. [EBS Snapshotter in Lambda (CFT)](aws/lambda/cloudformation/ebs_snapshotter_lambda.json) - This is a CFT template to create 4 lambda tasks.
  1. `EbsSnapshotCreatorLambdaFunction` - This is the real work. It basically searches Ec2 instances for a tag (defined as a set of CFT params)
  1. `EbsSnapshotDailyLambdaFunction` - Runs daily with a retention period of 7 days
  1. `EbsSnapshotWeeklyLambdaFunction` - Runs weekly with a retention period of 14 days
  1. `EbsSnapshotJanitorLambdaFunction` - Runs daily and deletes ebs snapshots that were created by the `EbsSnapshotCreatorLambdaFunction` task with dates <date run (daily)
