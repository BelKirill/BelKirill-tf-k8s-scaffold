# Initialize remote state.
# Please note that it is assumed you are authenticated with GCP
remote_state {
	backend = "gcs"
	generate = {
		path = "backend.tf"
		if_exists = "overwrite"
	}
	config = {
		project = get_env("TF_VAR_project")
		location = get_env("TF_VAR_location")
		bucket = get_env("STATE_BUCKET_NAME")
		prefix = "terragrunt/state/${path_relative_to_include()}"

		gcs_bucket_labels = {
			name = "state_storage"
			managed = "terragrunt"
		}
	}
}

# Generate the basic provider and versions files. Assumed to be overwritten if needed by modules.
generate "providers" {
	path = "providers.tf"
	if_exists = "overwrite_terragrunt"
	contents = <<EOF
provider "google" {
  project = "${get_env("TF_VAR_project")}"
  region  = "${get_env("TF_VAR_region")}"
  zone    = "${get_env("TF_VAR_zone")}"
}
EOF
}

generate "versions" {
	path = "versions.tf"
	if_exists = "overwrite_terragrunt"
	contents = <<EOF
terraform {
  required_providers {
		google = {
		  version = "~> 4.63.1"
		}
  }

  required_version = "~> 1.4.6"
}
EOF
}

# Generate the scaffolding required by tflint
generate "main" {
	path = "main.tf"
	if_exists = "skip"
	contents = ""
}

generate "variables" {
	path = "variables.tf"
	if_exists = "skip"
	contents = <<EOF
variable "labels" {
	description = "Basic set of labels to be used on any and all supporting resources"
	type        = map(string)
	default     = {
		managed   = "terragrunt"
		ephemeral = "true"
	}
}
# variable "project" {
# 	description = "GCP project"
# 	type        = string
# 	default     = ""
# }

# variable "location" {
# 	description = "GCP project"
# 	type        = string
# 	default     = "US"
# }

# variable "region" {
# 	description = "GCP project"
# 	type        = string
# 	default     = "us-east1"
# }

# variable "zone" {
# 	description = "GCP project"
# 	type        = string
# 	default     = "us-east1-c"
# }
EOF
}

generate "outputs" {
	path = "outputs.tf"
	if_exists = "skip"
	contents = ""
}
