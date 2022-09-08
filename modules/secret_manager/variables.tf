variable "project" {
  description = "Project containing the secret."
}

variable "region" {
  description = "Restrict secret to this region"
  type        = string
}

variable "secret_id" {
  description = "Secret name"
  type        = string
}

variable "secret_data" {
  description = "Payload for secret"
  type        = string
}

variable "labels" {
  description = "(Optional) The labels assigned to this Secret. Label keys must be between 1 and 63 characters long, have a UTF-8 encoding of maximum 128 bytes"
  type        = map(string)
  default     = {}
}

variable "expire_time" {
  description = "(Optional) Timestamp in UTC when the Secret is scheduled to expire."
  type        = string
  default     = ""
}

