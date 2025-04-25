output "aws_lb_kong_dns_name" {
  value = aws_lb.kong.dns_name
  description = "The public dns name of the Application Load Balancer (ALB)"
}