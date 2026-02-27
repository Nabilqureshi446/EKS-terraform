provider "aws" {
    region = "us-west-2"
  
}
 module "eks" {
    source = "./module/eks"
 }