locals {
  root    = "netology"
  env     = "develop"
  project = "platform"

  vm_web_name = "${local.root}-${local.env}-${local.project}-web"
  vm_db_name  = "${local.root}-${local.env}-${local.project}-db"

}

