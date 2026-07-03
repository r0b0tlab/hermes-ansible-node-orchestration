# Host variables

Use `host_vars/` for per-node overrides when group defaults are not enough.

Example local-only file:

```yaml
# host_vars/worker01.yml
---
gb10_role: worker
gb10_default_model_root: /mnt/models
gb10_default_results_root: /mnt/results
ansible_user: gb10
ansible_ssh_private_key_file: ~/.ssh/id_ed25519
```

For public repositories, avoid committing real hostnames, IPs, paths that reveal private topology, passwords, tokens, or private keys.

For secrets, use Ansible Vault or an external secret manager. If a variable must be vaulted, put it in a `vault.yml` file; `**/vault.yml` is gitignored by default.
