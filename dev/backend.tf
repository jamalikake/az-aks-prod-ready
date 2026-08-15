# Partial backend configuration - the storage account (created by ../bootstrap)
# is supplied at `terraform init` time so no account details are hardcoded
# in version control. See backend.hcl.example.
#
#   terraform init -backend-config=backend.hcl
terraform {
  backend "azurerm" {
    key = "dev.tfstate"
  }
}
