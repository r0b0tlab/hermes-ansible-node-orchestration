# Inventories

Inventories define the GB10 nodes Ansible can manage. Do not edit the example inventory directly for production use; copy it into a local or site-specific path and customize there.

Recommended workflow:

```bash
cp inventories/examples/three-node-gb10.yml inventories/local/my-cluster.yml
$EDITOR inventories/local/my-cluster.yml
ansible-inventory -i inventories/local/my-cluster.yml --graph
ansible all -i inventories/local/my-cluster.yml -m ansible.builtin.ping
```

`inventories/local/` is gitignored so operators can keep private hostnames, IPs, SSH users, and key paths out of public commits.

## Inventory pattern

Use YAML inventories. They are explicit, structured, and easy for agents to parse.

- `gb10`: all GB10 nodes.
- `gb10_heads`: coordinator/head nodes.
- `gb10_workers`: worker nodes.
- `gb10_role`: node role metadata used by playbooks and reports.

Use host aliases such as `head01` and put the actual address in `ansible_host`.

## Multiple environments

Keep separate inventories for lab/staging/production:

```text
inventories/local/lab.yml
inventories/local/staging.yml
inventories/local/prod.yml
```

Never point a destructive operation at an inventory or group until you have inspected it with `ansible-inventory --graph`.

## Secrets

Do not put plaintext passwords, tokens, or private keys in inventory files. Use Ansible Vault, SSH agent forwarding, or external secret managers.
