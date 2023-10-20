resource "aws_cloudwatch_event_rule" "scheduled_lambda_event_rule" {
  count = var.create_eventbridge_scheduled_rule ? 1 : 0

  name                = "${var.prefix}-scheduled-rule"
  schedule_expression = var.schedule_expression
}

resource "aws_cloudwatch_event_target" "lambda_target" {
  count = var.create_eventbridge_scheduled_rule ? 1 : 0

  arn  = aws_lambda_function.function.arn
  rule = aws_cloudwatch_event_rule.scheduled_lambda_event_rule[0].name
}
