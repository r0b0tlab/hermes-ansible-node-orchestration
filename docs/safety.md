# Safety Model

This repo is intentionally conservative. It should be safe for an agent to inspect and operate only when the operator provides inventory and target scope.

## Target limits

Mutating playbooks refuse to run without `--limit/-l` unless an explicit override is set.

Examples:

- `provision-node.yml` requires `-l <target>` or `gb10_allow_unlimited_provision=true`.
- `sync-model.yml` requires `-l <target>` or `gb10_allow_unlimited_model_sync=true`.
- `deploy-docker-image.yml` requires `-l <target>` or `gb10_allow_unlimited_image_deploy=true`.
- `serve-model.yml` requires `-l <target>` or `gb10_allow_unlimited_serve=true`.
- `benchmark.yml` requires `-l <target>` or `gb10_allow_unlimited_benchmark=true`.
- `stop-services.yml` requires `-l <target>` or `gb10_allow_unlimited_stop=true`.

## Container replacement

Serving refuses to replace an existing same-name container unless explicitly allowed:

```bash
-e gb10_allow_container_replacement=true
```

Stopping services requires either a model key with a container name or an explicit container name. It never stops all containers by default.

## Network changes

`configure-network.yml` is intentionally a placeholder. Do not run `netplan apply` from this repo without a rollback plan. Network changes should be implemented as a separate guarded phase with:

1. current route/IP capture,
2. rollback script generation,
3. live reversible test,
4. persistent change only after operator approval,
5. post-change connectivity verification.

## SM120/SM121 defaults

GB10 defaults are conservative:

- FP8 KV cache by default.
- bounded FlashInfer/NVCC parallelism.
- no network tuning by default.
- no reboots by default.

Do not silently switch to fallback/emulation paths when native optimized paths were requested.

## Evidence gates

Do not call an operation complete without evidence:

- health output for node state,
- endpoint verification for serving,
- tmux status/log tail for benchmarks,
- evidence bundle for reproducibility.
