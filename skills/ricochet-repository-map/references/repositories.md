# Ricochet repository ownership

Use this index to locate likely ownership, then verify it against current repository content.

## Product repositories

| Repository | Primary responsibility |
| --- | --- |
| `ricochet-rs/ricochet` | Rust server monorepo, including API, authentication, core domain, database, encryption, licensing, proxy, and UI crates |
| `ricochet-rs/cli` | Rust command-line client and the `ricochet` binary |
| `ricochet-rs/helm` | Helm chart for deploying the Ricochet server |
| `ricochet-rs/docs` | Product documentation site |
| `ricochet-rs/exec-envs` | R execution-environment container images |
| `ricochet-rs/ansible` | Ansible collection and server installation role |
| `ricochet-rs/homebrew-tap` | Homebrew formula for the CLI |
| `ricochet-rs/test-apps` | Content used for smoke and deployment tests |
| `ricochet-rs/ricochet-dev` | Development-container support |

## Infrastructure and SaaS repositories

These repositories are hosted under the private `ricochet` organization on Codefloe.

| Repository | Primary responsibility |
| --- | --- |
| `kubernetes-cluster` | Cluster infrastructure, platform services, and Argo CD applications |
| `infrastructure` | VM infrastructure, DNS, firewall, HAProxy, and deployment playbooks |
| `proxmox` | Proxmox and Ceph host configuration |
| `web` | Marketing website |
| `saas-portal` | Managed-SaaS portal, control-plane operator, and API contracts |
| `helm-portal` | Helm chart for the SaaS platform layer |
| `aditus` | Self-hostable licensing dashboard |

## Dependency chains

### Product deployment

`ricochet-rs/ricochet` builds the server image.
`ricochet-rs/helm` defines the server deployment.
`kubernetes-cluster` selects chart and image versions and deploys them through Argo CD.

### Execution environments

`ricochet-rs/exec-envs` builds language execution images.
`ricochet-rs/helm` exposes the corresponding image configuration.
`kubernetes-cluster` selects deployed image values.

### SaaS portal

`saas-portal` builds the portal and control-plane images.
`helm-portal` packages the platform deployment.
`kubernetes-cluster` deploys the chart and supplies environment-specific configuration.

### Licensing

The licensing crate in `ricochet-rs/ricochet` implements product-side licensing behavior.
`aditus` provides the licensing administration interface.
`kubernetes-cluster` owns the deployed licensing-service configuration.

### VM-hosted sites and services

`web`, `ricochet-rs/docs`, and `ricochet-rs/ricochet` produce artifacts consumed by deployment playbooks in `infrastructure`.

## Verification points

Check Cargo workspace membership for Rust ownership.
Check container build definitions and registry references for image ownership.
Check `Chart.yaml`, chart values, and templates for packaging ownership.
Check Argo CD applications and environment values for cluster deployment ownership.
Check Ansible playbooks and OpenTofu roots for VM and infrastructure ownership.
