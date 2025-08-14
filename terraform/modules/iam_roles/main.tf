resource "aws_iam_role" "this" {
    name = var.role_name
    assume_role_policy = var.assume_role_policy
}

resource "aws_iam_role_policy_attachment" "this"{
    count = length(var.policy_arns)
    role = aws_iam_role.this.name
    policy_arn = var.policy_arns[count.index]
}

# only create instance profile if instance_profile_name is provided (for EC2)
resource "aws_iam_instance_profile" "this" {
    count = var.instance_profile_name == null? 0: 1
    name = var.instance_profile_name
    role = aws_iam_role.this.name
}