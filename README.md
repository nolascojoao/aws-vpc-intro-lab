# AWS VPC Introduction Lab

<div align="center">
  <img src="screenshot/architecture.jpg" width=""/>
</div>

---

## Overview

This Lab covers the following steps:

- **VPC Creation**: Create a VPC with a CIDR block.
- **Subnet Creation**: Set up public and private subnets.
- **Internet Gateway Setup**: Attach an Internet Gateway to the VPC.
- **NAT Gateway Setup**: Create a NAT Gateway for private subnet internet access.
- **Route Tables Configuration**: Configure route tables for public and private subnets.
- **Security Groups Configuration**: Set rules to allow HTTP traffic.
- **Web Server Deployment**: Launch an EC2 instance with a web server and associate an Elastic IP.
- **Resource Cleanup**: Terminate resources to avoid charges.

---  
⚠️ **Attention**: 
- All the tasks will be completed via the command line using AWS CLI. Ensure you have the necessary permissions. [Install AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/getting-started-install.html)
- Charges may apply for completing this lab. [AWS Pricing](https://aws.amazon.com/pricing/)
---

## Step 1 - VPC Creation
#### 1.1. To create a VPC with the CIDR block 10.0.0.0/16:
```bash
aws ec2 create-vpc \
	--cidr-block 10.0.0.0/16 \
	--tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=LabVPC}]'
```
Copy the VPC ID for further use.

#### 1.2. To check the status of the VPC:
replace `<VPC_ID>` with your VPC ID value
```bash
aws ec2 describe-vpcs --vpc-ids <VPC_ID> --query "Vpcs[*].State"
```

<div align="center">
  <img src="screenshot/1.2.PNG"/>
</div>

---

## Step 2 - Subnet Creation
#### 2.1. To list Availability Zones:
```bash
aws ec2 describe-availability-zones --query "AvailabilityZones[*].ZoneName" --output text
```
#### 2.2. Create a public subnet in Availability Zone A:
replace `<VPC_ID>` with your VPC ID value and `<AZ_A>` with the name of AvailabilityZone A
```bash
aws ec2 create-subnet \
	--vpc-id <VPC_ID> \
	--cidr-block 10.0.0.0/24 \
  	--availability-zone <AZ_A> \
  	--tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public Subnet 1}]'
```
#### 2.3. Create a private subnet in Availability Zone A:
replace `<VPC_ID>` with your VPC ID value and `<AZ_A>` with the name of AvailabilityZone A
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

#### 2.4. Create a public subnet in Availability Zone B:
replace `<VPC_ID>` with your VPC ID value and `<AZ_B>` with the name of AvailabilityZone B
```bash
aws ec2 create-subnet \
	--vpc-id <VPC_ID> \
	--cidr-block 10.0.2.0/24 \
	--availability-zone <AZ_B> \
	--tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public Subnet 2}]'
```
#### 2.5. Create a private subnet in Availability Zone B:
replace `<VPC_ID>` with your VPC ID value and `<AZ_B>` with the name of AvailabilityZone B
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

#### 2.6. Retrieve the subnets IDs:
replace `VPC_ID` with your VPC ID value
```bash
aws ec2 describe-subnets \
	--filters "Name=vpc-id,Values=VPC_ID" \
	--query "Subnets[*].[SubnetId, Tags[?Key=='Name'].Value | [0]]" \
	--output table
```

<div align="center">
  <img src="screenshot/4.3.PNG"/>
</div>

---

## Step 3 - Internet Gateway Setup
#### 3.1. Create the Internet Gateway:
```bash
aws ec2 create-internet-gateway \
	--tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=LabIGW}]'
```

Copy the Internet Gateway ID for further use.

#### 3.2. Attach the Internet Gateway to the VPC:
Replace `<VPC_ID>` with your VPC ID value and `<IGW_ID>` with your Internet Gateway ID
```bash
aws ec2 attach-internet-gateway \
	--vpc-id <VPC_ID> \
	--internet-gateway-id <IGW_ID>
```
#### 3.3. To verify the Internet Gateway status:
Replace `<IGW_ID>` with your Internet Gateway ID
```bash
aws ec2 describe-internet-gateways --internet-gateway-ids <IGW_ID> --query "InternetGateways[*].Attachments"
```

<div align="center">
  <img src="screenshot/3.3.PNG"/>
</div>

---

## Step 4 - NAT Gateway Setup
#### 4.1. Allocate an Elastic IP to your Account:
```bash
aws ec2 allocate-address --domain vpc
```

Copy the PublicIp and the AllocationId for further use.

<div align="center">
  <img src="screenshot/4.6.PNG"/>
</div>

#### 4.2. Create a NAT gateway in the public subnet (Availability Zone A):
Replace `<PUBLIC_SUBNET_1_ID>` with the Public Subnet 1 ID and `<ALLOCATION_ID>` with your Elastic IP Allocation ID
```bash
aws ec2 create-nat-gateway \
	--subnet-id <PUBLIC_SUBNET_1_ID> \
	--allocation-id <ALLOCATION_ID>
```

Copy the NAT gateway for further use.

<div align="center">
  <img src="screenshot/4.7.PNG"/>
</div>

---

## Step 5 - Route Tables Configuration
#### 5.1. Create a route table for public subnets:
Replace `<VPC_ID>` with your VPC ID
```bash
aws ec2 create-route-table \
	--vpc-id <VPC_ID> \
	--tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Public Route Table}]'
```

Copy the Public Route Table ID for further use.

<div align="center">
  <img src="screenshot/4.1.PNG"/>
</div>

#### 5.2. Create a route to the Internet Gateway for the public route table:
Replace `<PUBLIC_RT_ID>` with your Route Table ID and `<IGW_ID>` with your Internet Gateway ID
```bash
aws ec2 create-route \
	--route-table-id <PUBLIC_RT_ID> \
	--destination-cidr-block 0.0.0.0/0 \
	--gateway-id <IGW_ID>
```

<div align="center">
  <img src="screenshot/4.2.PNG"/>
</div>

#### 5.3. Associate the public route table with public subnets:
Replace `<PUBLIC_RT_ID>` with your Route Table ID and `<PUBLIC_SUBNET_1_ID>` and `<PUBLIC_SUBNET_2_ID>` with the IDs of your public subnets
```bash
aws ec2 associate-route-table --subnet-id <PUBLIC_SUBNET_1_ID> --route-table-id <PUBLIC_RT_ID> 
aws ec2 associate-route-table --subnet-id <PUBLIC_SUBNET_2_ID> --route-table-id <PUBLIC_RT_ID>
```

<div align="center">
  <img src="screenshot/4.4.PNG"/>
</div>

#### 5.4. Create a route table for private subnets:
Replace `<VPC_ID>` with your VPC ID
```bash
aws ec2 create-route-table \
	--vpc-id <VPC_ID> \
	--tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Private Route Table}]'
```

Copy the Private Route Table ID for further use.

<div align="center">
  <img src="screenshot/4.5.PNG"/>
</div>

#### 5.5. Create a route to the NAT gateway for the private route table:
Replace `<PRIVATE_RT_ID>` with your Private Route Table ID and `<NAT_GW_ID>` with your NAT Gateway ID
```bash
aws ec2 create-route \
	--route-table-id <PRIVATE_RT_ID> \
	--destination-cidr-block 0.0.0.0/0 \
	--nat-gateway-id <NAT_GW_ID>
```

<div align="center">
  <img src="screenshot/4.8.PNG"/>
</div>

#### 5.6. Associate the private route table with private subnets:
Replace `<PUBLIC_RT_ID>` with your Route Table ID and `<PRIVATE_SUBNET_1_ID>` and `<PRIVATE_SUBNET_2_ID>` with the IDs of your public subnets
```bash
aws ec2 associate-route-table --subnet-id <PRIVATE_SUBNET_1_ID> --route-table-id <PRIVATE_RT_ID> 
aws ec2 associate-route-table --subnet-id <PRIVATE_SUBNET_2_ID> --route-table-id <PRIVATE_RT_ID>
```

<div align="center">
  <img src="screenshot/4.9.PNG"/>
</div>

---

## Step 6 - Security Groups Configuration
#### 6.1. Create a security group for the web server:
Replace `<VPC_ID>` with your VPC ID
```bash
aws ec2 create-security-group \
	--group-name web-server-sg \
	--description "Web Server Security Group" \
	--vpc-id <VPC_ID>
```

Copy the Security Group ID for further use.

<div align="center">
  <img src="screenshot/5.1.PNG"/>
</div>

#### 6.2. Allow inbound traffic on port 80 (HTTP):
Replace `<SG_ID>` with your Security Group ID
```bash
aws ec2 authorize-security-group-ingress --group-id <SG_ID> --protocol tcp --port 80 --cidr 0.0.0.0/0
```

<div align="center">
  <img src="screenshot/5.2.PNG"/>
</div>

---

## Step 7 - Web Server Deployment
#### 7.1. Launch the web server instance in Public Subnet 2:
Replace `<AMI_ID>` with your AMI ID (e.g., `ami-0ebfd941bbafe70c6`), `<SG_ID>` with your Security Group ID, and `<PUBLIC_SUBNET_2_ID>` with the ID of Public Subnet 2
```bash
aws ec2 run-instances \
	--image-id <AMI_ID> \
	--instance-type t2.micro \
	--associate-public-ip-address \
	--security-group-ids <SG_ID> \
	--subnet-id <PUBLIC_SUBNET_2_ID> \
	--user-data file://install-webserver.sh
```

Copy the ec2 Instance ID for further use.

<div align="center">
  <img src="screenshot/5.3.PNG"/>
</div>

#### Content of `install-webserver.sh`:
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

#### 7.2. Retrieve the instance's IPv4 Public Address and test the web server:
Replace `<INSTANCE_ID>` with your Instance ID
```bash
aws ec2 describe-instances --instance-ids <INSTANCE_ID> \
	--query "Reservations[*].Instances[*].PublicIpAddress" --output text
```

<div align="center">
  <img src="screenshot/5.4.PNG"/>
</div>

#### 7.3. Visit http://<INSTANCE_PUBLIC_IP> to verify the web server is running.
Replace `<INSTANCE_PUBLIC_IP>` with the public IP address retrieved in the previous step

<div align="center">
  <img src="screenshot/5.5.PNG"/>
</div>

#### 7.4. Allocate a new Elastic IP to your Account:
```bash
aws ec2 allocate-address --domain vpc
```

Copy the PublicIp and the AllocationId for further use.

#### 7.5. Associate the Elastic IP obtained in the last step to the EC2 instance and test the web server:
Replace `<INSTANCE_ID>` with your Instance ID and `<ALLOCATION_ID>` with the Elastic IP Allocation ID
```bash
aws ec2 associate-address \
	--instance-id <INSTANCE_ID> \
	--allocation-id <ALLOCATION_ID>
```

<div align="center">
  <img src="screenshot/5.6.PNG"/>
</div>

#### 7.6. Visit http://<INSTANCE_PUBLIC_IP> to verify the web server is running.
Replace `<INSTANCE_PUBLIC_IP>` with the public IP address retrieved in the previous step

<div align="center">
  <img src="screenshot/5.7.PNG"/>
</div>

---

## Step 8 - Resource Cleanup
#### 8.1. Terminate the EC2 instance:
Replace `<INSTANCE_ID>` with your Instance ID
```bash
aws ec2 terminate-instances --instance-ids <INSTANCE_ID>
```

<div align="center">
  <img src="screenshot/5.8.PNG"/>
</div>

#### 8.2. Delete NAT Gateway
Replace `<NAT_GATEWAY_ID>` with your NAT Gateway ID
```bash
aws ec2 delete-nat-gateway --nat-gateway-id <NAT_GATEWAY_ID>
```

<div align="center">
  <img src="screenshot/5.9.PNG"/>
</div>

#### 8.3. Detach and Delete Internet Gateway
Replace `<IGW_ID>` with your Internet Gateway ID and `<VPC_ID>` with your VPC ID
```bash
aws ec2 detach-internet-gateway --internet-gateway-id <IGW_ID> --vpc-id <VPC_ID>
aws ec2 delete-internet-gateway --internet-gateway-id <IGW_ID>
```

#### 8.4. Release the Elastic IP:
Replace `<ALLOCATION_ID>` with your Elastic IP Allocation ID
```bash
aws ec2 release-address --allocation-id <ALLOCATION_ID>
```

#### 8.5. Delete VPC

```bash
aws ec2 delete-vpc --vpc-id <VPC_ID>
```
Replace `<VPC_ID>` with your VPC ID
<div align="center">
  <img src="screenshot/6.0.PNG"/>
</div>

---

### Conclusion

This AWS VPC Introduction Lab provided a hands-on experience in creating and managing essential AWS components like Virtual Private Clouds (VPCs), subnets, gateways, and security groups. For production environments you can use Bash scripts to automate this process making deployment easier and more consistent.
