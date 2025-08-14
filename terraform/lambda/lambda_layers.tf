resource "aws_lambda_layer_version" "libs_for_crawl_data" {
    layer_name = "libs_for_crawl_data"
    filename = "${path.module}/../src/lambda_layers/libs_for_crawl_data.zip"
    compatible_runtimes = ["python3.11"]
}