output "lambda_cloudwatch_log_group" {
  description = "CloudWatch Logs group used by the Lambda function."
  value       = aws_cloudwatch_log_group.lambda_log_group
}

output "logs_cloudwatch_log_group" {
  description = "CloudWatch Logs group storing the CloudFront logs."
  value       = aws_cloudwatch_log_group.target_log_group
}

output "lambda_function" {
  description = "Lambda function used to forward CloudFront logs."
  value       = aws_lambda_function.cloudfront_logs_function
}

output "logs_s3_bucket" {
  description = "S3 Bucket storing CloudFront logs."
  value       = aws_s3_bucket.logs
}