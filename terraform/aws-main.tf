//create AWS provider 
provider "aws" {
    //aws profile defined in aws cli
  profile = "AWSPersonalProfile" // Decomment this line to use this file locally
    //aws region selection
  region  = local.availability_zone_names[0]
}

############################
# LOCAL VARIABLES
############################
locals {
  availability_zone_names = ["eu-west-1"]
}
