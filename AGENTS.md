# AGENTS.md — Hermes GB10 Ansible Node Orchestration

This repository is a planned Hermes + Ansible operations kit for GB10 / DGX Spark cluster operators.

When you are a Hermes Agent working in this repo, your job is to turn operator intent into safe, auditable Ansible operations. Do not improvise raw SSH changes when an Ansible playbook or role should exist.

## Primary rule

Use Ansible as the execution layer and this repository as the source of truth. Use Hermes tools to inspect, edit, run, and verify, but preserve idempotent playbooks and reproducible evidence.

## Current status

This repo is currently a runnable Ansible skeleton. The example inventory, conservative group vars, `gb10_health`, `gb10_base`, `nvidia_container_runtime`, `model_artifacts`, `vllm_service`, `benchmark_runner`, and `evidence_bundle` roles are present. `playbooks/health.yml`, guarded `playbooks/provision-node.yml`, guarded `playbooks/sync-model.yml`, guarded `playbooks/deploy-docker-image.yml`, guarded `playbooks/serve-model.yml`, controlled `playbooks/stop-services.yml`, tmux-backed `playbooks/benchmark.yml`, and `playbooks/collect-evidence.yml` are implemented. Network and discovery playbooks currently exist as safe placeholders pending full implementation in:

- `docs/plans/IMPLEMENTATION_PLAN.md`

The draft portable Hermes skill is:

- `skills/hermes-gb10-cluster-orchestration/SKILL.md`

If the user asks to implement the repo, follow the implementation plan task by task. If the user asks to operate a real cluster before implementation is complete, first explain which playbooks are not yet present and offer a minimal safe read-only health-check path.

## Required behavior for cluster operations

Before any operation that touches nodes:

1. Identify the inventory file.
   - Default only after checking: `inventories/my-cluster.yml` if present, otherwise ask or use an explicit user-provided path.
   - Never assume the example inventory is the live inventory.

2. Parse inventory and target scope.
   - Use `ansible-inventory -i <inventory> --graph`.
   - Determine the target group or host with `--limit` / `-l`.
   - If the task is destructive or disruptive, require explicit target scope.

3. Run read-only preflight first.
   - Connectivity: `ansible all -i <inventory> -m ansible.builtin.ping` with an appropriate limit.
   - Health playbook once implemented: `ansible-playbook -i <inventory> playbooks/health.yml -l <target>`.
   - Capture current Docker containers, GPU state, disk, memory, uptime, and tmux sessions.

4. Prefer check mode where meaningful.
   - Use `--check --diff` for configuration changes that support it.
   - Do not pretend check mode validates shell commands, Docker runtime launches, or benchmark quality.

5. Execute the smallest relevant playbook.
   - Use tags for narrow operations.
   - Use `--limit <host-or-group>`.
   - Use explicit variables only when the repo defaults are insufficient.

6. Verify with evidence.
   - Re-run health checks.
   - Check service endpoints (`/health`, `/v1/models`) when serving models.
   - Check tmux/process state for long-running benchmarks.
   - Collect logs and write evidence paths in the final report.

7. Report status, not vibes.
   - Include exact target, command, changed/ok/failed summary, artifact paths, and any caveats.

## Hard safety constraints

- Do not run `netplan apply` on GB10 nodes unless the user explicitly requests it and a rollback path is prepared. Prefer temporary `ip link set` tests and persistent systemd/network scripts with evidence.
- Do not reboot, power off, stop Docker, kill containers, overwrite model directories, or change MTU without explicit user approval and a target limit.
- Do not assume NVFP4 KV cache is safe on SM120/SM121. Default to FP8 KV unless a future validated implementation supersedes this.
- Do not use fallback/emulation paths when the operator asks for native optimized paths.
- Do not commit secrets, `.env`, Ansible vault plaintext, HF tokens, GitHub tokens, SSH keys, benchmark raw traces with secrets, or local host-only paths intended to be private.
- Do not report a benchmark as final until result files, logs, and sample counts are validated.

## Preferred command patterns

Inventory inspection:

```bash
ansible-inventory -i inventories/my-cluster.yml --graph
ansible-inventory -i inventories/my-cluster.yml --host <host>
```

Connectivity:

```bash
ansible all -i inventories/my-cluster.yml -m ansible.builtin.ping
ansible gb10 -i inventories/my-cluster.yml -m ansible.builtin.setup -a 'filter=ansible_distribution*'
```

Syntax and lint:

```bash
ansible-playbook -i inventories/my-cluster.yml playbooks/health.yml --syntax-check
ansible-lint playbooks/ roles/
yamllint .
```

Execution:

```bash
ansible-playbook -i inventories/my-cluster.yml playbooks/health.yml -l gb10
ansible-playbook -i inventories/my-cluster.yml playbooks/provision-node.yml -l node3 --check --diff
ansible-playbook -i inventories/my-cluster.yml playbooks/provision-node.yml -l node3
```

Evidence collection:

```bash
ansible-playbook -i inventories/my-cluster.yml playbooks/collect-evidence.yml -l gb10 \
  -e evidence_run_id="$(date -u +%Y%m%dT%H%M%SZ)"
```

## File and design conventions

- Use YAML inventories for examples; they are easier for agents to parse than INI.
- Use `ansible.builtin.*` FQCNs for built-in modules.
- Name every play, task, and block.
- Explicitly set module `state` when a module supports it.
- Keep variables override-friendly: defaults in `roles/*/defaults/main.yml`, cluster defaults in `group_vars/`, secrets via Vault or external env.
- Avoid putting site-specific values in roles.
- Keep model definitions in `group_vars/gb10_models.yml` or similar, not hardcoded inside playbooks.
- Make operations idempotent. A second run should be safe.
- Preserve operator-customizable namespaces: `inventories/local/`, `group_vars/local/`, or `local/` should be gitignored.

## Hermes-specific guidance

- Load the bundled skill if available: `hermes-gb10-cluster-orchestration`.
- For complex edits, maintain a todo list and mark steps completed only after verification.
- Use tools rather than describing future action.
- Use `terminal(background=true, notify_on_complete=true)` for long-running bounded local commands, but for remote benchmark persistence prefer tmux launched by Ansible playbooks.
- When using cron monitoring later, make cron jobs read-only unless the operator explicitly asks for autonomous remediation.
- If using `delegate_task`, treat subagent reports as unverified until files/commands are checked directly.

## Expected final report format

```text
Status: <complete|running|blocked|failed>
Inventory: <path>
Target: <group/host>
Operation: <playbook/tag/command>
Result: ok=<n> changed=<n> failed=<n> unreachable=<n>
Evidence:
- <path or command output summary>
Health:
- <per-node concise status>
Caveats:
- <anything not validated or intentionally skipped>
Next recommended step:
- <single next step>
```

## If the user asks for GitHub publishing

The user intends MIT license publication. Before pushing:

1. Verify no secrets or private local data:
   - `git status --short`
   - `git diff --cached`
   - search for tokens, IPs if public release should not include private topology, and large files.
2. Keep example inventories generic.
3. Ensure README, AGENTS.md, LICENSE, implementation plan, and skill are present.
4. Push only after the user confirms the target owner/repo.
