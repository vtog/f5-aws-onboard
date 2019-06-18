data "aws_ami" "ubuntu_ami" {
  most_recent = true
  owners      = ["aws-marketplace"]

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-bionic-18.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_security_group" "ubuntu_sg" {
  name   = "ubuntu_sg"
  vpc_id = var.vpc_id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.myIP]
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
    Lab  = "Containers"
  }
}

resource "aws_instance" "ubuntu1" {
  ami                    = data.aws_ami.ubuntu_ami.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ubuntu_sg.id]
  subnet_id              = var.vpc_subnet[0]

  tags = {
    Name = "ubuntu1"
    Lab  = "BIGIP"
  }
}

resource "aws_instance" "ubuntu2" {
  ami                    = data.aws_ami.ubuntu_ami.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ubuntu_sg.id]
  subnet_id              = var.vpc_subnet[0]

  tags = {
    Name = "ubuntu2"
    Lab  = "BIGIP"
  }
}

# write out ubuntu inventory
data "template_file" "inventory" {
  template = <<EOF
[all]
${aws_instance.ubuntu1.tags.Name} ansible_host=${aws_instance.ubuntu1.public_ip} private_ip=${aws_instance.ubuntu1.private_ip}
${aws_instance.ubuntu2.tags.Name} ansible_host=${aws_instance.ubuntu2.public_ip} private_ip=${aws_instance.ubuntu2.private_ip}

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
    aws ec2 wait instance-status-ok --region ${var.aws_region} --profile ${var.aws_profile} --instance-ids ${aws_instance.ubuntu1.id} ${aws_instance.ubuntu2.id}
    ansible-playbook ./playbooks/deploy-ubuntu.yaml
    
EOF

}
}

