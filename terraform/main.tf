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

# Create EC2 instance to host jenkins server
module "jenkins" {
  source = "./modules/jenkins"
  ami = var.jenkins_ami_id
  instance_type = var.jenkins_instance_type
  vpc_security_group_ids = [aws_security_group.jenkins_sg.id]
  key_name = var.jenkins_key_name
}