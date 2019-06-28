output "bigip_password" {
  value = random_string.password.result
}

output "bigip_public_dns" {
  value = formatlist(
  "%s = https://%s",
  aws_instance.bigip.*.tags.Name,
  aws_instance.bigip.*.public_dns,
  )
}

output "bigip_public_ip" {
  value = formatlist(
  "%s = %s ",
  aws_instance.bigip.*.tags.Name,
  aws_instance.bigip.*.public_ip,
  )
}

output "ubuntu_public_ip" {
  value = formatlist(
  "%s = %s ",
  aws_instance.ubuntu.*.tags.Name,
  aws_instance.ubuntu.*.public_ip
  )
}

