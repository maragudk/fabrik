# Reinforcement learning

Unsloth supports GRPO, DPO, ORPO, KTO, SimPO, and PPO — all via TRL trainers wrapped with Unsloth's kernels. GRPO is the flagship path for training reasoning models with verifiable rewards (RLVR: math, code execution, schema validation). DPO/ORPO/KTO are the preference-tuning family.

Claimed memory savings vs standard + FA2: ~90% for RL workloads, e.g. GRPO at 20k-context / 8 generations goes from ~511GB to ~54GB.

## GRPO

### Preconditions

- Base model ≥1.5B parameters (smaller models produce incoherent chains of thought).
- Dataset ≥500 examples.
- Expect to train for ≥300 steps before reward curves start moving.
- 16-bit LoRA is the default (not 4-bit). VRAM roughly equals model parameter count in GB.

### Model load

```python
import os
os.environ["UNSLOTH_VLLM_STANDBY"] = "1"   # +30% context, shares memory with vLLM

from unsloth import FastLanguageModel

model, tokenizer = FastLanguageModel.from_pretrained(
    model_name = "meta-llama/Llama-3.2-3B-Instruct",
    max_seq_length = 2048,
    load_in_4bit = False,
    fast_inference = True,                 # vLLM as generation backend
    max_lora_rank = 64,
    gpu_memory_utilization = 0.9,          # 0.9-0.95 with UNSLOTH_VLLM_STANDBY=1
)

model = FastLanguageModel.get_peft_model(
    model,
    r = 64, lora_alpha = 64, lora_dropout = 0, bias = "none",
    target_modules = ["q_proj","k_proj","v_proj","o_proj",
                      "gate_proj","up_proj","down_proj"],
    use_gradient_checkpointing = "unsloth",
    random_state = 3407,
)
```

### Dataset preparation

GRPO expects `{"prompt": <chat-formatted>, "answer": <ground-truth-for-verifiers>}` rows. Example for GSM8K:

```python
SYSTEM_PROMPT = """You solve math problems. Respond in the format:
<reasoning>
...
</reasoning>
<answer>
...
</answer>"""

def extract_hash_answer(text):
    if "####" not in text:
        return None
    return text.split("####")[1].strip()

from datasets import load_dataset
ds = load_dataset("openai/gsm8k", "main", split="train")
ds = ds.map(lambda x: {
    "prompt": [
        {"role": "system", "content": SYSTEM_PROMPT},
        {"role": "user",   "content": x["question"]},
    ],
    "answer": extract_hash_answer(x["answer"]),
})
ds = ds.filter(lambda x: x["answer"] is not None)
```

### Reward functions

Signatures (TRL passes whatever your dataset columns are in as `**kwargs`):

```python
def fn(completions, **kwargs) -> list[float]: ...
def fn(prompts, completions, answer, **kwargs) -> list[float]: ...
```

Design principle: many small verifiable rewards beat one monolithic score. Each reward function becomes a separate learning signal. Canonical set from the Llama 3.2 advanced-reasoning notebook:

```python
import re

def match_format_exactly(completions, **kwargs):
    """Reward exactly matching the <reasoning>...</reasoning><answer>...</answer> format."""
    pattern = re.compile(
        r"^<reasoning>.*?</reasoning>\s*<answer>.*?</answer>$", re.DOTALL,
    )
    return [3.0 if pattern.match(c[0]["content"].strip()) else -1.0 for c in completions]

def match_format_approximately(completions, **kwargs):
    """Partial credit: each tag present adds 0.5, each duplicate subtracts 0.25."""
    def score(text):
        s = 0.0
        for tag in ["<reasoning>", "</reasoning>", "<answer>", "</answer>"]:
            n = text.count(tag)
            s += 0.5 if n == 1 else -0.25 * n
        return s
    return [score(c[0]["content"]) for c in completions]

def check_answer(prompts, completions, answer, **kwargs):
    """Reward when extracted answer string matches ground truth."""
    rewards = []
    for c, gt in zip(completions, answer):
        m = re.search(r"<answer>(.*?)</answer>", c[0]["content"], re.DOTALL)
        guess = m.group(1).strip() if m else ""
        rewards.append(2.0 if guess == gt.strip() else -1.0)
    return rewards

def check_numbers(prompts, completions, answer, **kwargs):
    """Reward when the numeric content of the answer matches (robust to formatting)."""
    rewards = []
    for c, gt in zip(completions, answer):
        m = re.search(r"<answer>(.*?)</answer>", c[0]["content"], re.DOTALL)
        guess = m.group(1).strip() if m else ""
        try:
            rewards.append(1.5 if float(guess) == float(gt) else -0.5)
        except ValueError:
            rewards.append(-0.5)
    return rewards
```

Typical reward magnitudes: ±0.5 to ±3.0. Too large (e.g. ±100) destabilizes training.

### `GRPOConfig`

```python
from trl import GRPOConfig, GRPOTrainer

training_args = GRPOConfig(
    learning_rate            = 5e-6,
    weight_decay             = 0.1,
    warmup_ratio             = 0.1,
    lr_scheduler_type        = "cosine",
    optim                    = "adamw_8bit",
    logging_steps            = 1,
    per_device_train_batch_size = 1,
    gradient_accumulation_steps = 4,
    num_generations          = 4,              # 4-8 typical; lower if OOM
    max_prompt_length        = 512,
    max_completion_length    = 1536,           # fits in max_seq_length
    max_steps                = 500,            # or num_train_epochs = 1
    save_steps               = 250,
    max_grad_norm            = 1.0,
    report_to                = "none",
    output_dir               = "outputs",
)

trainer = GRPOTrainer(
    model = model, tokenizer = tokenizer,
    reward_funcs = [match_format_exactly, match_format_approximately,
                    check_answer, check_numbers],
    train_dataset = ds,
    args = training_args,
)
trainer.train()
```

### GRPO variants

`GRPOConfig` supports `loss_type` and `epsilon` arguments that unlock published variants:

- `loss_type="dr_grpo"` — Dr. GRPO (unbiased estimator).
- `loss_type="dapo"` — DAPO (decoupled advantage).
- `loss_type="gspo"` — GSPO (group-sequence policy optimization).

Consult the model-specific notebook for tested configurations — docs page lists support but doesn't commit to a best-default recommendation.

## DPO

`PatchDPOTrainer()` must be called before constructing the trainer; it's what tells Unsloth to apply its kernels to `DPOTrainer`.

```python
from unsloth import PatchDPOTrainer
PatchDPOTrainer()

from trl import DPOTrainer, DPOConfig

# Dataset shape (after preprocessing):
# {"prompt": "...", "chosen": "...", "rejected": "..."}
# The chosen/rejected strings should already have the chat template applied;
# TRL has a helper: dataset.map(..., apply_chat_template, {"tokenizer": tokenizer, "task": "dpo"})

dpo_trainer = DPOTrainer(
    model = model,
    ref_model = None,             # Unsloth can run without a separate ref model
    args = DPOConfig(
        per_device_train_batch_size = 2,
        gradient_accumulation_steps = 4,
        warmup_ratio = 0.1,
        num_train_epochs = 3,
        learning_rate = 5e-6,
        logging_steps = 1,
        optim = "adamw_8bit",
        weight_decay = 0.0,
        lr_scheduler_type = "linear",
        seed = 42,
        output_dir = "outputs",
        report_to = "none",
    ),
    beta = 0.1,                   # canonical DPO beta; 0.01-0.5 range
    train_dataset = dataset,
    tokenizer = tokenizer,
    max_length = 1024,
    max_prompt_length = 512,
)
dpo_trainer.train()
```

DPO hyperparameter notes:
- `beta`: controls how much the fine-tuned policy can diverge from the reference. 0.1 is canonical; lower = more aggressive updates, higher = more conservative.
- `learning_rate = 5e-6`. If you see loss exploding, drop to 1e-6.
- `lora_alpha` typically equals `r` for DPO (not `2*r`).

## ORPO, KTO, SimPO

Supported via TRL's `ORPOTrainer`, `KTOTrainer`, and SimPO-configured `DPOTrainer`. The docs page inlines only the DPO code — the others are "see the Colab notebook" territory. The pattern is the same:

1. `PatchDPOTrainer()` (still required even for the ORPO/KTO patches).
2. Construct the TRL trainer of choice with your Unsloth-loaded model.
3. Use the TRL-recommended config class for that trainer.

Rough defaults for all three: `lr=5e-6`, `beta` or `alpha=0.1`, `batch_size=2`, `grad_accum=4`, `num_train_epochs=1-3`, `optim="adamw_8bit"`.

KTO additionally needs `desirable_weight` / `undesirable_weight` on `KTOConfig` — set both to 1.0 and tune from there.

## PPO

Listed as supported via TRL's `PPOTrainer` with an Unsloth-wrapped model. Unsloth's docs emphasize GRPO over PPO; GRPO usually wins on sample efficiency at smaller scales. If you need PPO, pattern after TRL's PPO examples and swap in the Unsloth model.

## Memory-efficient RL knobs

```bash
UNSLOTH_VLLM_STANDBY=1     # +30% context; vLLM and training share VRAM via suspend/resume
```

With this flag set, you can push `gpu_memory_utilization` up to 0.9-0.95 in `FastLanguageModel.from_pretrained`. Without it, keep it around 0.5-0.7.

For long-context RL (100k+ tokens) and FP8 RL, Unsloth has dedicated docs pages — the setup diverges from this baseline (different environment flags, specific CUDA/driver requirements). Check `unsloth.ai/docs` if the context length matters.

## RLVR (RL with verifiable rewards) patterns

Unsloth leans heavily on verifiable rewards — rewards where correctness can be checked programmatically:

- Math answers: exact match, numeric equivalence, unit conversion.
- Code: run against a test suite, count passing tests.
- Schema: parse output as JSON, validate against schema, count valid rows.
- Format: regex on the expected output shape (as in `match_format_exactly`).

Composite rewards (sum several verifiers) work well. Avoid one mega-reward that tries to capture everything — the gradient signal gets noisier with each thing it has to weigh.

## Sanity checks during training

- First 100 steps: rewards should be roughly flat while the model learns format. If they're already high, your verifiers might be too lenient.
- Reward variance should be non-zero across a batch. Zero variance = the model is producing identical completions, usually because temperature is too low or `num_generations` is too small.
- If KL to the reference explodes early, drop LR or raise `max_grad_norm` regularization.
