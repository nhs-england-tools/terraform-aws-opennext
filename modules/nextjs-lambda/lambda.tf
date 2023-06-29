# TODO: CKV_AWS_115: "Ensure that AWS Lambda function is configured for function-level concurrent execution limit"
resource "aws_lambda_code_signing_config" "signing_config" {
  count = var.code_signing_config == null ? 0 : 1

  description = var.code_signing_config.description

  allowed_publishers {
    signing_profile_version_arns = var.code_signing_config.signing_profile_version_arns
  }

  dynamic "policies" {
    for_each = var.code_signing_config.untrusted_artfact_on_deployment == null ? [1] : [0]

    content {
      untrusted_artifact_on_deployment = var.code_signing_config.untrusted_artfact_on_deployment
    }
  }
}

resource "aws_lambda_function" "function" {
  filename         = var.filename
  source_code_hash = filebase64sha256(var.filename)

  function_name           = var.prefix
  handler                 = "index.handler"
  runtime                 = var.runtime
  architectures           = var.architectures
  role                    = aws_iam_role.lambda_role.arn
  kms_key_arn             = var.kms_key_arn
  code_signing_config_arn = try(aws_lambda_code_signing_config.signing_config[0].arn, null)


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

  dynamic "dead_letter_config" {
    for_each = var.dead_letter_config != null ? [true] : []

    content {
      target_arn = var.dead_letter_config.target_arn
    }
  }
}

# TODO: CKV_AWS_258: "Ensure that Lambda function URLs AuthType is not None"
resource "aws_lambda_function_url" "function_url" {
  function_name      = aws_lambda_function.function.function_name
  authorization_type = "NONE"
  invoke_mode        = "BUFFERED"
}

resource "aws_lambda_permission" "function_url_permission" {
  action                 = "lambda:InvokeFunctionUrl"
  function_name          = aws_lambda_function.function.function_name
  principal              = "cloudfront.amazonaws.com"
  function_url_auth_type = "NONE"
}

# TODO: CKV2_AWS_5: "Ensure that Security Groups are attached to another resource"
resource "aws_security_group" "function_sg" {
  count = var.vpc_id == null ? 0 : 1

  name   = "${var.prefix}-sg"
  vpc_id = var.vpc_id

  egress {
    description = "Allow HTTPS egress from Lambda function"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  dynamic "ingress" {
    for_each = var.security_group_ingress_rules

    content {
      description      = ingress.value["description"]
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
      description      = egress.value["description"]
      from_port        = egress.value["from_port"]
      to_port          = egress.value["to_port"]
      cidr_blocks      = egress.value["cidr_blocks"]
      ipv6_cidr_blocks = egress.value["ipv6_cidr_blocks"]
      prefix_list_ids  = egress.value["prefix_list_ids"]
      protocol         = egress.value["protocol"]
      security_groups  = egress.value["security_groups"]
      self             = egress.value["self"]
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