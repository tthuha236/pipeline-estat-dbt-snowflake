resource "aws_iam_policy" "lambda_custom_policy" {
    name = "LambdaCustomPolicy"
    policy = jsonencode({
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                  "s3:PutObject",
                  "s3:GetObject",
                  "s3:GetObjectVersion"
              ],
              "Resource": "arn:aws:s3:::estat-dbt-sf/*"
          },
          {
              "Effect": "Allow",
              "Action": [
                  "s3:ListBucket",
                  "s3:GetBucketLocation"
              ],
              "Resource": "arn:aws:s3:::estat-dbt-sf"
          }
      ]
  })
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