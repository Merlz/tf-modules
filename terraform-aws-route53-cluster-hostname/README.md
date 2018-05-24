## terraform-aws-route53-cluster-hostname


Terraform module to define a consistent AWS Route53 hostname

## Input

<!--------------------------------REQUIRE POSTPROCESSING-------------------------------->
|  Name |  Default  |  Description  |
|:------|:---------:|:--------------:|
| enabled |"true" |Set to false to prevent the module from creating any resources|
| name |"dns" ||
| namespace |"global" ||
| records |__REQUIRED__ ||
| stage |"default" ||
| ttl |"300" ||
| type |"CNAME" ||
| zone_id |__REQUIRED__ ||

## Output

<!--------------------------------REQUIRE POSTPROCESSING-------------------------------->
|  Name | Description  |
|:------|:------------:|
| hostname |   |
