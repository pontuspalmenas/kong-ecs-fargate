resource "aws_security_group" "kong_sg" {
  name        = local.name
  description = "Allow inbound access on port 8000,8443"
  vpc_id      = module.vpc.vpc_id

  ingress {
    from_port = 8000
    to_port   = 8000
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8443
    to_port   = 8443
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port = 8100
    to_port   = 8100
    protocol  = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_service" "kong" {
  name            = "kong-service"
  cluster         = module.ecs_cluster.id
  task_definition = aws_ecs_task_definition.kong.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets          = module.vpc.public_subnets
    assign_public_ip = true
    security_groups = [aws_security_group.kong_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.kong.arn
    container_name   = "kong"
    container_port   = 8000
  }

  depends_on = [aws_lb_listener.https]
}

locals {
  env_vars = {
    KONG_ROLE = "data_plane"
    KONG_DATABASE = "off"
    KONG_VITALS = "off"
    KONG_CLUSTER_MTLS = "pki"
    KONG_CLUSTER_CONTROL_PLANE = "${var.kong_cluster_prefix}.${var.kong_cluster_region}.cp0.konghq.com:443"
    KONG_CLUSTER_SERVER_NAME = "${var.kong_cluster_prefix}.${var.kong_cluster_region}.cp0.konghq.com"
    KONG_CLUSTER_TELEMETRY_ENDPOINT = "${var.kong_cluster_prefix}.${var.kong_cluster_region}.tp0.konghq.com:443"
    KONG_CLUSTER_TELEMETRY_SERVER_NAME = "${var.kong_cluster_prefix}.${var.kong_cluster_region}.tp0.konghq.com"
    KONG_LUA_SSL_TRUSTED_CERTIFICATE = "system"
    KONG_KONNECT_MODE = "on"
    KONG_ROUTER_FLAVOR = "expressions"
    KONG_STATUS_LISTEN = "0.0.0.0:8100"
  }
}

resource "aws_ecs_task_definition" "kong" {
  family             = "kong"
  requires_compatibilities = ["FARGATE"]
  cpu                = "256"
  memory             = "512"
  network_mode       = "awsvpc"
  execution_role_arn = aws_iam_role.ecs_task_execution.arn

  container_definitions = jsonencode([
    {
      name  = "kong"
      image = "kong/kong-gateway:3.10"
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
          protocol      = "tcp"
        },
        {
          containerPort = 8443
          hostPort      = 8443
          protocol      = "tcp"
        },
        {
          containerPort = 8100
          hostPort      = 8100
          protocol      = "tcp"
        },
      ]
      environment = [
        for k, v in local.env_vars : {
          name  = k
          value = v
        }
      ]
      secrets = [
        {
          name = "KONG_CLUSTER_CERT"
          valueFrom = var.aws_secretsmanager_kong_cert_arn,
        },
        {
          name = "KONG_CLUSTER_CERT_KEY"
          valueFrom = var.aws_secretsmanager_kong_cert_key_arn,
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = "/aws/ecs/kong"
          awslogs-region        = local.region
          awslogs-stream-prefix = "kong"
        }
      }
    }
  ])
}

resource "aws_cloudwatch_log_group" "kong" {
  name              = "/aws/ecs/kong"
  retention_in_days = 7
}