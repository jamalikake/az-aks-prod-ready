# az-aks-prod-ready

Production-ready Azure Kubernetes Service (AKS), deployed with modular Terraform across `dev`, `uat` and `prod` environments.

## Architecture

- **Private AKS cluster** — no public API server endpoint, reachable via a bring-your-own Private DNS Zone.
- **Azure CNI Overlay** networking with the Azure network policy engine, Standard Load Balancer.
- **Azure AD + Azure RBAC** for cluster auth (`local_account_disabled = true` — no static admin kubeconfig).
- **Workload Identity / OIDC issuer** enabled for pod-level Azure AD auth (no more AAD Pod Identity / secrets in pods).
- **System/user node pool split** — the default pool is tainted `CriticalAddonsOnly` and only runs system pods; application workloads run on a separate autoscaling user pool.
- **Azure Container Registry** — no admin credentials; AKS pulls images via its kubelet managed identity + `AcrPull` role assignment.
- **Key Vault** — RBAC-authorization mode (no legacy access policies).
- **Log Analytics + Container Insights** for cluster/workload observability.
- **Azure Policy add-on** enabled for governance.
- Automatic upgrade channel (`stable`) for the control plane + `NodeImage` channel for node OS security patching.

```
az-aks-prod-ready/
├── bootstrap/     # one-time: creates the Storage Account used for remote Terraform state
├── modules/       # reusable modules (no environment awareness)
│   ├── resource-group/
│   ├── network/       # VNet, subnets, NSGs, AKS private DNS zone
│   ├── identity/       # user-assigned identity + role assignments (Network Contributor, Private DNS Zone Contributor)
│   ├── log-analytics/
│   ├── acr/
│   ├── key-vault/
│   └── aks/             # cluster + node pools
├── dev/           # parent config for dev - calls the modules above
├── uat/           # parent config for uat
└── prod/          # parent config for prod
```

Each environment folder (`dev/`, `uat/`, `prod/`) is a self-contained Terraform root module: its `main.tf` is the "parent file" that wires the shared modules together, and `terraform.tfvars` holds the environment-specific sizing/config. The modules themselves are environment-agnostic.

## Prerequisites

- Terraform >= 1.7
- Azure CLI, logged in (`az login`) with rights to create resources in the target subscription
- An Azure AD group for cluster-admin access (object ID goes into `admin_group_object_ids` in each environment's `terraform.tfvars`)

## 1. Bootstrap remote state (one-time)

```bash
cd bootstrap
cp terraform.tfvars.example terraform.tfvars   # set a globally-unique storage_account_name
terraform init
terraform apply
```

This creates the resource group + Storage Account + blob container that hold every environment's state file. State for `bootstrap/` itself stays local (`bootstrap/terraform.tfstate`) — treat it as a secret, it is not committed.

## 2. Deploy an environment

```bash
cd dev   # or uat / prod
cp backend.hcl.example backend.hcl   # fill in the storage account details from step 1
terraform init -backend-config=backend.hcl
terraform plan
terraform apply
```

Repeat for `uat/` and `prod/` — each has its own state file (`dev.tfstate`, `uat.tfstate`, `prod.tfstate`) in the same storage account.

## 3. Get cluster credentials

Access is via Azure AD (no static admin kubeconfig, since `local_account_disabled = true`):

```bash
az aks get-credentials --resource-group <rg> --name <cluster-name> --overwrite-existing
kubelogin convert-kubeconfig -l azurecli
```

The exact command is also printed as the `get_credentials_command` output after `terraform apply`. Since the cluster is private, run this (and `kubectl`) from a network with connectivity to the cluster's private endpoint (VPN/ExpressRoute/jumpbox/self-hosted CI agent in the VNet).

## CI/CD (GitHub Actions)

`.github/workflows/terraform-deploy.yml` is the entry point. It figures out which environment(s) actually changed and only plans/applies those:

- A push/PR touching only `dev/**` deploys `dev`. A change under `modules/**` (shared by all three) deploys `dev`, `uat` **and** `prod`, since all three consume that code.
- On a pull request, only `terraform plan` runs (per changed environment) and the plan is posted as a PR comment for review — nothing is applied.
- On push to `main`, plan runs and then, if successful, apply runs automatically.
- `workflow_dispatch` lets you force a plan+apply of one specific environment regardless of what changed (e.g. to reconcile drift).

The actual per-environment logic lives in the reusable workflow `.github/workflows/terraform-plan-apply.yml`, called once per changed environment:

1. **Plan job** — `terraform init` (backend config passed via `-backend-config`, not committed), `terraform validate`, `terraform plan -out=tfplan`, then the `tfplan` file plus a `tfplan.timestamp` file are uploaded as a single artifact (`tfplan-<environment>`).
2. **Apply job** — downloads that same artifact and applies the *exact* plan that was reviewed (`terraform apply tfplan`), not a freshly-generated one. Before applying, it checks `tfplan.timestamp`: **if the plan is more than 15 minutes old, the job fails instead of applying it** — the underlying Azure state may have drifted since the plan was calculated, so a stale plan is refused rather than blindly applied. Re-run the workflow to get a fresh plan.

### One-time GitHub setup

1. **Azure OIDC federated credentials** — create an Entra ID App Registration (or use one per environment for tighter blast-radius isolation) with a federated credential per environment, subject format:
   ```
   repo:<org>/<repo>:environment:dev
   repo:<org>/<repo>:environment:uat
   repo:<org>/<repo>:environment:prod
   ```
   Grant it the Azure RBAC roles it needs on the subscription/resource groups (Contributor + User Access Administrator, or a scoped custom role, is typical for this kind of pipeline). No client secret is used — auth is via GitHub's OIDC token.

2. **GitHub Environments** — create `dev`, `uat`, `prod` under repo Settings → Environments. Add required reviewers on `prod` (and optionally `uat`) so applies to it need manual approval — this is what actually gates production deploys, not anything in the workflow YAML. On each environment, set:
   - **Secrets**: `AZURE_CLIENT_ID`, `AZURE_TENANT_ID`, `AZURE_SUBSCRIPTION_ID`
   - **Variables**: `TF_STATE_RESOURCE_GROUP`, `TF_STATE_STORAGE_ACCOUNT`, `TF_STATE_CONTAINER` (the values from the `bootstrap/` step)

## Notes / follow-up hardening

- `key-vault` module does not provision a private endpoint — `key_vault_public_network_access_enabled` must stay `true` unless you extend the module with one (mirroring the pattern already used in `modules/acr`).
- `admin_group_object_ids` is empty by default in every `terraform.tfvars` — set it before applying, or nobody will have Azure RBAC cluster-admin.
- Storage account names and ACR/Key Vault names must be globally unique — adjust the naming in `terraform.tfvars` / `bootstrap/terraform.tfvars` if you hit a collision.
- GitHub Environment secrets aren't available to `pull_request` runs triggered from a fork by default — plan-only runs from external fork PRs will fail at the Azure login step unless you change that trust setting deliberately.
