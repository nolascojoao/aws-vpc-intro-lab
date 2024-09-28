#!/bin/bash

# Step 3 - Internet Gateway Setup

# 3.1. Create the Internet Gateway
echo "Creating Internet Gateway..."
IGW_ID=$(aws ec2 create-internet-gateway \
    --tag-specifications 'ResourceType=internet-gateway,Tags=[{Key=Name,Value=LabIGW}]' \
    --query 'InternetGateway.InternetGatewayId' --output text)

echo "Internet Gateway created with ID: $IGW_ID"

# 3.2. Attach the Internet Gateway to the VPC
echo "Attaching Internet Gateway to VPC $VPC_ID..."
aws ec2 attach-internet-gateway \
    --vpc-id $VPC_ID \
    --internet-gateway-id $IGW_ID

# 3.3. Verify the Internet Gateway status
echo "Verifying Internet Gateway status..."
aws ec2 describe-internet-gateways \
    --internet-gateway-ids $IGW_ID \
    --query "InternetGateways[*].Attachments"

# Step 4 - NAT Gateway Setup

# 4.1. Allocate an Elastic IP
echo "Allocating Elastic IP..."
ALLOCATION_ID=$(aws ec2 allocate-address --domain vpc --query 'AllocationId' --output text)

echo "Elastic IP allocated with ID: $ALLOCATION_ID"

# 4.2. Create NAT Gateway in Public Subnet 1 (AZ A)
echo "Creating NAT Gateway in Public Subnet 1 ($SUBNET_PUBLIC_A)..."
NAT_GW_ID=$(aws ec2 create-nat-gateway \
    --subnet-id $SUBNET_PUBLIC_A \
    --allocation-id $ALLOCATION_ID \
    --query 'NatGateway.NatGatewayId' --output text)

echo "NAT Gateway created with ID: $NAT_GW_ID"

# End of script
echo "Internet Gateway and NAT Gateway setup complete!"
