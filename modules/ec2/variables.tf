# modules/ec2/variables.tf

variable "project_name"         { type = string }
variable "environment"          { type = string }
variable "ami_id"               { type = string }
variable "instance_type"        { type = string }
variable "public_subnet_ids"    { type = list(string) }
variable "vpc_id"               { type = string }
variable "iam_instance_profile" { type = string }
variable "key_pair_name"        { type = string }
