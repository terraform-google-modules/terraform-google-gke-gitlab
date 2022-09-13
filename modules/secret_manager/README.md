# Secret Manager SubModule

Secret Manager is a secure and convenient storage system for API keys, passwords, certificates, and other sensitive data.
This module is capable of creating a GCP secret or retrieving data from it. It creates a Kubernetes Opaque secret with same payload, if necessary.
The actual secret payload can only:
   - Retrievied from an existent GCP secret
   - Randomly generated

It's not possible to pass the secret value as an argument in plain text.

In detail: 
 - If the  **secret_id** variable has got a string value, secret payload will be retrieved from secret_id GCP entry and a K8S secret will be created, if necessary.
 - If the **secret_id** is an empty string , a new GCP secret with a random name will be created and filled with random data.

## Usage

```hcl
module "gcp_secret" {
  source           = "./modules/secret_manager"
  project          = my-awesom-project
  region           = europe-west1
  secret_id        = "GCP-SECRET"
  k8s_namespace    = my-k8s-namespace
  k8s_secret_name  = "my-k8s-secret-name"
  k8s_secret_key   = "password"
}
```

 <!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| k8s\_create\_secret | Enable k8s secret creation | `bool` | `true` | no |
| k8s\_namespace | Namespace for the K8s Opaque secret to be deployed | `string` | n/a | yes |
| k8s\_secret\_key | Secret Key to be paired to the secret value | `string` | n/a | yes |
| k8s\_secret\_name | Name of the K8s Opaque secret to be deployed | `string` | n/a | yes |
| project | Project containing the secret. | `any` | n/a | yes |
| region | Restrict secret to this region | `string` | n/a | yes |
| secret\_expire\_time | (Optional) Timestamp in UTC when the Secret is scheduled to expire. | `string` | `""` | no |
| secret\_id | GCP Secret name | `string` | n/a | yes |
| secret\_labels | (Optional) The labels assigned to this Secret. Label keys must be between 1 and 63 characters long, have a UTF-8 encoding of maximum 128 bytes | `map(string)` | `{}` | no |

## Outputs

| Name | Description |
|------|-------------|
| project | Project containing secret |
| region | Region containing secret |
| secret | Secret resource |
| secret\_id | Id of secret |
| secret\_value | Secret Payload |

 <!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
