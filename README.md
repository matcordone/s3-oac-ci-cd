# Static Website on S3 with CloudFront and CI/CD

This project implements a static website on AWS using:
- Amazon S3 for storage
- CloudFront for content distribution with OAC (Origin Access Control)
- AWS CodePipeline for automated CI/CD
- Lambda for cache invalidation

## Architecture
GitHub -> CodePipeline -> S3 -> CloudFront -> Users  
                                    I  
                                    V
                         Lambda (Invalidation)

## Prerequisites

- AWS CLI configured
- Terraform installed
- GitHub connection configured in AWS

## Deployment

1. Configure the GitHub connection in AWS CodeConnections
2. Update `terraform.tfvars` with the ARN of the connection
3. Initialize Terraform: *terraform init*
4. Deploy the infrastructure: *terraform apply*

## Usage

After deployment, the website will be available at the URL provided in the Terraform outputs. Every time the `index.html` file is updated in the repository, the pipeline will automatically trigger, update the content, and invalidate the CloudFront cache.