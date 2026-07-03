---
name: hermes-gb10-cluster-orchestration
description: Operate GB10 clusters safely with Hermes + Ansible.
version: 0.1.0
platforms: [linux]
metadata:
  hermes:
    tags: [gb10, dgx-spark, ansible, cluster, devops, mlops]
    category: devops
    requires_toolsets: [terminal, file]
---

# Hermes GB10 Cluster Orchestration

## When to Use

Use this skill when an operator asks Hermes to manage, inspect, provision, benchmark, or troubleshoot a GB10 / DGX Spark cluster through an Ansible repository.

Common requests:

- Discover cluster nodes and build or validate inventory.
- Run cluster health checks.
- Provision Docker, NVIDIA Container Toolkit, Python/venv dependencies, or benchmark harnesses.
- Deploy model artifacts or Docker images to nodes.
- Start/stop vLLM or other model-serving containers.
- Launch long-running benchmarks in tmux.
- Monitor benchmark progress.
- Collect logs, telemetry, and reproducibility evidence.

## Operating Contract

1. Treat the Ansible repo as source of truth.
2. Inspect inventory before targeting hosts.
3. Prefer playbooks and roles over raw SSH commands.
4. Use `--limit` for any operation narrower than the whole cluster.
5. Use `--check --diff` before configuration changes when meaningful.
6. Verify every side effect with health checks and evidence files.
7. Preserve local customization; do not overwrite operator inventory or secrets.

## First Steps in a New Repo

1. Read root `AGENTS.md`.
2. Find inventory files:

```bash
find inventories -maxdepth 3 -type f \( -name '*.yml' -o -name '*.yaml' -o -name '*.ini' \)
```

3. Ask for the live inventory only if not explicit and more than one candidate exists.
4. Inspect the inventory:

```bash
ansible-inventory -i <inventory> --graph
ansible-inventory -i <inventory> --list
```

5. Run connectivity preflight:

```bash
ansible all -i <inventory> -m ansible.builtin.ping
```

6. Run the health playbook if present:

```bash
ansible-playbook -i <inventory> playbooks/health.yml
```

## Standard Workflows

### Health Check

```bash
ansible-inventory -i <inventory> --graph
ansible all -i <inventory> -m ansible.builtin.ping
ansible-playbook -i <inventory> playbooks/health.yml -l <target>
```

Report:

- Node reachability.
- Hostnames/IPs.
- Uptime/load/memory/disk.
- GPU temperature/utilization/power.
- Docker status and running containers.
- tmux sessions.
- Open model endpoints.

### Provision a Node

Preflight:

```bash
ansible-playbook -i <inventory> playbooks/health.yml -l <node>
ansible-playbook -i <inventory> playbooks/provision-node.yml -l <node> --check --diff
```

Execute only after reviewing the check output:

```bash
ansible-playbook -i <inventory> playbooks/provision-node.yml -l <node>
```

Verify:

```bash
ansible-playbook -i <inventory> playbooks/health.yml -l <node>
```

### Deploy and Serve a Model

1. Confirm model definition in group vars.
2. Confirm model path exists on source and target capacity is sufficient.
3. Sync artifacts:

```bash
ansible-playbook -i <inventory> playbooks/sync-model.yml -l <node> -e model_key=<model_key>
```

4. Start server:

```bash
ansible-playbook -i <inventory> playbooks/serve-model.yml -l <node> -e model_key=<model_key>
```

5. Verify endpoint:

```bash
ansible-playbook -i <inventory> playbooks/health.yml -l <node> --tags model_endpoint
```

### Launch a Long Benchmark

Benchmarks should run remotely under tmux so they survive Hermes session resets.

```bash
ansible-playbook -i <inventory> playbooks/benchmark.yml -l <node> -e model_key=<model_key> -e benchmark=gsm8k
```

Monitor:

```bash
ssh <node> 'tmux ls'
ssh <node> 'tmux capture-pane -t <session> -p -S -80 | tail -80'
```

Collect only after completion:

```bash
ansible-playbook -i <inventory> playbooks/collect-evidence.yml -l <node> -e run_id=<run_id>
```

## GB10-Specific Defaults and Pitfalls

- Use native optimized paths when requested; do not silently fall back to emulation or non-native kernels.
- On SM120/SM121, default KV cache dtype to FP8 for vLLM unless a validated NVFP4 KV fix exists.
- Bound FlashInfer/NVCC parallelism during JIT, for example `MAX_JOBS=6`, `FLASHINFER_NVCC_THREADS=2`, and `NVCC_THREADS=2`, unless the operator has larger memory headroom.
- Do not use `netplan apply` casually. Network changes can strand a node. Prefer reversible live tests and staged persistent config with rollback.
- Treat Docker as a shared resource: list running containers before killing or replacing anything.
- Long-running benchmarks should preserve raw logs and samples before summarization.

## Ansible Quality Rules

- Use roles for reusable behavior.
- Use `ansible.builtin.*` FQCNs.
- Name every play, task, and block.
- Explicitly specify module `state` when supported.
- Keep secrets in Ansible Vault or external secret stores, not plaintext git files.
- Keep production/staging/lab inventories separate.
- Run syntax/lint checks before publishing changes:

```bash
ansible-playbook -i <inventory> playbooks/health.yml --syntax-check
ansible-lint playbooks/ roles/
yamllint .
```

## Final Report Template

```text
Status: <complete|running|blocked|failed>
Inventory: <path>
Target: <host/group>
Command(s):
- <exact command>
Result: ok=<n> changed=<n> failed=<n> unreachable=<n>
Evidence:
- <artifact path or log excerpt>
Node health:
- <host>: <summary>
Caveats:
- <not validated / skipped / operator action needed>
Next:
- <single recommended next step>
```
