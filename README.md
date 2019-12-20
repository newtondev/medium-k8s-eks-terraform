# medium-k8s-eks-terraform
Launching production-grade Kubernetes cluster on AWS using Terraform.

[ARTICLE LINK TO BE ADDED]

### Disclaimer
This setup is based on what I have setup in production, it is not the only way on setting this up. Feel free to change it however you feel. This stack will cost you $$$ to spin up so make sure you remove the resources if you no longer require them to run.

### Requirements
At the time of writing this article I am using:
* AWS Account (Costs will be incurred)
* AWS CLI (latest)
* Terraform client: v0.12.16
* kubectl client: v1.16.3
* Kubernetes on EKS: v1.14.8-eks-b7174d

### TL;DR
To get up to quickly:
1. open up the `variables.tf` file, make the changes to match your desired settings
2. run `terraform init`
3. run `terraform plan`
4. run `terraform apply`
5. enter `yes` then press return on your keyboard

To tear down the environment and delete everything that was created run: `terraform destroy` and follow the prompts.

