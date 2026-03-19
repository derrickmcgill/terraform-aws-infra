terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}
resource "aws_subnet" "public" {
  for_each = {
    a = "10.0.1.0/24"
    b = "10.0.2.0/24"
  }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = "us-east-1${each.key}"
}

resource "aws_subnet" "private" {
  for_each = {
    a = "10.0.3.0/24"
    b = "10.0.4.0/24"
  }

  vpc_id            = aws_vpc.main.id
  cidr_block        = each.value
  availability_zone = "us-east-1${each.key}"
}
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
}

resource "aws_eip" "nat" {
  domain = "vpc"
}


resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id


}
resource "aws_route_table_association" "public" {
  for_each = aws_subnet.public

  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table_association" "private" {
  for_each = aws_subnet.private

  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}
resource "aws_instance" "public" {
  ami           = "ami-02dfbd4ff395f2a1b" # Amazon Linux 2 (us-east-1)
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.public["a"].id
  key_name      = "gilly" # 👈 existing key pair name

  vpc_security_group_ids      = [aws_security_group.public_ec2.id]
  associate_public_ip_address = true
}
resource "aws_instance" "private" {
  ami           = "ami-02dfbd4ff395f2a1b"
  instance_type = "t3.micro"
  subnet_id     = aws_subnet.private["a"].id
  key_name      = "gilly" # 👈 existing key pair name

  vpc_security_group_ids      = [aws_security_group.private_ec2.id]
  associate_public_ip_address = false
}
resource "aws_vpc_endpoint" "s3" {
  vpc_id            = aws_vpc.main.id
  service_name      = "com.amazonaws.us-east-1.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = [
    aws_route_table.private.id
  ]

  tags = {
    Name = "s3-gateway-endpoint"
  }
}

resource "aws_security_group" "public_ec2" {
  name   = "public-ec2-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # lock this down in real life
  }

  ingress {
    from_port   = -1
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "private_ec2" {
  name   = "private-ec2-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.public_ec2.id]
  }

  ingress {
    from_port       = -1
    to_port         = -1
    protocol        = "icmp"
    security_groups = [aws_security_group.public_ec2.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_launch_template" "app" {
  name_prefix   = "app-"
  image_id      = "ami-02dfbd4ff395f2a1b"
  instance_type = "t3.micro"
}

resource "aws_autoscaling_group" "app_asg" {
  name             = "app-asg"
  min_size         = 1
  max_size         = 3
  desired_capacity = 2

  vpc_zone_identifier = [
    aws_subnet.private["a"].id,
    aws_subnet.private["b"].id,
  ]

  launch_template {
    id      = aws_launch_template.app.id
    version = "$Latest"
  }

  health_check_type = "EC2"

  tag {
    key                 = "Name"
    value               = "asg-instance"
    propagate_at_launch = true
  }
}
