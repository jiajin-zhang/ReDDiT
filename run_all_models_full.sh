#!/usr/bin/env bash
set -euo pipefail

GPU_ID="${1:-3}"
ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"
TS="$(date +%Y%m%d_%H%M%S)"
LOG_DIR="${ROOT_DIR}/run_logs/full_run_${TS}"
mkdir -p "${LOG_DIR}"

run_cmd() {
  local name="$1"
  shift
  echo "[START] ${name}" | tee -a "${LOG_DIR}/summary.log"
  echo "[CMD] $*" | tee -a "${LOG_DIR}/summary.log"
  "$@" 2>&1 | tee "${LOG_DIR}/${name}.log"
  echo "[DONE] ${name}" | tee -a "${LOG_DIR}/summary.log"
}

cd "${ROOT_DIR}"

echo "GPU_ID=${GPU_ID}" | tee -a "${LOG_DIR}/summary.log"

# Full training for all three dataset settings.
run_cmd train_lolv1 \
  python train.py --config ./config/lolv1_train.json --dataset ./config/lolv1.yml \
  --w_str 0.0 --w_snr 0.8 --w_gt 1.0 --w_lpips 0.6 --ablation --gpu_ids "${GPU_ID}"

run_cmd train_lolv2_real \
  python train.py --config ./config/lolv2_real_train.json --dataset ./config/lolv2_real.yml \
  --w_str 0.0 --w_snr 0.4 --w_gt 0.0 --w_lpips 0.6 --ablation --gpu_ids "${GPU_ID}"

run_cmd train_lolv2_syn \
  python train.py --config ./config/lolv2_syn_train.json --dataset ./config/lolv2_syn.yml \
  --w_str 0.0 --w_snr 0.4 --w_gt 0.0 --w_lpips 0.6 --ablation --gpu_ids "${GPU_ID}"

# Final test/inference validation for each dataset config.
run_cmd test_lolv1 \
  python test.py --dataset ./config/lolv1.yml --config config/lolv1_test.json \
  --w_str 0.9 --w_snr 0.2 --w_gt 0.2 --gpu_ids "${GPU_ID}"

run_cmd test_lolv2_real \
  python test.py --dataset ./config/lolv2_real.yml --config config/lolv2_real_test.json \
  --w_str 0.9 --w_snr 0.2 --w_gt 0.2 --gpu_ids "${GPU_ID}"

run_cmd test_lolv2_syn \
  python test.py --dataset ./config/lolv2_syn.yml --config config/lolv2_syn_test.json \
  --w_str 0.9 --w_snr 0.2 --w_gt 0.2 --gpu_ids "${GPU_ID}"

echo "All runs finished. Logs at: ${LOG_DIR}" | tee -a "${LOG_DIR}/summary.log"
