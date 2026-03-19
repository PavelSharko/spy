import requests
import time
import sys
from concurrent.futures import ThreadPoolExecutor

url = "https://n8n.sharksbots.com/webhook/get-scene-picture"
locations = ["Аэропорт", "Пиратский корабль", "Банк", "Казино", "Посольство"]

def fetch_loc(loc):
    t0 = time.time()
    try:
        res = requests.post(url, json={"location": loc}, timeout=30)
        t1 = time.time()
        print(f"   [{loc}] -> Status {res.status_code}, Time: {t1-t0:.2f}s, Bytes: {len(res.content)}")
        return t1-t0
    except Exception as e:
        print(f"   [{loc}] -> Error: {e}")
        return 0

def run_test(num_locs):
    print(f"\n========= Тест: {num_locs} локаций одновременно =========")
    locs = locations[:num_locs]
    with ThreadPoolExecutor(max_workers=5) as ex:
        results = list(ex.map(fetch_loc, locs))
    if results:
        print(f"Итоговое время загрузки (самый долгий запрос): {max(results):.2f} секунд")
    time.sleep(3)

if __name__ == "__main__":
    for i in range(1, 6):
        run_test(i)
