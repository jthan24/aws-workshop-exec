# 01-vpc
```bash
wget https://static.us-east-1.prod.workshops.aws/public/029ae133-bcd6-4175-80b7-a5afcb59763d/static/foundational/cfn/pre-requisites.yaml


aws cloudformation validate-template --template-body file://pre-requisites.yaml 

aws cloudformation create-stack --stack-name NetworkingWorkshopPrerequisites --template-body file://pre-requisites.yaml --capabilities CAPABILITY_NAMED_IAM

```

# terraform

```bash
terraform init
terraform plan
terraform apply

```



# references
https://catalog.workshops.aws/networking/en-US/foundational/prereqs/aws-account
