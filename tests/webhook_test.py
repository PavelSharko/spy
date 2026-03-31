#!/usr/bin/env python3
"""
🔬 Spy Game — Webhook Test Runner
==================================
Interactive CLI to test webhook cases against the n8n endpoints.
Run: python3 tests/webhook_test.py
Then type: help_test

Test photos: data_for_test/1.jpeg .. 6.jpeg
"""

import sys
import os
import json
import time
import random
import io
import requests
from requests.auth import HTTPBasicAuth

# ─── Config ──────────────────────────────────────────────────────────────────

PRIMARY_URL   = "https://n8n.sharksbots.com/webhook/get-scene-picture"
FALLBACK_URL  = "https://n8n.sharksbots.com/webhook-test/get-scene-picture"
AUTH          = HTTPBasicAuth("spygame", "secretspy")
TIMEOUT       = 60

SCRIPT_DIR    = os.path.dirname(os.path.abspath(__file__))
PROJECT_ROOT  = os.path.dirname(SCRIPT_DIR)
PHOTO_DIR     = os.path.join(PROJECT_ROOT, "data_for_test")
RESULTS_DIR   = os.path.join(SCRIPT_DIR, "results")

# ─── Game Data (из locations_data.dart) ──────────────────────────────────────

LOCATIONS_WITH_ROLES = {
    "Больница": ["Хирург", "Медсестра", "Санитар", "Анестезиолог", "Терапевт",
                 "Охранник", "Главврач", "Лаборант", "Рентгенолог", "Регистратор"],
    "Школа":    ["Учитель", "Директор", "Завуч", "Охранник", "Уборщица",
                 "Библиотекарь", "Психолог", "Повар", "Ученик", "Секретарь"],
    "Тюрьма":   ["Охранник", "Заключённый", "Начальник", "Врач", "Повар",
                 "Священник", "Адвокат", "Психолог", "Электрик", "Уборщик"],
    "Банк":     ["Кассир", "Охранник", "Менеджер", "Клиент", "Инкассатор",
                 "IT-специалист", "Директор", "Аналитик", "Консультант", "Бухгалтер"],
    "Аэропорт": ["Пилот", "Стюардесса", "Сотрудник таможни", "Охранник", "Пассажир",
                 "Диспетчер", "Носильщик", "Менеджер стойки", "Уборщик", "Сотрудник паспортного контроля"],
    "Казино":   ["Крупье", "Охранник", "Бармен", "VIP-гость", "Менеджер зала",
                 "Официантка", "Игрок", "Владелец", "Диджей", "Кассир"],
    "Космическая станция": ["Капитан", "Штурман", "Инженер", "Врач", "Учёный",
                 "Техник", "Связист", "Пилот шаттла", "Биолог", "Кок"],
    "Хогвартс":  ["Гарри Поттер", "Дамблдор", "Снейп", "Хагрид", "Малфой",
                  "Гермиона", "Рон", "Минерва", "Добби", "Филч"],
    "Ночной клуб": ["Диджей", "Бармен", "Вышибала", "Танцовщица", "Посетитель",
                    "Администратор", "Фотограф", "Промоутер", "Уборщик", "Владелец"],
    "Фитнес клуб": ["Тренер", "Администратор", "Клиент", "Массажист", "Охранник",
                    "Инструктор по йоге", "Врач", "Уборщик", "Менеджер", "Диетолог"],
}

STYLES = [
    "не выбрано", "реальное фото", "мультяшный", "пиксели", "живопись",
    "фэнтези", "черно белое", "детское", "18+", "комиксы",
    "аниме", "киберпанк", "неон", "ретро плакаты ссср", "ретро плакаты сша",
]

DEFAULT_STYLE = "как настоящее фото"

# ─── Helpers ─────────────────────────────────────────────────────────────────

def pick_random_location():
    loc = random.choice(list(LOCATIONS_WITH_ROLES.keys()))
    return loc, LOCATIONS_WITH_ROLES[loc]

def pick_roles(all_roles, player_count):
    """Pick (player_count - 1) random roles (1 player = spy, no role)."""
    shuffled = list(all_roles)
    random.shuffle(shuffled)
    return shuffled[:player_count - 1]

def pick_random_style():
    style = random.choice(STYLES)
    return DEFAULT_STYLE if style == "не выбрано" else style

def load_photos(count):
    photos = []
    for i in range(1, count + 1):
        path = os.path.join(PHOTO_DIR, f"{i}.jpeg")
        if os.path.exists(path):
            with open(path, "rb") as f:
                photos.append(f.read())
        else:
            print(f"  ⚠ Photo not found: {path}")
    return photos

def save_result(test_id, data):
    os.makedirs(RESULTS_DIR, exist_ok=True)
    ext = "png" if data[:4] == b'\x89PNG' else "jpg"
    path = os.path.join(RESULTS_DIR, f"{test_id}.{ext}")
    with open(path, "wb") as f:
        f.write(data)
    print(f"  💾 Saved: {path} ({len(data)} bytes)")


# ─── Senders ─────────────────────────────────────────────────────────────────

def send_json(url, payload, test_id):
    """Send JSON POST — for gen_card_for_location and gen_card_for_finish_round without photos."""
    print(f"\n📤 [{test_id}] JSON POST → {url}")
    print(f"   Payload: {json.dumps(payload, ensure_ascii=False, indent=2)}")

    try:
        r = requests.post(url, json=payload, auth=AUTH, timeout=TIMEOUT)
        print(f"   Status: {r.status_code}")
        if r.status_code == 200 and len(r.content) > 0:
            save_result(test_id, r.content)
            return True
        else:
            print(f"   ❌ Failed: status={r.status_code}, body={r.text[:300]}")
            return False
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False


def send_multipart_manual(url, payload, spy_photo, civilian_photos, test_id):
    """Send multipart/form-data with manually constructed body.

    Matches the Dart app behavior exactly:
    - Text fields: only content-disposition, NO content-type → n8n body
    - List fields (roles): bracket notation roles[0], roles[1] → n8n array
    - Photos: spy_photo and separated photo_0, photo_1 -> n8n binary
    """
    print(f"\n📤 [{test_id}] MULTIPART POST → {url}")
    print(f"   Fields: {json.dumps(payload, ensure_ascii=False, indent=2)}")
    print(f"   Photos: {len(civilian_photos) + (1 if spy_photo else 0)} files")

    try:
        boundary = f"----SpyGame{int(time.time() * 1000)}"
        body = io.BytesIO()

        # Text fields (NO content-type header) — matches Dart app exactly
        for key, value in payload.items():
            if isinstance(value, list):
                for j, item in enumerate(value):
                    body.write(f"--{boundary}\r\n".encode())
                    body.write(f'content-disposition: form-data; name="{key}[{j}]"\r\n'.encode())
                    body.write(b"\r\n")
                    body.write(str(item).encode("utf-8"))
                    body.write(b"\r\n")
            elif isinstance(value, bool):
                body.write(f"--{boundary}\r\n".encode())
                body.write(f'content-disposition: form-data; name="{key}"\r\n'.encode())
                body.write(b"\r\n")
                body.write(str(value).lower().encode("utf-8"))
                body.write(b"\r\n")
            else:
                body.write(f"--{boundary}\r\n".encode())
                body.write(f'content-disposition: form-data; name="{key}"\r\n'.encode())
                body.write(b"\r\n")
                body.write(str(value).encode("utf-8"))
                body.write(b"\r\n")

        # Photo files (WITH content-type + filename)
        if spy_photo:
            body.write(f"--{boundary}\r\n".encode())
            body.write(b'content-disposition: form-data; name="spy_photo"; filename="spy.jpg"\r\n')
            body.write(b"content-type: image/jpeg\r\n")
            body.write(b"\r\n")
            body.write(spy_photo)
            body.write(b"\r\n")

        for i, photo_bytes in enumerate(civilian_photos):
            body.write(f"--{boundary}\r\n".encode())
            body.write(f'content-disposition: form-data; name="photo_{i}"; filename="player_{i}.jpg"\r\n'.encode())
            body.write(b"content-type: image/jpeg\r\n")
            body.write(b"\r\n")
            body.write(photo_bytes)
            body.write(b"\r\n")

        body.write(f"--{boundary}--\r\n".encode())

        headers = {
            "Content-Type": f"multipart/form-data; boundary={boundary}",
        }

        r = requests.post(
            url,
            data=body.getvalue(),
            headers=headers,
            auth=AUTH,
            timeout=TIMEOUT,
        )
        print(f"   Status: {r.status_code}")
        if r.status_code == 200 and len(r.content) > 0:
            save_result(test_id, r.content)
            return True
        else:
            print(f"   ❌ Failed: status={r.status_code}, body={r.text[:300]}")
            return False
    except Exception as e:
        print(f"   ❌ Error: {e}")
        return False


# ─── Test Cases ──────────────────────────────────────────────────────────────

TESTS = {}

def register(test_id, description, fn):
    TESTS[test_id] = {"desc": description, "fn": fn}


# ━━━ 1-1: gen_card_for_location, 4 игрока, рандом ━━━━━━━━━━━━━━━━━━━━━━━━━━

def test_1_1(url):
    loc, all_roles = pick_random_location()
    roles = pick_roles(all_roles, 4)
    style = pick_random_style()
    payload = {
        "location": loc,
        "roles": roles,
        "type_query": "gen_card_for_location",
        "generation_style": style,
        "need_add_faces": False,
    }
    return send_json(url, payload, "1_1")

register("1_1", "gen_card_for_location | 4 игрока | рандом локация/роли/стиль", test_1_1)


# ━━━ 1-2: gen_card_for_location, 5 игроков, рандом ━━━━━━━━━━━━━━━━━━━━━━━━━

def test_1_2(url):
    loc, all_roles = pick_random_location()
    roles = pick_roles(all_roles, 5)
    style = pick_random_style()
    payload = {
        "location": loc,
        "roles": roles,
        "type_query": "gen_card_for_location",
        "generation_style": style,
        "need_add_faces": False,
    }
    return send_json(url, payload, "1_2")

register("1_2", "gen_card_for_location | 5 игроков | рандом локация/роли/стиль", test_1_2)


# ━━━ 1-3: как 1-1, но 3 запроса с интервалом 5 сек (имитация 3 раундов) ━━━

def test_1_3(url):
    results = []
    for round_num in range(1, 4):
        loc, all_roles = pick_random_location()
        roles = pick_roles(all_roles, 4)
        style = pick_random_style()
        payload = {
            "location": loc,
            "roles": roles,
            "type_query": "gen_card_for_location",
            "generation_style": style,
            "need_add_faces": False,
        }
        tid = f"1_3_round{round_num}"
        ok = send_json(url, payload, tid)
        results.append(ok)

        if round_num < 3:
            print(f"\n   ⏳ Ждём 5 сек перед следующим раундом...")
            time.sleep(5)

    return all(results)

register("1_3", "gen_card_for_location | 3 раунда × 4 игрока | интервал 5 сек", test_1_3)


# ━━━ 2-1: gen_card_for_finish_round | spy_is_win=true | faces=true | 4 фото ━

def test_2_1(url):
    loc, all_roles = pick_random_location()
    roles = pick_roles(all_roles, 4)
    style = pick_random_style()
    photos = load_photos(4)
    payload = {
        "location": loc,
        "roles": roles,
        "type_query": "gen_card_for_finish_round",
        "generation_style": style,
        "need_add_faces": True,
        "spy_is_win": True,
    }
    return send_multipart_manual(url, payload, photos[0], photos[1:], "2_1")

register("2_1", "gen_card_for_finish_round | spy_win | faces ON | 4 фото (multipart)", test_2_1)


# ━━━ 2-2: gen_card_for_finish_round | spy_is_win=false | faces=true | 4 фото ━

def test_2_2(url):
    loc, all_roles = pick_random_location()
    roles = pick_roles(all_roles, 4)
    style = pick_random_style()
    photos = load_photos(4)
    payload = {
        "location": loc,
        "roles": roles,
        "type_query": "gen_card_for_finish_round",
        "generation_style": style,
        "need_add_faces": True,
        "spy_is_win": False,
    }
    return send_multipart_manual(url, payload, photos[0], photos[1:], "2_2")

register("2_2", "gen_card_for_finish_round | spy_loss | faces ON | 4 фото (multipart)", test_2_2)


# ━━━ 2-3: gen_card_for_finish_round | spy_is_win=true | faces=false | БЕЗ фото

def test_2_3(url):
    loc, all_roles = pick_random_location()
    roles = pick_roles(all_roles, 4)
    style = pick_random_style()
    payload = {
        "location": loc,
        "roles": roles,
        "type_query": "gen_card_for_finish_round",
        "generation_style": style,
        "need_add_faces": False,
        "spy_is_win": True,
    }
    return send_json(url, payload, "2_3")

register("2_3", "gen_card_for_finish_round | spy_win | faces OFF | без фото (JSON)", test_2_3)


# ━━━ 2-4: gen_card_for_finish_round | spy_is_win=false | faces=false | БЕЗ фото

def test_2_4(url):
    loc, all_roles = pick_random_location()
    roles = pick_roles(all_roles, 4)
    style = pick_random_style()
    payload = {
        "location": loc,
        "roles": roles,
        "type_query": "gen_card_for_finish_round",
        "generation_style": style,
        "need_add_faces": False,
        "spy_is_win": False,
    }
    return send_json(url, payload, "2_4")

register("2_4", "gen_card_for_finish_round | spy_loss | faces OFF | без фото (JSON)", test_2_4)


# ─── CLI ─────────────────────────────────────────────────────────────────────

def print_help():
    print("\n" + "="*80)
    print("🔬 SPY GAME — WEBHOOK TEST RUNNER")
    print("="*80)
    print(f"\n📊 Total test cases: {len(TESTS)}")
    print(f"📡 Primary:  {PRIMARY_URL}")
    print(f"📡 Fallback: {FALLBACK_URL}\n")

    print("  📂 gen_card_for_location (JSON POST):")
    for tid in ["1_1", "1_2", "1_3"]:
        print(f"     {tid:10s} — {TESTS[tid]['desc']}")

    print("\n  📂 gen_card_for_finish_round:")
    for tid in ["2_1", "2_2", "2_3", "2_4"]:
        print(f"     {tid:10s} — {TESTS[tid]['desc']}")

    print("\n" + "-"*80)
    print("🎮 COMMANDS:")
    print("  help_test                 — This help message")
    print("  run <id>                  — Run test (primary URL)")
    print("  run <id> fallback         — Run test (fallback URL)")
    print("  run_all                   — Run ALL tests (primary)")
    print("  run_all fallback          — Run ALL tests (fallback)")
    print("  quit / exit / q           — Exit")
    print("-"*80)
    print("\n📋 QUICK COPY-PASTE COMMANDS:")
    print("  run 1_1 fallback")
    print("  run 1_2 fallback")
    print("  run 1_3 fallback")
    print("  run 2_1 fallback")
    print("  run 2_2 fallback")
    print("  run 2_3 fallback")
    print("  run 2_4 fallback")
    print("  run_all fallback")
    print("-"*80)
    print("\n💡 TIPS:")
    print("  • Production (без fallback) требует активный workflow в n8n")
    print("  • Fallback (webhook-test) работает при открытом окне n8n")
    print("  • Результаты сохраняются в tests/results/")
    print("  • Фото берутся из data_for_test/1.jpeg .. 6.jpeg")
    print("  • Стиль 'не выбрано' автоматически заменяется на 'как настоящее фото'")
    print("="*80 + "\n")


def get_url(args):
    if "fallback" in args:
        print("  🔄 Using FALLBACK URL (webhook-test)")
        return FALLBACK_URL
    return PRIMARY_URL


def run_single(test_id, url):
    if test_id not in TESTS:
        print(f"  ❌ Unknown test: {test_id}")
        print(f"  Available: {', '.join(sorted(TESTS.keys()))}")
        return
    start = time.time()
    ok = TESTS[test_id]["fn"](url)
    elapsed = time.time() - start
    status = "✅ PASS" if ok else "❌ FAIL"
    print(f"\n  {status} | {test_id} | {elapsed:.1f}s")


def run_all(url):
    print(f"\n🚀 Running ALL {len(TESTS)} tests...")
    passed = 0
    failed = 0
    total_start = time.time()

    for tid in sorted(TESTS.keys()):
        start = time.time()
        ok = TESTS[tid]["fn"](url)
        elapsed = time.time() - start
        if ok:
            passed += 1
        else:
            failed += 1
        status = "✅" if ok else "❌"
        print(f"  {status} {tid} ({elapsed:.1f}s)")

    total = time.time() - total_start
    print(f"\n📊 Results: {passed} passed, {failed} failed, {len(TESTS)} total | {total:.1f}s")


def main():
    print("\n🕵️ Spy Game Webhook Tester")
    print("Type 'help_test' for available commands.\n")

    while True:
        try:
            cmd = input("spy_test> ").strip()
        except (EOFError, KeyboardInterrupt):
            print("\nBye!")
            break

        if not cmd:
            continue

        parts = cmd.split()
        action = parts[0].lower()

        if action in ("quit", "exit", "q"):
            print("Bye!")
            break
        elif action == "help_test":
            print_help()
        elif action == "run" and len(parts) >= 2:
            url = get_url(parts)
            run_single(parts[1], url)
        elif action == "run_all":
            url = get_url(parts)
            run_all(url)
        else:
            print(f"  ❓ Unknown command: {cmd}. Type 'help_test' for help.")


if __name__ == "__main__":
    main()
