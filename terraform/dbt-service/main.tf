####### create  ecs cluster
resource "aws_ecs_cluster" "dbt_service_cluster" {
  name = var.cluster_name
}

####### create ecs task
# get information of repo for container image 
data "aws_ecr_repository" "repo" {
  name  = var.dbt_repo_name
}

# define the secrets paramaters used in task
data "aws_secretsmanager_secret" "dbt_profile_info" {
    name = var.secrets_dbt_profile
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
        "Resource": [data.aws_secretsmanager_secret.dbt_profile_info.arn]
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
        aws_iam_policy.get_ecr_authorization_policy.arn,
        "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
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
      "name"   : "dbt_image"
      "image"   : "${data.aws_ecr_repository.repo.repository_url}:latest"
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
              valueFrom = "${data.aws_secretsmanager_secret.dbt_profile_info.arn}:dbt_password::"
          },
          {
              name =  "dbt_user",
              valueFrom = "${data.aws_secretsmanager_secret.dbt_profile_info.arn}:dbt_user::"
          },
          {
              name =  "snowflake_account",
              valueFrom = "${data.aws_secretsmanager_secret.dbt_profile_info.arn}:snowflake_account::"
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