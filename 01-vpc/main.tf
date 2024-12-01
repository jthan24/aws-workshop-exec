terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}



resource "aws_vpc" "vpc_a" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "VPC A"
  }
}


resource "aws_subnet" "vpc_a_public_subnet_az1" {
  vpc_id     = aws_vpc.vpc_a.id
  cidr_block = "10.0.0.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "VPC A Public Subnet AZ1"
  }
}

resource "aws_subnet" "vpc_a_public_subnet_az2" {
  vpc_id     = aws_vpc.vpc_a.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "VPC A Public Subnet AZ2"
  }
}

resource "aws_subnet" "vpc_a_private_subnet_az1" {
  vpc_id     = aws_vpc.vpc_a.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "VPC A Private Subnet AZ1"
  }
}

resource "aws_subnet" "vpc_a_private_subnet_az2" {
  vpc_id     = aws_vpc.vpc_a.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "VPC A Private Subnet AZ2"
  }
}


resource "aws_network_acl" "vpc_a_nacl" {
  vpc_id = aws_vpc.vpc_a.id



  tags = {
    Name = "VPC A Workload Subnets NACL"
  }
}

resource "aws_network_acl_association" "private_nacl_az1" {
  network_acl_id = aws_network_acl.vpc_a_nacl.id
  subnet_id      = aws_subnet.vpc_a_private_subnet_az1.id
}

resource "aws_network_acl_association" "private_nacl_az2" {
  network_acl_id = aws_network_acl.vpc_a_nacl.id
  subnet_id      = aws_subnet.vpc_a_private_subnet_az2.id
}

resource "aws_network_acl_association" "public_nacl_az1" {
  network_acl_id = aws_network_acl.vpc_a_nacl.id
  subnet_id      = aws_subnet.vpc_a_public_subnet_az1.id
}

resource "aws_network_acl_association" "public_nacl_az2" {
  network_acl_id = aws_network_acl.vpc_a_nacl.id
  subnet_id      = aws_subnet.vpc_a_public_subnet_az2.id
}


resource "aws_network_acl_rule" "inbound_allow" {
  network_acl_id = aws_network_acl.vpc_a_nacl.id
  rule_number    = 100
  egress         = false
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = -1
  to_port        = -1
}

resource "aws_network_acl_rule" "outbound_allow" {
  network_acl_id = aws_network_acl.vpc_a_nacl.id
  rule_number    = 100
  egress         = true
  protocol       = -1
  rule_action    = "allow"
  cidr_block     = "0.0.0.0/0"
  from_port      = -1
  to_port        = -1
}

#Allowing all traffic in and out of your subnets is not a good security posture. You can use NACLs to set broad rules and/or DENY rules, and then use Security Groups to create fine grained rules. For example, you can deny traffic from specific IPs with NACLs but not with Security Groups.


resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.vpc_a.id

  route = []

  tags = {
    Name = "VPC A Public Route Table"
  }
}

resource "aws_route_table_association" "public_rt_az1" {
  subnet_id      = aws_subnet.vpc_a_public_subnet_az1.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table_association" "public_rt_az2" {
  subnet_id      = aws_subnet.vpc_a_public_subnet_az2.id
  route_table_id = aws_route_table.public_rt.id
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.vpc_a.id

  route = []

  tags = {
    Name = "VPC A Private Route Table"
  }
}

resource "aws_route_table_association" "private_rt_az1" {
  subnet_id      = aws_subnet.vpc_a_private_subnet_az1.id
  route_table_id = aws_route_table.private_rt.id
}

resource "aws_route_table_association" "private_rt_az2" {
  subnet_id      = aws_subnet.vpc_a_private_subnet_az2.id
  route_table_id = aws_route_table.private_rt.id
}