resource "aws_iam_policy" "lambda_custom_policy" {
    name = "LambdaCustomPolicy"
    policy = file("${path.module}/../policies/LambdaCustomPolicy.json")
}

module "lambda_role" {
  source = "../modules/iam_roles"
  role_name = "lambda_role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "lambda.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
  policy_arns = [
    "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole",
    aws_iam_policy.lambda_custom_policy.arn
  ]
}