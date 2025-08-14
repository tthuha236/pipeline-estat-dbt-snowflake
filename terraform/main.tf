terraform { 
  cloud { 
    organization = "side_project" 
    workspaces { 
      name = "demo-workspace" 
    } 
  } 
}

provider "aws" {
  region = var.aws_region
}