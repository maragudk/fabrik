# Supported models

Modal Endpoints serve the open-weight models listed on this page.
[Shared Endpoints](/docs/guide/shared-endpoints) serve models from a
Modal-managed compute pool, using token-based billing.
[Dedicated Endpoints](/docs/guide/dedicated-endpoints) run the models listed in
[Dedicated Endpoint models](#dedicated-endpoint-models), or compatible custom
weights, on isolated, autoscaling containers.

Learn more about model capabilities in the
[Model Library](https://modal.com/library).

## Shared Endpoint models

Shared Endpoints are billed per token. Rates are in USD per million tokens and
also appear when you create an Endpoint.

| Model                                                                  | Input Modalities   | Input <span class="text-xs text-secondary">($/Mtok)</span> | Output <span class="text-xs text-secondary">($/Mtok)</span> |
| ---------------------------------------------------------------------- | ------------------ | ---------------------------------------------------------- | ----------------------------------------------------------- |
| [GLM 5.3 Flash NVFP4](/library/zai/glm-5-3-flash-nvfp4)                | Text, Image        | 0.15 / 0.03 cached                                         | 0.50                                                        |
| [DeepSeek V4.1 Flash 1017](/library/deepseek/deepseek-v4-1-flash-1017) | Text, Image        | 0.25 / 0.005 cached                                        | 1.00                                                        |
| [DeepSeek V4.1 Flash](/library/deepseek/deepseek-v4-1-flash)           | Text, Image        | 0.30 / 0.03 cached                                         | 1.20                                                        |
| [GLM 5.3 Flash](/library/zai/glm-5-3-flash)                            | Text, Image        | 0.45 / 0.09 cached                                         | 1.50                                                        |
| [Muse Spark Open](/library/meta/muse-spark-open)                       | Text, Image, Audio | 1.25 / 0.15 cached                                         | 4.25                                                        |
| [GLM 5.3](/library/zai/glm-5-3)                                        | Text               | 1.40 / 0.26 cached                                         | 4.40                                                        |
| [Inkling NVFP4](/library/thinking-machines/inkling)                    | Text, Image, Audio | 1.20 / 0.27 cached                                         | 5.00                                                        |
| [Qwen3.8-Max](/library/qwen/qwen3-8-max)                               | Text               | 2.00 / 0.25 cached                                         | 6.00                                                        |
| [Qwen3.8-Max VL](/library/qwen/qwen3-8-max-vl)                         | Text, Image        | 2.00 / 0.25 cached                                         | 6.00                                                        |
| [Kimi K3](/library/moonshot/kimi-k3)                                   | Text, Image        | 3.00 / 0.30 cached                                         | 15.00                                                       |

## Dedicated Endpoint models

Dedicated Endpoints bill for compute required to serve the model; see
[Dedicated Endpoint pricing](/docs/guide/dedicated-endpoints#pricing).

For entries shown as model IDs, pass the ID to `modal endpoint create --model`.

| Model                                                                                              | Input Modalities   |
| -------------------------------------------------------------------------------------------------- | ------------------ |
| [Beam 1.0 501B-A23B-FP8](/library/reflection/beam)                                                 | Text               |
| [Beam 1.0 501B-A23B-NVFP4](/library/reflection/beam)                                               | Text               |
| [DeepSeek V4 Flash](/library/deepseek/deepseek-v4-flash)                                           | Text               |
| [DeepSeek V4 Flash Preview](/library/deepseek/deepseek-v4-flash-preview)                           | Text               |
| [DeepSeek V4 Pro](/library/deepseek/deepseek-v4-pro)                                               | Text               |
| [DeepSeek V4 Pro Preview](/library/deepseek/deepseek-v4-pro-preview)                               | Text               |
| [DeepSeek V4.1 Flash](/library/deepseek/deepseek-v4-1-flash)                                       | Text, Image        |
| [Gemma 3 1B IT](/library/google/gemma-3-1b-it)                                                     | Text               |
| [Gemma 4 26B A4B IT](/library/google/gemma-4-26b-a4b-it)                                           | Text, Image        |
| [Gemma 4 31B IT](/library/google/gemma-4-31b)                                                      | Text, Image        |
| [Gemma 4 E2B IT](/library/google/gemma-4-e2b-it)                                                   | Text, Image        |
| [Gemma 4 E4B IT](/library/google/gemma-4-e4b-it)                                                   | Text, Image        |
| [GLM 4.7](/library/zai/glm-4-7)                                                                    | Text               |
| [GLM 5.2 FP8](/library/zai/glm-5-2-fp8)                                                            | Text               |
| [GLM 5.2 NVFP4](/library/zai/glm-5-2-nvfp4)                                                        | Text               |
| [GLM 5.3](/library/zai/glm-5-3-nvfp4)                                                              | Text               |
| [GLM 5.3 Flash](/library/zai/glm-5-3-flash)                                                        | Text, Image        |
| [GPT-OSS 120B](/library/openai/gpt-oss-120b)                                                       | Text               |
| [Hy3 GPTQ Int4](/library/tencent/hy3-gptq-int4)                                                    | Text               |
| [Inkling NVFP4](/library/thinking-machines/inkling)                                                | Text, Image, Audio |
| [K2 Horizon 0.9B](/library/ifm/k2-horizon-0-9b)                                                    | Text               |
| [Kimi K2.6 NVFP4](/library/moonshot/kimi-k2-6-nvfp4)                                               | Text               |
| [Kimi K3](/library/moonshot/kimi-k3)                                                               | Text, Image        |
| [Muse Glimmer 30B BF16](/library/meta/muse-glimmer-30b-bf16)                                       | Text               |
| [Muse Glimmer 30B NVFP4](/library/meta/muse-glimmer-30b-nvfp4)                                     | Text               |
| [Nemotron 3.5 Lightning 30B A3B NVFP4](/library/nvidia/nemotron-3-5-lightning-30b-a3b-nvfp4)       | Text               |
| [Nemotron 3.5 Super VL 120B A12B NVFP4](/library/nvidia/nemotron-3-5-super-vl-120b-a12b-nvfp4)     | Text, Image        |
| [NVIDIA Nemotron 3 Super 120B A12B NVFP4](/library/nvidia/nvidia-nemotron-3-super-120b-a12b-nvfp4) | Text               |
| [NVIDIA Nemotron 3 Ultra 550B A55B NVFP4](/library/nvidia/nvidia-nemotron-3-ultra-550b-a55b-nvfp4) | Text               |
| [PhoneLLM Alpha 1](/library/pipecat/phonellm-alpha-1)                                              | Text               |
| [PhoneLLM Max Alpha 2](/library/pipecat/phonellm-max-alpha-2)                                      | Text               |
| [PhoneLLM Mini Alpha 2](/library/pipecat/phonellm-mini-alpha-2)                                    | Text               |
| [Qwen3 Embedding 0.6B](/library/qwen/qwen3-embedding-0-6b)                                         | Text               |
| [Qwen3 Embedding 8B](/library/qwen/qwen3-embedding-8b)                                             | Text               |
| [Qwen3.5 0.8B](/library/qwen/qwen3-5-0-8b)                                                         | Text, Image        |
| [Qwen3.5 122B A10B FP8](/library/qwen/qwen3-5-122b-a10b-fp8)                                       | Text, Image        |
| [Qwen3.5 27B FP8](/library/qwen/qwen3-5-27b-fp8)                                                   | Text, Image        |
| [Qwen3.5 2B](/library/qwen/qwen3-5-2b)                                                             | Text, Image        |
| [Qwen3.5 35B A3B FP8](/library/qwen/qwen3-5-35b-a3b-fp8)                                           | Text, Image        |
| [Qwen3.5 397B A17B FP8](/library/qwen/qwen3-5-397b-a17b-fp8)                                       | Text, Image        |
| [Qwen3.5 4B](/library/qwen/qwen3-5-4b)                                                             | Text, Image        |
| [Qwen3.5 9B](/library/qwen/qwen3-5-9b)                                                             | Text, Image        |
| [Qwen3.6 27B](/library/qwen/qwen3-6-27b)                                                           | Text, Image        |
| [Qwen3.6 27B FP8](/library/qwen/qwen3-6-27b-fp8)                                                   | Text, Image        |
| [Qwen3.6 35B A3B](/library/qwen/qwen3-6-35b-a3b)                                                   | Text, Image        |
| [Qwen3.6 35B A3B FP8](/library/qwen/qwen3-6-35b-a3b-fp8)                                           | Text, Image        |
| [Qwen3.8 2.4T A95B NVFP4](/library/qwen/qwen3-8-2-4t-a95b-nvfp4)                                   | Text               |
| [Qwen3.8 27B](/library/qwen/qwen3-8-27b)                                                           | Text               |
| [Qwen3.8 Flash Next](/library/qwen/qwen3-8-flash-next-fp8)                                         | Text, Image        |
| [Qwen3.8 Flash Next FP8](/library/qwen/qwen3-8-flash-next-fp8)                                     | Text, Image        |
| [Step 5 Preview](/library/stepfun/step-5-preview)                                                  | Text, Image        |
