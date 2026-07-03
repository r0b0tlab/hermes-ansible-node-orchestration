# Operations Guide

All commands below are examples. Replace `<inventory>` and `<target>` with your live inventory and explicit host/group limit.

## Preflight

```bash
ansible-inventory -i <inventory> --graph
ansible all -i <inventory> -m ansible.builtin.ping
ansible-playbook -i <inventory> playbooks/health.yml -l <target>
```

## Provision a node

Check mode first:

```bash
ansible-playbook -i <inventory> playbooks/provision-node.yml -l <target> --check --diff
```

Apply only after reviewing the check output:

```bash
ansible-playbook -i <inventory> playbooks/provision-node.yml -l <target>
```

## Sync a model

Using the model registry:

```bash
ansible-playbook -i <inventory> playbooks/sync-model.yml -l <target> -e model_key=<model-key>
```

Using explicit paths:

```bash
ansible-playbook -i <inventory> playbooks/sync-model.yml -l <target>   -e model_source_path=/local/path/to/model   -e model_destination_path=/models/model-name
```

## Deploy Docker image

Registry pull:

```bash
ansible-playbook -i <inventory> playbooks/deploy-docker-image.yml -l <target>   -e image_name=ghcr.io/example/vllm-gb10:latest
```

Tar load:

```bash
ansible-playbook -i <inventory> playbooks/deploy-docker-image.yml -l <target>   -e image_tar=/local/path/image.tar   -e image_name=example/image:tag
```

## Serve a model

```bash
ansible-playbook -i <inventory> playbooks/serve-model.yml -l <target> -e model_key=<model-key>
```

Replacement is blocked by default. To intentionally replace an existing same-name container:

```bash
ansible-playbook -i <inventory> playbooks/serve-model.yml -l <target>   -e model_key=<model-key>   -e gb10_allow_container_replacement=true
```

## Stop a service

```bash
ansible-playbook -i <inventory> playbooks/stop-services.yml -l <target> -e model_key=<model-key>
```

or:

```bash
ansible-playbook -i <inventory> playbooks/stop-services.yml -l <target> -e container_name=<container>
```

Remove after stopping only when explicitly requested:

```bash
ansible-playbook -i <inventory> playbooks/stop-services.yml -l <target>   -e container_name=<container>   -e remove_container=true
```

## Collect evidence

```bash
ansible-playbook -i <inventory> playbooks/collect-evidence.yml -l <target>   -e evidence_bundle_run_id="$(date -u +%Y%m%dT%H%M%SZ)"
```

Evidence is written under `evidence/<run-id>/<host>/` on the controller.
