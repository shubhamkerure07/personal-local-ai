# 🚀 Personal Local AI System

A sovereign, zero-cost personal local AI infrastructure engineered for Windows 11 with dedicated NVIDIA RTX 4050 GPU acceleration and seamless **5 TB Google Drive Cloud Model Archiving**.

---

## 📌 Architecture & Design Concept

Running local Large Language Models (LLMs) locally requires high-speed SSD storage and VRAM for real-time inference, but model weights quickly fill up a 512 GB laptop SSD.

This project implements a **two-tier storage architecture**:

```
+---------------------------------------------------------------------------------+
|                               WINDOWS 11 LAPTOP                                 |
|                                                                                 |
|   +-------------------------------------------------------------------------+   |
|   |                         OPEN WEBUI (PORT 8080)                          |   |
|   |                Modern ChatGPT-style Web Interface                       |   |
|   +-------------------------------------------------------------------------+   |
|                                        │                                        |
|                                        ▼                                        |
|   +-------------------------------------------------------------------------+   |
|   |                     OLLAMA ENGINE (PORT 11434)                          |   |
|   |             Native Windows Core with CUDA 13.1 Acceleration             |   |
|   +-------------------------------------------------------------------------+   |
|                                        │                                        |
|            HOT TIER                    │                    COLD TIER           |
|      (Ultra-fast Local SSD)            │               (5 TB Google Drive)      |
|   ┌─────────────────────────────┐      │      ┌─────────────────────────────┐   |
|   │ C:\Users\...\.ollama\models │ <────┴────> │ G:\My Drive\AI-Library\     │   |
|   │ Active Models in VRAM       │  Sync via   │  ├── Models/ (Archived)     │   |
|   │ 100% GPU Offload (RTX 4050) │  PowerShell │  ├── Backups/               │   |
|   │ ~30-70+ tokens/sec          │   Manager   │  └── Configurations/        │   |
|   └─────────────────────────────┘             └─────────────────────────────┘   |
+---------------------------------------------------------------------------------+
```

### 1. 🔥 Hot Tier (Local SSD + GPU)
- **Engine**: Ollama running directly on Windows 11.
- **Hardware Acceleration**: 100% layer offload to **NVIDIA GeForce RTX 4050 Laptop GPU (6 GB VRAM)** using CUDA 13.1.
- **Execution**: Only active models reside in the local SSD hot directory (`%USERPROFILE%\.ollama\models`). Never runs from virtual cloud drives to eliminate I/O lag and lock issues.

### 2. ❄️ Cold Tier (5 TB Google Drive Cloud Archive)
- **Cloud Library Path**: `Google Drive/AI-Library/Models/`, `Backups/`, `Configurations/`.
- **Purpose**: Acts as an unlimited cloud vault for all your downloaded models. When you want to experiment with multiple 7B, 8B, 14B, or vision models without consuming your 512 GB SSD, you archive inactive models to Google Drive.
- **Instant Restore**: Restoring an archived model copies layer blobs directly back to Ollama without downloading them from the internet again.

---

## 💻 Hardware Compatibility & Model Matrix

Optimized specifically for **NVIDIA RTX 4050 (6 GB VRAM) + 16 GB RAM**:

| Model | Quantization | Size | VRAM Usage | Inference Speed | Best Use Case |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Qwen 2.5 (7B)** | `Q4_K_M` | ~4.7 GB | ~5.2 GB (100% GPU) | ~35–45 tok/s | Coding, logic, tool use, general assistant |
| **Llama 3.2 (3B)** | `Q4_K_M` | ~2.0 GB | ~2.6 GB (100% GPU) | ~70+ tok/s | Ultra-low latency, instant summaries |
| **Llama 3.1 (8B)** | `Q4_0` | ~4.7 GB | ~5.4 GB (100% GPU) | ~30–40 tok/s | Prose, creative writing, roleplay |
| **Phi 3.5 / 4-mini (3.8B)** | `Q4_K_M` | ~2.3 GB | ~3.0 GB (100% GPU) | ~55 tok/s | Concise mathematical & analytical reasoning |
| **Gemma 2 (2B)** | `Q4_K_M` | ~1.6 GB | ~2.2 GB (100% GPU) | ~80 tok/s | Fast conversational Q&A |

---

## 🛠️ Model Lifecycle Automation (`ai-model-manager.ps1`)

The repository includes a PowerShell automation utility to manage hot vs cold storage tiers seamlessly.

### Check Status of Tiers
```powershell
.\ai-model-manager.ps1 status
```
Displays free SSD space, active models loaded in Ollama, and cold models stored in Google Drive.

### Archive a Model to Google Drive
```powershell
.\ai-model-manager.ps1 archive qwen2.5:7b
```
Safely copies the model manifest and deduplicated layer blobs to `Google Drive\AI-Library\Models\qwen2.5_7b`, allowing you to free SSD space via `ollama rm qwen2.5:7b`.

### Restore a Model from Google Drive
```powershell
.\ai-model-manager.ps1 restore qwen2.5:7b
```
Instantly copies the blobs and manifest from Google Drive back to the local SSD without re-downloading over the internet.

---

## 🌐 Open WebUI Setup (ChatGPT Interface)

To run the local browser interface:

```powershell
# Using Python virtual environment or Docker:
pip install open-webui
open-webui serve
```
Then open your browser at **`http://localhost:8080`**.

---

## 🔒 Security & Privacy Notice
- **100% Private**: All prompts and model generations stay strictly on your local hardware.
- **Zero API Costs**: No OpenAI, Anthropic, or cloud GPU fees.
- **Safe Secrets**: No API keys or tokens are ever committed to this repository.
