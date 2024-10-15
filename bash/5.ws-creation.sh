#!/bin/bash

# Stop script execution on any error
set -e

# Step 1: Retrieve necessary resource IDs

# Retrieve VPC ID
echo "Retrieving VPC ID..."
VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=LabVPC" \
    --query "Vpcs[0].VpcId" --output text)
echo "VPC ID: $VPC_ID"

# Retrieve Public Subnet 2 ID (AZ B)
echo "Retrieving Public Subnet 2 ID (AZ B)..."
SUBNET_PUBLIC_B=$(aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=tag:Name,Values=PublicSubnet2" \
    --query "Subnets[0].SubnetId" --output text)
echo "Public Subnet 2 ID: $SUBNET_PUBLIC_B"

# Retrieve Security Group ID
echo "Retrieving Security Group ID for web server..."
SG_ID=$(aws ec2 describe-security-groups \
    --filters "Name=vpc-id,Values=$VPC_ID" "Name=group-name,Values=web-server-sg" \
    --query "SecurityGroups[0].GroupId" --output text)
echo "Security Group ID: $SG_ID"

# Specify the AMI ID (Ensure this is valid for your region)
AMI_ID="ami-0ebfd941bbafe70c6"
echo "Using AMI ID: $AMI_ID"

# Step 7 - Web Server Deployment

# 7.1. Launch the web server instance in Public Subnet 2
echo "Launching web server instance in Public Subnet 2 ($SUBNET_PUBLIC_B)..."
INSTANCE_ID=$(aws ec2 run-instances \
    --image-id $AMI_ID \
    --instance-type t2.micro \
    --associate-public-ip-address \
    --security-group-ids $SG_ID \
    --subnet-id $SUBNET_PUBLIC_B \
    --user-data file://install-webserver.sh \
	--tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=WebServer}]' \
    --query 'Instances[0].InstanceId' --output text)

echo "Instance launched with ID: $INSTANCE_ID"

# Wait for the instance to be in running state
echo "Waiting for the instance to reach 'running' state..."
aws ec2 wait instance-running --instance-ids $INSTANCE_ID

# 7.2. Retrieve the instance's IPv4 Public Address and test the web server
echo "Retrieving the public IPv4 address of the instance..."
PUBLIC_IP=$(aws ec2 describe-instances --instance-ids $INSTANCE_ID \
    --query "Reservations[*].Instances[*].PublicIpAddress" --output text)

echo "Instance Public IP: $PUBLIC_IP"

# 7.4. Allocate a new Elastic IP to your account
echo "Allocating a new Elastic IP..."
ALLOCATION_ID=$(aws ec2 allocate-address --domain vpc \
    --query 'AllocationId' --output text)

PUBLIC_ELASTIC_IP=$(aws ec2 describe-addresses --allocation-ids $ALLOCATION_ID \
    --query 'Addresses[0].PublicIp' --output text)

echo "Elastic IP allocated: $PUBLIC_ELASTIC_IP with Allocation ID: $ALLOCATION_ID"

# 7.5. Associate the Elastic IP with the EC2 instance
echo "Associating the Elastic IP ($PUBLIC_ELASTIC_IP) with the instance ($INSTANCE_ID)..."
aws ec2 associate-address \
    --instance-id $INSTANCE_ID \
    --allocation-id $ALLOCATION_ID

echo "Elastic IP associated successfully. You can now access the web server at http://$PUBLIC_ELASTIC_IP"

# End of Step 7
echo "Web Server Deployment complete!"
