# Simple Example

This example illustrates how to use the `gke-gitlab` module.

[^]: (autogen_docs_start)

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|:----:|:-----:|:-----:|
| certmanager\_email | Email used to retrieve SSL certificates from Let's Encrypt | string | n/a | yes |
| project\_id | The project ID to deploy to | string | n/a | yes |

## Outputs

| Name | Description |
|------|-------------|
| gitlab\_url |  |
| project\_id |  |

[^]: (autogen_docs_end)

To provision this example, run the following from within this directory:
- `terraform init` to get the plugins
- `terraform plan` to see the infrastructure plan
- `terraform apply` to apply the infrastructure build
- `terraform destroy` to destroy the built infrastructure
