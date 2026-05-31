import json
import random

with open("n8n_part/shuffle_md_hints.py", "r", encoding="utf-8") as f:
    code = f.read()

# Make it wrap around the pool
code = code.replace(
    "if pool_idx < len(pool):",
    "if True:"
).replace(
    "loc_hints.append(pool[pool_idx])\n                pool_idx += 1",
    "loc_hints.append(pool[pool_idx % len(pool)])\n                pool_idx += 1"
)

with open("n8n_part/shuffle_md_hints.py", "w", encoding="utf-8") as f:
    f.write(code)

