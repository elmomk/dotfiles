-- DevOps tooling: Helm, Terraform, Terragrunt, Ansible, Kubernetes
-- Builds on LazyVim extras enabled in lazyvim.json:
--   lang.terraform, lang.helm, lang.ansible, lang.yaml, lang.docker
return {
  -- ── Terragrunt ──────────────────────────────────────────────────
  -- Attach terraform-ls to .hcl files so terragrunt configs get
  -- completions, go-to-definition, and diagnostics.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        terraformls = {
          filetypes = { "terraform", "terraform-vars", "hcl" },
        },
      },
    },
  },

  -- Replace packer_fmt (from terraform extra) with terragrunt hclfmt
  -- for .hcl files, since we use terragrunt not packer.
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        hcl = { "terragrunt_hclfmt" },
      },
      formatters = {
        terragrunt_hclfmt = {
          command = "terragrunt",
          args = { "hclfmt", "--terragrunt-hclfmt-file", "$FILENAME" },
          stdin = false,
        },
      },
    },
  },

  -- ── Kubernetes ──────────────────────────────────────────────────
  -- yamlls (from yaml extra) already loads SchemaStore schemas.
  -- Add explicit kubernetes schema mappings for common k8s paths
  -- so manifests get validation without needing modeline comments.
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        yamlls = {
          settings = {
            yaml = {
              schemas = {
                kubernetes = {
                  "k8s/**/*.{yaml,yml}",
                  "kubernetes/**/*.{yaml,yml}",
                  "manifests/**/*.{yaml,yml}",
                  "deploy/**/*.{yaml,yml}",
                  "base/**/*.{yaml,yml}",
                  "overlays/**/*.{yaml,yml}",
                },
              },
            },
          },
        },
      },
    },
  },
}
