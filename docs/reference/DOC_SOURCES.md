# Documentation sources used for the project plan

This plan is grounded in the current Hermes Agent documentation, current Ansible community documentation, and the local `gb10-ansible-cluster` skill that has already been validated on a three-node GB10 cluster.

## Hermes Agent sources

- Hermes skills guide: https://hermes-agent.nousresearch.com/docs/guides/work-with-skills
  - Skills are markdown files with YAML frontmatter.
  - Skills support progressive disclosure through main `SKILL.md` plus optional `references/`, `templates/`, and `scripts/` files.
  - Skills can be installed from a URL or placed in `~/.hermes/skills/`.
  - Skills are procedural knowledge; memory is for facts.

- Hermes skills system reference: https://hermes-agent.nousresearch.com/docs/user-guide/features/skills
  - Canonical `SKILL.md` frontmatter and structure.
  - Skill directory conventions.
  - Agent-managed skills and skill bundles.

- Hermes tips and best practices: https://hermes-agent.nousresearch.com/docs/guides/tips
  - `AGENTS.md` is automatically loaded from the project root.
  - Subdirectory `AGENTS.md` files are discovered lazily during tool calls.
  - Context files should hold recurring project-specific instructions.
  - Skills are the right home for reusable procedures.

- Hermes tools and toolsets: https://hermes-agent.nousresearch.com/docs/user-guide/features/tools
  - Terminal/file tools are appropriate for Ansible orchestration.
  - Background process management exists, but durable remote work should be represented in Ansible/tmux patterns.
  - Toolsets can be scoped to terminal,file,skills,session_search for safe repo work.

- Hermes profile distributions: https://hermes-agent.nousresearch.com/docs/user-guide/profile-distributions
  - Future option for packaging a full cluster-operator Hermes profile.
  - Distribution repos should exclude `.env`, auth, sessions, memories, logs, state databases, and other user data.

- Hermes CLI reference: https://hermes-agent.nousresearch.com/docs/reference/cli-commands
  - Relevant commands include `hermes chat`, `hermes skills`, `hermes tools`, `hermes profile`, `hermes cron`, and `hermes mcp`.

## Ansible sources

- Ansible documentation index: https://docs.ansible.com/projects/ansible/latest/index.html
  - Current stable community documentation.
  - Covers installation, configuration, inventories, playbooks, vault, modules/plugins, collections, and developer guides.

- Inventory guide: https://docs.ansible.com/projects/ansible/latest/inventory_guide/intro_inventory.html
  - Inventory defines managed nodes and variables.
  - Hosts can be grouped by function, location, and environment.
  - Inventories can be static, dynamic, multiple sources, or directories.
  - Parent/child group relationships reduce maintenance.

- Roles guide: https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_reuse_roles.html
  - Roles load related vars, files, tasks, handlers, templates, defaults, meta, and optional plugins based on standard structure.
  - Roles make automation reusable and shareable.
  - Defaults have low precedence and are suitable for override-friendly role variables.

- Variables guide: https://docs.ansible.com/projects/ansible/latest/playbook_guide/playbooks_variables.html
  - Variables represent differences among systems.
  - Variables can live in playbooks, inventory, reusable files, roles, or command line overrides.
  - Variable names must be valid identifiers and should avoid reserved keywords.
  - Jinja expressions at the start of YAML values must be quoted.

- Ansible general tips: https://docs.ansible.com/projects/ansible/latest/tips_tricks/ansible_tips_tricks.html
  - Keep automation simple.
  - Keep playbooks, roles, inventories, and variables in version control.
  - Avoid configuration-dependent content; prefer paths relative to known project locations.
  - Always name plays/tasks/blocks.
  - Explicitly mention state.
  - Use fully qualified collection names.
  - Group inventory by function.
  - Separate production and staging inventories.
  - Use Ansible Vault for sensitive variables.
  - Try changes in staging and run `--syntax-check`.

## Local inspiration source

- Local Hermes skill: `gb10-ansible-cluster`
  - Existing working pattern for a 3-node GB10 cluster.
  - Includes inventory, health checks, provisioning, Docker image transfer, FlashInfer cache sync, model deploy, vLLM serve, tmux-backed benchmarks, and pitfall documentation.
  - Important generalizable lessons:
    - Use tmux for long-running remote evals.
    - Use FP8 KV by default on SM120/SM121 until NVFP4 KV cache is fixed.
    - Bound FlashInfer/NVCC parallelism to avoid OOM during JIT.
    - Do not use risky network apply paths without rollback.
    - Use completions endpoints for reasoning models when scoring visible answers.
