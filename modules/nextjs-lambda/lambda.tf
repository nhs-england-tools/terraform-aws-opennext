resource "aws_lambda_function" "function" {
  filename         = var.filename
  source_code_hash = filebase64sha256(var.filename)

  function_name = var.prefix
  handler       = "index.handler"
  runtime       = var.runtime
  architectures = var.architectures
  role          = aws_iam_role.lambda_role.arn

  memory_size = var.memory_size
  timeout     = var.timeout

  environment {
    variables = var.environment_variables
  }

  dynamic "vpc_config" {
    for_each = var.vpc_id == null ? [] : [1]

    content {
      security_group_ids = [aws_security_group.function_sg.id]
      subnet_ids = var.subnet_ids
    }
  }
}

resource "aws_lambda_function_url" "function_url" {
  function_name = aws_lambda_function.function.function_name
  authorization_type = "NONE"

  cors {
    allow_credentials = true
    allow_origins = ["*"]
    allow_methods = ["*"]
    allow_headers = ["date", "keep-alive"]
    expose_headers = ["date", "keep-alive"]
    max_age = 86400
  }
}

resource "aws_security_group" "function_sg" {
  count = var.vpc_id == null ? 0 : 1
  
  name = "${var.prefix}-sg"
  vpc_id = var.vpc_id

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = var.security_group_ingress_rules

    content {
      from_port = ingress.value["from_port"]
      to_port = ingress.value["to_port"]
      cidr_blocks = ingress.value["cidr_blocks"]
      ipv6_cidr_blocks = ingress.value["ipv6_cidr_blocks"]
      prefix_list_ids = ingress.value["prefix_list_ids"]
      protocol = ingress.value["protocol"]
      security_groups = ingress.value["security_groups"]
      self = ingress.value["self"]
    }
  }

  dynamic "egress" {
    for_each = var.security_group_egress_rules

    content {
      from_port = ingress.value["from_port"]
      to_port = ingress.value["to_port"]
      cidr_blocks = ingress.value["cidr_blocks"]
      ipv6_cidr_blocks = ingress.value["ipv6_cidr_blocks"]
      prefix_list_ids = ingress.value["prefix_list_ids"]
      protocol = ingress.value["protocol"]
      security_groups = ingress.value["security_groups"]
      self = ingress.value["self"]
    }
  }
}

resource "aws_lambda_permission" "allow_execution_from_eventbridge" {
  count = var.create_eventbridge_scheduled_rule ? 1 : 0
  statement_id = "AllowExecutionFromEventbridge"
  action = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal = "events.amazonaws.com"
}