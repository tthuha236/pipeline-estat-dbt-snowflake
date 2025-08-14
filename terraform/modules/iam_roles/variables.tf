variable "role_name" {
    description = "Name of iam role"
    type = string
}
variable "assume_role_policy" {
    description = "Trust policy for iam role"
}
variable "policy_arns" {
    description = "List of ARNS for policies"
    type = list(string)
    default = []
}
variable "instance_profile_name" {
    description = "Name for instance profile"
    type = string
    default = null
}