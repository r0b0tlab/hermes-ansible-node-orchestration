# Customization Guide

This repository is designed to be copied and adapted by GB10 / DGX Spark operators without editing the reusable roles directly.

## Inventory

Start by copying the example inventory into a private/local path:

```bash
cp inventories/examples/three-node-gb10.yml inventories/local/my-cluster.yml
```

`inventories/local/` is gitignored. Put private hostnames, IPs, SSH users, and key paths there.

Validate the shape before running any playbook:

```bash
ansible-inventory -i inventories/local/my-cluster.yml --graph
ansible all -i inventories/local/my-cluster.yml -m ansible.builtin.ping
```

## Variables

Global defaults live in `group_vars/all.yml` and GB10 defaults live in `group_vars/gb10.yml`.

Override safely in one of these places:

1. A local inventory vars block.
2. `inventories/local/group_vars/` if using inventory directories.
3. `host_vars/<host>.yml` for per-node differences.
4. `-e key=value` for one-off commands.

Do not edit role task files for site-specific paths or credentials.

## Model registry

Model definitions live in `group_vars/gb10_models.yml`.

A model entry may include:

```yaml
gb10_models:
  my-model:
    local_path: /models/my-model
    served_model_name: my-model
    container_name: gb10-my-model
    port: 8000
    image: vllm/vllm-openai:latest
    kv_cache_dtype: fp8
    max_model_len: 4096
    tensor_parallel_size: 1
    extra_env:
      MAX_JOBS: "6"
      FLASHINFER_NVCC_THREADS: "2"
      NVCC_THREADS: "2"
```

Keep private or license-gated paths out of public commits.

## Secrets

Never commit:

- `.env`
- vault password files
- SSH keys
- API tokens
- Hugging Face tokens
- registry credentials

Use Ansible Vault or an external secret manager. Files named `vault.yml` are ignored by default.

## Safe local namespaces

The following are intended for operator-private data and are gitignored:

- `local/`
- `inventories/local/`
- `evidence/`
- `results/`
- `logs/`
- `.env`
