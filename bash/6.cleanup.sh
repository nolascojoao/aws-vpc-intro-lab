#!/bin/bash

# Exit on any error
set -e

# Functions to check if a resource is deleted
check_instance_terminated() {
  instance_id=$1
  state=$(aws ec2 describe-instances --instance-ids "$instance_id" --query 'Reservations[*].Instances[*].State.Name' --output text)
  while [ "$state" != "terminated" ]; do
    echo "Waiting for instance $instance_id to terminate..."
    sleep 10
    state=$(aws ec2 describe-instances --instance-ids "$instance_id" --query 'Reservations[*].Instances[*].State.Name' --output text)
  done
  echo "Instance $instance_id terminated."
}

check_resource_deleted() {
  resource_type=$1
  resource_id=$2
  while aws ec2 describe-$resource_type --${resource_type%-s}-ids "$resource_id" &> /dev/null; do
    echo "Waiting for $resource_type $resource_id to be deleted..."
    sleep 10
  done
  echo "$resource_type $resource_id deleted."
}

# Step 1: Terminate running instances
echo "Terminating running instances..."
instance_ids=$(aws ec2 describe-instances --filters "Name=instance-state-name,Values=running" --query 'Reservations[*].Instances[*].InstanceId' --output text)
if [ -n "$instance_ids" ]; then
  aws ec2 terminate-instances --instance-ids $instance_ids
  for instance_id in $instance_ids; do
    check_instance_terminated "$instance_id"
  done
else
  echo "No running instances found."
fi

# Step 2: Delete NAT Gateway
echo "Deleting NAT Gateways..."
nat_gateway_ids=$(aws ec2 describe-nat-gateways --filter "Name=state,Values=available" --query 'NatGateways[*].NatGatewayId' --output text)
for nat_gateway_id in $nat_gateway_ids; do
  aws ec2 delete-nat-gateway --nat-gateway-id "$nat_gateway_id"
  check_resource_deleted "nat-gateways" "$nat_gateway_id"
done

# Step 3: Delete security groups (except the default security group)
echo "Deleting security groups..."
vpc_ids=$(aws ec2 describe-vpcs --query 'Vpcs[*].VpcId' --output text)
for vpc_id in $vpc_ids; do
  sg_ids=$(aws ec2 describe-security-groups --filters "Name=vpc-id,Values=$vpc_id" --query 'SecurityGroups[*].GroupId' --output text)
  for sg_id in $sg_ids; do
    sg_name=$(aws ec2 describe-security-groups --group-ids "$sg_id" --query 'SecurityGroups[*].GroupName' --output text)
    if [ "$sg_name" != "default" ]; then
      aws ec2 delete-security-group --group-id "$sg_id"
      check_resource_deleted "security-groups" "$sg_id"
    else
      echo "Skipping default security group $sg_id."
    fi
  done
done

# Step 4: Detach and delete IGW (Internet Gateway)
echo "Detaching and deleting Internet Gateways..."
igw_ids=$(aws ec2 describe-internet-gateways --query 'InternetGateways[*].InternetGatewayId' --output text)
for igw_id in $igw_ids; do
  vpc_id=$(aws ec2 describe-internet-gateways --internet-gateway-ids "$igw_id" --query 'InternetGateways[*].Attachments[*].VpcId' --output text)
  if [ -n "$vpc_id" ]; then
    echo "Detaching IGW $igw_id from VPC $vpc_id"
    aws ec2 detach-internet-gateway --internet-gateway-id "$igw_id" --vpc-id "$vpc_id"
  fi
  echo "Deleting IGW $igw_id"
  aws ec2 delete-internet-gateway --internet-gateway-id "$igw_id"
  check_resource_deleted "internet-gateways" "$igw_id"
done

# Step 5: Delete subnets
echo "Deleting subnets..."
subnet_ids=$(aws ec2 describe-subnets --query 'Subnets[*].SubnetId' --output text)
for subnet_id in $subnet_ids; do
  aws ec2 delete-subnet --subnet-id "$subnet_id"
  check_resource_deleted "subnets" "$subnet_id"
done

# Step 6: Delete route tables (except the main route table)
echo "Deleting route tables..."
route_table_ids=$(aws ec2 describe-route-tables --query 'RouteTables[*].RouteTableId' --output text)
main_route_table_ids=$(aws ec2 describe-route-tables --filters "Name=association.main,Values=true" --query 'RouteTables[*].RouteTableId' --output text)

for route_table_id in $route_table_ids; do
  if [[ "$main_route_table_ids" != *"$route_table_id"* ]]; then
    aws ec2 delete-route-table --route-table-id "$route_table_id"
    check_resource_deleted "route-tables" "$route_table_id"
  else
    echo "Skipping main route table $route_table_id."
  fi
done

# Step 7: Release unassociated Elastic IPs
echo "Releasing unassociated Elastic IPs..."
allocation_ids=$(aws ec2 describe-addresses --query 'Addresses[?AssociationId==null].AllocationId' --output text)
if [ -n "$allocation_ids" ]; then
  for allocation_id in $allocation_ids; do
    echo "Releasing Elastic IP with Allocation ID: $allocation_id"
    aws ec2 release-address --allocation-id "$allocation_id"
  done
else
  echo "No unassociated Elastic IPs found."
fi

# Step 8: Delete VPCs
echo "Deleting VPCs..."
for vpc_id in $vpc_ids; do
  aws ec2 delete-vpc --vpc-id "$vpc_id"
  check_resource_deleted "vpcs" "$vpc_id"
done

echo "Cleanup completed."
