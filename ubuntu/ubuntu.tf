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
    Lab  = "BIGIP"
  }
}

resource "aws_instance" "ubuntu-client" {
  ami                    = data.aws_ami.ubuntu_ami.id
  instance_type          = var.instance_type
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ubuntu_sg.id]
  subnet_id              = var.vpc_subnet[0]

  tags = {
    Name = "ubuntu-client"
    Lab  = "BIGIP"
  }
}

resource "aws_instance" "ubuntu" {
  ami                    = data.aws_ami.ubuntu_ami.id
  instance_type          = var.instance_type
  count                  = var.ubuntu_count
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ubuntu_sg.id]
  subnet_id              = var.vpc_subnet[0]

  tags = {
    Name = "ubuntu${count.index + 1}"
    Lab  = "BIGIP"
  }
}

# write out ubuntu inventory
data "template_file" "inventory" {
  template = <<EOF
[all]
${aws_instance.ubuntu-client.tags.Name} ansible_host=${aws_instance.ubuntu-client.public_ip} private_ip=${aws_instance.ubuntu-client.private_ip}
%{ for instance in aws_instance.ubuntu ~}
${instance.tags.Name} ansible_host=${instance.public_ip} private_ip=${instance.private_ip}
%{ endfor ~}

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
    aws ec2 wait instance-status-ok --region ${var.aws_region} --profile ${var.aws_profile} --instance-ids ${aws_instance.ubuntu-client.id} ${aws_instance.ubuntu.*.id}
    ansible-playbook ./playbooks/deploy-ubuntu.yaml
    EOF
  }
}

#-------- ubuntu output --------

output "public_ip" {
  value = formatlist(
  "%s = %s ",
  aws_instance.ubuntu.*.tags.Name,
  aws_instance.ubuntu.*.public_ip
  )
}
