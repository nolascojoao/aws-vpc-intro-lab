#!/bin/bash

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
echo "You can now test the web server by accessing http://$PUBLIC_IP"

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
