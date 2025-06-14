# Kong on ECS Fargate



> [!WARNING]
> This is purposefully kept simple just for demo purposes, it is not suited for production.

## Features
* Kong Gateway on ECS Fargate (50/50 SPOT) for use with Konnect.
* Application Load Balancer (ALB) with Health checks using Kong status listener (port `8100`).
* Certificate for Gateway <-> Konnect mTLS in Secrets Manager.
* Logging with CloudWatch Logs (group `/aws/ecs/kong`).
* 

## Limitations
* Uses default, non-hardened Kong image
* Does not scale automatically
* Uses self-signed certificate
* Uses HTTP between ALB and Kong Gateway

## Considerations
* Use ECS Service Auto Scaling with target metric or CloudWatch Alarms.
* Use Konnect Vault to manage reading from Secrets Manager.
* Add Amazon CA cert to Kong Gateway to re-encrypt ALB->ECS

## Datadog setup
> [!WARNING]
> This is just a Proof of Concept. Very experimental.

1. Create the fluent-bit image, push it to ECR, and have it used as a sidecar in the task definition (see Terraform `ecs.tf`).
```bash
task -t fluentbit/Taskfile.yml publish
```

2. In Konnect, configure the HTTP Log plugin with host: http://localhost:9880
3. Configure the StatsD plugin, port: 8125

## Initial setup
This Terraform config expects an S3 backend. Create a `backend-config.tfbackend` file like:

```hcl
bucket = "my-tf-state-bucket"
key    = "some/path/terraform.tfstate"
region = "eu-north-1"
```
Then run:
```bash
terraform init -backend-config=backend-config.tfbackend
```

Then you will need a Konnect Control Plane and add it to `.tfvars`:
```hcl
kong_cluster_prefix = "123456a1b2"
```

You will also need a certificate (cert.pem, cert.key) in AWS Secrets Manager in plaintext format, and provide the ARN of them in the `.tfvars`:
```hcl
aws_secretsmanager_kong_cert_arn = "arn:aws:secretsmanager:eu-north-1:555555555555:secret:my-project/cert.pem-abc123"
aws_secretsmanager_kong_cert_key_arn = "arn:aws:secretsmanager:eu-north-1:412431539555:secret:my-project/cert.key-abc123"
```

And finally a cert in AWS Certificate Manager (ACM) for the ALB:
```hcl
aws_acm_certificate_arn = "arn:aws:acm:eu-north-1:555555555555:certificate/12345678-1234-4abc-8def-abcdefabcdef"
```

### Deploy
```bash
terraform apply -var-file=lab.tfvars

Outputs:

aws_lb_kong_dns_name = "my-project-123456789.eu-north-1.elb.amazonaws.com"
```

### Test

```bash
$ export PROXY=$(terraform output -raw aws_lb_kong_dns_name) 
$ curl -ki https://$PROXY:8443/hello

HTTP/2 404
date: Fri, 25 Apr 2025 08:50:10 GMT
content-type: application/json; charset=utf-8
content-length: 103
x-kong-response-latency: 0
server: kong/3.10.0.1-enterprise-edition
x-kong-request-id: eced566fbaa0335dfa8ed111e9e3ed54

{
  "message":"no Route matched with those values",
  "request_id":"eced566fbaa0335dfa8ed111e9e3ed54"
}
```

Now you're ready to start publishing your APIs.

