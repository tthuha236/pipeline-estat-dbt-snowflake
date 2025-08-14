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

# Create security group for jenkins server
resource "aws_security_group" "jenkins_sg" {
  description = "Security group for Jenkins EC2 instance"
  vpc_id = var.aws_vpc_id
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = [var.allowed_ip] # ssh access, restrict as needed
  }

  ingress {
    from_port = 8080
    to_port = 8080
    protocol = "tcp"
    cidr_blocks = [var.allowed_ip] # Jenkins UI, restrict as needed
  }

  egress {
    from_port = 0
    to_port = 0
    protocol = "-1"
    cidr_blocks = ["0.0.0.0/0"] # Allow all outbound
  }

  tags = {
    Name = "Estat jenkins server sg"
  }
}

# create instance profile for jenkins server
resource "aws_iam_policy" "ecr_custom_policy" {
  name = "PushImageToECRCustomPolicy"
  policy = file("./policies/PushImageToECRCustomPolicy.json")
}

module "iam_roles" {
  source = "./modules/iam_roles"
  role_name = "jenkins-server-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [{
      Effect = "Allow",
      Principal = { Service = "ec2.amazonaws.com" },
      Action = "sts:AssumeRole"
    }]
  })
  policy_arns = [
    aws_iam_policy.ecr_custom_policy.arn
  ]
  instance_profile_name = "jenkins-server-instance-profile"
}


# Create EC2 instance to host jenkins server
module "jenkins" {
  source = "./modules/jenkins"
  ami = var.jenkins_ami_id
  instance_type = var.jenkins_instance_type
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name = var.jenkins_key_name
  iam_instance_profile = module.iam_roles.instance_profile_name
}