# output "public_subnet_ids" {
#   value = { for k, v in aws_subnet.public : k => v.id }
# }

# output "private_subnet_ids" {
#   value = { for k, v in aws_subnet.private : k => v.id }
# }

# output "public_route_table_association_ids" {
#   value = { for k, v in aws_route_table_association.public : k => v.id }
# }

# output "private_route_table_association_ids" {
#   value = { for k, v in aws_route_table_association.private : k => v.id }
# }

# output "public_ec2_public_ip" {
#   value = aws_instance.public.public_ip
# }

# output "private_ec2_private_ip" {
#   value = aws_instance.private.private_ip
# }
