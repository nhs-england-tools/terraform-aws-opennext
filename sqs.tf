resource "aws_sqs_queue" "revalidation_queue" {
  name                              = "${var.prefix}-isr-revalidation.fifo"
  fifo_queue                        = true
  content_based_deduplication       = true
  kms_master_key_id                 = var.revalidation_queue_kms_key_arn
  kms_data_key_reuse_period_seconds = 300
}

resource "aws_lambda_event_source_mapping" "revalidation_queue_source" {
  depends_on = [module.revalidation_function.lambda_function]

  event_source_arn = aws_sqs_queue.revalidation_queue.arn
  function_name    = module.revalidation_function.lambda_function_arn
}