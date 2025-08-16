variable "environment" {
    description = "Deployment environment (dev, stg, prod)"
    type = string
    default = "dev"
}

variable "aws_vpc_id" {
    type = string
    default = "vpc-2c1f0f4b"
}

variable "allowed_ip" {
    type = string
    default = "211.10.51.214/32"
}

variable "jenkins_instance_type" {
    type = string
    default = "t2.small"
}

variable "jenkins_ami_id" {
    type = string
    default = "ami-054400ced365b82a0"
}

variable "jenkins_key_name" {
    type = string
    default = "estat-jenkins-key"
}

variable "aiflow_instance_type" {
    type = string
    default = "t3.large"
}

variable "airflow_ami_id" {
    type = string
    default = "ami-054400ced365b82a0"
}

variable "airflow_key_name" {
    type = string
    default = "estat-jenkins-key"
}