#!/bin/bash

# Stop script execution on any error
set -e

# Step 1: Retrieve VPC ID
echo "Retrieving VPC ID..."
VPC_ID=$(aws ec2 describe-vpcs \
    --filters "Name=tag:Name,Values=LabVPC" \
    --query "Vpcs[0].VpcId" --output text)

echo "VPC ID: $VPC_ID"

# Step 2: Retrieve Public Subnet IDs
echo "Retrieving Public Subnet 1 ID..."
SUBNET_PUBLIC_A=$(aws ec2 describe-subnets \
    --filters "Name=tag:Name,Values=PublicSubnet1" \
    --query "Subnets[0].SubnetId" --output text)

echo "Public Subnet 1 ID: $SUBNET_PUBLIC_A"

echo "Retrieving Public Subnet 2 ID..."
SUBNET_PUBLIC_B=$(aws ec2 describe-subnets \
    --filters "Name=tag:Name,Values=PublicSubnet2" \
    --query "Subnets[0].SubnetId" --output text)

echo "Public Subnet 2 ID: $SUBNET_PUBLIC_B"

# Step 3: Retrieve Private Subnet IDs
echo "Retrieving Private Subnet 1 ID..."
SUBNET_PRIVATE_A=$(aws ec2 describe-subnets \
    --filters "Name=tag:Name,Values=PrivateSubnet1" \
    --query "Subnets[0].SubnetId" --output text)

echo "Private Subnet 1 ID: $SUBNET_PRIVATE_A"

echo "Retrieving Private Subnet 2 ID..."
SUBNET_PRIVATE_B=$(aws ec2 describe-subnets \
    --filters "Name=tag:Name,Values=PrivateSubnet2" \
    --query "Subnets[0].SubnetId" --output text)

echo "Private Subnet 2 ID: $SUBNET_PRIVATE_B"

# Step 4: Retrieve Internet Gateway ID
echo "Retrieving Internet Gateway ID..."
IGW_ID=$(aws ec2 describe-internet-gateways \
    --filters "Name=tag:Name,Values=LabIGW" \
    --query "InternetGateways[0].InternetGatewayId" --output text)

echo "Internet Gateway ID: $IGW_ID"

# Step 5: Retrieve NAT Gateway ID
echo "Retrieving NAT Gateway ID..."
NAT_GW_ID=$(aws ec2 describe-nat-gateways \
    --filter "Name=subnet-id,Values=$SUBNET_PUBLIC_A" \
    --query "NatGateways[0].NatGatewayId" --output text)

echo "NAT Gateway ID: $NAT_GW_ID"

# Step 5 - Route Tables Configuration

# 5.1. Create a route table for public subnets
echo "Creating route table for public subnets in VPC $VPC_ID..."
PUBLIC_RT_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Public Route Table}]' \
    --query 'RouteTable.RouteTableId' --output text)

echo "Public Route Table created with ID: $PUBLIC_RT_ID"

# 5.2. Create a route to the Internet Gateway for the public route table
echo "Creating route to Internet Gateway ($IGW_ID) in Public Route Table ($PUBLIC_RT_ID)..."
aws ec2 create-route \
    --route-table-id $PUBLIC_RT_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --gateway-id $IGW_ID

# 5.3. Associate the public route table with public subnets
echo "Associating Public Route Table ($PUBLIC_RT_ID) with Public Subnet 1 ($SUBNET_PUBLIC_A)..."
aws ec2 associate-route-table --subnet-id $SUBNET_PUBLIC_A --route-table-id $PUBLIC_RT_ID

echo "Associating Public Route Table ($PUBLIC_RT_ID) with Public Subnet 2 ($SUBNET_PUBLIC_B)..."
aws ec2 associate-route-table --subnet-id $SUBNET_PUBLIC_B --route-table-id $PUBLIC_RT_ID

# 5.4. Create a route table for private subnets
echo "Creating route table for private subnets in VPC $VPC_ID..."
PRIVATE_RT_ID=$(aws ec2 create-route-table \
    --vpc-id $VPC_ID \
    --tag-specifications 'ResourceType=route-table,Tags=[{Key=Name,Value=Private Route Table}]' \
    --query 'RouteTable.RouteTableId' --output text)

echo "Private Route Table created with ID: $PRIVATE_RT_ID"

# 5.5. Create a route to the NAT Gateway for the private route table
echo "Creating route to NAT Gateway ($NAT_GW_ID) in Private Route Table ($PRIVATE_RT_ID)..."
aws ec2 create-route \
    --route-table-id $PRIVATE_RT_ID \
    --destination-cidr-block 0.0.0.0/0 \
    --nat-gateway-id $NAT_GW_ID

# 5.6. Associate the private route table with private subnets
echo "Associating Private Route Table ($PRIVATE_RT_ID) with Private Subnet 1 ($SUBNET_PRIVATE_A)..."
aws ec2 associate-route-table --subnet-id $SUBNET_PRIVATE_A --route-table-id $PRIVATE_RT_ID

echo "Associating Private Route Table ($PRIVATE_RT_ID) with Private Subnet 2 ($SUBNET_PRIVATE_B)..."
aws ec2 associate-route-table --subnet-id $SUBNET_PRIVATE_B --route-table-id $PRIVATE_RT_ID

# End of Step 5
echo "Route Tables Configuration complete!"
