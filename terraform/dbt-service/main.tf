# create  ecs cluster
resource "aws_ecs_cluster" "dbt_service" {
  name = var.cluster_name
}

# define the secrets paramaters used in task
data "aws_secretsmanager_secret" "dbt_profile_info" {
    name = "estat/dbt/profile_info"
}

data "aws_secretsmanager_secret_version" "dbt_profile_info_value" {
    secret_id = data.aws_secretsmanager_secret.dbt_profile_info.id
}

locals {
    dbt_profile_info_json = jsondecode(data.aws_secretsmanager_secret_version.dbt_profile_info_value.secret_string)
}

# create task definition
resource "aws_ecs_task_definition" "service" {
  family = "dbt_task"
  requires_compatibilities = ["FARGATE"]
  cpu = 1024
  memory = 3072
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