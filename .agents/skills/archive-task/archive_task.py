import sys
import os
import datetime

def archive():
    if len(sys.argv) < 3:
        print("Usage: python archive_task.py '<agent_name>' '<task_keyword>'")
        sys.exit(1)
        
    agent = sys.argv[1].strip()
    task_kw = sys.argv[2].strip().lower()
    
    q_file = "agent_tasks/current_tasks.md"
    safe_agent = agent.replace('-', '_').replace(' ', '_').lower()
    a_file = f"agent_tasks/old_prompts_{safe_agent}.md"
    
    if not os.path.exists(q_file):
        print(f"Error: {q_file} not found.")
        sys.exit(1)
        
    with open(q_file, 'r', encoding='utf-8') as f:
        lines = f.readlines()
        
    new_lines = []
    archived_content = []
    
    i = 0
    while i < len(lines):
        line = lines[i]
        
        # Находим начало блока агента
        if line.startswith("## ") and agent.lower() in line.lower():
            block_buffer = [line]
            found_task = False
            i += 1
            
            # Читаем до следующего "---" или "## "
            while i < len(lines):
                inner_line = lines[i]
                if inner_line.startswith("---") or inner_line.startswith("## "):
                    break
                    
                block_buffer.append(inner_line)
                if task_kw in inner_line.lower():
                    found_task = True
                i += 1
                
            if found_task:
                # Задача найдена! Заменяем её заглушкой
                new_lines.append(f"## 🔵 {agent} | Статус: ✅ Выполнено — {datetime.date.today()}\n\n")
                new_lines.append(f"### Задача: {task_kw.capitalize()}\n")
                new_lines.append(f"*Промпт перенесён в {a_file}*\n\n")
                archived_content = block_buffer
            else:
                # Это не та задача, возвращаем строки как было
                new_lines.extend(block_buffer)
                
            continue
            
        new_lines.append(line)
        i += 1
        
    if not archived_content:
        print(f"Task matching keyword '{task_kw}' for agent '{agent}' not found in {q_file}.")
        sys.exit(1)
        
    # Записываем изменения обратно в очередь
    with open(q_file, 'w', encoding='utf-8') as f:
        f.writelines(new_lines)
        
    # Делаем аппенд в архив агента
    os.makedirs(os.path.dirname(a_file), exist_ok=True)
    with open(a_file, 'a', encoding='utf-8') as f:
        f.write("\n---\n")
        f.writelines(archived_content)
        f.write("\n")
        
    print(f"Success! Task archived beautifully to {a_file}")

if __name__ == "__main__":
    archive()
