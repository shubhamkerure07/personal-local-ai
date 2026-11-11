# Requirements Specification: Personal Local AI System

## 1. Functional Requirements

### FR-01: Local Inference Engine
- Native Windows Ollama installation with automatic NVIDIA CUDA acceleration detection.
- Fast local model execution with GPU layer offloading (100% layers in VRAM for primary models).

### FR-02: Model Tiering & Cloud Archive
- Folder hierarchy on Google Drive:
  ```
  Google Drive/
      AI-Library/
          Models/
          Backups/
          Configurations/
  ```
- Active models store locally in high-performance SSD directory (e.g. `C:\Users\Shubham\.ollama\models`).
- PowerShell CLI utility to archive inactive models to Google Drive (`AI-Library/Models/`) and restore them to the local SSD on demand.
- Deduplication and verification checks (hash/size) to prevent re-downloading existing models.

### FR-03: Model Portfolio Selection
- Qwen 2.5 (7B Instruct Q4_K_M): Coding, reasoning, math, general assistant (~4.7 GB).
- Llama 3.1 / 3.2 (3B / 8B Q4_K_M): Versatile language capabilities, creative writing.
- Gemma 2 (2B / 9B Q4): Fast conversational and lightweight tasks.
- Phi 3.5 / Phi 4 (3.8B - 14B): High-density logic and compact footprint.
- Benchmark verification of 1 active baseline model (e.g., `llama3.2:3b` or `qwen2.5:7b`) with `nvidia-smi` GPU tracking.

### FR-04: ChatGPT-like User Interface
- Open WebUI running locally, connecting to Ollama's API (`http://localhost:11434`).
- Rich chat interface with markdown formatting, multi-chat sessions, and model selector dropdown.
- Self-contained, lightweight installation (Docker or Python virtual environment).

## 2. Non-Functional Requirements & Safety
- **NFR-01 Performance**: Inference latency < 100ms time-to-first-token, > 25 tokens/second for quantized 7B/8B models.
- **NFR-02 Storage Safety**: Maintain at least 50 GB free SSD buffer at all times on C:\.
- **NFR-03 Cost**: $0 recurring cost; no OpenAI, Anthropic, or paid cloud APIs.
- **NFR-04 Transparency**: Explain all commands before execution; no silent deletions.
