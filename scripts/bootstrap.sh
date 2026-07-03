#!/usr/bin/env bash
set -euo pipefail
python3 -m venv .venv
source .venv/bin/activate
python -m pip install -U pip
python -m pip install ansible-core ansible-lint yamllint
ansible-galaxy collection install -r requirements.yml --collections-path .ansible/collections
ansible --version
