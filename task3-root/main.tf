module "stack" {
  source = "../modules/vpc-ec2"

  vpc_cidr = "10.0.0.0/16"

  public_subnet_cidr  = ["10.0.1.0/24"]
  private_subnet_cidr = ["10.0.2.0/24"]

  instance_type       = "t2.micro"
  associate_public_ip = true
}
