# Sample Application

## How to run

```bash
poetry env use python3
poetry install
poetry run python main.py
```

## How to test

```bash
poetry run pytest -s
```

# Approach and steps involved in CI/CD and deployment

## Approach

This CI/CD pipeline implemented using GitHub Actions and the infrastructure deployment using Terraform on AWS. The pipeline builds a Docker image, runs tests, pushes the image to Amazon ECR, and deploys it to Amazon ECS.

## CI/CD and deployment pipeline steps

### 1. Workflow Trigger
The pipeline is triggered on:
- Push/merge to the `main` branch.
- Pull request targeting the `main` branch.

### 2. Workflow steps:
#### - Checkout: Uses the `actions/checkout@v4` to check out the repository code
#### - Build: Builds to a image using Dockerfile and command, take advantage of commit SHA to tags the image
#### - Test: Set up python, poetry then run test using poetry command
#### - Push image to ECR: Login and then push image to ECR (both use AWS CLI)
#### - Remove image: Clean after pushing image
#### - Deploy: Setup Terraform using `hashicorp/setup-terraform@v2`, then run init and apply commands using AWS CLI 

## Deployment
Regarding of the stuff `deploy the application to the specified domain https://sample-app.example.com`, I use Route 53 and Load Balancer to handle direct requests from the URL https://sample-app.example.com => Route 53 => Route 53 uses a alias to direct to Load Balancer => Target group forward to ECS container

## Terraform Infrastructure
The terraform configure following resources:
- Route 53
- Load balance
- Security group
- ECS Task definition
- ECS Service
- S3
- RDS Postgresql
- ECR repo
- EC2
- Auto scaling gropu
- IAM
