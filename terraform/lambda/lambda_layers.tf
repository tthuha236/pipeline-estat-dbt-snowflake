resource "aws_lambda_layer_version" "libs_for_crawl_data" {
    layer_name = "libs_for_crawl_data"
    filename = "${path.module}/../src/lambda_layers/libs_for_crawl_data.zip"
    compatible_runtimes = ["python3.11"]
}

resource "aws_lambda_layer_version" "libs_for_processing_excel" {
    layer_name = "libs_for_processing_excel"
    filename = "${path.module}/../src/lambda_layers/libs_for_processing_excel.zip"
    compatible_runtimes = ["python3.11"]
}