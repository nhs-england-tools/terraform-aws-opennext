output "cloudfront_logs" {
  value = module.cloudfront_logs
}

output "server" {
  value = module.server_function
}

output "image_optimization" {
  value = module.image_optimization_function
}

output "revalidation" {
  value = module.revalidation_function
}

output "warmer" {
  value = module.warmer_function
}

output "revalidation_queue" {
  value = module.revalidation_queue
}

output "cloudfront" {
  value = module.cloudfront
}
