# WSL Work Tools

The `wsl` stow package provides tooling for a work WSL environment.

## Scripts (`wsl/bin/`)

### AWS
| Script | Description |
|--------|-------------|
| `asg-describe` | Describe Auto Scaling Groups |
| `asg-set-desired` | Set ASG desired capacity |
| `capacity_check` | Check cluster capacity |
| `get-aws-secrets` | Retrieve AWS secrets |
| `get-kubeconfig-aws` | Generate AWS kubeconfig |
| `list-ecr` | List ECR repositories |

### GCP
| Script | Description |
|--------|-------------|
| `check-gatewai-iam.sh` | Check Gateway IAM permissions |
| `check-nodepools` | Inspect GKE node pools |
| `gar-inspect` | Inspect Google Artifact Registry |
| `get-kubeconfig` | Generate GCP kubeconfig |
| `get-kubeconfig-gum` | Interactive kubeconfig generation with gum |
| `pre_check_gar` | Pre-flight GAR checks |

### Kubernetes
| Script | Description |
|--------|-------------|
| `check_taints` | Check node taints |
| `verify-ds` | Verify DaemonSets |

### Infrastructure
| Script | Description |
|--------|-------------|
| `stack_list` | List infrastructure stacks |
| `stack_plan_unit` | Plan individual stack units |
| `get-reference` | Get reference configs |
| `switch` | Switch between environments |

### WSL Utilities
| Script | Description |
|--------|-------------|
| `wsl-monitor` | Monitor WSL disk space with Windows notifications |
| `wsl-cleanup` | Clean up WSL disk space |
| `wsl-inspect` | Inspect WSL environment |
| `check_stow` | Show stow deployment status |
| `jira-task` | Create/manage Jira tasks from CLI |

## Toolchain (`wsl/.config/mise/config.toml`)

Managed via [mise](https://mise.jdx.dev/):

- awscli, fzf, jq, gum, rg, delta
- node, tree-sitter
- terramate, kcl, krew, trivy
- opencode, chezmoi

## Systemd Timer

`wsl-monitor.service` / `wsl-monitor.timer` — periodic WSL disk space monitoring that sends Windows toast notifications when space is low.
