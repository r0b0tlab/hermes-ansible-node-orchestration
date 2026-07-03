# Hermes Ansible Node Orchestration for GB10 Clusters

A planned open-source starter repository for GB10 / DGX Spark cluster operators who want Hermes Agent to operate their cluster through Ansible safely, reproducibly, and with enough structure for local customization.

> Repository status: runnable Ansible skeleton. The example inventory, health playbook, guarded provision baseline, model artifact sync, Docker image deploy, guarded vLLM serving, controlled container stop, tmux-backed benchmark launcher/monitoring, evidence collection, lint/syntax validation, and placeholder future network/discovery playbooks validate locally. Full guarded network implementation remains planned in `docs/plans/IMPLEMENTATION_PLAN.md`.

## Goal

Build a reusable Hermes-ready Ansible operations repository that lets an operator point Hermes Agent at the repo and say things like:

- "discover my GB10 nodes and build the inventory"
- "health-check the cluster"
- "provision node3 for Docker + NVIDIA Container Toolkit"
- "deploy this vLLM image to node2"
- "start a model server on node2 and a benchmark on node3"
- "collect logs and produce a reproducibility bundle"

The repository should be general enough for different GB10 owners, but opinionated enough that Hermes has a safe default workflow.

## Design principles

1. Source-of-truth inventory, not chat memory.
   - Cluster state lives in `inventories/`, `group_vars/`, `host_vars/`, and generated evidence files.
   - Hermes memory may remember where the repo is, but not transient node state.

2. Ansible-first operations.
   - Use `ansible-playbook`, roles, inventories, tags, check mode, and idempotent tasks.
   - Avoid one-off SSH command drift unless the command is wrapped into a playbook after validation.

3. Agent-readable from the first turn.
   - `AGENTS.md` tells Hermes exactly how to inspect, customize, dry-run, execute, and verify.
   - The bundled skill in `skills/hermes-gb10-cluster-orchestration/SKILL.md` gives portable procedure memory.

4. Safety before speed.
   - Every destructive or disruptive operation has a preflight, target limit, dry-run/check path when possible, and explicit evidence capture.
   - Never auto-apply network changes that can strand a node without a rollback strategy.

5. General defaults, local overrides.
   - Example inventories and variables are templates, not hardcoded assumptions.
   - Operators copy `inventories/examples/` into their own environment directory and adjust names/IPs/paths.

6. Evidence-based completion.
   - A task is not "done" until the relevant playbook returns successfully and health/log/output artifacts prove the result.

## Why Hermes + Ansible

Hermes provides the agent loop, project context loading (`AGENTS.md`), terminal/file tools, skills, scheduled jobs, and session recall. Ansible provides deterministic orchestration, inventory targeting, role reuse, variable overrides, check mode, and clean auditability.

The intended workflow is:

```text
operator request
  -> Hermes reads AGENTS.md + skill
  -> Hermes inspects inventory and current node state
  -> Hermes chooses the smallest relevant playbook
  -> Ansible performs idempotent operations
  -> Hermes verifies with health checks and evidence files
  -> operator receives a concise status report
```

## Repository layout target

```text
hermes-ansibel-node-orchestration/
├── README.md
├── AGENTS.md
├── LICENSE
├── ansible.cfg                       # planned
├── requirements.yml                  # planned Ansible collection deps
├── inventories/
│   ├── examples/
│   │   └── three-node-gb10.yml       # planned example inventory
│   └── README.md                     # planned inventory customization guide
├── group_vars/
│   ├── all.yml                       # planned safe global defaults
│   └── gb10.yml                      # planned GB10 defaults
├── host_vars/
│   └── README.md                     # planned per-host override guide
├── playbooks/
│   ├── health.yml                    # planned
│   ├── discover.yml                  # planned
│   ├── provision-node.yml            # planned
│   ├── configure-network.yml         # planned guarded network tasks
│   ├── deploy-docker-image.yml       # planned
│   ├── sync-model.yml                # planned
│   ├── serve-model.yml               # planned
│   ├── stop-services.yml             # planned
│   ├── benchmark.yml                 # planned
│   └── collect-evidence.yml          # planned
├── roles/
│   ├── gb10_health/                  # planned role
│   ├── gb10_base/                    # planned role
│   ├── nvidia_container_runtime/     # planned role
│   ├── model_artifacts/              # planned role
│   ├── vllm_service/                 # planned role
│   ├── benchmark_runner/             # planned role
│   └── evidence_bundle/              # planned role
├── skills/
│   └── hermes-gb10-cluster-orchestration/
│       └── SKILL.md                  # draft portable skill
├── docs/
│   ├── plans/IMPLEMENTATION_PLAN.md
│   └── reference/DOC_SOURCES.md
└── scripts/
    ├── bootstrap.sh                  # planned local setup helper
    ├── validate-inventory.sh         # planned lint and connectivity helper
    └── collect-summary.py            # planned result summarizer
```

The current repository contains the plan and draft agent-facing documents. The implementation plan defines the task-by-task path to fill in the planned files.

## Operator quick start after implementation

Expected post-implementation flow:

```bash
# 1. Clone and enter the repo
git clone https://github.com/<owner>/hermes-ansibel-node-orchestration.git
cd hermes-ansibel-node-orchestration

# 2. Install Python/Ansible dependencies
python3 -m venv .venv
source .venv/bin/activate
pip install -U pip ansible-core ansible-lint yamllint
ansible-galaxy collection install -r requirements.yml

# 3. Copy and customize inventory
cp inventories/examples/three-node-gb10.yml inventories/my-cluster.yml
$EDITOR inventories/my-cluster.yml

# 4. Validate connectivity and inventory
ansible-inventory -i inventories/my-cluster.yml --graph
ansible all -i inventories/my-cluster.yml -m ansible.builtin.ping

# 5. Ask Hermes to operate from the repo
hermes chat --toolsets terminal,file,skills,session_search
```

Then tell Hermes:

```text
Use this repo to health-check my GB10 cluster. Inventory is inventories/my-cluster.yml.
Do not change network settings or stop containers; report only.
```

## Hermes installation options for the skill

This repo is intended to support three user patterns:

1. Point Hermes at the repo.
   - Run Hermes from the repository root so `AGENTS.md` is loaded automatically.

2. Install only the skill.
   - Copy or install `skills/hermes-gb10-cluster-orchestration/SKILL.md` into `~/.hermes/skills/devops/`.

3. Future profile distribution.
   - Package a full GB10 cluster-operator Hermes profile using `distribution.yaml`, skills, and safe tool defaults.

## Source docs used for this plan

See `docs/reference/DOC_SOURCES.md`.

Key upstream guidance reflected here:

- Hermes skills are markdown files with YAML frontmatter, progressive disclosure, optional `references/`, `templates/`, and `scripts/` directories.
- Hermes auto-loads root `AGENTS.md` as project context and discovers subdirectory context lazily.
- Hermes tools can run terminal commands, manage files, search sessions, delegate tasks, and schedule cron jobs.
- Ansible inventories define hosts/groups/variables and can be static, dynamic, or multi-source.
- Ansible roles provide reusable task/handler/default/template/file structure.
- Ansible best practices emphasize simplicity, version control, named tasks, explicit states, FQCN modules, separate inventories, vaulted secrets, and check/syntax validation.

## MIT license

The repository is intended for MIT release. `LICENSE` is included now so the future GitHub upload has an explicit license from the first commit.
