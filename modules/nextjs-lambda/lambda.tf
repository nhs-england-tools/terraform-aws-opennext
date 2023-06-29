# TODO: CKV_AWS_272: "Ensure AWS Lambda function is configured to validate code-signing"
# TODO: CKV_AWS_116: "Ensure that AWS Lambda function is configured for a Dead Letter Queue(DLQ)"
# TODO: CKV_AWS_115: "Ensure that AWS Lambda function is configured for function-level concurrent execution limit"
# TODO: CKV_AWS_272: "Ensure AWS Lambda function is configured to validate code-signing"
resource "aws_lambda_function" "function" {
  filename         = var.filename
  source_code_hash = filebase64sha256(var.filename)

  function_name = var.prefix
  handler       = "index.handler"
  runtime       = var.runtime
  architectures = var.architectures
  role          = aws_iam_role.lambda_role.arn
  kms_key_arn   = var.kms_key_arn


  memory_size = var.memory_size
  timeout     = var.timeout
  publish     = var.publish

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = var.environment_variables
  }

  dynamic "vpc_config" {
    for_each = var.vpc_id == null ? [] : [1]

    content {
      security_group_ids = [aws_security_group.function_sg.id]
      subnet_ids         = var.subnet_ids
    }
  }
}

# TODO: CKV_AWS_258: "Ensure that Lambda function URLs AuthType is not None"
resource "aws_lambda_function_url" "function_url" {
  function_name      = aws_lambda_function.function.function_name
  authorization_type = "NONE"
  invoke_mode        = "BUFFERED"
}

# TODO: CKV_AWS_301: "Ensure that AWS Lambda function is not publicly accessible"
resource "aws_lambda_permission" "function_url_permission" {
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.function.function_name
  principal              = "*"
  function_url_auth_type = "NONE"
}

# TODO: CKV_AWS_23: "Ensure every security groups rule has a description"
# TODO: CKV2_AWS_5: "Ensure that Security Groups are attached to another resource"
resource "aws_security_group" "function_sg" {
  count = var.vpc_id == null ? 0 : 1

  name   = "${var.prefix}-sg"
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
      from_port        = ingress.value["from_port"]
      to_port          = ingress.value["to_port"]
      cidr_blocks      = ingress.value["cidr_blocks"]
      ipv6_cidr_blocks = ingress.value["ipv6_cidr_blocks"]
      prefix_list_ids  = ingress.value["prefix_list_ids"]
      protocol         = ingress.value["protocol"]
      security_groups  = ingress.value["security_groups"]
      self             = ingress.value["self"]
    }
  }

  dynamic "egress" {
    for_each = var.security_group_egress_rules

    content {
      from_port        = ingress.value["from_port"]
      to_port          = ingress.value["to_port"]
      cidr_blocks      = ingress.value["cidr_blocks"]
      ipv6_cidr_blocks = ingress.value["ipv6_cidr_blocks"]
      prefix_list_ids  = ingress.value["prefix_list_ids"]
      protocol         = ingress.value["protocol"]
      security_groups  = ingress.value["security_groups"]
      self             = ingress.value["self"]
    }
  }
}

resource "aws_lambda_permission" "allow_execution_from_eventbridge" {
  count         = var.create_eventbridge_scheduled_rule ? 1 : 0
  statement_id  = "AllowExecutionFromEventbridge"
  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.function.function_name
  principal     = "events.amazonaws.com"
}