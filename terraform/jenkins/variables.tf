variable "instance_type" {
    description = "EC2 instance type"
    type = string
}

variable "ami" {
    description = "AMI ID for EC2"
    type = string
}

variable "key_name" {
    description = "Name of the SSH key pair"
    type = string
}

variable "vpc_security_group_ids" {
    description = "List of security groups attached to EC2"
    type = list(string)
}

variable "iam_instance_profile" {
    description = "name of instance profile for ec2 instance"
    default = null
}

variable "environment" {}