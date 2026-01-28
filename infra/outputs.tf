output "master_public_ip" {
  value = aws_instance.master.public_ip
}

output "worker1_public_ip" {
  value = aws_instance.worker[0].public_ip
}

output "worker2_public_ip" {
  value = aws_instance.worker[1].public_ip
}
