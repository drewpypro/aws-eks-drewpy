# resource "aws_instance" "test_ec2" {
#   ami             = "ami-09190d816c07cca00"
#   instance_type   = "t2.micro"
#   subnet_id       = module.vpc.private_subnets[0]
#   vpc_security_group_ids = [module.security_groups.security_group_ids["ec2_test_sg"]]

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

#   depends_on = [
#     module.vpc,
#     module.security_groups,
#     aws_eks_cluster.eks
#   ]
# }

# output "instance_id" {
#   value       = aws_instance.test_ec2.id
# }

# # ## ELASTIC IP
# # resource "aws_eip" "test_ec2_eip" {
# #   instance = aws_instance.test_ec2.id
# #   domain   = "vpc"
# # }

# # output "test_ec2_public_ip" {
# #   value = aws_eip.test_ec2_eip.public_ip
# # }
