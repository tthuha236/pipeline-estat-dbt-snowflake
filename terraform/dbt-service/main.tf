####### create  ecs cluster
resource "aws_ecs_cluster" "dbt_service_cluster" {
  name = var.cluster_name
}

####### create ecs task
# create repo for container image 
resource "aws_ecr_repository" "dbt_image_repo" {
  name                 = "dbt_image_repo"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }
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
    role_name = "dbt_task_role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
        Effect = "Allow",
        Principal = { Service = "ecs-tasks.amazonaws.com" },
        Action = "sts:AssumeRole"
        }]
    })
    policy_arns = [
        aws_iam_policy.access_secretsmanager_policy.arn,
        aws_iam_policy.get_ecr_authorization_policy.arn
    ]
}

# create task definition
resource "aws_ecs_task_definition" "dbt_task" {
  family = "dbt_task"
  requires_compatibilities = ["FARGATE"]
  network_mode = "awsvpc"
  cpu = 1024
  memory = 3072
  execution_role_arn = module.dbt_task_role.role_arn
  container_definitions = jsonencode([
    {
      "name"   : "dbt_container"
      "image"   : "${aws_ecr_repository.dbt_image_repo.repository_url}:latest"
      "essential": true
      "portMappings" = [
        {
          "containerPort" : 80
          "hostPort"      : 80
        }
      ],
      "secrets": [
          {
              name = "dbt_password",
              valueFrom = local.dbt_profile_info_json.dbt_password
          },
          {
              name =  "dbt_user",
              valueFrom = local.dbt_profile_info_json.dbt_user
          },
          {
              name =  "snowflake_account",
              valueFrom = local.dbt_profile_info_json.snowflake_account
          }
      ]
    }
  ])
}

#### create ecs service 
resource "aws_ecs_service" "dbt_service" {
    name = "dbt_service"
    cluster = aws_ecs_cluster.dbt_service_cluster.id
    task_definition = aws_ecs_task_definition.dbt_task.arn
    network_configuration {
        subnets = [var.subnet_id]
    }
}