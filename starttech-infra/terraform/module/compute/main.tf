##################################
# VARIABLES
##################################

variable "vpc_id" {
  description = "VPC ID"
  type        = string
}

variable "public_subnets" {
  description = "Public subnet IDs"
  type        = list(string)
}

variable "mongodb_uri" {
  description = "MongoDB Atlas connection string"
  type        = string
}

##################################
# SECURITY GROUPS
##################################

# API / EC2 Security Group
resource "aws_security_group" "api" {
  name        = "starttech-api-sg"
  description = "Allow HTTP traffic to API"
  vpc_id      = var.vpc_id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # assessment only
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Redis Security Group
resource "aws_security_group" "redis" {
  name   = "starttech-redis-sg"
  vpc_id = var.vpc_id

  ingress {
    from_port       = 6379
    to_port         = 6379
    protocol        = "tcp"
    security_groups = [aws_security_group.api.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

##################################
# ELASTICACHE (REDIS)
##################################

resource "aws_elasticache_subnet_group" "redis" {
  name       = "starttech-redis-subnet-group"
  subnet_ids = var.public_subnets
}

resource "aws_elasticache_cluster" "redis" {
  cluster_id           = "starttech-redis"
  engine               = "redis"
  node_type            = "cache.t2.micro"
  num_cache_nodes      = 1
  parameter_group_name = "default.redis7"

  subnet_group_name  = aws_elasticache_subnet_group.redis.name
  security_group_ids = [aws_security_group.redis.id]
}

##################################
# APPLICATION LOAD BALANCER
##################################

resource "aws_lb" "this" {
  name               = "starttech-alb"
  load_balancer_type = "application"
  subnets            = var.public_subnets
  security_groups    = [aws_security_group.api.id]
}

resource "aws_lb_target_group" "api" {
  name     = "starttech-api-tg"
  port     = 80
  protocol = "HTTP"
  vpc_id   = var.vpc_id

  health_check {
    path                = "/health"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "http" {
  load_balancer_arn = aws_lb.this.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.api.arn
  }
}

##################################
# LAUNCH TEMPLATE
##################################

resource "aws_launch_template" "api" {
  name_prefix   = "starttech-api-"
  instance_type = "t3.micro"

  user_data = base64encode(
    templatefile("${path.module}/user-data.sh", {
      mongodb_uri = var.mongodb_uri
      redis_host  = aws_elasticache_cluster.redis.cache_nodes[0].address
      redis_port  = 6379
    })
  )

  network_interfaces {
    security_groups = [aws_security_group.api.id]
  }
}


##################################
# AUTO SCALING GROUP
##################################

resource "aws_autoscaling_group" "api" {
  name                = "starttech-api-asg"
  min_size            = 1
  max_size            = 2
  desired_capacity    = 1
  vpc_zone_identifier = var.public_subnets

  launch_template {
    id      = aws_launch_template.api.id
    version = "$Latest"
  }

  target_group_arns = [aws_lb_target_group.api.arn]
}
