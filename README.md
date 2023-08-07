# OpenNext Terraform Module for AWS

This is a Terraform module for deploying a Next.js application built with [OpenNext](https://open-next.js.org/).

## Table of Contents

- [OpenNext Terraform Module for AWS](#opennext-terraform-module-for-aws)
  - [Table of Contents](#table-of-contents)
  - [Example](#example)
  - [Installation](#installation)
    - [Prerequisites](#prerequisites)
  - [Usage](#usage)
  - [Architecture](#architecture)
    - [Diagrams](#diagrams)
    - [Configuration](#configuration)
  - [Contributing](#contributing)
  - [Contacts](#contacts)
  - [Licence](#licence)

## Example

The example app in `example/` is deployed using the latest version of this Terraform module to [terraform-aws-opennext.tools.engineering.england.nhs.uk](https://terraform-aws-opennext.tools.engineering.england.nhs.uk/).

## Installation

Copy and paste the following into your Terraform configuration, edit the variables, and then run `terraform init`.

```tf
module "opennext" {
  source  = "nhs-england-tools/opennext/aws"
  version = "1.0.0" # Use the latest release from https://github.com/nhs-england-tools/terraform-aws-opennext/releases

  prefix              = "opennext"                          # Prefix for all created resources
  opennext_build_path = "../.open-next"                     # Path to your .open-next folder
  hosted_zone_id      = data.aws_route53_zone.zone.zone_id  # The Route53 hosted zone ID for your domain name

  cloudfront = {
    aliases             = [local.domain_name]                                             # Your domain name
    acm_certificate_arn = aws_acm_certificate_validation.ssl_certificate.certificate_arn  # The ACM (SSL) certificate for your domain
  }
}
```

### Prerequisites

The following software packages or their equivalents are expected to be installed

- [Terraform](https://developer.hashicorp.com/terraform/downloads) (>=1.5)

## Usage

<!-- TODO: Add docs for Lambda@Edge -->

After a successful installation, provide an informative example of how this project can be used. Additional code snippets, screenshots and demos work well in this space. You may also link to the other documentation resources, e.g. the [User Guide](./docs/user-guide.md) to demonstrate more use cases and to show more features.

## Architecture

### Diagrams

The [C4 model](https://c4model.com/) is a simple and intuitive way to create software architecture diagrams that are clear, consistent, scalable and most importantly collaborative. This should result in documenting all the system interfaces, external dependencies and integration points.

### Configuration

Most of the projects are built with customisability and extendability in mind. At a minimum, this can be achieved by implementing service level configuration options and settings. The intention of this section is to show how this can be used. If the system processes data, you could mention here for example how the input is prepared for testing - anonymised, synthetic or live data.

## Contributing

Describe or link templates on how to raise an issue, feature request or make a contribution to the codebase. Reference the other documentation files, like

- Environment setup for contribution, i.e. `CONTRIBUTING.md`
- Coding standards, branching, linting, practices for development and testing
- Release process, versioning, changelog
- Backlog, board, roadmap, ways of working
- High-level requirements, guiding principles, decision records, etc.

## Contacts

- Thomas Judd-Cooper - [Email](mailto:thomas.judd-cooper1@nhs.net) - [GitHub](https://github.com/Tomdango)

## Licence

Unless stated otherwise, the codebase is released under the MIT License. This covers both the codebase and any sample code in the documentation.

Any HTML or Markdown documentation is [© Crown Copyright](https://www.nationalarchives.gov.uk/information-management/re-using-public-sector-information/uk-government-licensing-framework/crown-copyright/) and available under the terms of the [Open Government Licence v3.0](https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/).
