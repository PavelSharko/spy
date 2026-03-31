---
name: archive-task
description:
  A core automated skill used by AI Sub-Agents to safely extract completed tasks from the active queue and append them to their historical archives.
---

# Archive Task Skill

This Python script is used to automatically archive a completed prompt from `agent_tasks/current_tasks.md` to `agent_tasks/old_prompts_<agent_name>.md`.

## WHY USE THIS?
We use this script so the LLM does not hallucinate, summarize, or accidentally truncate its previous prompts during copy-pasting. The script performs a pristine Markdown extraction.

## HOW TO USE:
As soon as you (a sub-agent) finish your coding task, execute this command directly in the terminal:
`python3 .agents/skills/archive-task/archive_task.py "[Твое_Имя]" "[Уникальное слово из названия твоей задачи]"`

Example:
`python3 .agents/skills/archive-task/archive_task.py "ui-agent" "Кнопка Логина"`

The script will find the section containing your task, replace it with a green checkmark `✅ Выполнено`, and move the original prompt payload to your archive file.
