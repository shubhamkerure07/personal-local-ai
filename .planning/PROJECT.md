# Personal Local AI System

## Vision & Overview
A self-hosted, offline-capable, and cost-free local AI ecosystem running on a Windows 11 laptop with an NVIDIA RTX 4050 (6 GB VRAM) and 16 GB RAM, backed by a 5 TB Google Drive cloud archive for multi-model staging and cold storage. Active inference runs directly on the local high-speed SSD, while inactive model weights and configurations are organized in Google Drive without cloud execution overhead or sync congestion.

## Target Hardware & Infrastructure State
- **OS**: Windows 11 64-bit
- **CPU**: Intel Core i7
- **GPU**: NVIDIA GeForce RTX 4050 Laptop GPU (6 GB VRAM / 6141 MiB)
- **NVIDIA Driver**: 592.82 (CUDA 13.1 supported)
- **RAM**: 16 GB Physical Memory
- **SSD**: C:\ with 117.5 GB free space (Active Hot Tier)
- **Cloud Storage**: Google Drive 5 TB (Cold Archive Tier)

## Core Stack
- **Inference Engine**: Ollama (Windows native x64)
- **Web Interface**: Open WebUI (Local web GUI, port 8080)
- **Cloud Storage Client**: Google Drive for Desktop
- **Storage Management Scripts**: Clean PowerShell automation for Hot-SSD ↔ Cold-Drive archiving and restoration

## Constraints & Principles
- 100% Free & Open Source: No paid API subscriptions or SaaS dependencies.
- Hardware-Optimized: Active models fit within 6 GB VRAM (Q4_K_M 7B/8B or smaller) for full GPU acceleration.
- Never execute directly from Google Drive virtual stream (avoids catastrophic I/O bottlenecks and file lock issues).
- Clear user prompts and zero silent deletions.
