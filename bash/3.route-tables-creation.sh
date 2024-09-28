#!/bin/bash

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
