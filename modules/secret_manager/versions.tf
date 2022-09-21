terraform {
  required_version = ">= 0.13.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.37.0"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.37.0"
    }
     kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.10"
    }
 }
}
