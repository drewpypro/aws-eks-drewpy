resource "aws_instance" "test_ec2" {
  ami             = "ami-09190d816c07cca00"
  instance_type   = "t2.micro"
  subnet_id       = module.eks.private_subnet_ids[0]
  vpc_security_group_ids = [aws_security_group.test_ec2_sg.id]

  tags = {
    Name = "test-ec2-instance"
  }

  metadata_options {
    http_endpoint               = "enabled"
    http_tokens                 = "optional"
    http_put_response_hop_limit = 1
    http_protocol_ipv6          = "disabled"
  }

  iam_instance_profile = aws_iam_instance_profile.test_instance_profile.name

  user_data = templatefile("scripts/test_ec2_startup.sh", {
    public_key         = var.PUBLIC_KEY
    source_ssh_net     = var.SOURCE_SSH_NET
  })
}

## ELASTIC IP
resource "aws_eip" "test_ec2_eip" {
  instance = aws_instance.test_ec2.id
  domain   = "vpc"
}

output "test_ec2_public_ip" {
  value = aws_eip.test_ec2_eip.public_ip
}