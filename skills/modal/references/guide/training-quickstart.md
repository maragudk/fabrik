# LLM training quickstart

Modal provides many ways to get started with training.

The easiest way is to use [Modal Dojo](https://dojo.modal.dev), an open-source library that gives you the building blocks,
tuned defaults, and observability you need for easy, production-grade post-training: supervised fine-tuning (SFT) and reinforcement learning (RL).

For a Tinker-compatible API, you can deploy a [Spindle](/docs/guide/spindle)
server.

And when you need maximum control over your stack, you can bring your existing training code and infrastructure to a
[Clustered Function](/docs/guide/multi-node-training).

Here, we walk through how to start training with Modal Dojo. See [here](/docs/examples/paint_flowers) for a more fully-fledged example.

## Run your first example

Install the package:

```bash
uv add modal-dojo
```

Set up [Modal](/docs/cli/latest/setup) and the [dashboard](https://dojo.modal.dev/guides/dashboard):

```bash
modal-dojo setup
```

And empower your agents with the [skill bundle](https://dojo.modal.dev/guides/agent):

```bash
modal-dojo skills install
```

Then, it's as easy as:

```python notest
import re

from modal_dojo import (
    HuggingFaceDataset,
    Qwen3_5_4B,
    Qwen3_5_4B_Recipe,
    TrainConfig,
)

model = Qwen3_5_4B()


async def gsm8k_rm(args, sample, **kwargs) -> float:
    text = model.parse_response(sample.response or "").content
    boxed = re.findall(r"\\boxed\{([^}]+)\}", text)
    pred = boxed[-1] if boxed else (re.findall(r"-?[\d,]+(?:\.\d+)?", text) or [""])[-1]
    try:
        return float(float(pred.replace(",", "")) == float(sample.label))
    except ValueError:
        return 0.0


config = TrainConfig(
    model=model,
    dataset=HuggingFaceDataset(
        hf_repo="skrishna/gsm8k_only_answer",
        hf_split="train[:120]",
        input_column="text",
        output_column="label",
        input_format="text",
    ),
    recipe=Qwen3_5_4B_Recipe(
        custom_rm_function=gsm8k_rm,
    ),
)

if __name__ == "__main__":
    run = config.launch()
    print(run.training_run_id)
```

See the [documentation](https://dojo.modal.dev) for more information.
