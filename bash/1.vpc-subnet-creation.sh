#!/bin/bash

# Step 1 - VPC Creation
echo "Creating VPC..."
VPC_ID=$(aws ec2 create-vpc \
    --cidr-block 10.0.0.0/16 \
    --tag-specifications 'ResourceType=vpc,Tags=[{Key=Name,Value=LabVPC}]' \
    --query 'Vpc.VpcId' --output text)

echo "VPC created with ID: $VPC_ID"

# Check the status of the VPC
echo "Checking VPC status..."
aws ec2 describe-vpcs --vpc-ids $VPC_ID --query "Vpcs[*].State"

# Step 2 - Subnet Creation
# List Availability Zones
echo "Retrieving Availability Zones..."
AZ_A=$(aws ec2 describe-availability-zones --query "AvailabilityZones[0].ZoneName" --output text)
AZ_B=$(aws ec2 describe-availability-zones --query "AvailabilityZones[1].ZoneName" --output text)

echo "Creating public subnet in Availability Zone A ($AZ_A)..."
SUBNET_PUBLIC_A=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.0.0/24 \
    --availability-zone $AZ_A \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public Subnet 1}]' \
    --query 'Subnet.SubnetId' --output text)

echo "Creating private subnet in Availability Zone A ($AZ_A)..."
SUBNET_PRIVATE_A=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.1.0/24 \
    --availability-zone $AZ_A \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private Subnet 1}]' \
    --query 'Subnet.SubnetId' --output text)

echo "Creating public subnet in Availability Zone B ($AZ_B)..."
SUBNET_PUBLIC_B=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.2.0/24 \
    --availability-zone $AZ_B \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Public Subnet 2}]' \
    --query 'Subnet.SubnetId' --output text)

echo "Creating private subnet in Availability Zone B ($AZ_B)..."
SUBNET_PRIVATE_B=$(aws ec2 create-subnet \
    --vpc-id $VPC_ID \
    --cidr-block 10.0.3.0/24 \
    --availability-zone $AZ_B \
    --tag-specifications 'ResourceType=subnet,Tags=[{Key=Name,Value=Private Subnet 2}]' \
    --query 'Subnet.SubnetId' --output text)

# Retrieve the subnet IDs
echo "Retrieving all subnet IDs for VPC $VPC_ID..."
aws ec2 describe-subnets \
    --filters "Name=vpc-id,Values=$VPC_ID" \
    --query "Subnets[*].[SubnetId, Tags[?Key=='Name'].Value | [0]]" \
    --output table

echo "VPC and subnets created successfully!"
