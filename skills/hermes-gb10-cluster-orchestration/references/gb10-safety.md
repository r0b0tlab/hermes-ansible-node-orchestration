# GB10 Safety Notes

- Default KV cache dtype to FP8 on SM120/SM121 unless NVFP4 KV is validated.
- Bound FlashInfer/NVCC parallelism: MAX_JOBS=6, FLASHINFER_NVCC_THREADS=2, NVCC_THREADS=2.
- Do not run `netplan apply` without rollback.
- Do not stop all containers by default.
- Check existing containers and tmux sessions before serving or benchmarking.
