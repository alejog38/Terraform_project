# Terraform_project

Project created to deploy an ecs cluster in AWS assumming that the VPC are already created and the subnets public and private are related to that VPC. The AWS access keys are obtained from the environment configuration.

## Prerequisites 

-   AWS Account
-   Proper Permissions for your user
-   Terraform installed on your IDE
-   AWS CLI installed and configured on your IDE
-   SSH Agent (For Windows PowerShell)


## AWS configuration settings CLI
Run command:
```sh 
aws configure
AWS Access Key ID [None]: access key
AWS Secret Access Key [None]: secret access key
Default region name [None]: region
Default output format [None]: default output format
```

