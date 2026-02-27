provider "aws" {
    region = "us-west-1"
  
}
 module "eks" {
    source = "./module/eks"
 }