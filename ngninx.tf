variable "nginx_app_name" {
  description = "Name of Application Container"
  default = "nginx"
}
variable "nginx_app_image" {
  description = "Docker image to run in the ECS cluster"
  default = "nginx:latest"
}
variable "nginx_app_port" {
  description = "Port exposed by the Docker image to redirect traffic to"
  default = 80
}
variable "nginx_app_count" {
  description = "Number of Docker containers to run"
  default = 2
}
variable "nginx_fargate_cpu" {
  description = "Fargate instance CPU units to provision (1 vCPU = 1024 CPU units)"
  default = "1024"
}
variable "nginx_fargate_memory" {
  description = "Fargate instance memory to provision (in MiB)"
  default = "2048"
}



# container template
data "template_file" "nginx_app" {
  template = file("./nginx.json")
  vars = {
    app_name = var.nginx_app_name
    app_image = var.nginx_app_image
    app_port = var.nginx_app_port
    fargate_cpu = var.nginx_fargate_cpu
    fargate_memory = var.nginx_fargate_memory
    aws_region = var.aws_region
  }
}
# ECS task definition
resource "aws_ecs_task_definition" "nginx_app" {
  family = "nginx-task"
  execution_role_arn = aws_iam_role.ecsTaskExecutionRole.arn
  network_mode = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu = var.nginx_fargate_cpu
  memory = var.nginx_fargate_memory
  container_definitions = data.template_file.nginx_app.rendered
}
# ECS service
resource "aws_ecs_service" "nginx_app" {
  name = var.nginx_app_name
  cluster = aws_ecs_cluster.aws-ecs.id
  task_definition = aws_ecs_task_definition.nginx_app.arn
  desired_count = var.nginx_app_count
  launch_type = "FARGATE"
  network_configuration {
    security_groups = [aws_security_group.ecs_tasks.id]
    subnets = aws_subnet.aws-subnet.*.id
    assign_public_ip = true
  }
  load_balancer {
    target_group_arn = aws_alb_target_group.nginx_app.id
    container_name = var.nginx_app_name
    container_port = var.nginx_app_port
  }
  depends_on = [aws_alb_listener.front_end]
  tags = {
    Name = "${var.nginx_app_name}-nginx-ecs"
  }
}



# ALB Security Group: Edit to restrict access to the application
resource "aws_security_group" "aws-lb" {
  name = "${var.nginx_app_name}-load-balancer"
  description = "Controls access to the ALB"
  vpc_id = aws_vpc.aws-vpc.id
  ingress {
    protocol = "tcp"
    from_port = var.nginx_app_port
    to_port = var.nginx_app_port
    cidr_blocks = [var.app_sources_cidr]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.nginx_app_name}-load-balancer"
  }
}
# Traffic to the ECS cluster from the ALB
resource "aws_security_group" "aws-ecs-tasks" {
  name = "${var.nginx_app_name}-ecs-tasks"
  description = "Allow inbound access from the ALB only"
  vpc_id = aws_vpc.aws-vpc.id
  ingress {
    protocol = "tcp"
    from_port = var.nginx_app_port
    to_port = var.nginx_app_port
    security_groups = [aws_security_group.aws-lb.id]
  }
  egress {
    protocol = "-1"
    from_port = 0
    to_port = 0
    cidr_blocks = ["0.0.0.0/0"]
  }
  tags = {
    Name = "${var.nginx_app_name}-ecs-tasks"
  }
}



resource "aws_alb" "main" {
  name = "${var.nginx_app_name}-load-balancer"
  subnets = aws_subnet.aws-subnet.*.id
  security_groups = [aws_security_group.aws-lb.id]
  tags = {
    Name = "${var.app_name}-alb"
  }
}
resource "aws_alb_target_group" "nginx_app" {
  name = "${var.nginx_app_name}-target-group"
  port = 80
  protocol = "HTTP"
  vpc_id = aws_vpc.aws-vpc.id
  target_type = "ip"
  health_check {
    healthy_threshold = "3"
    interval = "30"
    protocol = "HTTP"
    matcher = "200"
    timeout = "3"
    path = "/"
    unhealthy_threshold = "2"
  }
  tags = {
    Name = "${var.nginx_app_name}-alb-target-group"
  }
}
# Redirect all traffic from the ALB to the target group
resource "aws_alb_listener" "front_end" {
  load_balancer_arn = aws_alb.main.id
  port = var.nginx_app_port
  protocol = "HTTP"
  default_action {
    target_group_arn = aws_alb_target_group.nginx_app.id
    type = "forward"
  }
}
# output nginx public ip
output "nginx_dns_lb" {
  description = "DNS load balancer"
  value = aws_alb.main.dns_name
}