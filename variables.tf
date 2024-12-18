# Global Variables
variable "project_name" {
  description = "Name of the project"
  type        = string
}
variable "environment" {
  description = "Deployment environment (dev/staging/prod)"
  type        = string
}

# AWS Settings
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
}
variable "aws_access_key" {
  description = "AWS access key for terraform moves"
  type        = string
}
variable "aws_secret_key" {
  description = "AWS secret key for terraform moves"
  type        = string
}

# EC2 Instance Settings
variable "ami_id" {
  description = "AMI ID for the EC2 instance"
  type        = string
}
variable "ebs_volume_size" {
  description = "Size of Ebs attached to the ec2 instance"
  type        = string
}
variable "env_secrets_id" {
  description = "The ID of the environment secrets in AWS Secrets Manager"
  type        = string
}
variable "key_pair_name" {
  description = "key pair pem to ssh into the server"
  type        = string
}
variable "instance_type"{
  description = "The instance size and type that is going to be deploy in the server"
  type        = string
}

# Cloudflare Settings
variable "cloudflare_api_token" {
  description = "Cloudflare API Token"
  type        = string
  sensitive   = true
}
variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID"
  type        = string
}

# Docker Settings
variable "dockerhub_repo"{
  description = "Dockerhub repo name that store the application iamge"
  type        = string
}