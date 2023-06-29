# TODO: CKV_AWS_27: "Ensure all data stored in the SQS queue is encrypted"
resource "aws_sqs_queue" "revalidation_queue" {
  name                        = "${var.prefix}-isr-revalidation.fifo"
  fifo_queue                  = true
  content_based_deduplication = true
}

resource "aws_lambda_event_source_mapping" "revalidation_queue_source" {
  depends_on = [module.revalidation_function.lambda_function]

  event_source_arn = aws_sqs_queue.revalidation_queue.arn
  function_name    = module.revalidation_function.lambda_function_arn
}