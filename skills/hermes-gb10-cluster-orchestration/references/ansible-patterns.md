# Ansible Patterns

Use YAML inventories, explicit groups, named plays/tasks, FQCN modules, role defaults, and separate operator-local overrides.

Required preflight:

```bash
ansible-inventory -i <inventory> --graph
ansible-playbook -i <inventory> playbooks/<play>.yml --syntax-check
```

Mutating operations should require `--limit/-l` and expose an explicit override variable for deliberate broad runs.
