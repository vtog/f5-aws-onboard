provider "aws" {
  profile = "${var.aws_profile}"
  region  = "${var.aws_region}"
}

#----- Create VPC -----

resource "aws_vpc" "bigip_vpc" {
  cidr_block           = "${var.vpc_cidr}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags {
    Name = "bigip_vpc"
    Lab  = "BIGIP"
  }
}

# Internet gateway

resource "aws_internet_gateway" "bigip_igw" {
  vpc_id = "${aws_vpc.bigip_vpc.id}"

  tags {
    Name = "bigip_igw"
    Lab  = "BIGIP"
  }
}

# Route tables

resource "aws_route_table" "bigip_public_rt" {
  vpc_id = "${aws_vpc.bigip_vpc.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.bigip_igw.id}"
  }

  tags {
    Name = "bigip_public"
    Lab  = "BIGIP"
  }
}

resource "aws_default_route_table" "bigip_private_rt" {
  default_route_table_id = "${aws_vpc.bigip_vpc.default_route_table_id}"

  tags {
    Name = "bigip_private"
    Lab  = "BIGIP"
  }
}

# Subnets

resource "aws_subnet" "mgmt1_subnet" {
  vpc_id                  = "${aws_vpc.bigip_vpc.id}"
  cidr_block              = "${var.cidrs["mgmt1"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "bigip_mgmt1"
    Lab  = "BIGIP"
  }
}

resource "aws_subnet" "mgmt2_subnet" {
  vpc_id                  = "${aws_vpc.bigip_vpc.id}"
  cidr_block              = "${var.cidrs["mgmt2"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags {
    Name = "bigip_mgmt2"
    Lab  = "BIGIP"
  }
}

resource "aws_subnet" "external1_subnet" {
  vpc_id                  = "${aws_vpc.bigip_vpc.id}"
  cidr_block              = "${var.cidrs["external1"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "bigip_external1"
    Lab  = "BIGIP"
  }
}

resource "aws_subnet" "external2_subnet" {
  vpc_id                  = "${aws_vpc.bigip_vpc.id}"
  cidr_block              = "${var.cidrs["external2"]}"
  map_public_ip_on_launch = true
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags {
    Name = "bigip_external2"
    Lab  = "BIGIP"
  }
}

resource "aws_subnet" "internal1_subnet" {
  vpc_id                  = "${aws_vpc.bigip_vpc.id}"
  cidr_block              = "${var.cidrs["internal1"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[0]}"

  tags {
    Name = "bigip_internal1"
    Lab  = "BIGIP"
  }
}

resource "aws_subnet" "internal2_subnet" {
  vpc_id                  = "${aws_vpc.bigip_vpc.id}"
  cidr_block              = "${var.cidrs["internal2"]}"
  map_public_ip_on_launch = false
  availability_zone       = "${data.aws_availability_zones.available.names[1]}"

  tags {
    Name = "bigip_internal2"
    Lab  = "BIGIP"
  }
}

resource "aws_route_table_association" "bigip_mgmt1_assoc" {
  subnet_id      = "${aws_subnet.mgmt1_subnet.id}"
  route_table_id = "${aws_route_table.bigip_public_rt.id}"
}

resource "aws_route_table_association" "bigip_mgmt2_assoc" {
  subnet_id      = "${aws_subnet.mgmt2_subnet.id}"
  route_table_id = "${aws_route_table.bigip_public_rt.id}"
}

resource "aws_route_table_association" "bigip_external1_assoc" {
  subnet_id      = "${aws_subnet.external1_subnet.id}"
  route_table_id = "${aws_route_table.bigip_public_rt.id}"
}

resource "aws_route_table_association" "bigip_external2_assoc" {
  subnet_id      = "${aws_subnet.external2_subnet.id}"
  route_table_id = "${aws_route_table.bigip_public_rt.id}"
}

resource "aws_route_table_association" "bigip_internal1_assoc" {
  subnet_id      = "${aws_subnet.internal1_subnet.id}"
  route_table_id = "${aws_default_route_table.bigip_private_rt.id}"
}

resource "aws_route_table_association" "bigip_internal2_assoc" {
  subnet_id      = "${aws_subnet.internal2_subnet.id}"
  route_table_id = "${aws_default_route_table.bigip_private_rt.id}"
}

#----- Set default SSH key pair -----
resource "aws_key_pair" "bigip_auth" {
  key_name   = "${var.key_name}"
  public_key = "${file(var.public_key_path)}"
}

#----- Deploy Big-IP -----
module "bigip" {
  source              = "./bigip"
  aws_region          = "${var.aws_region}"
  aws_profile         = "${var.aws_profile}"
  myIP                = "${chomp(data.http.myIP.body)}/32"
  key_name            = "${var.key_name}"
  instance_type       = "${var.bigip_instance_type}"
  bigip_count         = "${var.bigip_count}"
  bigip_ami_prod_code = "${var.bigip_ami_prod_code}"
  bigip_ami_name_filt = "${var.bigip_ami_name_filt}"
  bigip_admin         = "${var.bigip_admin}"
  do_rpm              = "${var.do_rpm}"
  as3_rpm             = "${var.as3_rpm}"
  vpc_id              = "${aws_vpc.bigip_vpc.id}"
  vpc_cidr            = "${var.vpc_cidr}"
  vpc_subnet          = ["${aws_subnet.mgmt1_subnet.id}", "${aws_subnet.mgmt2_subnet.id}", "${aws_subnet.external1_subnet.id}", "${aws_subnet.external2_subnet.id}", "${aws_subnet.internal1_subnet.id}", "${aws_subnet.internal2_subnet.id}"]
}
