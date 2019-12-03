
terraform {
  required_version = ">= 0.12"
  required_providers {
    external    = "~> 1.2.0"
    google      = "~> 2.18.0"
    google-beta = "~> 2.18.0"
    helm        = "~> 0.10"
    kubernetes  = "~> 1.10.0"
    template    = "~> 2.1"
    null        = "~> 2.1"                                                                                                               
    random      = "~> 2.2"   
  }
}
