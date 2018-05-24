## terraform-aws-cicd

Terraform module to create AWS [`CodePipeline`](https://aws.amazon.com/codepipeline/) with [`CodeBuild`](https://aws.amazon.com/codebuild/) for [`CI/CD`](https://en.wikipedia.org/wiki/CI/CD)

This module supports three use-cases:

1. **GitHub -> S3 (build artifact) -> Elastic Beanstalk (running application stack)**.
The module gets the code from a ``GitHub`` repository (public or private), builds it by executing the ``buildspec.yml`` file from the repository, pushes the built artifact to an S3 bucket,
and deploys the artifact to ``Elastic Beanstalk`` running one of the supported stacks (_e.g._ ``Java``, ``Go``, ``Node``, ``IIS``, ``Python``, ``Ruby``, etc.).
    - http://docs.aws.amazon.com/codebuild/latest/userguide/sample-maven-5m.html
    - http://docs.aws.amazon.com/codebuild/latest/userguide/sample-nodejs-hw.html
    - http://docs.aws.amazon.com/codebuild/latest/userguide/sample-go-hw.html


2. **GitHub -> ECR (Docker image) -> Elastic Beanstalk (running Docker stack)**.
The module gets the code from a ``GitHub`` repository, builds a ``Docker`` image from it by executing the ``buildspec.yml`` and ``Dockerfile`` files from the repository,
pushes the ``Docker`` image to an ``ECR`` repository, and deploys the ``Docker`` image to ``Elastic Beanstalk`` running ``Docker`` stack.
    - http://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html


3. **GitHub -> ECR (Docker image)**.
The module gets the code from a ``GitHub`` repository, builds a ``Docker`` image from it by executing the ``buildspec.yml`` and ``Dockerfile`` files from the repository,
and pushes the ``Docker`` image to an ``ECR`` repository. This is used when we want to build a ``Docker`` image from the code and push it to ``ECR`` without deploying to ``Elastic Beanstalk``.
To activate this mode, don't specify the ``app`` and ``env`` attributes for the module.
    - http://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html


## Usage

Include this repository as a module in your existing terraform code:

```hcl
module "build" {
    source              = "git::https://github.com/merlz/tf-modules/terraform-aws-cicd.git?ref=master"
    namespace           = "global"
    name                = "app"
    stage               = "staging"

    # Enable the pipeline creation
    enabled             = "true"

    # Elastic Beanstalk
    app                 = "<(Optional) Elastic Beanstalk application name>"
    env                 = "<(Optional) Elastic Beanstalk environment name>"

    # Application repository on GitHub
    github_oauth_token  = "(Optional) <GitHub Oauth Token with permissions to access private repositories>"
    repo_owner          = "<GitHub Organization or Person name>"
    repo_name           = "<GitHub repository name of the application to be built and deployed to Elastic Beanstalk>"
    branch              = "<Branch of the GitHub repository>"

    # http://docs.aws.amazon.com/codebuild/latest/userguide/build-env-ref.html
    # http://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html
    build_image         = "aws/codebuild/docker:17.09.0"
    build_compute_type  = "BUILD_GENERAL1_SMALL"

    # These attributes are optional, used as ENV variables when building Docker images and pushing them to ECR
    # For more info:
    # http://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html
    # https://www.terraform.io/docs/providers/aws/r/codebuild_project.html
    privileged_mode     = "true"
    aws_region          = "us-east-1"
    aws_account_id      = "xxxxxxxxxx"
    image_repo_name     = "ecr-repo-name"
    image_tag           = "latest"
}
```


### Example: GitHub, NodeJS, S3 and EB

This is an example to build a Node app, store the build artifact to an S3 bucket, and then deploy it to Elastic Beanstalk running ``Node`` stack


``buildspec.yml`` file

```yaml
version: 0.2

phases:
  install:
    commands:
      - echo Starting installation ...
  pre_build:
    commands:
      - echo Installing NPM dependencies...
      - npm install
  build:
    commands:
      - echo Build started on `date`
  post_build:
    commands:
      - echo Build completed on `date`
artifacts:
  files:
    - node_modules/**/*
    - public/**/*
    - routes/**/*
    - views/**/*
    - app.js
```


### Example: GitHub, NodeJS, Docker, ECR and EB

This is an example to build a ``Docker`` image for a Node app, push the ``Docker`` image to an ECR repository, and then deploy it to Elastic Beanstalk running ``Docker`` stack


``buildspec.yml`` file


```yaml
version: 0.2

phases:
  pre_build:
    commands:
      - echo Logging in to Amazon ECR...
      - $(aws ecr get-login --region $AWS_REGION)
  build:
    commands:
      - echo Build started on `date`
      - echo Building the Docker image...
      - docker build -t $IMAGE_REPO_NAME .
      - docker tag $IMAGE_REPO_NAME:$IMAGE_TAG $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
  post_build:
    commands:
      - echo Build completed on `date`
      - echo Pushing the Docker image to ECR...
      - docker push $AWS_ACCOUNT_ID.dkr.ecr.$AWS_REGION.amazonaws.com/$IMAGE_REPO_NAME:$IMAGE_TAG
artifacts:
  files:
    - '**/*'
```

``Dockefile``

```dockerfile
FROM node:latest

WORKDIR /usr/src/app

COPY package.json package-lock.json ./
RUN npm install
COPY . .

EXPOSE 8081
CMD [ "npm", "start" ]

```

## Input

|  Name  |  Default  |  Description  |
|--------|-----------|---------------|
| app | "" | Elastic Beanstalk application name. If not provided or set to empty string, the ``Deploy`` stage of the pipeline will not be created |
| attributes | [] | Additional attributes (e.g. `policy` or `role`) |
| aws_account_id | "" | AWS Account ID. Used as CodeBuild ENV variable when building Docker images. [For more info](http://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html) |
| aws_region | "" | AWS Region, e.g. us-east-1. Used as CodeBuild ENV variable when building Docker images. [For more info](http://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html) |
| branch | __REQUIRED__ | Branch of the GitHub repository, _e.g._ ``master`` |
| build_compute_type | "BUILD_GENERAL1_SMALL" | `CodeBuild` instance size.  Possible values are: ```BUILD_GENERAL1_SMALL``` ```BUILD_GENERAL1_MEDIUM``` ```BUILD_GENERAL1_LARGE``` |
| build_image | "aws/codebuild/docker:17.09.0" | Docker image for build environment, _e.g._ `aws/codebuild/docker:17.09.0` or `aws/codebuild/eb-nodejs-6.10.0-amazonlinux-64:4.0.0` |
| buildspec | "" | Declaration to use for building the project. [For more info](http://docs.aws.amazon.com/codebuild/latest/userguide/build-spec-ref.html) |
| delimiter | "-" | Delimiter to be used between `name`, `namespace`, `stage`, etc. |
| enabled | "true" | Enable ``CodePipeline`` creation |
| env | "" | Elastic Beanstalk environment name. If not provided or set to empty string, the ``Deploy`` stage of the pipeline will not be created |
| github_oauth_token | __REQUIRED__ | GitHub Oauth Token with permissions to access private repositories |
| image_repo_name | "UNSET" | ECR repository name to store the Docker image built by this module. Used as CodeBuild ENV variable when building Docker images. [For more info](http://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html) |
| image_tag | "latest" | Docker image tag in the ECR repository, e.g. 'latest'. Used as CodeBuild ENV variable when building Docker images. [For more info](http://docs.aws.amazon.com/codebuild/latest/userguide/sample-docker.html) |
| name | "app" | Solution name, e.g. 'app' or 'jenkins' |
| namespace | "global" | Namespace, which could be your organization name, e.g. 'ExM' or 'Exodus' |
| poll_source_changes | "true" | Periodically check the location of your source content and run the pipeline if changes are detected |
| privileged_mode | "false" | If set to true, enables running the Docker daemon inside a Docker container on the CodeBuild instance. Used when building Docker images |
| repo_name | __REQUIRED__ | GitHub repository name of the application to be built (and deployed to Elastic Beanstalk if configured) |
| repo_owner | __REQUIRED__ | GitHub Organization or Person name |
| stage | "default" | Stage, e.g. 'prod', 'staging', 'dev', or 'test' |
| tags | {} | Additional tags (e.g. `map('BusinessUnit', 'XYZ')` |

## Output
None