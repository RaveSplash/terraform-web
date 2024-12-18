# Terraform Configuration
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 4.16"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.2.0"
}

# AWS Provider Configuration
provider "aws" {
  region = var.aws_region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

# Cloudflare Provider Configuration
provider "cloudflare" {
  api_token = var.cloudflare_api_token
}



# IAM Role for EC2 to access Secrets Manager
data "aws_iam_policy_document" "ec2_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}
data "aws_caller_identity" "current" {
  # No need for parameters, it fetches the details of the currently authenticated AWS caller
}

resource "aws_iam_role" "ec2_role" {
  name               = "${var.project_name}-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role_policy.json
}

# Secrets Manager Access Policy
data "aws_iam_policy_document" "secrets_manager_policy" {
  statement {
    actions   = ["secretsmanager:GetSecretValue"]
    resources = [
      "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:web-general-credentials*",
      "arn:aws:secretsmanager:${var.aws_region}:${data.aws_caller_identity.current.account_id}:secret:${var.env_secrets_id}*"    ]
  }
}

resource "aws_iam_policy" "secrets_manager_policy" {
  name   = "${var.project_name}-secrets-manager-policy"
  policy = data.aws_iam_policy_document.secrets_manager_policy.json
}

resource "aws_iam_role_policy_attachment" "secrets_manager_policy_attachment" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = aws_iam_policy.secrets_manager_policy.arn
}

# CloudWatch Logs Policy
resource "aws_iam_role_policy_attachment" "cloudwatch_logs_policy" {
  role       = aws_iam_role.ec2_role.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchLogsFullAccess"
}

# IAM Instance Profile
resource "aws_iam_instance_profile" "ec2_instance_profile" {
  name = "${var.project_name}-ec2-instance-profile"
  role = aws_iam_role.ec2_role.name
}

# Security Group
resource "aws_security_group" "instance_sg" {
  name        = "${var.project_name}-security-group"
  description = "Security group for ${var.project_name} EC2 instance"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
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


# Launch Template
resource "aws_launch_template" "main" {
  name_prefix   = "${var.project_name}-lt-"
  image_id      = var.ami_id
  instance_type = var.instance_type
  key_name      = var.key_pair_name

  # Restore the user_data configuration
  user_data = base64encode(templatefile("./launch_template_web_app.sh", {
    PROJECT_NAME = var.project_name,
    CERTBOT_EMAIL = "jermaine@mindhive.asia",
    GENERAL_SECRETS_ID = "web-general-credentials",
    ENV_SECRETS_ID = var.env_secrets_id,
    DOCKERHUB_REPO = var.dockerhub_repo 
  }))

  iam_instance_profile {
    name = aws_iam_instance_profile.ec2_instance_profile.name
  }

  network_interfaces {
    device_index                = 0
    security_groups             = [aws_security_group.instance_sg.id]
    associate_public_ip_address = true
  }

  block_device_mappings {
    device_name = "/dev/xvda"
    ebs {
      volume_size = var.ebs_volume_size
      volume_type = "gp3"
      delete_on_termination = true
    }
  }
}

# EC2 Instance using Launch Template
resource "aws_instance" "main" {
  launch_template {
    id      = aws_launch_template.main.id
    version = "$Latest"
  }
  
  tags = {
    Name = var.project_name
  }
}
# CloudWatch Log Group
resource "aws_cloudwatch_log_group" "app_logs" {
  name              = "/aws/ec2/${var.project_name}"
  retention_in_days = 30
}

# Cloudflare DNS Record
resource "cloudflare_record" "domain" {
  zone_id   = var.cloudflare_zone_id 
  name      = var.project_name        
  content   = aws_instance.main.public_ip
  type      = "A"                   
  ttl       = 1                  
  proxied   = false                 

  depends_on = [aws_instance.main]  
}

# Outputs

output "launch_template_id" {
  description = "ID of the created launch template"
  value       = aws_launch_template.main.id
}

output "instance_public_ip" {
  description = "Public IP of the EC2 instance"
  value       = aws_instance.main.public_ip
}

output "cloudflare_domain" {
  description = "Cloudflare domain record"
  value       = cloudflare_record.domain.hostname
}

