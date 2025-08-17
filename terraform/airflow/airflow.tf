
### security group for airflow instance
resource "aws_security_group" "airflow_sg" {
    description = "Security group for Airflow instance"
    vpc_id = var.vpc_id
    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = [var.allowed_ip] # ssh access, restricted as needed
    }
    ingress {
        from_port = 8080
        to_port = 8080
        protocol = "tcp"
        cidr_blocks = [var.allowed_ip] # Airflow UI, restrict as needed
    }
    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"] # allow all outbound
    }
    tags = {
        name = "Estat Airflow server sg"
    }
}

### instance profile for airflow instance
# create policy to allow airflow to invoke lambda and ecs task
resource "aws_iam_policy" "invoke_lambda_policy" {
    name = "InvokeLambdaPolicy"
    policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
        {
            "Effect": "Allow",
            "Action": "lambda:InvokeFunction",
            "Resource": "arn:aws:lambda:${var.region}:${var.account_id}:function:*"
        }
        ]
    })
}

resource "aws_iam_policy" "execute_ecs_task_policy" {
    name = "ExecuteEcsTaskPolicy"
    policy = jsonencode({
        "Version": "2012-10-17",
        "Statement": [
            {
            "Effect": "Allow",
            "Action": [
                "ecs:RunTask",
                "ecs:DescribeTasks",
                "ecs:DescribeTaskDefinition"
            ],
            "Resource": "arn:aws:ecs:${var.region}:${var.account_id}:*"
            }
        ]
        })
}

resource "aws_iam_policy" "access_s3_policy" {
    name = "AccessS3Policy"
    policy = jsonencode({
      "Version": "2012-10-17",
      "Statement": [
          {
              "Effect": "Allow",
              "Action": [
                  "s3:GetObject",
                  "s3:GetObjectVersion"
              ],
              "Resource": "arn:aws:s3:::estat-dbt-sf/airflow-config/*"
          },
          {
              "Effect": "Allow",
              "Action": [
                  "s3:ListBucket",
                  "s3:GetBucketLocation"
              ],
              "Resource": "arn:aws:s3:::estat-dbt-sf"
          }
      ]
  })
}

resource "aws_iam_policy" "access_secretsmanager_policy" {
    name = "AirflowSecretsManagerAccessPolicy"
    policy = jsonencode({
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": [
        "secretsmanager:GetSecretValue",
        "secretsmanager:DescribeSecret"
      ],
      "Resource": "arn:aws:secretsmanager:${var.region}:${var.account_id}:secret:airflow/connections/*"
    }
  ]
})
}

# create iam role and instance profile
module "airflow_role" {
    source = "../modules/iam_roles"
    role_name = "airflow_role"
    assume_role_policy = jsonencode({
        Version = "2012-10-17",
        Statement = [{
        Effect = "Allow",
        Principal = { Service = "ec2.amazonaws.com" },
        Action = "sts:AssumeRole"
        }]
    })
    policy_arns = [
        aws_iam_policy.invoke_lambda_policy.arn,
        aws_iam_policy.execute_ecs_task_policy.arn,
        aws_iam_policy.access_s3_policy.arn,
        aws_iam_policy.access_secretsmanager_policy.arn
    ]
    instance_profile_name = "airflow-server-instance-profile"
}

### airflow instance
resource "aws_instance" "airflow_server" {
    ami = var.ami
    instance_type = var.instance_type
    key_name = var.key_name
    user_data = file("${path.module}/user_data.sh")
    vpc_security_group_ids = [aws_security_group.airflow_sg.id]
    iam_instance_profile = module.airflow_role.instance_profile_name
    tags = {
        env: "${var.environment}"
        Name: "Airflow server"
    }
}