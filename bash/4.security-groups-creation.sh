#!/bin/bash

# Stop script execution on any error
set -e

# Step 1: Retrieve VPC ID
echo "Retrieving VPC ID..."
VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=LabVPC" \
    --query "Vpcs[0].VpcId" --output text)

echo "VPC ID: $VPC_ID"

# Step 6 - Security Groups Configuration

# 6.1. Create a security group for the web server
echo "Creating Security Group for the web server in VPC $VPC_ID..."
SG_ID=$(aws ec2 create-security-group \
    --group-name web-server-sg \
    --description "Web Server Security Group" \
    --vpc-id $VPC_ID \
    --query 'GroupId' --output text)

echo "Security Group created with ID: $SG_ID"

# 6.2. Allow inbound traffic on port 80 (HTTP)
echo "Authorizing inbound HTTP traffic on port 80 for Security Group $SG_ID..."
aws ec2 authorize-security-group-ingress \
    --group-id $SG_ID \
    --protocol tcp \
    --port 80 \
    --cidr 0.0.0.0/0

# End of Step 6
echo "Security Group Configuration complete!"
