module "logs_label" {
  source     = "git::git@github.com:Merlz/tf-modules.git//terraform-null-label?ref=master"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  name       = "${var.name}"
  delimiter  = "${var.delimiter}"
  attributes = ["${compact(concat(var.attributes, list("logs")))}"]
  tags       = "${var.tags}"
}

resource "aws_s3_bucket" "logs" {
  bucket        = "${module.logs_label.id}"
  force_destroy = true
  tags          = "${module.logs_label.tags}"
}

module "backups_label" {
  source     = "git::git@github.com:Merlz/tf-modules.git//terraform-null-label?ref=master"
  namespace  = "${var.namespace}"
  stage      = "${var.stage}"
  name       = "${var.name}"
  delimiter  = "${var.delimiter}"
  attributes = ["${compact(concat(var.attributes, list("backups")))}"]
  tags       = "${var.tags}"
}

resource "aws_s3_bucket" "backups" {
  bucket = "${module.backups_label.id}"
  tags   = "${module.backups_label.tags}"

  versioning {
    enabled = true
  }

  lifecycle_rule {
    enabled = true
    prefix  = "efs"

    noncurrent_version_expiration {
      days = "${var.noncurrent_version_expiration_days}"
    }
  }
}
