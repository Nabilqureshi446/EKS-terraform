provider "aws" {
    region = "ap-southeast-1"
  
}
 module "eks" {
    source = "./module/eks"
 }