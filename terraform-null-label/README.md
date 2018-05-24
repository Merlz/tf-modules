## terraform-null-label

Terraform module designed to generate consistent label names and tags for resources. Use `terraform-null-label` to implement a strict naming convention.

A label follows the following convention: `{namespace}-{stage}-{name}-{attributes}`. The delimiter (e.g. `-`) is interchangeable.

It's recommended to use one `terraform-null-label` module for every unique resource of a given resource type.
For example, if you have 10 instances, there should be 10 different labels.
However, if you have multiple different kinds of resources (e.g. instances, security groups, file systems, and elastic ips), then they can all share the same label assuming they are logically related.

All modules use this module to ensure resources can be instantiated multiple times within an account and without conflict.

**NOTE:** The `null` refers to the primary Terraform [provider](https://www.terraform.io/docs/providers/null/index.html) used in this module.


## Usage

### Simple Example

```hcl
module "eg_prod_bastion_label" {
  source     = "git::https://github.com/Merlz/tf-modules/terraform-null-label.git?ref=master"
  namespace  = "eg"
  stage      = "prod"
  name       = "bastion"
  attributes = ["public"]
  delimiter  = "-"
  tags       = "${map("BusinessUnit", "XYZ", "Snapshot", "true")}"
}
```

This will create an `id` with the value of `eg-prod-bastion-public`.

Now reference the label when creating an instance:

```hcl
resource "aws_instance" "eg_prod_bastion_public" {
  instance_type = "t1.micro"
  tags          = "${module.eg_prod_bastion_label.tags}"
}
```

Or define a security group:

```hcl
resource "aws_security_group" "eg_prod_bastion_public" {
  vpc_id = "${var.vpc_id}"
  name   = "${module.eg_prod_bastion_label.id}"
  tags   = "${module.eg_prod_bastion_label.tags}"
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
```


### Advanced Example

Here is a more complex example with two instances using two different labels. Note how efficiently the tags are defined for both the instance and the security group.

```hcl
module "eg_prod_bastion_abc_label" {
  source     = "git::https://github.com/Merlz/tf-modules/terraform-null-label.git?ref=master"
  namespace  = "eg"
  stage      = "prod"
  name       = "bastion"
  attributes = ["abc"]
  delimiter  = "-"
  tags       = "${map("BusinessUnit", "ABC")}"
}

resource "aws_security_group" "eg_prod_bastion_abc" {
  name = "${module.eg_prod_bastion_abc_label.id}"
  tags = "${module.eg_prod_bastion_abc_label.tags}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "eg_prod_bastion_abc" {
   instance_type          = "t1.micro"
   tags                   = "${module.eg_prod_bastion_abc_label.tags}"
   vpc_security_group_ids = ["${aws_security_group.eg_prod_bastion_abc.id}"]
}

module "eg_prod_bastion_xyz_label" {
  source     = "git::https://github.com/Merlz/tf-modules/terraform-null-label.git?ref=master"
  namespace  = "eg"
  stage      = "prod"
  name       = "bastion"
  attributes = ["xyz"]
  delimiter  = "-"
  tags       = "${map("BusinessUnit", "XYZ")}"
}

resource "aws_security_group" "eg_prod_bastion_xyz" {
  name = "${module.eg_prod_bastion_xyz_label.id}"
  tags = "${module.eg_prod_bastion_xyz_label.tags}"
  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_instance" "eg_prod_bastion_xyz" {
   instance_type          = "t1.micro"
   tags                   = "${module.eg_prod_bastion_xyz_label.tags}"
   vpc_security_group_ids = ["${aws_security_group.eg_prod_bastion_xyz.id}"]
}
```

### Advanced Example 2

Here is a more complex example with an autoscaling group that has a different tagging schema than other resources and requires its tags to be in this format, which this module can generate:

```hcl
tags = [
    {
        key = Name,
        propagate_at_launch = 1,
        value = namespace-stage-name
    },
    {
        key = Namespace,
        propagate_at_launch = 1,
        value = namespace
    },
    {
        key = Stage,
        propagate_at_launch = 1,
        value = stage
    }
]
```

Autoscaling group using propagating tagging below (full example: [autoscalinggroup](examples/autoscalinggroup/main.tf))

```hcl
################################
# terraform-null-label example #
################################
module "label" {
  source    = "../../"
  namespace = "Ex"
  stage     = "prod"
  name      = "app"

  tags = {
    BusinessUnit = "Finance"
    ManagedBy    = "Terraform"
  }

  additional_tag_map = {
    propagate_at_launch = "true"
  }
}

#######################
# Launch template     #
#######################
resource "aws_launch_template" "default" {
  # terraform-null-label example used here: Set template name prefix
  name_prefix                           = "${module.label.id}-"
  image_id                              = "${data.aws_ami.amazon_linux.id}"
  instance_type                         = "t2.micro"
  instance_initiated_shutdown_behavior  = "terminate"

  vpc_security_group_ids                = ["${data.aws_security_group.default.id}"]

  monitoring {
    enabled                             = false
  }
  # terraform-null-label example used here: Set tags on volumes
  tag_specifications {
    resource_type                       = "volume"
    tags                                = "${module.label.tags}"
  }
}

######################
# Autoscaling group  #
######################
resource "aws_autoscaling_group" "default" {
  # terraform-null-label example used here: Set ASG name prefix
  name_prefix                           = "${module.label.id}-"
  vpc_zone_identifier                   = ["${data.aws_subnet_ids.all.ids}"]
  max_size                              = "1"
  min_size                              = "1"
  desired_capacity                      = "1"

  launch_template = {
    id                                  = "${aws_launch_template.default.id}"
    version                             = "$$Latest"
  }
  
  # terraform-null-label example used here: Set tags on ASG and EC2 Servers
  tags                                  = ["${module.label.tags_as_list_of_maps}"]
}
```

## Input

|  Name |  Default  |  Description  |
|:------|:---------:|:--------------:|
| attributes |[] |Additional attributes (e.g. `policy` or `role`)|
| delimiter |"-" |Delimiter to be used between `name`, `namespace`, `stage`, etc.|
| enabled |"true" |Set to false to prevent the module from creating any resources|
| name |__REQUIRED__ |Solution name, e.g. 'app' or 'jenkins'|
| namespace |__REQUIRED__ |Namespace, which could be your organization name, e.g. 'Ex' or 'Example'|
| stage |__REQUIRED__ |Stage, e.g. 'prod', 'staging', 'dev', or 'test'|
| tags |{} |Additional tags (e.g. `map('BusinessUnit`,`XYZ`)|
| additional_tag_map | {} | additional tags that get appended to each map in the list of maps, for the output `tags_as_list_of_maps` |

**WARNING** Any tags passed as an input to this module will *override* the tags generated by this module.


## Output

|  Name | Description  |
|:------|:------------:|
| attributes | Normalized attributes  |
| id | Disambiguated ID  |
| name | Normalized name  |
| namespace | Normalized namespace  |
| stage | Normalized stage  |
| tags | Normalized Tag map   |
| tags_as_list_of_maps | Additional tags as a list of maps, which can be used in several AWS resources |