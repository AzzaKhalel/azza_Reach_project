terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "4.54.0"
    }
  }
}
#to locate the tfstate file remotly
backend "S3" {
  bucket = "mybucket"
  key = "ReachProject/state.tfstate"
  region = var.region
}
provider "aws" {
  #you should export your AWS credentials on your local machine by "aws configure" command
}