data "archive_file" "fact_expense_lambda_crawl_zip" {
    type = "zip"
    source_file = "${path.module}/../src/lambda_handlers/fact_expense_lambda/crawl_file.py"
    output_path = "${path.module}/../src/lambda_handlers/fact_expense_lambda/crawl_file.zip"
}

data "archive_file" "fact_expense_lambda_clean_zip" {
    type = "zip"
    source_file = "${path.module}/../src/lambda_handlers/fact_expense_lambda/clean_file.py"
    output_path = "${path.module}/../src/lambda_handlers/fact_expense_lambda/clean_file.zip"
}

resource "aws_lambda_function" "fact_expense_crawl_data" {
    function_name = "estat-fact-expense-crawl-data-${var.environment}"
    handler = "crawl_file.lambda_handler"
    runtime = var.runtime
    filename = data.archive_file.fact_expense_lambda_crawl_zip.output_path
    role = module.lambda_role.role_arn
    layers = [
        aws_lambda_layer_version.libs_for_crawl_data.arn]
    timeout = 600
    memory_size = 128
    tags = {
        env: "${var.environment}"
    }
}

resource "aws_lambda_function" "fact_expense_clean_data" {
    function_name = "estat-fact-expense-clean-data-${var.environment}"
    handler = "clean_file.lambda_handler"
    runtime = var.runtime
    filename = data.archive_file.fact_expense_lambda_clean_zip.output_path
    role = module.lambda_role.role_arn
    layers = [
        "arn:aws:lambda:ap-northeast-1:336392948345:layer:AWSSDKPandas-Python311:22",
        aws_lambda_layer_version.libs_for_processing_excel.arn]
    timeout = 600
    memory_size = 128
    tags = {
        env: "${var.environment}"
    }
}