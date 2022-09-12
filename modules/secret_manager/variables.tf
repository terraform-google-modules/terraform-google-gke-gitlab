variable "project" {
  description = "Project containing the secret."
}

variable "region" {
  description = "Restrict secret to this region"
  type        = string
}

variable "secret_id" {
  description = "GCP Secret name"
  type        = string
}

variable "secret_value" {
  description = "Payload for Secret"
  type        = string
  default     = ""
}

variable "secret_labels" {
  description = "(Optional) The labels assigned to this Secret. Label keys must be between 1 and 63 characters long, have a UTF-8 encoding of maximum 128 bytes"
  type        = map(string)
  default     = {}
}

variable "secret_expire_time" {
  description = "(Optional) Timestamp in UTC when the Secret is scheduled to expire."
  type        = string
  default     = ""
}

variable "k8s_namespace" {
  description = "Namespace for the K8s Opaque secret to be deployed"
  type        = string
}

variable "k8s_secret_name" {
  description = "Name of the K8s Opaque secret to be deployed"
  type        = string
}

variable "k8s_secret_key" {
  description = "Secret Key to be paired to the secret value"
  type        = string
}

variable "k8s_create_secret" {
  description = "Enable k8s secret creation"
  type        = bool
  default     = true
}

