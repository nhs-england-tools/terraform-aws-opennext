locals {
  revalidation_kms_key_arn = try(data.aws_kms_key.revalidation_queue_key[0].arn, aws_kms_key.revalidation_queue_key[0].arn)
}

resource "aws_sqs_queue" "revalidation_queue" {
  name                              = "${var.prefix}-isr-revalidation.fifo"
  fifo_queue                        = true
  content_based_deduplication       = true
  kms_master_key_id                 = local.revalidation_kms_key_arn
  kms_data_key_reuse_period_seconds = 300
}

resource "aws_lambda_event_source_mapping" "revalidation_queue_source" {
  event_source_arn = aws_sqs_queue.revalidation_queue.arn
  function_name    = var.revalidation_function_arn
}
