data "archive_file" "lambda_zip" {
  type = "zip"

  source_dir  = var.source_dir
  output_path = "${var.output_dir}${var.prefix}.zip"
}
