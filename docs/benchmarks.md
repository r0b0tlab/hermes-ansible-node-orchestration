# Benchmark Guide

Benchmarks run under tmux on the target node so they survive local Hermes session resets.

## GSM8K lm-eval launcher

Launch:

```bash
ansible-playbook -i <inventory> playbooks/benchmark.yml -l <target>   -e model_key=<model-key>   -e benchmark=gsm8k
```

Monitor:

```bash
ansible-playbook -i <inventory> playbooks/benchmark.yml -l <target>   -e model_key=<model-key>   -e monitor_only=true
```

The run directory defaults to:

```text
<gb10_default_results_root>/<benchmark>-<model-key>-<run-id>/
```

The launcher writes:

- `run-meta.json`
- `run.log`
- lm-eval outputs
- `MANIFEST.sha256`

## Defaults

- endpoint: `/v1/completions`
- benchmark: GSM8K
- zero-shot
- `temperature=0`
- `max_gen_toks=2048`
- `num_concurrent=4`
- `max_retries=3`
- `--log_samples`

For GSM8K reporting, use flexible extraction. Do not cite strict-match as the primary score for thinking/chatty models.

## Custom benchmark

```bash
ansible-playbook -i <inventory> playbooks/benchmark.yml -l <target>   -e model_key=<model-key>   -e benchmark=custom   -e benchmark_command='python3 my_benchmark.py --endpoint http://127.0.0.1:8000/v1/completions'
```

## Duplicate session protection

If a tmux session already exists, the role refuses to launch another benchmark with the same session name. Use monitor mode first. Force relaunch only after deciding how to preserve or stop the active run.

```bash
-e benchmark_runner_force_relaunch=true
```

## Finality standard

A benchmark is not final until:

1. tmux session has completed or logs prove completion,
2. result files are present,
3. sample/log counts are checked,
4. artifacts are hashed,
5. evidence bundle is collected.
