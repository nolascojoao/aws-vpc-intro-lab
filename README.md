# AWS VPC Introduction Lab

<div align="center">
  <img src="screenshot/architecture.jpg" width=""/>
</div>

---

This lab provides a guide to:
- Creating a VPC with public and private subnets in two Availability Zones
- Setting up a NAT Gateway for private subnet internet access
- Configuring security groups for web server traffic
- Launching an EC2 instance with Apache Web Server in a public subnet
- Terminating the instance
---  
⚠️ **Attention**: 
1. All the tasks will be completed via the command line using AWS CLI. [AWS CLI Install](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
2. Please be aware that charges may apply while completing this lab. [AWS Pricing](https://aws.amazon.com/pricing/)

---

## Step 1 - Create a VPC
1.1. To create a VPC with the CIDR block 10.0.0.0/16:
```bash
aws ec2 create-vpc \
	--cidr-block 10.0.0.0/16 \
	--tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=LabVPC}]'
```
1.2. Note the VPC ID returned in the output.

## Step 2 - Create Subnets
2.1. Create a public subnet in Availability Zone A:
```bash
aws ec2 create-subnet \
	--vpc-id <VPC_ID> \
	--cidr-block 10.0.0.0/24 \
  --availability-zone <AZ_A> \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public Subnet 1}]'
```
2.2. Create a private subnet in Availability Zone A:
```bash
aws ec2 create-subnet \
  --vpc-id <VPC_ID> \
  --cidr-block 10.0.1.0/24 \
  --availability-zone <AZ_A> \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private Subnet 1}]'
```
2.3. Create a public subnet in Availability Zone B:
```bash
aws ec2 create-subnet \
  --vpc-id <VPC_ID> \
  --cidr-block 10.0.2.0/24 \
  --availability-zone <AZ_B> \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public Subnet 2}]'
```
2.4. Create a private subnet in Availability Zone B:
```bash
aws ec2 create-subnet \
  --vpc-id <VPC_ID> \
  --cidr-block 10.0.3.0/24 \
  --availability-zone <AZ_B> \
  --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private Subnet 2}]'
```
## Step 3 - Create an Internet Gateway and Attach it to the VPC
3.1. Create the Internet Gateway:
```bash
aws ec2 create-internet-gateway \
  --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=LabIGW}]'
```
3.2. Attach the Internet Gateway to the VPC:
```bash
aws ec2 attach-internet-gateway \
  --vpc-id <VPC_ID> \
  --internet-gateway-id <IGW_ID>
```

## Step 4: Create Route Tables and Routes
4.1. Create a route table for public subnets:
```bash
aws ec2 create-route-table \
  --vpc-id <VPC_ID> \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Public Route Table}]'
```
4.2. Create a route to the Internet Gateway for the public route table:
```bash
aws ec2 create-route \
  --route-table-id <PUBLIC_RT_ID> \
  --destination-cidr-block 0.0.0.0/0 \
  --gateway-id <IGW_ID>
```
4.3. Retrieve the subnets IDs:
```bash
aws ec2 describe-subnets \
	--filters "Name=vpc-id,Values=<VPC_ID>" \
	--query "Subnets[*].SubnetId" \
	--output text
```
4.4. Associate the public route table with public subnets:
```bash
aws ec2 associate-route-table --subnet-id <PUBLIC_SUBNET_1_ID> --route-table-id <PUBLIC_RT_ID> 
aws ec2 associate-route-table --subnet-id <PUBLIC_SUBNET_2_ID> --route-table-id <PUBLIC_RT_ID>
```
4.5. Create a route table for private subnets:
```bash
aws ec2 create-route-table \
  --vpc-id <VPC_ID> \
  --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Private Route Table}]'
```
4.6. Create a NAT gateway in the public subnet (Availability Zone A):
```bash
aws ec2 create-nat-gateway \
  --subnet-id <PUBLIC_SUBNET_1_ID> \
  --allocation-id <ELASTIC_IP_ID>
```
4.7. Create a route to the NAT gateway for the private route table:
```bash
aws ec2 create-route \
  --route-table-id <PRIVATE_RT_ID> \
  --destination-cidr-block 0.0.0.0/0 \
  --nat-gateway-id <NAT_GW_ID>
```
4.8. Associate the private route table with private subnets:
```bash
aws ec2 associate-route-table --subnet-id <PRIVATE_SUBNET_1_ID> --route-table-id <PRIVATE_RT_ID> 
aws ec2 associate-route-table --subnet-id <PRIVATE_SUBNET_2_ID> --route-table-id <PRIVATE_RT_ID>
```

## Step 5 - Launch a Web Server in the Public Subnet 
5.1. Create a security group for the web server:
```bash
aws ec2 create-security-group \
  --group-name web-server-sg \
  --description "Web Server Security Group" \
  --vpc-id <VPC_ID>
```
5.2. Allow inbound traffic on port 80 (HTTP):
```bash
aws ec2 authorize-security-group-ingress --group-id <SG_ID> --protocol tcp --port 80 --cidr 0.0.0.0/0
```
5.3. Launch the web server instance in Public Subnet 2:
```bash
aws ec2 run-instances \
  --image-id <AMI_ID> \
  --instance-type t2.micro \
  --security-group-ids <SG_ID> \
  --subnet-id <PUBLIC_SUBNET_2_ID> \
  --user-data file://install-webserver.sh
```
Content of `install-webserver.sh`:
```bash
#!/bin/bash
#Install Apache Web Server and PHP
yum install -y httpd mysql php
#Download Lab files
wget https://aws-tc-largeobjects.s3.us-west-2.amazonaws.com/CUR-TF-100-RESTRT-1/267-lab-NF-build-vpc-web-server/s3/lab-app.zip
unzip lab-app.zip -d /var/www/html/
#Turn on web server
chkconfig httpd on
service httpd start
```
## Step 6 - Test the Web Server
To test, open a web browser and enter the public IP address of the instance. You should see the web server's default page.

