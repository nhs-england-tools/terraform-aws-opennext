module "server_function" {
    source = "./modules/nextjs-lambda"

    prefix = "${var.prefix}-nextjs-server"
    description = "Next.js Server"
    filename = "build/server-function.zip"   
}

module "image_optimization_function" {
    source = "./modules/nextjs-lambda"

    prefix = "${var.prefix}-nextjs-image-optimization"
    description = "Next.js Image Optimization"
    filename = "build/image-optimization-function.zip"
    memory_size = 512

    environment_variables = {
        BUCKET_NAME = "some_bucket"
    }

    iam_policy_statements = [{
      effect = "Allow"
      actions = ["s3:GetObject"]
      resources = ["s3_bucket_arn"]
    }]
}

module "warmer_function" {
    source = "./modules/nextjs-lambda"

    create_eventbridge_scheduled_rule = true
    prefix = "${var.prefix}-nextjs-warmer"
    description = "Next.js Warmer"
    filename = "build/warmer-function.zip"
    memory_size = 128

    environment_variables = {
        FUNCTION_NAME = "server_lambda_func_name",
        CONCURRENCY = 1
    }

    iam_policy_statements = [{
      effect = "Allow"
      actions = ["lambda:InvokeFunction"]
      resources = ["server_lambda_func_arn"]
    }]
}