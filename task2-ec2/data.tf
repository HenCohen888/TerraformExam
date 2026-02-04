data "terraform_remote_state" "task1" {
  backend = "local"

  config = {
    path = "../task1-vpc/terraform.tfstate"
  }
}
