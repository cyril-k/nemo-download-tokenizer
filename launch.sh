docker run -d \
  --gpus all \
  --shm-size=64g \
  --privileged \
  -v ./logs:/logs \
  -v ./config:/config \
  -v ./megatron_gpt_pretraining.py:/opt/NeMo/examples/nlp/language_modeling/megatron_gpt_pretraining.py \
  -v ./megatron_utils.py:/opt/NeMo/nemo/collections/nlp/modules/common/megatron/megatron_utils.py \
  nvcr.io/nvidia/nemo:24.07 \
  /bin/bash -c '
    LOG_FILE="/logs/output_$(hostname)_$(date +%Y%m%d_%H%M%S).log"
    touch "$LOG_FILE" && chmod 777 "$LOG_FILE" && \
    echo "Starting training at $(date)" >> "$LOG_FILE" && \
    for i in {1..10}; do
      export NEMO_ITERATION=$i
      echo "Run #$i at $(date)" >> "$LOG_FILE"
      torchrun \
        --nnodes=1 \
        --nproc_per_node=64 \
        --standalone \
        /opt/NeMo/examples/nlp/language_modeling/megatron_gpt_pretraining.py \
        --config-path=/config \
        --config-name=config.yaml \
      >> "$LOG_FILE" 2>&1
      echo "Clearing /root/.cache/torch/megatron" >> "$LOG_FILE"
      rm -rf /root/.cache/torch/megatron
    done
  '