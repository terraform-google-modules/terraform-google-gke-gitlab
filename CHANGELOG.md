# Change Log

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](http://keepachangelog.com/) and this
project adheres to [Semantic Versioning](http://semver.org/).

## [1.0.0](https://github.com/terraform-google-modules/terraform-google-gke-gitlab/compare/v0.5.2...v1.0.0) (2022-04-21)


### ⚠ BREAKING CHANGES

* Update min provider to TPG ~> 3.44, CI fixes (#91)

### Features

* update to allow TPG version 4.0 and TF v0.13+ format ([#86](https://github.com/terraform-google-modules/terraform-google-gke-gitlab/issues/86)) ([42550a8](https://github.com/terraform-google-modules/terraform-google-gke-gitlab/commit/42550a804eff1d14f0e51b43312031080e7a9926))


### Bug Fixes

* Update min provider to TPG ~> 3.44, CI fixes ([#91](https://github.com/terraform-google-modules/terraform-google-gke-gitlab/issues/91)) ([1971baa](https://github.com/terraform-google-modules/terraform-google-gke-gitlab/commit/1971baaf005070bf971e2b401293ec15f11b466f))

### [0.5.2](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/compare/v0.5.1...v0.5.2) (2021-04-23)


### Bug Fixes

* update project services to 10.x ([#79](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/issues/79)) ([0900ee8](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/commit/0900ee8faf89a5091bcdc59ede2f6774d370001e))

### [0.5.1](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/compare/v0.5.0...v0.5.1) (2021-04-05)


### Bug Fixes

* Allow cleanup of buckets even if there are objects in them ([#72](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/issues/72)) ([cad73dd](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/commit/cad73ddda1e69504ac51fa757cd1bc95621c0645))

## [0.5.0](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/compare/v0.4.0...v0.5.0) (2021-03-22)


### ⚠ BREAKING CHANGES

* add Terraform 0.13 constraint and module attribution (#73)

### Features

* add Terraform 0.13 constraint and module attribution ([#73](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/issues/73)) ([14b9e72](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/commit/14b9e7212f36a8a96e8c76108343364f0914df56))


### Bug Fixes

* Dependency fixes for the Kubernetes resources ([#65](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/issues/65)) ([802759d](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/commit/802759d8cbac136b62ba027c3542c04991a84851))
* Update so we don't rebuild the domain used for output.gitlab_url ([#62](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/issues/62)) ([5248208](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/commit/52482084dc445525d48fbd737764822a9d69b172))
* Updating the project services and gke module versions. ([#61](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/issues/61)) ([5e2f645](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/commit/5e2f64573419dd31bf246c9fb90ff7f33d194a8e))
* Upgrade minimum Google provider version to 3.39.0 ([#64](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/issues/64)) ([1ed4fd4](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/commit/1ed4fd49075978dbb97683b7e534defcc2200956))

## [0.4.0](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/compare/v0.3.1...v0.4.0) (2020-08-28)


### Features

* Broaden oauth scope to cloud-platform ([#56](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/issues/56)) ([6eea966](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/commit/6eea966f4ea4d5de2b5570f908ec756361ef8bcd))

### [0.3.1](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/compare/v0.3.0...v0.3.1) (2020-08-13)


### Bug Fixes

* Fixed typo in values.yaml.tpl which prevented cache from working on GCS. ([#52](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/issues/52)) ([ba4d0df](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/commit/ba4d0df929627c75d76d7da1ad33f165b7d1a8a9))
* Update to enable working with v4.2.4 of GitLab Helm Chart ([#55](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/issues/55)) ([8dfded6](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/commit/8dfded6d6c9fd507740ce3968614f46fa10e4454))

## [0.3.0](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/compare/v0.2.0...v0.3.0) (2020-07-16)


### Features

* Expose the K8s cluster info as outputs ([#50](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/issues/50)) ([1ea4e88](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/commit/1ea4e882d13b800ca213b89a27a134efc28d4afe))

## [0.2.0](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/compare/v0.1.1...v0.2.0) (2020-06-27)


### Features

* Optionally add random prefix to csql db instance ([#47](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/issues/47)) ([8edb48c](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/commit/8edb48ce868f0ca9374213aae767a363f03474a7))


### Bug Fixes

* Switch to helm3 and add tests ([#46](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/issues/46)) ([6f4b9f7](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/commit/6f4b9f745c3f5a51e018b47d1ade7f9d32c36630))
* terraform fmt, and fixing tf 0.12 warnings ([#42](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/issues/42)) ([c3dd306](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/commit/c3dd306bb46ed92cfac24be0ad7e680ae769f6dd))

### [0.1.1](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/compare/v0.1.0...v0.1.1) (2020-05-20)


### Bug Fixes

* Switch to using module for service activation and ensure ordering. ([ef2a316](https://www.github.com/terraform-google-modules/terraform-google-gke-gitlab/commit/ef2a3166a2746e6544c3c33f5aba7a19d5034765))

## [v0.1.0](https://github.com/terraform-google-modules/terraform-google-gke-gitlab/releases/tag/v0.1.0) - 2020-05-15
This is the initial module release.
