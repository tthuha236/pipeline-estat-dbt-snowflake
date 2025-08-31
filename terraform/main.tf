terraform { 
  cloud { 
    organization = "side_project" 
    workspaces { 
      name = "demo-workspace" 
    } 
  } 
}

provider "aws" {
  region = "ap-northeast-1"
}

data "aws_region" "current" {}
data "aws_caller_identity" "current" {}

locals {
  aws_region = data.aws_region.current.region
  aws_account_id = data.aws_caller_identity.current.account_id
}

module "lambda" {
  source = "./lambda"
  environment = var.environment
  runtime = "python3.11"
}

module "airflow" {
  source = "./airflow"
  environment = var.environment
  region = local.aws_region
  account_id = local.aws_account_id
  vpc_id = var.aws_vpc_id
  instance_type = var.aiflow_instance_type
  ami = var.airflow_ami_id
  key_name = var.airflow_key_name
  allowed_ip = var.allowed_ip
}

module "image_repo" {
  source = "./image_repo"
  name = "dbt_image_repo"
}