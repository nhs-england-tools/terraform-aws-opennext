output "lambda_function" {
  value = aws_lambda_function.function
}

output "lambda_function_name" {
  value = aws_lambda_function.function.function_name
}

output "lambda_function_arn" {
  value = aws_lambda_function.function.arn
}

output "lambda_function_qualified_arn" {
  value = aws_lambda_function.function.qualified_arn
}

output "lambda_function_url_id" {
  value = aws_lambda_function_url.function_url.url_id
}

output "lambda_function_role_arn" {
  value = aws_iam_role.lambda_role.arn
}