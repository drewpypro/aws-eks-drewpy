# provider "aws" {
#   region = var.region
# }

# resource "aws_instance" "test_ec2" {
#   ami             = var.ami_id
#   instance_type   = var.instance_type
#   subnet_id       = aws_subnet.test_subnet.id
#   vpc_security_group_ids = [aws_security_group.test_ec2_sg.id]

#   tags = {
#     Name = "test-ec2-instance"
#   }

#   metadata_options {
#     http_endpoint               = "enabled"
#     http_tokens                 = "optional"
#     http_put_response_hop_limit = 1
#     http_protocol_ipv6          = "disabled"
#   }

#   iam_instance_profile = aws_iam_instance_profile.test_instance_profile.name

#   user_data = templatefile("scripts/test_ec2_startup.sh", {
#     public_key         = var.PUBLIC_KEY
#     account_id         = var.ACCOUNT_ID
#     source_ssh_net     = var.SOURCE_SSH_NET
#     aws_commands       = file("${path.module}/scripts/aws_commands.json")
#     tester_script      = file("${path.module}/scripts/aws_vpce_policy_tester.py")
#     option             = var.option
#     option_description = local.option_description[var.option]
#   })
# }

# ## ELASTIC IP
# resource "aws_eip" "test_ec2_eip" {
#   instance = aws_instance.test_ec2.id
#   domain   = "vpc"
# }

# output "test_ec2_public_ip" {
#   value = aws_eip.test_ec2_eip.public_ip
# }