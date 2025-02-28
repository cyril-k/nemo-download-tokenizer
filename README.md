# nemo-download-tokenizer

This repository contains the code example necessary to demonstrate potential race condition in downloading default tokenizer files with [`megatron_utils._download()`](https://github.com/NVIDIA/NeMo/blob/e938df327c6d1e9d26e9670e51c1ceea0bf5a677/nemo/collections/nlp/modules/common/megatron/megatron_utils.py#L193-L215).

## Code adjustments:

There are 2 adjustmnents made to NeMo files to log the download process:
1. `megatron_utils.py` - added print statements to L207 and L212-213.
2. `megatron_gpt_pretraining.py` - commented `trainer.fit(model)` on L66 to stop immediately after loading the model and not to start the training process.

The `launch.sh` script contains docker run command that mounts the modified NeMo files and runs the pretraining script 10 times to observe the download process. At the end of every iteration it clears the cache to force the download again.

## Running the example:

Launch with:

```
chmod +x launch.sh && ./launch.sh
```

To observe the results find your log file in `logs` directory and search for ": downloading" in it:

```
cat output_<container-name>_<date>_<time>.log | grep ": downloading"
```

You will get something like:
```
Iteration 1: downloading on LOCAL_RANK 0 from https://s3.amazonaws.com/models.huggingface.co/bert/gpt2-vocab.json
Iteration 1: downloading on LOCAL_RANK 0 from https://s3.amazonaws.com/models.huggingface.co/bert/gpt2-merges.txt
Iteration 1: downloading on LOCAL_RANK 42 from https://s3.amazonaws.com/models.huggingface.co/bert/gpt2-merges.txt
Iteration 1: downloading on LOCAL_RANK 31 from https://s3.amazonaws.com/models.huggingface.co/bert/gpt2-merges.txt
Iteration 2: downloading on LOCAL_RANK 26 from https://s3.amazonaws.com/models.huggingface.co/bert/gpt2-vocab.json
Iteration 2: downloading on LOCAL_RANK 29 from https://s3.amazonaws.com/models.huggingface.co/bert/gpt2-vocab.json
Iteration 2: downloading on LOCAL_RANK 26 from https://s3.amazonaws.com/models.huggingface.co/bert/gpt2-merges.txt
Iteration 2: downloading on LOCAL_RANK 29 from https://s3.amazonaws.com/models.huggingface.co/bert/gpt2-merges.txt
Iteration 3: downloading on LOCAL_RANK 0 from https://s3.amazonaws.com/models.huggingface.co/bert/gpt2-vocab.json
Iteration 3: downloading on LOCAL_RANK 0 from https://s3.amazonaws.com/models.huggingface.co/bert/gpt2-merges.txt
```

Here on iterations 1 and 2, the same files were downloaded by different process which sometimes may result in errors due to race condition while moving these files to `MEGATRON_CACHE` with `shutil.move()`.