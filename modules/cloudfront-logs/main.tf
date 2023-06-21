terraform {
  experiments = [module_variable_optional_attrs]

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.0"
    }
  }
}
