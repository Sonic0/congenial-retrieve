//create s3 terraform-state location cl
terraform {
  backend "s3"{
    bucket         = "terraf0rm-states-dev" # Change it based on your preferences
    key            = "TbotRetriveLastCommit/terraform.tfstate" # Change it based on your preferences
    dynamodb_table = "terraform_state_lock"
    profile        = "AWSPersonalProfile"
    region         = "eu-west-1"
  }
}