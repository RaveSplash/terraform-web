<!-- BEGIN_TF_DOCS -->


## Installation
To install Terraform, follow these steps:
1. Download Terraform from the [official Terraform website](https://www.terraform.io/downloads).
2. Add the downloaded binary to your system's PATH.
3. Verify the installation by running:
    ```bash
    terraform --version
    ```

## Usage

Below are the basic steps to use this module:

1. Initialize the Terraform configuration:
    ```bash
    terraform init
    ```

2. Validate the configuration:
    ```bash
    terraform validate
    ```

3. Plan the infrastructure changes:
    ```bash
    terraform plan
    ```

4. Apply the changes:
    ```bash
    terraform apply
    ```

5. Destroy the resources (if needed):
    ```bash
    terraform destroy
    ```

## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.2.0 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 4.16 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 4.0 |

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | 4.67.0 |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | 4.48.0 |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ami_id"></a> [ami\_id](#input\_ami\_id) | AMI ID for the EC2 instance | `string` | n/a | yes |
| <a name="input_aws_access_key"></a> [aws\_access\_key](#input\_aws\_access\_key) | AWS access key for terraform moves | `string` | n/a | yes |
| <a name="input_aws_region"></a> [aws\_region](#input\_aws\_region) | AWS region to deploy resources | `string` | n/a | yes |
| <a name="input_aws_secret_key"></a> [aws\_secret\_key](#input\_aws\_secret\_key) | AWS secret key for terraform moves | `string` | n/a | yes |
| <a name="input_cloudflare_api_token"></a> [cloudflare\_api\_token](#input\_cloudflare\_api\_token) | Cloudflare API Token | `string` | n/a | yes |
| <a name="input_cloudflare_zone_id"></a> [cloudflare\_zone\_id](#input\_cloudflare\_zone\_id) | Cloudflare Zone ID | `string` | n/a | yes |
| <a name="input_dockerhub_repo"></a> [dockerhub\_repo](#input\_dockerhub\_repo) | Dockerhub repo name that store the application iamge | `string` | n/a | yes |
| <a name="input_ebs_volume_size"></a> [ebs\_volume\_size](#input\_ebs\_volume\_size) | Size of Ebs attached to the ec2 instance | `string` | n/a | yes |
| <a name="input_env_secrets_id"></a> [env\_secrets\_id](#input\_env\_secrets\_id) | The ID of the environment secrets in AWS Secrets Manager | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Deployment environment (dev/staging/prod) | `string` | n/a | yes |
| <a name="input_instance_type"></a> [instance\_type](#input\_instance\_type) | The instance size and type that is going to be deploy in the server | `string` | n/a | yes |
| <a name="input_key_pair_name"></a> [key\_pair\_name](#input\_key\_pair\_name) | key pair pem to ssh into the server | `string` | n/a | yes |
| <a name="input_project_name"></a> [project\_name](#input\_project\_name) | Name of the project | `string` | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| <a name="output_cloudflare_domain"></a> [cloudflare\_domain](#output\_cloudflare\_domain) | Cloudflare domain record |
| <a name="output_instance_public_ip"></a> [instance\_public\_ip](#output\_instance\_public\_ip) | Public IP of the EC2 instance |
| <a name="output_launch_template_id"></a> [launch\_template\_id](#output\_launch\_template\_id) | ID of the created launch template |

## Contributing

Contributions are welcome! Please follow the typical Git workflow:
1. Fork this repository.
2. Create a feature branch (`git checkout -b feature-name`).
3. Make your changes and commit them.
4. Push the changes to your fork (`git push origin feature-name`).
5. Create a pull request to merge your changes.
<!-- END_TF_DOCS -->