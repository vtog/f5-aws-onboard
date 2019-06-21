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
    from_port   = 3389
    to_port     = 3389
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

resource "aws_instance" "ubuntu" {
  ami                    = data.aws_ami.ubuntu_ami.id
  instance_type          = var.instance_type
  count                  = var.ubuntu_count
  key_name               = var.key_name
  vpc_security_group_ids = [aws_security_group.ubuntu_sg.id]
  subnet_id              = var.vpc_subnet[0]

  tags = {
    Name = "${count.index == 0 ? "jumpbox" : "ubuntu${count.index}"}"
    Lab  = "BIGIP"
  }
}

# write out ubuntu inventory
data "template_file" "inventory" {
  template = <<EOF
[all]
%{ for instance in aws_instance.ubuntu ~}
${instance.tags.Name} ansible_host=${instance.public_ip} private_ip=${instance.private_ip}
%{ endfor ~}

[desktop]
%{ for instance in aws_instance.ubuntu ~}
%{ if instance.tags.Name == "jumpbox" }${instance.tags.Name} ansible_host=${instance.public_ip} private_ip=${instance.private_ip}%{ endif }
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
    aws ec2 wait instance-status-ok --region ${var.aws_region} --profile ${var.aws_profile} --instance-ids ${join(" ", aws_instance.ubuntu.*.id)}
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

