provider "aws" {
  region = local.region
}

locals {
  region = "eu-north-1"
  name = "palmenas-lab-ecs"

  tags = {
    Name       = local.name
    author    = "pontus.palmenas@konghq.com"
  }
}
