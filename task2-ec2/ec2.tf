resource "aws_instance" "web" {
  ami           = data.aws_ami.ubuntu_2204.id
  instance_type = "t2.micro"

  vpc_security_group_ids = [aws_security_group.web_sg.id]
  subnet_id              = data.terraform_remote_state.task1.outputs.public_subnet_id

  associate_public_ip_address = true

  tags = {
    Name = "task2-web"
  }
}
