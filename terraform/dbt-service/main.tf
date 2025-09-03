# create  ecs cluster
resource "aws_ecs_cluster" "dbt_service" {
  name = var.cluster_name
}

# define the secrets paramaters used in task
data "aws_secretsmanager_secret" "dbt_profile_info" {
    name = var.secrets_dbt_profile
}

data "aws_secretsmanager_secret_version" "dbt_profile_info_value" {
    secret_id = data.aws_secretsmanager_secret.dbt_profile_info.id
}

locals {
    dbt_profile_info_json = jsondecode(data.aws_secretsmanager_secret_version.dbt_profile_info_value.secret_string)
}

# create security group


# create iam_role for task
resource aws_iam_policy "access_secretsmanager_policy" {
    name = "DbtSecretsManagerAccessPolicy"
    policy = jsonencode({
    "Version": "2012-10-17",
    "Statement": [
        {
        "Effect": "Allow",
        "Action": [
            "secretsmanager:GetSecretValue",
            "secretsmanager:DescribeSecret",
            "secretsmanager:ListSecrets",
			"secretsmanager:DescribeSecret",
        ],
        "Resource": "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:estat/dbt/*"
        }
    ]
})
}

resource aws_iam_policy "get_ecr_authorization_policy" {
    name = "DbtEcrAuthorizationPolicy"
    policy = jsonencode({
    "Version": "2012-10-17",
	"Statement": [
		{
			"Sid": "VisualEditor0",
			"Effect": "Allow",
			"Action": [
				"ecr:DescribeRegistry",
				"ecr:DescribeImages",
				"ecr:GetAuthorizationToken",
				"ecr:DescribeRepositories"
			],
			"Resource": "*"
		}
	]
    })
}

module "dbt_task_role" {
    source = "../modules/iam_roles"
    name = "dbt_task_role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
        Effect = "Allow",
        Principal = { Service = "ecs-tasks.amazonaws.com" },
        Action = "sts:AssumeRole"
        }]
    })
    policy_arns = [
        aws.aws_iam_policy.access_secretsmanager_policy.arn,
        aws.aws_iam_policy.get_ecr_authorization_policy.arn
    ]
}

# create task definition
resource "aws_ecs_task_definition" "service" {
  family = "dbt_task"
  requires_compatibilities = ["FARGATE"]
  cpu = 1024
  memory = 3072
  task_role_arn = module.dbt_task_role.role_arn
  container_definitions = jsonencode([
    {
      "name"   : "dbt_container"
      "image"   : var.container_image
      "essential": "true"
      "portMappings" = [
        {
          "containerPort" : 80
          "hostPort"      : 80
        }
      ],
      "secrets": [
          {
              "name":"dbt_password",
              "value_from": local.dbt_profile_info_json.dbt_password
          },
          {
              "name": "dbt_user",
              "value_from": local.dbt_profile_info_json.dbt_user
          },
          {
              "name": "snowflake_account",
              "value_from": local.dbt_profile_info_json.snowflake_account
          }
      ]
    }
  ])
}