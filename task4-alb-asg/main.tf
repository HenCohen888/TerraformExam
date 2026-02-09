module "network" {
  source = "../modules/vpc-ec2"

  vpc_cidr = "10.0.0.0/16"

  public_subnet_cidr  = ["10.0.1.0/24", "10.0.3.0/24"]
  private_subnet_cidr = ["10.0.2.0/24", "10.0.4.0/24"]


  instance_type       = "t2.micro"
  associate_public_ip = true
}


# Ubuntu 22.04 AMI
data "aws_ami" "ubuntu_2204" {
  most_recent = true
  owners      = ["099720109477"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# ALB security group: allow HTTP from anywhere
resource "aws_security_group" "alb_sg" {
  name        = "task4-alb-sg"
  description = "Allow HTTP to ALB"
  vpc_id      = module.network.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Instance security group: allow HTTP only from ALB
resource "aws_security_group" "instance_sg" {
  name        = "task4-instance-sg"
  description = "Allow HTTP from ALB"
  vpc_id      = module.network.vpc_id

  ingress {
    from_port       = 80
    to_port         = 80
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Target Group
resource "aws_lb_target_group" "tg" {
  name     = "task4-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = module.network.vpc_id

  health_check {
    path = "/"
  }
}

# Application Load Balancer
resource "aws_lb" "alb" {
  name               = "task4-alb"
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_sg.id]
  subnets            = module.network.public_subnet_ids
}

# Listener
resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

# Launch Template for ASG instances
resource "aws_launch_template" "lt" {
  name_prefix   = "task4-lt-"
  image_id      = data.aws_ami.ubuntu_2204.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.instance_sg.id]

  user_data = base64encode(<<-EOF
    #!/bin/bash
    apt-get update -y
    apt-get install -y nginx
    systemctl enable nginx
    systemctl start nginx
    echo "Hello from Auto Scaling Group" > /var/www/html/index.html
  EOF
  )
}

# Auto Scaling Group (min 1, max 3)
resource "aws_autoscaling_group" "asg" {
  name                = "task4-asg"
  min_size            = 1
  max_size            = 3
  desired_capacity    = 1
  vpc_zone_identifier = module.network.public_subnet_ids

  target_group_arns = [aws_lb_target_group.tg.arn]

  launch_template {
    id      = aws_launch_template.lt.id
    version = "$Latest"
  }
}
