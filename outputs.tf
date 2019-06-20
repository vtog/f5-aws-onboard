#--------root/outputs.tf--------
output "BIGIP_Admin_URL" {
  value = "${module.bigip.public_dns}"
}

output "BIGIP_Mgmt_IP" {
  value = "${module.bigip.public_ip}"
}

output "BIGIP_Admin_Password" {
  value = "${module.bigip.password}"
}

output "UBUNTU_IP" {
  value = "${module.ubuntu.public_ip}"
}

