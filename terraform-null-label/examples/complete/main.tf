module "label" {
  source     = "git::git@github.com:Merlz/tf-modules.git//terraform-null-label?ref=master"
  namespace  = "Namespace"
  stage      = "Stage"
  name       = "Name"
  attributes = ["1", "2", "3", ""]
  tags       = "${map("Key", "Value")}"
}
