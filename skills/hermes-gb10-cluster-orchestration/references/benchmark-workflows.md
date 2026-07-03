# Benchmark Workflows

Benchmarks should run under tmux on the target node and preserve raw logs, samples, metadata, and hashes.

For GSM8K via lm-eval:

- use completions endpoint,
- zero-shot unless explicitly changed,
- log samples,
- max_gen_toks=2048 for thinking models,
- report flexible-extract as primary.

Monitor using the benchmark playbook with `monitor_only=true` before deciding whether to relaunch.
