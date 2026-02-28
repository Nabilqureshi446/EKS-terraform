provider "aws" {
    region = "ap-southeast-1"
  
}
 module "eks" {
    source = "./module/eks"
    desired_size = 2
    max_size = 2    
    min_size = 1
    env = "dev"
    project = "cbz-app"
 }