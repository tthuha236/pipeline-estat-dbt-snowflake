resource "aws_instance" "jenkins" {
    ami = var.ami
    instance_type = var.instance_type
    key_name = var.key_name
    user_data = file("${path.module}/user_data.sh")
    vpc_security_group_ids = var.vpc_security_group_ids
    tags = {
        Name = "Estat jenkins server"
    }
    iam_instance_profile = var.iam_instance_profile
}