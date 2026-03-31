# 🚀 AI Multi-Agent Starter Kit

This directory contains a standalone, project-agnostic boilerplate to bootstrap a multi-agent AI environment.

## How to Install into a New Project:

1. **Copy the contents** of `tmp_starter_kit/` directly into the root folder of your new or legacy project repository.
2. **Open your primary AI Chat** (this will be your `main_agent`).
3. Send the following prompt to the AI to initialize the system:

> "Ты — main_agent в этом проекте. Мы начинаем работать по протоколу Agent Manager. Пожалуйста, прочитай `MEMORY_BANK.md` в корне, а затем просканируй проект и обнови файлы в `memory_bank/` согласно правилам из `memory_enrichment_guide.md`."

The `main_agent` will automatically adopt the rules, decide which sub-agents it needs to create for your specific project scale, and manage tasks via `agent_tasks/current_tasks.md`.
