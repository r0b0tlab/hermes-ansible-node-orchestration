# Hermes Ansible GB10 Node Orchestration Implementation Plan

> **For Hermes:** Use this plan to build the repository task-by-task. Keep the repo general-purpose for GB10 cluster operators, not hardcoded to one operator's cluster.

**Goal:** Create an MIT-licensed Hermes-ready Ansible operations repository that GB10 cluster operators can clone, customize, and point Hermes Agent at for safe cluster orchestration.

**Architecture:** The repo combines a human README, a root `AGENTS.md` for project-level Hermes behavior, a portable Hermes skill, and an Ansible project organized around inventories, roles, playbooks, variables, scripts, and evidence bundles. Hermes interprets operator intent and executes Ansible playbooks; Ansible owns cluster state changes.

**Tech Stack:** Hermes Agent, Ansible Core, YAML inventories, Ansible roles, Docker/NVIDIA Container Toolkit, tmux for durable remote jobs, optional vLLM/model-serving workflows.

---

## Non-goals for v1

- No hardcoded private topology.
- No automatic repo publishing before the user confirms GitHub owner/repo.
- No destructive remediation daemon.
- No model-specific benchmark claims.
- No assumption that every GB10 cluster has the same network, storage, or serving engine.

## Acceptance criteria

1. A fresh operator can read `README.md` and understand what the repo does, how to install dependencies, how to customize inventory, and how to invoke Hermes.
2. Hermes can read `AGENTS.md` and know the safe operating procedure without extra explanation.
3. The repo includes a portable skill under `skills/hermes-gb10-cluster-orchestration/SKILL.md` that users can install into Hermes.
4. The Ansible structure follows upstream best practices: inventories, roles, group vars, host vars, named tasks, explicit states, FQCNs, syntax/lint checks.
5. Example inventory and variables are generic and safe.
6. Health/provision/serve/benchmark/evidence flows are represented as playbooks and roles.
7. Every potentially disruptive workflow has preflight, target limiting, verification, and evidence capture.
8. MIT license and secret-safe `.gitignore` are present before first GitHub upload.

## Phase 0 — Keep the planning skeleton clean

### Task 0.1: Verify current skeleton

**Objective:** Confirm the repo has only planning-safe files and no accidental private data.

**Files:**
- Read: `README.md`
- Read: `AGENTS.md`
- Read: `docs/plans/IMPLEMENTATION_PLAN.md`
- Read: `skills/hermes-gb10-cluster-orchestration/SKILL.md`

**Commands:**

```bash
cd <repo-root>
find . -maxdepth 3 -type f | sort
grep -RInE 'HF_TOKEN|GITHUB_TOKEN|BEGIN OPENSSH|PRIVATE KEY|password:|api[_-]?key|token' . --exclude-dir=.git || true
grep -RInE '192\.168\.|10\.0\.0\.|node-[0-9]+\.internal|example-private-host' . --exclude-dir=.git || true
```

**Expected:** No secrets and no private topology in files intended for public release.

### Task 0.2: Decide whether to preserve the typo in repo name

**Objective:** The requested folder name is `hermes-ansibel-node-orchestration`, but the public repo should probably be `hermes-ansible-node-orchestration`.

**Recommendation:** Keep the local folder exactly as requested for now. Before GitHub creation, ask whether to publish with corrected `ansible` spelling.

## Phase 1 — Repository metadata and guardrails

### Task 1.1: Add `.gitignore`

**Objective:** Prevent secrets, local inventories, logs, evidence bundles, and runtime artifacts from entering git.

**Create:** `.gitignore`

**Content outline:**

```gitignore
# Python / virtualenv
.venv/
__pycache__/
*.pyc

# Ansible
*.retry
.vault_pass*
.vault-password*

# Secrets and local operator config
.env
.env.*
!.env.example
local/
inventories/local/
inventories/*local*.yml
group_vars/*/vault.yml
host_vars/*/vault.yml

# Runtime evidence / logs / benchmark outputs
evidence/
artifacts/
results/
logs/
*.log
*.jsonl
*.nsys-rep
*.sqlite

# Hermes runtime state if used as a profile distribution later
auth.json
state.db*
sessions/
memories/
cache/
```

**Verify:**

```bash
git check-ignore -v .env inventories/local/cluster.yml evidence/run.log || true
```

### Task 1.2: Add `ansible.cfg`

**Objective:** Make commands deterministic from the repo root without relying on global config.

**Create:** `ansible.cfg`

**Recommended settings:**

```ini
[defaults]
inventory = inventories/examples/three-node-gb10.yml
roles_path = roles
collections_path = .ansible/collections:~/.ansible/collections
stdout_callback = yaml
bin_ansible_callbacks = True
host_key_checking = True
retry_files_enabled = False
interpreter_python = auto_silent
forks = 10

[ssh_connection]
pipelining = True
ssh_args = -o ControlMaster=auto -o ControlPersist=60s
```

**Caveat:** The default inventory is an example only. `AGENTS.md` must still require identifying the live inventory.

### Task 1.3: Add `requirements.yml`

**Objective:** Declare Ansible collection dependencies.

**Create:** `requirements.yml`

**Initial collections:**

```yaml
---
collections:
  - name: community.docker
  - name: ansible.posix
  - name: community.general
```

**Verify:**

```bash
ansible-galaxy collection install -r requirements.yml --collections-path .ansible/collections
```

## Phase 2 — Generic inventory and variables

### Task 2.1: Add example inventory

**Objective:** Provide a generic three-node GB10 pattern without private hostnames/IPs.

**Create:** `inventories/examples/three-node-gb10.yml`

**Content outline:**

```yaml
---
all:
  children:
    gb10:
      children:
        gb10_heads:
          hosts:
            head01:
              ansible_host: 10.0.0.10
              gb10_role: head
        gb10_workers:
          hosts:
            worker01:
              ansible_host: 10.0.0.11
              gb10_role: worker
            worker02:
              ansible_host: 10.0.0.12
              gb10_role: worker
  vars:
    ansible_user: gb10
    ansible_ssh_private_key_file: ~/.ssh/id_ed25519
```

**Verify:**

```bash
ansible-inventory -i inventories/examples/three-node-gb10.yml --graph
```

### Task 2.2: Add inventory README

**Objective:** Teach users how to copy/customize inventories.

**Create:** `inventories/README.md`

Include:
- static inventory example
- multi-subnet notes
- host aliases vs `ansible_host`
- separate lab/staging/prod inventories
- dynamic inventory extension points
- how to run `ansible-inventory --graph`

### Task 2.3: Add group vars

**Objective:** Centralize safe default variables.

**Create:**
- `group_vars/all.yml`
- `group_vars/gb10.yml`
- `group_vars/gb10_models.yml`

**Key defaults:**

```yaml
gb10_operator_user: "{{ ansible_user }}"
gb10_docker_enabled: true
gb10_nvidia_container_toolkit_enabled: true
gb10_allow_network_changes: false
gb10_evidence_root: "{{ playbook_dir }}/../evidence"
gb10_tmux_prefix: gb10

gb10_flashinfer_max_jobs: 6
gb10_flashinfer_nvcc_threads: 2
gb10_nvcc_threads: 2

gb10_default_kv_cache_dtype: fp8
```

**Reasoning:** defaults should be safe for 121 GiB unified-memory GB10 systems and avoid known JIT OOM / NVFP4 KV pitfalls.

### Task 2.4: Add host vars guide

**Objective:** Explain per-node overrides without shipping real host vars.

**Create:** `host_vars/README.md`

Include:
- example `host_vars/worker01.yml`
- per-node model path overrides
- per-node SSH user/key overrides
- where not to put secrets

## Phase 3 — Roles

### Task 3.1: Create role skeletons

**Objective:** Establish reusable role structure matching Ansible docs.

**Create directories:**

```text
roles/gb10_health/{tasks,defaults,templates,files,handlers,meta}
roles/gb10_base/{tasks,defaults,handlers,meta}
roles/nvidia_container_runtime/{tasks,defaults,handlers,meta}
roles/model_artifacts/{tasks,defaults,templates,meta}
roles/vllm_service/{tasks,defaults,templates,handlers,meta}
roles/benchmark_runner/{tasks,defaults,templates,meta}
roles/evidence_bundle/{tasks,defaults,templates,meta}
```

Each role should at minimum include:
- `tasks/main.yml`
- `defaults/main.yml`
- `meta/main.yml`

### Task 3.2: Implement `gb10_health`

**Objective:** Gather read-only health facts.

**Tasks:**
- ping/connectivity is external, but role gathers:
  - hostname/date/uptime
  - OS/kernel
  - memory/disk
  - NVIDIA GPU state if `nvidia-smi` exists
  - Docker status if Docker exists
  - running containers
  - tmux sessions
  - listening ports relevant to model serving

**Use:** `ansible.builtin.command` for read-only commands with `changed_when: false`.

**Verify:**

```bash
ansible-playbook -i inventories/examples/three-node-gb10.yml playbooks/health.yml --syntax-check
```

### Task 3.3: Implement `gb10_base`

**Objective:** Basic host prep that is safe and idempotent.

**Tasks:**
- install base packages (`curl`, `rsync`, `tmux`, `python3-venv`, etc.)
- create standard directories
- optionally set sysctl/huges pages only when enabled
- no network changes by default

**Safety:** network-tuning variables must default to false.

### Task 3.4: Implement `nvidia_container_runtime`

**Objective:** Install/verify Docker and NVIDIA Container Toolkit idempotently.

**Tasks:**
- check Docker active
- install Docker only if enabled and absent
- install NVIDIA Container Toolkit only if enabled and absent
- configure Docker runtime
- restart Docker only when handler notified

**Pitfall from local skill:** Do not pipe cuda-keyring download directly into `dpkg` over SSH; download to `/tmp`, then install.

### Task 3.5: Implement `model_artifacts`

**Objective:** Sync model directories, Docker image tarballs, cache directories, or benchmark scripts.

**Tasks:**
- validate source path exists
- create remote parent dirs
- use `ansible.posix.synchronize`/rsync where appropriate
- support checksum/manifest capture

### Task 3.6: Implement `vllm_service`

**Objective:** Start/stop model serving containers from generic model registry variables.

**Tasks:**
- render launch env
- stop/replace only named container when requested
- set safe env vars (`MAX_JOBS`, `FLASHINFER_NVCC_THREADS`, `NVCC_THREADS`)
- default `kv_cache_dtype: fp8`
- expose `/v1/models` verification

**Safety:** container replacement requires explicit model key and target host.

### Task 3.7: Implement `benchmark_runner`

**Objective:** Launch durable benchmark sessions under tmux.

**Tasks:**
- render benchmark script from template
- create result dir
- start tmux session with deterministic name
- write launcher log
- provide monitor tags/tasks

**Default benchmark examples:**
- `gsm8k` via lm-eval completions endpoint
- `vllm_bench_serve_random` for throughput if vLLM version supports it

### Task 3.8: Implement `evidence_bundle`

**Objective:** Collect logs, configs, command lines, versions, and result manifests.

**Tasks:**
- create `evidence/<run_id>/<host>/`
- collect Ansible facts subset
- collect Docker inspect/logs for named containers
- collect tmux pane capture for benchmark sessions
- hash result files
- write `SUMMARY.md` or JSON summary

## Phase 4 — Playbooks

### Task 4.1: `playbooks/health.yml`

**Objective:** Run `gb10_health` on selected targets.

**Pattern:**

```yaml
---
- name: Collect GB10 health status
  hosts: gb10
  gather_facts: true
  roles:
    - role: gb10_health
```

### Task 4.2: `playbooks/discover.yml`

**Objective:** Help build inventory by probing a provided range/list.

**Constraint:** Keep this read-only and optional. Do not assume every operator wants subnet scans.

### Task 4.3: `playbooks/provision-node.yml`

**Objective:** Run base + NVIDIA runtime roles for a selected target.

**Safety:** Should refuse if `target` / `--limit` is not set unless explicitly overridden.

### Task 4.4: `playbooks/configure-network.yml`

**Objective:** Guarded network tuning for MTU/RoCE/sysctl.

**Safety requirements:**
- default disabled
- preflight current routes/IPs
- no `netplan apply` by default
- rollback script/task generated before persistent change
- require `gb10_allow_network_changes: true`

### Task 4.5: `playbooks/deploy-docker-image.yml`

**Objective:** Load or pull Docker images on nodes.

**Support:**
- registry pull
- local tar copy + `docker load`
- digest capture

### Task 4.6: `playbooks/sync-model.yml`

**Objective:** Sync model artifacts to target nodes.

**Support:**
- local path
- shared NFS path check
- remote already-present check
- manifest capture

### Task 4.7: `playbooks/serve-model.yml`

**Objective:** Start a model serving container and verify endpoint.

**Support:**
- model registry from group vars
- port mapping
- env vars
- container name
- health endpoint

### Task 4.8: `playbooks/stop-services.yml`

**Objective:** Stop named containers/services safely.

**Safety:** Never stop all containers by default. Require service/model key or explicit `gb10_stop_all_containers=true`.

### Task 4.9: `playbooks/benchmark.yml`

**Objective:** Launch and monitor durable benchmark jobs.

**Support:**
- tmux session creation
- run id
- result path
- monitor-only mode

### Task 4.10: `playbooks/collect-evidence.yml`

**Objective:** Collect reproducibility bundle after operations or benchmarks.

## Phase 5 — Scripts and developer quality gates

### Task 5.1: `scripts/bootstrap.sh`

**Objective:** Set up local venv and install Ansible dependencies.

**Verify:**

```bash
bash scripts/bootstrap.sh
source .venv/bin/activate
ansible --version
```

### Task 5.2: `scripts/validate-inventory.sh`

**Objective:** Validate inventory graph, ping, syntax, and lint.

**Usage:**

```bash
scripts/validate-inventory.sh inventories/my-cluster.yml
```

### Task 5.3: `scripts/collect-summary.py`

**Objective:** Summarize evidence bundle into concise JSON/Markdown for Hermes final reports.

### Task 5.4: CI workflow

**Create:** `.github/workflows/ci.yml`

**Checks:**
- yamllint
- ansible-lint
- syntax-check against example inventory
- markdown link sanity if desired

## Phase 6 — Documentation hardening

### Task 6.1: Expand README from planning to user guide

Include:
- quick start
- install requirements
- copy/customize inventory
- run Hermes from repo
- install skill only
- common operations
- safety model
- troubleshooting
- contribution guide

### Task 6.2: Expand AGENTS.md into operational runbook

Ensure it covers:
- safe defaults
- target scoping
- preflight
- execution patterns
- verification report template
- hard constraints

### Task 6.3: Add docs for operator customization

**Create:**
- `docs/customization.md`
- `docs/operations.md`
- `docs/safety.md`
- `docs/benchmarks.md`

### Task 6.4: Add skill references/templates

Under `skills/hermes-gb10-cluster-orchestration/`, add:

```text
references/
  ansible-patterns.md
  gb10-safety.md
  benchmark-workflows.md
templates/
  inventory-three-node.yml
  model-registry.yml
scripts/
  inspect_cluster.py
```

Keep `SKILL.md` concise and use linked files for details.

## Phase 7 — Verification on a real or simulated cluster

### Task 7.1: Local syntax validation

```bash
source .venv/bin/activate
ansible-inventory -i inventories/examples/three-node-gb10.yml --graph
ansible-playbook -i inventories/examples/three-node-gb10.yml playbooks/health.yml --syntax-check
ansible-lint playbooks/ roles/
yamllint .
```

### Task 7.2: Dry-run against one reachable test node

```bash
ansible all -i inventories/my-cluster.yml -l <test-node> -m ansible.builtin.ping
ansible-playbook -i inventories/my-cluster.yml playbooks/health.yml -l <test-node>
ansible-playbook -i inventories/my-cluster.yml playbooks/provision-node.yml -l <test-node> --check --diff
```

### Task 7.3: Controlled end-to-end smoke

On a non-critical node:

1. Health check.
2. Provision check mode.
3. Provision real if safe.
4. Deploy a tiny test container or non-GPU service.
5. Collect evidence.
6. Validate summary.

### Task 7.4: GB10 model-serving smoke

Only if operator approves GPU use:

1. Confirm no conflicting containers.
2. Start a small or already-cached model/service.
3. Verify endpoint.
4. Run one tiny request.
5. Stop service if requested.
6. Collect evidence.

## Phase 8 — GitHub publication

### Task 8.1: Secret and large-file scan

```bash
git status --short
git diff --cached
find . -type f -size +50M -print
grep -RInE 'HF_TOKEN|GITHUB_TOKEN|BEGIN OPENSSH|PRIVATE KEY|password|token' . --exclude-dir=.git || true
```

### Task 8.2: Initialize git and commit

```bash
git init
git add .
git commit -m "docs: add Hermes Ansible GB10 orchestration plan"
```

### Task 8.3: Create GitHub repo after user confirms owner/name

Recommended public repo name: `hermes-ansible-node-orchestration` unless the user wants to preserve the requested typo.

### Task 8.4: Push and verify

```bash
git remote add origin https://github.com/<owner>/<repo>.git
git push -u origin main
```

Verify URL loads and license is detected as MIT.

## Open decisions before implementation

1. Publish repo spelling: keep `ansibel` as requested or correct to `ansible` for public GitHub?
2. Scope v1 operations: health/provision only, or include model serving and benchmark from the first release?
3. Default install path: pure repo users, skill-only users, or full Hermes profile distribution?
4. How opinionated should GB10 defaults be about Docker, vLLM, lm-eval, and FP8 KV?
5. Whether to include CI from day one or after playbooks exist.

## Recommended v1 path

Build v1 as:

- README + AGENTS.md + skill
- example inventory
- health/provision/evidence roles
- safe Docker/NVIDIA runtime provisioning
- model serving and benchmark as documented extension points, with minimal working playbooks only after health/provision is verified

This gives operators immediate safe value and avoids overfitting the first public release to one cluster topology or one model-serving stack.
