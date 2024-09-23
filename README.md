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
- Associate Elastic IP to the EC2 instance
- Terminating the instance and deallocating resources to avoid charges
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
Save the VPC ID returned in the output.

1.2. To check the status of the VPC:
```bash
aws ec2 describe-vpcs --vpc-ids <VPC_ID> --query "Vpcs[*].State"
```

<div align="center">
  <img src="screenshot/1.2.PNG"/>
</div>

## Step 2 - Create Subnets
2.1. To list Availability Zones:
```bash
aws ec2 describe-availability-zones --query "AvailabilityZones[*].ZoneName" --output text
```
2.2. Create a public subnet in Availability Zone A:
```bash
aws ec2 create-subnet \
	--vpc-id <VPC_ID> \
	--cidr-block 10.0.0.0/24 \
  	--availability-zone <AZ_A> \
  	--tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public Subnet 1}]'
```
2.3. Create a private subnet in Availability Zone A:
```bash
aws ec2 create-subnet \
	--vpc-id <VPC_ID> \
	--cidr-block 10.0.1.0/24 \
	--availability-zone <AZ_A> \
	--tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private Subnet 1}]'
```

<div align="center">
  <img src="screenshot/2.3.PNG"/>
</div>

2.4. Create a public subnet in Availability Zone B:
```bash
aws ec2 create-subnet \
	--vpc-id <VPC_ID> \
	--cidr-block 10.0.2.0/24 \
	--availability-zone <AZ_B> \
	--tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public Subnet 2}]'
```
2.5. Create a private subnet in Availability Zone B:
```bash
aws ec2 create-subnet \
	--vpc-id <VPC_ID> \
	--cidr-block 10.0.3.0/24 \
	--availability-zone <AZ_B> \
	--tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private Subnet 2}]'
```

<div align="center">
  <img src="screenshot/2.5.PNG"/>
</div>

## Step 3 - Create an Internet Gateway and Attach it to the VPC
3.1. Create the Internet Gateway:
```bash
aws ec2 create-internet-gateway \
	--tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=LabIGW}]'
```
Save the Internet Gateway ID returned in the output.

3.2. Attach the Internet Gateway to the VPC:
```bash
aws ec2 attach-internet-gateway \
	--vpc-id <VPC_ID> \
	--internet-gateway-id <IGW_ID>
```
3.3. To verify the Internet Gateway status:
```bash
aws ec2 describe-internet-gateways --internet-gateway-ids <IGW_ID> --query "InternetGateways[*].Attachments"
```

<div align="center">
  <img src="screenshot/3.3.PNG"/>
</div>

## Step 4: Create Route Tables and Routes
4.1. Create a route table for public subnets:
```bash
aws ec2 create-route-table \
	--vpc-id <VPC_ID> \
	--tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Public Route Table}]'
```
Save the Public Route Table ID returned in the output.

<div align="center">
  <img src="screenshot/4.1.PNG"/>
</div>

4.2. Create a route to the Internet Gateway for the public route table:
```bash
aws ec2 create-route \
	--route-table-id <PUBLIC_RT_ID> \
	--destination-cidr-block 0.0.0.0/0 \
	--gateway-id <IGW_ID>
```

<div align="center">
  <img src="screenshot/4.2.PNG"/>
</div>

4.3. Retrieve the subnets IDs:
```bash
aws ec2 describe-subnets \
	--filters "Name=vpc-id,Values=VPC_ID" \
	--query "Subnets[*].[SubnetId, Tags[?Key=='Name'].Value | [0]]" \
	--output table
```

<div align="center">
  <img src="screenshot/4.3.PNG"/>
</div>

4.4. Associate the public route table with public subnets:
```bash
aws ec2 associate-route-table --subnet-id <PUBLIC_SUBNET_1_ID> --route-table-id <PUBLIC_RT_ID> 
aws ec2 associate-route-table --subnet-id <PUBLIC_SUBNET_2_ID> --route-table-id <PUBLIC_RT_ID>
```

<div align="center">
  <img src="screenshot/4.4.PNG"/>
</div>

4.5. Create a route table for private subnets:
```bash
aws ec2 create-route-table \
	--vpc-id <VPC_ID> \
	--tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Private Route Table}]'
```

Save the Private Route Table ID returned in the output.

<div align="center">
  <img src="screenshot/4.5.PNG"/>
</div>

4.6. Allocate an Elastic IP to your Account:
```bash
aws ec2 allocate-address --domain vpc
```

Save the PublicIp and the AllocationId returned in the output.

<div align="center">
  <img src="screenshot/4.6.PNG"/>
</div>

4.7. Create a NAT gateway in the public subnet (Availability Zone A): 
```bash
aws ec2 create-nat-gateway \
	--subnet-id <PUBLIC_SUBNET_1_ID> \
	--allocation-id <ALLOCATION_ID>
```

Save the NAT gateway ID returned in the output.

<div align="center">
  <img src="screenshot/4.7.PNG"/>
</div>

4.8. Create a route to the NAT gateway for the private route table: 
```bash
aws ec2 create-route \
	--route-table-id <PRIVATE_RT_ID> \
	--destination-cidr-block 0.0.0.0/0 \
	--nat-gateway-id <NAT_GW_ID>
```

<div align="center">
  <img src="screenshot/4.8.PNG"/>
</div>

4.9. Associate the private route table with private subnets:
```bash
aws ec2 associate-route-table --subnet-id <PRIVATE_SUBNET_1_ID> --route-table-id <PRIVATE_RT_ID> 
aws ec2 associate-route-table --subnet-id <PRIVATE_SUBNET_2_ID> --route-table-id <PRIVATE_RT_ID>
```

<div align="center">
  <img src="screenshot/4.9.PNG"/>
</div>

## Step 5 - Launch a Web Server in the Public Subnet 
5.1. Create a security group for the web server:
```bash
aws ec2 create-security-group \
	--group-name web-server-sg \
	--description "Web Server Security Group" \
	--vpc-id <VPC_ID>
```

<div align="center">
  <img src="screenshot/5.1.PNG"/>
</div>

Save the Security Group ID returned in the output.

5.2. Allow inbound traffic on port 80 (HTTP):
```bash
aws ec2 authorize-security-group-ingress --group-id <SG_ID> --protocol tcp --port 80 --cidr 0.0.0.0/0
```

<div align="center">
  <img src="screenshot/5.2.PNG"/>
</div>

5.3. Launch the web server instance in Public Subnet 2:
```bash
aws ec2 run-instances \
	--image-id <AMI_ID> \
	--instance-type t2.micro \
	--associate-public-ip-address \
	--security-group-ids <SG_ID> \
	--subnet-id <PUBLIC_SUBNET_2_ID> \
	--user-data file://install-webserver.sh
```

<div align="center">
  <img src="screenshot/5.3.PNG"/>
</div>

Save the ec2 Instance ID returned in the output.

5.4. Retrieve the instance's IPv4 Public Address and test the web server:
```bash
aws ec2 describe-instances --instance-ids <INSTANCE_ID> \
	--query "Reservations[*].Instances[*].PublicIpAddress" --output text
```

<div align="center">
  <img src="screenshot/5.4.PNG"/>
</div>

<div align="center">
  <img src="screenshot/5.5.PNG"/>
</div>

5.5. Allocate a new Elastic IP to your Account:
```bash
aws ec2 allocate-address --domain vpc
```
Save the PublicIp and the AllocationId returned in the output.

5.6. Associate the Elastic IP obtained in the last step to the EC2 instance and test the web server:
```bash
aws ec2 associate-address \
	--instance-id <INSTANCE_ID> \
	--allocation-id <ALLOCATION_ID>
```

<div align="center">
  <img src="screenshot/5.6.PNG"/>
</div>

<div align="center">
  <img src="screenshot/5.7.PNG"/>
</div>

Content of `install-webserver.sh`:
```bash
#!/bin/bash
# Installs the Apache web server            
yum -y install httpd
# Configures httpd to start on boot      
systemctl enable httpd
# Starts the httpd service now    
systemctl start httpd
# Creates an HTML homepage
echo '<html><h1>Hello From Your Web Server!</h1></html>' > /var/www/html/index.html 
```
