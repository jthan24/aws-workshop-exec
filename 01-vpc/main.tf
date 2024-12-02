terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.78.0"
    }
  }
}



resource "aws_vpc" "vpc_a" {
  cidr_block           = "10.0.0.0/16"
  instance_tenancy     = "default"
  enable_dns_hostnames = true

  tags = {
    Name = "VPC A"
  }
}


resource "aws_subnet" "vpc_a_public_subnet_az1" {
  vpc_id            = aws_vpc.vpc_a.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "VPC A Public Subnet AZ1"
  }
}

resource "aws_subnet" "vpc_a_public_subnet_az2" {
  vpc_id            = aws_vpc.vpc_a.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-west-2b"

  tags = {
    Name = "VPC A Public Subnet AZ2"
  }
}

resource "aws_subnet" "vpc_a_private_subnet_az1" {
  vpc_id            = aws_vpc.vpc_a.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-west-2a"

  tags = {
    Name = "VPC A Private Subnet AZ1"
  }
}

resource "aws_subnet" "vpc_a_private_subnet_az2" {
  vpc_id            = aws_vpc.vpc_a.id
  cidr_block        = "10.0.3.0/24"
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

resource "aws_internet_gateway" "igw_vpc_a" {
  tags = {
    Name = "VPC A IGW"
  }
}

resource "aws_internet_gateway_attachment" "igw_attach_vpc_a" {
  internet_gateway_id = aws_internet_gateway.igw_vpc_a.id
  vpc_id              = aws_vpc.vpc_a.id
}

resource "aws_route" "igw_vpc_a" {
  route_table_id            = aws_route_table.public_rt.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_internet_gateway.igw_vpc_a.id
}

resource "aws_eip" "eip_ngw_vpc_a" {
  domain   = "vpc"
  tags = {
    Name = "VPC A EIP"
  }
}


resource "aws_nat_gateway" "ngw_vpc_a" {
  allocation_id = aws_eip.eip_ngw_vpc_a.id
  subnet_id     = aws_subnet.vpc_a_public_subnet_az1.id

  tags = {
    Name = "VPC A NATGW"
  }

  # To ensure proper ordering, it is recommended to add an explicit dependency
  # on the Internet Gateway for the VPC.
  depends_on = [aws_internet_gateway.igw_vpc_a]
}


resource "aws_route" "ngw_vpc_a" {
  route_table_id            = aws_route_table.private_rt.id
  destination_cidr_block    = "0.0.0.0/0"
  gateway_id = aws_nat_gateway.ngw_vpc_a.id
}

/* 
VPC Endpoints are private links to supported AWS services from a VPC, instead of reaching the service's public endpoints through the internet. Two types of VPC endpoints exist, Gateway endpoints and Interface endpoints.

Gateway endpoints support only S3 and DynamoDB, and reach these services through a gateway from the VPC.

Interface endpoints create a network interface in the VPC's subnets, and all traffic to the service flows through this interface to the service.
*/

data "aws_security_groups" "sg_vpc_a_default"{
  filter {
    name   = "vpc-id"
    values = [aws_vpc.vpc_a.id]
  }
}

resource "aws_vpc_endpoint" "vpce_kms" {
  vpc_id            = aws_vpc.vpc_a.id
  service_name      = "com.amazonaws.us-west-2.kms"
  vpc_endpoint_type = "Interface"
  
  subnet_configuration {
    subnet_id = aws_subnet.vpc_a_private_subnet_az1.id
  }
  subnet_configuration {
    subnet_id = aws_subnet.vpc_a_private_subnet_az2.id
  }
  subnet_ids = [
    aws_subnet.vpc_a_private_subnet_az1.id, aws_subnet.vpc_a_private_subnet_az2.id
  ]

  security_group_ids = data.aws_security_groups.sg_vpc_a_default.ids
  
  tags = {
    Name = "VPC A KMS Endpoint"
  }

}


data "aws_route_tables" "rt_vpc_a_all" {
  vpc_id = aws_vpc.vpc_a.id
}


resource "aws_vpc_endpoint" "vpce_s3" {
  vpc_id            = aws_vpc.vpc_a.id
  service_name      = "com.amazonaws.us-west-2.s3"
  vpc_endpoint_type = "Gateway"

  route_table_ids = data.aws_route_tables.rt_vpc_a_all.ids
  
  tags = {
    Name = "VPC A S3 Endpoint"
  }
}


data "aws_ami" "amazon_ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "name"
    values = ["al2023-ami-2023*"]
  }
}

resource "aws_security_group" "sg_vpc_a_open_icmp" {
  name        = "VPC A Security Group"
  description = "Open-up ports for ICMP"
  vpc_id      = aws_vpc.vpc_a.id

  tags = {
    Name = "VPC A Security Group"
  }
}

resource "aws_vpc_security_group_ingress_rule" "sg_ingress_icmp" {
  security_group_id = aws_security_group.sg_vpc_a_open_icmp.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "icmp"
  description = "Open-up ports from ICMP"
  from_port = -1
  to_port = -1
}

data "aws_iam_instance_profile" "instance_profile_public" {
  name = "NetworkingWorkshopInstanceProfile"
}

resource "aws_instance" "instance_public_vpc_a" {
  ami           = data.aws_ami.amazon_ami.id # ami-055e3d4f0bbeb5878
  instance_type = "t2.micro"
  subnet_id = aws_subnet.vpc_a_public_subnet_az2.id
  associate_public_ip_address = true
  security_groups = [aws_security_group.sg_vpc_a_open_icmp.id]
  private_ip = "10.0.2.100"

  iam_instance_profile = data.aws_iam_instance_profile.instance_profile_public.name

  tags = {
    Name = "VPC A Public AZ2 Server"
  }
}

resource "aws_instance" "instance_private_vpc_a" {
  ami           = data.aws_ami.amazon_ami.id # ami-055e3d4f0bbeb5878
  instance_type = "t2.micro"
  subnet_id = aws_subnet.vpc_a_private_subnet_az1.id
  associate_public_ip_address = false
  security_groups = [aws_security_group.sg_vpc_a_open_icmp.id]
  private_ip = "10.0.1.100"
  
  iam_instance_profile = data.aws_iam_instance_profile.instance_profile_public.name

  tags = {
    Name = "VPC A Private Subnet AZ1"
  }
}