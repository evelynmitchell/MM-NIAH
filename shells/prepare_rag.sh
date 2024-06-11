#!/bin/bash

PARTITION=${PARTITION:-"llm_s"}
GPUS=${GPUS:-32}
GPUS_PER_NODE=${GPUS_PER_NODE:-8}
GPUS_PER_TASK=${GPUS_PER_TASK:-1}
QUOTA_TYPE=${QUOTA_TYPE:-"reserved"}

# 常量路径
OUTPUTS_DIR="outputs_v2_prepare_rag_${GPUS}"
LOG_DIR="logs_v2_prepare_rag_${GPUS}"

# 循环不同的数据集和答案文件
declare -a model_paths=( \
    'ckpts/OpenGVLab/InternVL-14B-224px' \
)

declare -a tasks=( \
    # 'retrieval-text' \
    # 'retrieval-image' \
    # 'counting-text' \
    # 'counting-image' \
    # 'reasoning-text' \
    # 'reasoning-image' \
    # 'retrieval-text-v2' \
    # 'retrieval-image-v2' \
    'counting-text-v2' \
    'counting-image-v2' \
    'reasoning-text-v2' \
    'reasoning-image-v2' \
)

mkdir -p $LOG_DIR

for ((i=0; i<${#model_paths[@]}; i++)); do
    for ((j=0; j<${#tasks[@]}; j++)); do
        model_path=${model_paths[i]}
        task=${tasks[j]}

        model_name="$(basename ${model_path})"

        srun -p ${PARTITION} \
            --gres=gpu:${GPUS_PER_NODE} \
            --ntasks=$((GPUS / GPUS_PER_TASK)) \
            --ntasks-per-node=$((GPUS_PER_NODE / GPUS_PER_TASK)) \
            --quotatype=${QUOTA_TYPE} \
            --job-name="prepare_rag_${model_name}_${task}" \
            -o "${LOG_DIR}/${model_name}_${task}.log" \
            -e "${LOG_DIR}/${model_name}_${task}.log" \
            --async \
            python -u prepare_rag.py \
            --model-path $model_path \
            --task $task \
            --outputs-dir $OUTPUTS_DIR \
            --num-gpus-per-rank ${GPUS_PER_TASK} \

    done
done
