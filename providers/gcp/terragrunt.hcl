# Initialize remote state. 
# Please note that it is assumed you are authenticated with GCP
remote_state {
    backend = "gcs"
    generate = {
        path = "backend.tf"
        if_exists = "overwrite"
    }
    config = {
        project = get_env("PROJECT")
        location = get_env("LOCATION")
        bucket = get_env("STATE_BUCKET_NAME")
        prefix = "terragrunt/state"
        
        gcs_bucket_labels = {
            name = "state_storage"
            managed = "terragrunt"
        }
    }
}

# Generate the basic provider and versions files. Assumed to be overwritten if needed by modules.
generate "provider" {
    path = "provider.tf"
    if_exists = "overwrite_terragrunt"
    contents = <<EOF
provider "google" {
    project = "${get_env("PROJECT")}"
    region  = "us-east1"
    zone    = "us-east1-c"
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
generate "outputs" {
    path = "outputs.tf"
    if_exists = "skip"
    contents = ""
}
