#############################
# Elastic Beanstalk Application
#############################
resource "aws_elastic_beanstalk_application" "node_app" {
  name        = "SimpleNodeApp"
  description = "Node.js Elastic Beanstalk app without S3"
}

#############################
# IAM Roles
#############################
resource "aws_iam_role" "eb_service_role" {
  name = "SimpleNodeApp-service-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "elasticbeanstalk.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_role" "eb_instance_role" {
  name = "SimpleNodeApp-instance-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "ec2.amazonaws.com" }
      Action    = "sts:AssumeRole"
    }]
  })
}

resource "aws_iam_instance_profile" "eb_instance_profile" {
  name = "SimpleNodeApp-instance-profile"
  role = aws_iam_role.eb_instance_role.name
}

resource "aws_iam_role_policy_attachment" "eb_web_tier" {
  role       = aws_iam_role.eb_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWebTier"
}

resource "aws_iam_role_policy_attachment" "eb_worker_tier" {
  role       = aws_iam_role.eb_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/AWSElasticBeanstalkWorkerTier"
}

resource "aws_iam_role_policy_attachment" "eb_cloudwatch_logs" {
  role       = aws_iam_role.eb_instance_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

#############################
# Elastic Beanstalk Environment
#############################
resource "aws_elastic_beanstalk_environment" "node_env" {
  name                = "SimpleNodeApp-env"
  application         = aws_elastic_beanstalk_application.node_app.name
  solution_stack_name = "64bit Amazon Linux 2023 v6.10.3 running Node.js 24"

  setting {
    namespace = "aws:autoscaling:launchconfiguration"
    name      = "IamInstanceProfile"
    value     = aws_iam_instance_profile.eb_instance_profile.name
  }

  setting {
    namespace = "aws:elasticbeanstalk:environment"
    name      = "ServiceRole"
    value     = aws_iam_role.eb_service_role.arn
  }
}

output "application_name" {
  value = aws_elastic_beanstalk_application.node_app.name
}

output "environment_name" {
  value = aws_elastic_beanstalk_environment.node_env.name
}