output "role_arn" {
    value = aws_iam_role.this.arn
}

output "instance_profile_name" {
    value = var.instance_profile_name == null? null : aws_iam_instance_profile.this[0].name
}