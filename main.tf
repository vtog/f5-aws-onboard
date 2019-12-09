provider "aws" {
  profile = var.aws_profile
  region  = var.aws_region
}

#----- Create VPC -----

resource "aws_vpc" "bigip_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "bigip_vpc"
    Lab  = "BIGIP"
  }
}

#----- Internet gateway -----

resource "aws_internet_gateway" "bigip_igw" {
  vpc_id = aws_vpc.bigip_vpc.id

  tags = {
    Name = "bigip_igw"
    Lab  = "BIGIP"
  }
}

#----- Route tables -----

resource "aws_route_table" "bigip_public_rt" {
  vpc_id = aws_vpc.bigip_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.bigip_igw.id
  }

  tags = {
    Name = "bigip_public"
    Lab  = "BIGIP"
  }
}

resource "aws_default_route_table" "bigip_private_rt" {
  default_route_table_id = aws_vpc.bigip_vpc.default_route_table_id

  tags = {
    Name = "bigip_private"
    Lab  = "BIGIP"
  }
}

#----- Subnets -----

resource "aws_subnet" "mgmt1_subnet" {
  vpc_id                  = aws_vpc.bigip_vpc.id
  cidr_block              = var.cidrs["mgmt1"]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "bigip_mgmt1"
    Lab  = "BIGIP"
  }
}

resource "aws_subnet" "mgmt2_subnet" {
  vpc_id                  = aws_vpc.bigip_vpc.id
  cidr_block              = var.cidrs["mgmt2"]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "bigip_mgmt2"
    Lab  = "BIGIP"
  }
}

resource "aws_subnet" "external1_subnet" {
  vpc_id                  = aws_vpc.bigip_vpc.id
  cidr_block              = var.cidrs["external1"]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "bigip_external1"
    Lab  = "BIGIP"
  }
}

resource "aws_subnet" "external2_subnet" {
  vpc_id                  = aws_vpc.bigip_vpc.id
  cidr_block              = var.cidrs["external2"]
  map_public_ip_on_launch = true
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "bigip_external2"
    Lab  = "BIGIP"
  }
}

resource "aws_subnet" "internal1_subnet" {
  vpc_id                  = aws_vpc.bigip_vpc.id
  cidr_block              = var.cidrs["internal1"]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "bigip_internal1"
    Lab  = "BIGIP"
  }
}

resource "aws_subnet" "internal2_subnet" {
  vpc_id                  = aws_vpc.bigip_vpc.id
  cidr_block              = var.cidrs["internal2"]
  map_public_ip_on_launch = false
  availability_zone       = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "bigip_internal2"
    Lab  = "BIGIP"
  }
}

resource "aws_route_table_association" "bigip_mgmt1_assoc" {
  subnet_id      = aws_subnet.mgmt1_subnet.id
  route_table_id = aws_route_table.bigip_public_rt.id
}

resource "aws_route_table_association" "bigip_mgmt2_assoc" {
  subnet_id      = aws_subnet.mgmt2_subnet.id
  route_table_id = aws_route_table.bigip_public_rt.id
}

resource "aws_route_table_association" "bigip_external1_assoc" {
  subnet_id      = aws_subnet.external1_subnet.id
  route_table_id = aws_route_table.bigip_public_rt.id
}

resource "aws_route_table_association" "bigip_external2_assoc" {
  subnet_id      = aws_subnet.external2_subnet.id
  route_table_id = aws_route_table.bigip_public_rt.id
}

resource "aws_route_table_association" "bigip_internal1_assoc" {
  subnet_id      = aws_subnet.internal1_subnet.id
  route_table_id = aws_default_route_table.bigip_private_rt.id
}

resource "aws_route_table_association" "bigip_internal2_assoc" {
  subnet_id      = aws_subnet.internal2_subnet.id
  route_table_id = aws_default_route_table.bigip_private_rt.id
}

#----- Set default SSH key pair -----

resource "aws_key_pair" "bigip_auth" {
  key_name   = var.key_name
  public_key = file(var.public_key_path)
}

data "aws_ami" "f5_ami" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "product-code"
    values = [var.bigip_ami_prod_code]
  }

  filter {
    name   = "name"
    values = [var.bigip_ami_name_filt]
  }
}

data "aws_ami" "ubuntu_ami" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-disco-*-amd64*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "bigip_mgmt_sg" {
  name   = "bigip_mgmt_sg"
  vpc_id = aws_vpc.bigip_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myIP.body)}/32"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myIP.body)}/32"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bigip_mgmt_sg"
    Lab  = "BIGIP"
  }
}

resource "aws_security_group" "bigip_external_sg" {
  name   = "bigip_external_sg"
  vpc_id = aws_vpc.bigip_vpc.id

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myIP.body)}/32"]
  }

  ingress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myIP.body)}/32"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "bigip_external_sg"
    Lab  = "BIGIP"
  }
}

resource "aws_security_group" "bigip_internal_sg" {
  name   = "bigip_internal_sg"
  vpc_id = aws_vpc.bigip_vpc.id

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  tags = {
    Name = "bigip_internal_sg"
    Lab  = "BIGIP"
  }
}

resource "aws_security_group" "ubuntu_sg" {
  name   = "ubuntu_sg"
  vpc_id = aws_vpc.bigip_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myIP.body)}/32"]
  }

  ingress {
    from_port   = 3389
    to_port     = 3389
    protocol    = "tcp"
    cidr_blocks = ["${chomp(data.http.myIP.body)}/32"]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.vpc_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "ubuntu_sg"
    Lab  = "BIGIP"
  }
}

resource "aws_network_interface" "mgmt" {
  count           = var.bigip_count
  subnet_id       = aws_subnet.mgmt1_subnet.id
  security_groups = [aws_security_group.bigip_mgmt_sg.id]

  tags = {
    Name = "bigip${count.index + 1}_mgmt"
    Lab  = "BIGIP"
  }
}

resource "aws_network_interface" "external" {
  count             = var.bigip_count
  subnet_id         = aws_subnet.external1_subnet.id
  security_groups   = [aws_security_group.bigip_external_sg.id]
  private_ips_count = 1

  tags = {
    Name = "bigip${count.index + 1}_external"
    Lab  = "BIGIP"
  }
}

resource "aws_network_interface" "internal" {
  count             = var.bigip_count
  subnet_id         = aws_subnet.internal1_subnet.id
  security_groups   = [aws_security_group.bigip_internal_sg.id]
  private_ips_count = 1

  tags = {
    Name = "bigip${count.index + 1}_internal"
    Lab  = "BIGIP"
  }
}

resource "aws_eip" "mgmt" {
  vpc = true
  depends_on = [
    aws_network_interface.mgmt,
    aws_instance.bigip,
  ]
  count             = var.bigip_count
  network_interface = element(aws_network_interface.mgmt.*.id, count.index)

  tags = {
    Name = "bigip${count.index + 1}_mgmt_eip"
    Lab  = "BIGIP"
  }
}

resource "aws_eip" "external" {
  vpc = true
  depends_on = [
    aws_network_interface.external,
    aws_instance.bigip,
  ]
  count             = var.bigip_count
  network_interface = element(aws_network_interface.external.*.id, count.index)

  tags = {
    Name = "bigip${count.index + 1}_external_eip"
    Lab  = "BIGIP"
  }
}

resource "random_string" "password" {
  length           = 16
  special          = true
  override_special = "@"
}

data "template_file" "cloudinit_data" {
  template = file("./bigip/cloudinit_data.tpl")

  vars = {
    admin_username = var.bigip_admin
    admin_password = random_string.password.result
  }
}

resource "aws_instance" "bigip" {
  ami           = data.aws_ami.f5_ami.id
  instance_type = var.bigip_instance_type
  count         = var.bigip_count
  key_name      = var.key_name
  depends_on = [
    aws_network_interface.mgmt,
    aws_network_interface.external,
    aws_network_interface.internal,
  ]

  network_interface {
    network_interface_id = element(aws_network_interface.mgmt.*.id, count.index)
    device_index         = 0
  }

  network_interface {
    network_interface_id = element(aws_network_interface.external.*.id, count.index)
    device_index         = 1
  }

  network_interface {
    network_interface_id = element(aws_network_interface.internal.*.id, count.index)
    device_index         = 2
  }

  user_data = data.template_file.cloudinit_data.rendered

  tags = {
    Name = "bigip${count.index + 1}"
    Lab  = "BIGIP"
  }
}

resource "aws_instance" "ubuntu" {
  ami                    = data.aws_ami.ubuntu_ami.id
  instance_type          = var.ubuntu_instance_type
  count                  = var.ubuntu_count
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ubuntu_sg.id]
  subnet_id              = aws_subnet.external1_subnet.id

  tags = {
    Name = "${count.index == 0 ? "jumpbox" : "ubuntu${count.index}"}"
    Lab  = "BIGIP"
  }
}

#----- Setup DO & AS3 -----
resource "null_resource" "prep_bigip" {
  depends_on = [aws_instance.bigip]
  count      = var.bigip_count

  provisioner "local-exec" {
    command = <<EOF
    aws ec2 wait instance-status-ok --region ${var.aws_region} --profile ${var.aws_profile} --instance-ids ${element(aws_instance.bigip.*.id, count.index)}
    #wget -q https://github.com/F5Networks/f5-declarative-onboarding/releases/download/v1.9.0/${var.do_rpm} -O ${var.do_rpm}
    #wget -q https://github.com/F5Networks/f5-appsvcs-extension/releases/download/v3.16.0/${var.as3_rpm} -O ${var.as3_rpm}

    CREDS=${var.bigip_admin}:${random_string.password.result}
    IP=${element(aws_eip.mgmt.*.public_ip, count.index)}
    do_LEN=$(wc -c ${var.do_rpm} | cut -f 1 -d ' ')
    as3_LEN=$(wc -c ${var.as3_rpm} | cut -f 1 -d ' ')
    do_DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/${var.do_rpm}\"}"
    as3_DATA="{\"operation\":\"INSTALL\",\"packageFilePath\":\"/var/config/rest/downloads/${var.as3_rpm}\"}"

    until $(curl -ku $CREDS -o /dev/null --silent --fail https://$IP/mgmt/shared/iapp/package-management-tasks);do sleep 10;done

    curl -ku $CREDS https://$IP/mgmt/shared/file-transfer/uploads/${var.do_rpm} -H 'Content-Type: application/octet-stream' -H "Content-Range: 0-$((do_LEN - 1))/$do_LEN" -H "Content-Length: $do_LEN" -H 'Connection: keep-alive' --data-binary @${var.do_rpm}
    curl -ku $CREDS https://$IP/mgmt/shared/file-transfer/uploads/${var.as3_rpm} -H 'Content-Type: application/octet-stream' -H "Content-Range: 0-$((as3_LEN - 1))/$as3_LEN" -H "Content-Length: $as3_LEN" -H 'Connection: keep-alive' --data-binary @${var.as3_rpm}

    curl -ku $CREDS https://$IP/mgmt/shared/iapp/package-management-tasks -H "Origin: https://$IP" -H 'Content-Type: application/json;charset=UTF-8' --data $do_DATA
    curl -ku $CREDS https://$IP/mgmt/shared/iapp/package-management-tasks -H "Origin: https://$IP" -H 'Content-Type: application/json;charset=UTF-8' --data $as3_DATA
    EOF
  }
}

#----- Configure and Send DO Declaration -----
data "template_file" "do_data" {
  count = var.bigip_count
  template = file("./bigip/do_data.tpl")

  vars = {
    host_name = element(aws_instance.bigip.*.private_dns, count.index)
    members = join(", ", formatlist("\"%s\"", aws_instance.bigip.*.private_dns))
    admin = var.bigip_admin
    password = random_string.password.result
    aws_dns = cidrhost(var.vpc_cidr, 2)
    mgmt_ip = element(aws_network_interface.mgmt.*.private_ip, count.index)
    external_ip = element(aws_network_interface.external.*.private_ip, count.index)
    internal_ip = element(aws_network_interface.internal.*.private_ip, count.index)
  }
}

resource "local_file" "save_do_data" {
  depends_on = [data.template_file.do_data]
  count = var.bigip_count
  content = data.template_file.do_data[count.index].rendered
  filename = "./bigip/bigip${count.index + 1}.tpl"
}

resource "null_resource" "onboard" {
  depends_on = [null_resource.prep_bigip]
  count = var.bigip_count

  provisioner "local-exec" {
    command = <<EOF
    until $(curl -ku ${var.bigip_admin}:${random_string.password.result} -o /dev/null --silent --fail https://${element(aws_eip.mgmt.*.public_ip, count.index)}/mgmt/shared/declarative-onboarding/info);do sleep 10;done
    curl -k -X POST https://${element(aws_eip.mgmt.*.public_ip, count.index)}/mgmt/shared/declarative-onboarding \
            --retry 10 \
            --retry-connrefused \
            --retry-delay 30 \
            -H "Content-Type: application/json" \
            -u ${var.bigip_admin}:${random_string.password.result} \
            -d @./bigip/bigip${count.index + 1}.tpl
    EOF
  }
}

#----- Configure and Send AS3 Declaration -----
data "template_file" "as3_data" {
  count    = var.bigip_count
  template = file("./bigip/as3_data.tpl")

  vars = {
    pool_members = join(", ", formatlist("\"%s\"", aws_instance.ubuntu.*.private_ip))
    vips         = join(", ", formatlist("\"%s\"", aws_network_interface.external.*.private_ip))
  }
}

#----- Write out ubuntu inventory -----
data "template_file" "inventory" {
  template = <<EOF
[all]
%{for instance in aws_instance.ubuntu~}
${instance.tags.Name} ansible_host=${instance.public_ip} private_ip=${instance.private_ip}
%{endfor~}

[desktop]
%{for instance in aws_instance.ubuntu~}
%{if instance.tags.Name == "jumpbox"}${instance.tags.Name} ansible_host=${instance.public_ip} private_ip=${instance.private_ip} %{endif}
%{endfor~}

[all:vars]
ansible_user=ubuntu
ansible_python_interpreter=/usr/bin/python3
EOF
}

resource "local_file" "save_inventory" {
  depends_on = [data.template_file.inventory]
  content = data.template_file.inventory.rendered
  filename = "./ubuntu/ansible/inventory.ini"
}

#----- Run Ansible Playbook -----
resource "null_resource" "ansible" {
  provisioner "local-exec" {
    working_dir = "./ubuntu/ansible/"

    command = <<EOF
    aws ec2 wait instance-status-ok --region ${var.aws_region} --profile ${var.aws_profile} --instance-ids ${join(" ", aws_instance.ubuntu.*.id)}
    ansible-playbook ./playbooks/deploy-ubuntu.yaml
    EOF
  }
}

