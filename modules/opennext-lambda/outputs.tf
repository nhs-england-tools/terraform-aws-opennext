output "lambda_function" {
  value = aws_lambda_function.function
}

output "lambda_function_url" {
  value = aws_lambda_function_url.function_url
}

output "cloudwatch_event_rule" {
  value = try(aws_cloudwatch_event_rule.scheduled_lambda_event_rule[0], null)
}

output "cloudwatch_event_target" {
  value = try(aws_cloudwatch_event_target.lambda_target[0], null)
}

output "lambda_role" {
  value = aws_iam_role.lambda_role
}

output "log_group" {
  value = aws_cloudwatch_log_group.function_log_group
}
