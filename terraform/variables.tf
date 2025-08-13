variable "aws_region" {
    type = string
    default = "ap-northeast-1"
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