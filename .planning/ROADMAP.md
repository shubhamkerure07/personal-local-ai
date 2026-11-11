# Roadmap: Personal Local AI System

## Milestones & Phases

### Phase 1: Environment & Hardware Verification [COMPLETED]
- [x] Check Windows 11 environment, CPU, RAM (16 GB verified).
- [x] Validate NVIDIA RTX 4050 Laptop GPU (6141 MiB VRAM), Driver 592.82, CUDA 13.1.
- [x] Verify internal SSD free space (117.5 GB free on C:\ drive).
- [x] Assess package manager & runtime prerequisites.

### Phase 2: Ollama Engine Installation & Service Configuration [COMPLETED]
- [x] Install native Ollama Windows binary (v0.40.16).
- [x] Configure `OLLAMA_MODELS` path (`C:\Users\Shubham\.ollama\models`).
- [x] Clean up and delete installer executable (`OllamaSetup.exe`).
- [x] Verify Ollama server daemon listening at `http://127.0.0.1:11434` with NVIDIA RTX 4050 (CUDA 13.1, 6.0 GiB VRAM) detected and active.

### Phase 3: Model Selection, Retrieval & GPU Benchmark [READY]
- [ ] Review hardware-tailored model matrix (Qwen 2.5, Llama 3.2, Gemma 2, Phi 4).
- [ ] Pull verified pilot model (e.g. `qwen2.5:7b` or `llama3.2:3b`).
- [ ] Test inference response and verify 100% GPU offload in `nvidia-smi`.

### Phase 4: Google Drive 5 TB Cold Archive & Model Lifecycle Management
- [ ] Guide setup of Google Drive for Desktop virtual drive or directory path.
- [ ] Establish folder tree (`Google Drive/AI-Library/Models`, `Backups`, `Configurations`).
- [ ] Develop and test `ai-model-manager.ps1` script for:
  - Archiving inactive models to Google Drive.
  - Restoring models from Google Drive to local SSD.
  - Listing models across SSD Hot storage and Drive Cold storage.
  - Cleaning SSD space safely without data loss.

### Phase 5: Open WebUI Deployment & System Verification
- [ ] Install Open WebUI (via Docker or standalone Python virtualenv).
- [ ] Configure Open WebUI to connect to Ollama.
- [ ] Test complete workflow: chat via Open WebUI, switch models, observe GPU memory.
- [ ] Deliver user operational manual and command cheatsheet.
