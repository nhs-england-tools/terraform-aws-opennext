output "queue" {
  value = aws_sqs_queue.revalidation_queue
}

output "queue_kms_key" {
  value = try(aws_kms_key.revalidation_queue_key[0], data.aws_kms_key.revalidation_queue_key[0])
}
