terraform {
  required_version = ">= 0.13.0"
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 4.35"
    }
    google-beta = {
      source  = "hashicorp/google-beta"
      version = "~> 4.35"
    }
     kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.10"
    }
 }
}