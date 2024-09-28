#!/bin/bash

# Step 8 - Resource Cleanup

# 8.1. Terminate the EC2 instance
echo "Terminating EC2 instance ($INSTANCE_ID)..."
aws ec2 terminate-instances --instance-ids $INSTANCE_ID

# Wait for the instance termination to complete
echo "Waiting for instance to terminate..."
aws ec2 wait instance-terminated --instance-ids $INSTANCE_ID
echo "Instance $INSTANCE_ID terminated."

# 8.2. Delete NAT Gateway
echo "Deleting NAT Gateway ($NAT_GATEWAY_ID)..."
aws ec2 delete-nat-gateway --nat-gateway-id $NAT_GATEWAY_ID

# Wait for the NAT gateway deletion to complete
echo "Waiting for NAT Gateway deletion..."
aws ec2 wait nat-gateway-available --nat-gateway-ids $NAT_GATEWAY_ID
echo "NAT Gateway $NAT_GATEWAY_ID deleted."

# 8.3. Detach and Delete Internet Gateway
echo "Detaching Internet Gateway ($IGW_ID) from VPC ($VPC_ID)..."
aws ec2 detach-internet-gateway --internet-gateway-id $IGW_ID --vpc-id $VPC_ID

echo "Deleting Internet Gateway ($IGW_ID)..."
aws ec2 delete-internet-gateway --internet-gateway-id $IGW_ID
echo "Internet Gateway $IGW_ID deleted."

# 8.4. Release the Elastic IP
echo "Releasing Elastic IP with Allocation ID: $ALLOCATION_ID..."
aws ec2 release-address --allocation-id $ALLOCATION_ID
echo "Elastic IP with Allocation ID $ALLOCATION_ID released."

# 8.5. Delete VPC
echo "Deleting VPC ($VPC_ID)..."
aws ec2 delete-vpc --vpc-id $VPC_ID
echo "VPC $VPC_ID deleted."

# End of Step 8
echo "Resource cleanup complete!"
