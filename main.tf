#After creating the ECR repo, You should prepare your containerized App Dokerfile to build and publish the App image to ECR repo we can do that from console or by Ansible
resource "aws_ecr_repository" "phpapplication_ecr_repo" {
  name = var.repo_name 
  lifecycle {
    create_before_destroy = true
  }
}
resource "aws_ecs_cluster" "ReachProjectCluster" {
  name = "ReachProjectCluster"
  lifecycle {
    create_before_destroy = true
  }
}
data "aws_iam_policy_document" "assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "ecsTaskExecutionRole" {
  name               = "ecsTaskExecutionRole"
  assume_role_policy = "${data.aws_iam_policy_document.assume_role_policy.json}"
}
resource "aws_iam_role_policy_attachment" "ecsTaskExecutionRole_policy" {
  role       = "${aws_iam_role.ecsTaskExecutionRole.name}"
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}
resource "aws_ecs_task_definition" "my_first_task" {
  family                   = "my-first-task" 
  container_definitions    = <<DEFINITION
  [
    {
      "name": "my-first-task",
      "image": "${aws_ecr_repository.phpapplication_ecr_repo.repository_url}",
      "essential": true,
      "portMappings": [
        {
          "containerPort": 80,
          "hostPort": 80
        }
      ],
      "memory": 512,
      "cpu": 256
      "environment" : [
        {
         { "name" : "USER", "value" : "${aws_db_instance.db_instance.username}" },
         { "name" : "PASSWORD", "value" : "${var.password}" },
         { "name" : "HOST", "value" :  "${aws_db_instance.db_instance.endpoint}"},
         { "name" : "DATABASE", "value" : "${aws_db_instance.db_instance.db_name}" }
        }
      ]
      
    }
  ]
  DEFINITION
  requires_compatibilities = ["FARGATE"] # Stating that we are using ECS Fargate
  network_mode             = "awsvpc"    # Using awsvpc as our network mode as this is required for Fargate
  memory                   = 512         # Specifying the memory our container requires
  cpu                      = 256         # Specifying the CPU our container requires
  execution_role_arn       = "${aws_iam_role.ecsTaskExecutionRole.arn}"
}
resource "aws_vpc" "Reachvpc" {
  cidr_block = var.cidr_block_vpc

  tags = {
    Env  = "production"
    Name = "Reachvpc"
  }
}
resource "aws_subnet" "Reachsubnet1" {
  availability_zone       = var.az1 
  cidr_block              = var.cidr_block_subnet1
  map_public_ip_on_launch = true

  tags = {
    Env  = "production"
    Name = "Reachsubnet"
  }

  vpc_id = aws_vpc.Reachvpc.id  
}
resource "aws_subnet" "Reachsubnet2" {
  availability_zone       = var.az2 
  cidr_block              = var.cidr_block_subnet2
  map_public_ip_on_launch = true

  tags = {
    Env  = "production"
    Name = "Reachsubnet"
  }

  vpc_id = aws_vpc.Reachvpc.id  
}
resource "aws_subnet" "Reachsubnet3" {
  availability_zone       = var.az3 
  cidr_block              = var.cidr_block_subnet3
  map_public_ip_on_launch = true

  tags = {
    Env  = "production"
    Name = "Reachsubnet"
  }

  vpc_id = aws_vpc.Reachvpc.id  
}

resource "aws_security_group" "service_security_group" {
  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    # Only allowing traffic in from the load balancer security group
    security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
  }

  egress {
    from_port   = 0 # Allowing any incoming port
    to_port     = 0 # Allowing any outgoing port
    protocol    = "-1" # Allowing any outgoing protocol 
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}
resource "aws_ecs_service" "my_first_service" {
  name            = "my-first-service"                             # Naming our first service
  cluster         = "${aws_ecs_cluster.ReachProjectCluster.id}"             # Referencing our created Cluster
  task_definition = "${aws_ecs_task_definition.my_first_task.arn}" # Referencing the task our service will spin up
  launch_type     = "FARGATE"
  desired_count   = 3 # Setting the number of containers we want deployed to 3
  network_configuration {
    subnets          = ["${aws_subnet.Reachsubnet1.id}", "${aws_subnet.Reachsubnet2.id}", "${aws_subnet.Reachsubnet3.id}"]
    assign_public_ip = true # Providing our containers with public IPs
    security_groups  = ["${aws_security_group.service_security_group.id}"]
  }
  load_balancer {
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # Referencing our target group
    container_name   = "${aws_ecs_task_definition.my_first_task.family}"
    container_port   = 3000 # Specifying the container port
  }
}
resource "aws_security_group" "load_balancer_security_group" {
  ingress {
    from_port   = 80 # Allowing traffic in from port 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic in from all sources
  }

  egress {
    from_port   = 0 # Allowing any incoming port
    to_port     = 0 # Allowing any outgoing port
    protocol    = "-1" # Allowing any outgoing protocol 
    cidr_blocks = ["0.0.0.0/0"] # Allowing traffic out to all IP addresses
  }
}
resource "aws_alb" "application_load_balancer" {
  name               = "myappLB" # Naming our load balancer
  load_balancer_type = "application"
  subnets = [ 
    aws_subnet.Reachsubnet1.id,
    aws_subnet.Reachsubnet2.id,
    aws_subnet.Reachsubnet3.id
  ]
  # Referencing the security group
  security_groups = ["${aws_security_group.load_balancer_security_group.id}"]
}

resource "aws_lb_target_group" "target_group" {
  name        = "target-group"
  port        = 80
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = "${aws_vpc.Reachvpc.id}" 
  health_check {
    matcher = "200,301,302"
    path = "/"
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = "${aws_alb.application_load_balancer.arn}" # Referencing our load balancer
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = "${aws_lb_target_group.target_group.arn}" # Referencing our tagrte group
  }
}
output "my_app_url" {
  description = "The DNS name of the load balancer."
  value       = aws_alb.application_load_balancer.dns_name 
}

resource "aws_db_subnet_group" "db-subnet-group" {
  name = "db-subnet-group"

  subnet_ids = [
    aws_subnet.Reachsubnet1.id,
    aws_subnet.Reachsubnet2.id,
    aws_subnet.Reachsubnet3.id
  ]
}
resource "aws_db_instance" "db_instance" {
  allocated_storage    = 10
  max_allocated_storage = 100
  engine               = var.engine
  engine_version       = var.engine_version
  instance_class       = var.instance_class
  db_name              = var.db_name 
  username             = var.username 
  password             = var.password
  parameter_group_name = var.parameter_group_name
  db_subnet_group_name = aws_db_subnet_group.db-subnet-group.name
  availability_zone = var.az1
  apply_immediately = true  
}

resource "null_resource" "setup_db" {
  depends_on = ["aws_db_instance.db_instance"] #wait for the db to be ready
  provisioner "local-exec" {
    command = "mysql -u ${aws_db_instance.db_instance.username} -p${var.password} -h ${aws_db_instance.db_instance.endpoint} < file.sql"
  }
}

resource "aws_acm_certificate" "cert" {
  domain_name               = var.domain_name
  subject_alternative_names = ["*.${var.domain_name}"]
  validation_method         = "DNS"
}
resource "aws_route53_zone" "hosted_zone" {
  name = var.domain_name

  vpc {
    vpc_id = aws_vpc.Reachvpc.id 
  }
}
resource "aws_route53_record" "certvalidation" {
  for_each = {
    for d in aws_acm_certificate.cert.domain_validation_options : d.domain_name => {
      name   = d.resource_record_name
      record = d.resource_record_value
      type   = d.resource_record_type
    }
  }
  allow_overwrite = true
  name            = each.value.name
  records         = [each.value.record]
  ttl             = 60
  type            = each.value.type
  zone_id         = aws_route53_zone.hosted_zone.zone_id
}
resource "aws_acm_certificate_validation" "certvalidation" {
  certificate_arn         = aws_acm_certificate.cert.arn
  validation_record_fqdns = [for r in aws_route53_record.certvalidation : r.fqdn]
}
# creating A record for domain:
resource "aws_route53_record" "websiteurl" {
  name    = var.domain_name
  zone_id = aws_route53_zone.hosted_zone.zone_id
  type    = "A"
  alias {
    name                   = aws_cloudfront_distribution.cf_dist.domain_name
    zone_id                = aws_cloudfront_distribution.cf_dist.hosted_zone_id
    evaluate_target_health = true
  }
}
resource "aws_cloudfront_distribution" "cf_dist" {
  enabled             = true
  aliases             = [var.domain_name]
  origin {
    domain_name = aws_alb.application_load_balancer.dns_name
    origin_id   = aws_alb.application_load_balancer.dns_name
    custom_origin_config {
      http_port              = 80
      https_port             = 443
      origin_protocol_policy = "http-only"
      origin_ssl_protocols   = ["TLSv1.2"]
    }
  }
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD", "OPTIONS", "PUT", "POST", "PATCH", "DELETE"]
    cached_methods         = ["GET", "HEAD", "OPTIONS"]
    target_origin_id       = aws_alb.application_load_balancer.dns_name
    viewer_protocol_policy = "redirect-to-https"
    forwarded_values {
      headers      = []
      query_string = true
      cookies {
        forward = "all"
      }
    }
  }
  restrictions {
    geo_restriction {
      restriction_type = "whitelist"
      locations        = ["IN", "US", "CA"]
    }
  }
  
  viewer_certificate {
    acm_certificate_arn      = aws_acm_certificate.cert.arn
    ssl_support_method       = "sni-only"
    minimum_protocol_version = "TLSv1.2_2018"
  }
}



