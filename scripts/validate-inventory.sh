#!/usr/bin/env bash
set -euo pipefail

inventory="${1:-inventories/examples/three-node-gb10.yml}"
limit_arg=()
if [[ "${2:-}" != "" ]]; then
  limit_arg=(-l "$2")
fi

echo "== inventory graph =="
ansible-inventory -i "$inventory" --graph

echo "== playbook syntax =="
for playbook in playbooks/*.yml; do
  echo "-- $playbook"
  ansible-playbook -i "$inventory" "$playbook" --syntax-check
done

if command -v yamllint >/dev/null 2>&1; then
  echo "== yamllint =="
  yamllint \
    requirements.yml \
    inventories \
    group_vars \
    host_vars \
    playbooks \
    roles
else
  echo "== yamllint skipped: command not found =="
fi

if command -v ansible-lint >/dev/null 2>&1; then
  echo "== ansible-lint =="
  mkdir -p .cache/ansible-lint
  XDG_CACHE_HOME="$PWD/.cache" ansible-lint playbooks/ roles/
else
  echo "== ansible-lint skipped: command not found =="
fi

if [[ "${RUN_PING:-0}" == "1" ]]; then
  echo "== connectivity ping =="
  ansible all -i "$inventory" "${limit_arg[@]}" -m ansible.builtin.ping
else
  echo "== connectivity ping skipped: set RUN_PING=1 to enable =="
fi
