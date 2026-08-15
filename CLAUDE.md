# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## What this repo is

Modular Terraform for a production-ready Azure Kubernetes Service (AKS) deployment, with separate `dev`, `uat`, `prod` environment roots that all call the same shared modules. `modules/` is environment-agnostic; each environment folder's `main.tf` is the "parent file" that wires modules together, and `terraform.tfvars` holds the environment-specific sizing/config — that's the only lever that should differ between environments. `bootstrap/` is a separate, one-off config (local state) that creates the Storage Account used for everyone else's remote state.

## Commands

```bash
# Format + validate everything (no Azure credentials needed for validate)
terraform fmt -recursive
cd <bootstrap|dev|uat|prod> && terraform init -backend=false -input=false && terraform validate

# One-time: create the remote state storage account
cd bootstrap
cp terraform.tfvars.example terraform.tfvars   # set a globally-unique storage_account_name
terraform init && terraform apply

# Per environment
cd dev   # or uat / prod
cp backend.hcl.example backend.hcl             # fill in storage account details from bootstrap
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

There is no single top-level `terraform` invocation — every root module (`bootstrap/`, `dev/`, `uat/`, `prod/`) is initialized and applied independently, each with its own state file (`dev.tfstate`, `uat.tfstate`, `prod.tfstate` in the same storage account/container).

Get AKS cluster credentials (no static admin kubeconfig exists — `local_account_disabled = true`):
```bash
az aks get-credentials --resource-group <rg> --name <cluster-name> --overwrite-existing
kubelogin convert-kubeconfig -l azurecli
```
This command is also emitted as the `get_credentials_command` output of each environment.

## Architecture

**Module dependency chain** (see any environment's `main.tf`): `resource_group` → `network` → `log_analytics` / `identity` / `key_vault` / `acr` → `aks`. Two cross-module wirings live at the parent level rather than inside a module, because they need outputs that don't exist until another module has already applied:
- `module.identity` takes `network.vnet_id` and `network.aks_private_dns_zone_id` as inputs, so it can grant the AKS control-plane identity **Network Contributor** on the VNet and **Private DNS Zone Contributor** on the BYO private DNS zone (both required for a private cluster with a custom VNet). `module.aks` has an explicit `depends_on = [module.identity]` because nothing else forces Terraform to wait for those role assignments before creating the cluster.
- The `azurerm_role_assignment.aks_acr_pull` resource (granting the cluster's auto-provisioned **kubelet identity** `AcrPull` on the registry) lives directly in each environment's `main.tf`, not inside `modules/acr` or `modules/aks`, because the kubelet identity only exists as an output of the already-created AKS cluster.

**Networking model:** private AKS cluster (no public API server), Azure CNI Overlay (`network_plugin_mode = "overlay"`, needs its own non-overlapping `pod_cidr` distinct from the VNet/service CIDRs), Azure network policy, Standard LB. `modules/network` creates one NSG per subnet with a deny-internet-inbound baseline, plus the `privatelink.<region>.azmk8s.io` private DNS zone and VNet link for the cluster.

**Auth model:** Azure AD + Azure RBAC only (`azure_active_directory_role_based_access_control` block with `azure_rbac_enabled = true`, `local_account_disabled = true`). `admin_group_object_ids` is empty by default in every `terraform.tfvars` — must be set to an Azure AD group object ID before applying, or nobody gets cluster-admin. `modules/aks` deliberately has no `kube_config`/`kube_config_raw` output since it would be unreliable/empty with local accounts disabled.

**Node pools:** the default (system) pool is always tainted `CriticalAddonsOnly` (`only_critical_addons_enabled = true`) so system pods don't share capacity with workloads. Application workloads run on `azurerm_kubernetes_cluster_node_pool` resources defined via the `user_node_pools` map variable in `modules/aks/node_pool.tf` (`for_each`) — add a pool by adding a map entry in `terraform.tfvars`, not by writing new HCL.

**ACR / Key Vault security asymmetry (intentional, documented in README):** `modules/acr` supports a full private-endpoint + private DNS zone path (`private_endpoint_subnet_id`/`vnet_id` vars), used in `prod/terraform.tfvars`. `modules/key-vault` does **not** have private endpoint support — its `public_network_access_enabled` must stay `true` in every environment or the vault becomes unreachable (including from Terraform itself). Don't set it to `false` without first adding a private endpoint to that module, mirroring the ACR pattern.

**Provider version:** pinned to `~> 4.0` (azurerm) everywhere. This template already required fixing two v3→v4 renames the hard way (via `terraform validate` against the real provider schema, not docs): the AKS auto-upgrade attribute is `automatic_upgrade_channel` (not `automatic_channel_upgrade`), and node pool availability zones use `zones` (not `availability_zones`). If validation fails on an "Unsupported argument" error, check `terraform providers schema -json` against the actual installed provider version rather than assuming the older/well-known attribute name is still correct.

## Adding a new module

Follow the existing module shape: `main.tf`, `variables.tf`, `outputs.tf`, `versions.tf` (each pins `required_providers` independently since modules don't inherit the root's provider requirements). Wire it into all three of `dev/main.tf`, `uat/main.tf`, `prod/main.tf` — there's no shared "environment" module, so the three parent files are kept structurally identical by convention and only diverge in `terraform.tfvars` values.

## CI/CD (GitHub Actions)

`.github/workflows/terraform-deploy.yml` (orchestrator) + `.github/workflows/terraform-plan-apply.yml` (reusable, called once per environment). Full setup instructions (OIDC federated credentials, GitHub Environments/secrets/vars) are in the README's "CI/CD" section — this is the mechanical summary:

- **Change detection**: `dorny/paths-filter` diffs `dev/**`, `uat/**`, `prod/**`, `modules/**` against each filter (each filter also watches `modules/**`, so a shared-module change targets all three environments, not just one). `workflow_dispatch` bypasses detection and targets exactly the chosen environment. The result is a JSON array (`["dev","prod"]`-style) consumed via `fromJSON(...)` + `contains()` to gate each environment's job.
- **Plan/apply split, same plan file**: the plan job runs `terraform plan -out=tfplan`, stamps a `tfplan.timestamp` file, and uploads both as one artifact (`tfplan-<environment>`). The apply job downloads that exact artifact and runs `terraform apply tfplan` — it never re-plans. Before applying, it diffs `tfplan.timestamp` against the current time and **fails outright if the plan is older than `PLAN_MAX_AGE_SECONDS` (900s / 15 min)**, since state may have drifted since the plan was computed. Both values live in the reusable workflow's top-level `env:` block if they ever need to change.
- **PR vs push behavior**: `pull_request` events set `apply: false` on the reusable workflow call (plan-only, posted as a PR comment) — `push`/`workflow_dispatch` set `apply: true`.
- **Auth**: Azure OIDC only, no client secret — `ARM_USE_OIDC: true` plus `ARM_CLIENT_ID`/`ARM_TENANT_ID`/`ARM_SUBSCRIPTION_ID` from GitHub Environment secrets. Requires `permissions: id-token: write` (already set) and a matching federated credential per environment in Entra ID.
- **Prod approval gate**: not expressed in the YAML at all — it comes entirely from required reviewers configured on the `prod` GitHub Environment (Settings → Environments), which GitHub enforces automatically on any job with `environment: prod`.
- **Provider lock files**: `dev/.terraform.lock.hcl`, `uat/.terraform.lock.hcl`, `prod/.terraform.lock.hcl` are committed (unlike the transient `.terraform/` directory) and include checksums for both `darwin_arm64` (local dev) and `linux_amd64` (GitHub-hosted runners) — generated via `terraform providers lock -platform=linux_amd64 -platform=darwin_arm64`. Re-run that in each environment folder after bumping the `azurerm` version constraint, otherwise CI's `terraform init` will fail with a missing-checksum error for `linux_amd64`.
