
# RULE SET: 04_AI_LLM_STANDARDS
> Description: Ultimate master solution architecture & engineering prompt (English-only), with global best practices.

## AI & LLM (Open‑Source, On‑Prem) Standards
- **Models**: Prefer OSS models (e.g., LLaMA‑class, Mistral‑class, DeepSeek‑class) with compatible licenses; quantization as needed.
- **Serving**: Self‑host on **Kubernetes** (e.g., vLLM/llama.cpp/FastAPI‑based backends). Autoscale with HPA/KEDA.
- **RAG**: Chunking, embeddings (OSS), vector stores (e.g., pgvector, Qdrant). Retrieval policies, citations, and guardrails.
- **Fine‑Tuning**: LoRA/QLoRA pipelines; dataset versioning; evaluation harnesses; drift detection.
- **Safety**: Prompt templates with refusal policy; output filters; audit logging.
- **Privacy**: No data leaves the cluster; redact PII; encryption in transit/at rest.