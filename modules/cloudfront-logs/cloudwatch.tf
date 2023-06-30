resource "aws_cloudwatch_log_group" "target_log_group" {
  name              = var.log_group_name
  retention_in_days = var.retention
  kms_key_id        = try(aws_kms_key.cloudwatch_logs_key[0].arn, var.cloudwatch_log_group_kms_key_arn)
}
