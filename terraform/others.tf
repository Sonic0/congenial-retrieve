
//# ---------------------------------------------------------------
//# --------------------------- VPC -------------------------------
//
//# create VPC
//resource "aws_vpc" "TbotRetriveLastCommitVPC" {
//  cidr_block           = "20.0.0.0/24"
//  instance_tenancy     = "default"
//  enable_dns_hostnames = "true"
//  tags = {
//    Name = "TerraformTest-VPC"
//  }
//}
//
////create Internet Gateway
//resource "aws_internet_gateway" "TbotRetriveLastCommitIGW" {
//  vpc_id = aws_vpc.TbotRetriveLastCommitVPC.id
//
//  tags = {
//    Name = "TbotRetriveLastCommitIGW"
//  }
//}