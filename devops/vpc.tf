resource "aws_vpc" "devops_test" {
  instance_tenancy = "default"
  tags = {
    name = "devops_test"
  }
  cidr_block = "10.16.0.0/16"
}

locals {
  devops_test_subnets = {
    "sn_web_a" : {
      availability_zone = "us-east-1a"
      cidr              = "10.16.0.0/20"
    }
    "sn_web_b" : {
      availability_zone = "us-east-1b"
      cidr              = "10.16.64.0/20"
    }
  }
}

resource "aws_subnet" "devops_test" {
  vpc_id                  = aws_vpc.devops_test.id
  for_each                = local.devops_test_subnets
  cidr_block              = each.value.cidr
  map_public_ip_on_launch = false
  availability_zone       = each.value.availability_zone
}

resource "aws_internet_gateway" "devops_test_igw" {
  vpc_id = aws_vpc.devops_test.id
}

resource "aws_route_table" "devops_test_access_internet" {
  vpc_id = aws_vpc.devops_test.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.devops_test_igw.id
  }
}

# attach route table to subnet
resource "aws_route_table_association" "devops_test_access_internet" {
  for_each       = local.devops_test_subnets
  subnet_id      = aws_subnet.devops_test[each.key].id
  route_table_id = aws_route_table.devops_test_access_internet.id
}

resource "aws_security_group" "devops_test_web" {
  name   = "devops_test_web"
  vpc_id = aws_vpc.devops_test.id
}

resource "aws_vpc_security_group_ingress_rule" "allow_http" {
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = aws_security_group.devops_test_web.id
  ip_protocol       = "tcp"
  from_port         = 0
  to_port           = var.webapp_port
}

resource "aws_vpc_security_group_ingress_rule" "allow_https" {
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = aws_security_group.devops_test_web.id
  ip_protocol       = "tcp"
  from_port         = 0
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "allow_outbound" {
  cidr_ipv4         = "0.0.0.0/0"
  security_group_id = aws_security_group.devops_test_web.id
  ip_protocol       = -1
}
