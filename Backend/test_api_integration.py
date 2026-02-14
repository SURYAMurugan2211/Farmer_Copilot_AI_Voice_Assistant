
import requests
import json
import time

BASE_URL = "http://localhost:8000"

def log(msg):
    try:
        print(msg)
    except UnicodeEncodeError:
        print(msg.encode("ascii", "replace").decode())
    with open("integration_logs.txt", "a", encoding="utf-8") as f:
        f.write(msg + "\n")

def test_integration():
    log("="*60)
    log("🛠️ INTEGRATION TEST: Hitting Live Server @ localhost:8000")
    log("="*60)

    # 1. Check Health
    try:
        log("\n[1/5] Checking Health Endpoint...")
        resp = requests.get(f"{BASE_URL}/health")
        if resp.status_code == 200:
            log(f"✅ Healthy! Version: {resp.json().get('version')}")
        else:
            log(f"❌ Failed! Status: {resp.status_code}")
            log(resp.text)
            return
    except requests.exceptions.ConnectionError:
        log("❌ Connection Error! Is the server running?")
        return

    # 2. Text Query Test
    log("\n[2/5] Testing Text Query Endpoint (/api/mobile/text-query)...")
    payload = {
        "text": "How do I control pests in tomato?",
        "lang": "en",
        "phone_number": "9999900000"  # Test number
    }
    
    start = time.time()
    resp = requests.post(f"{BASE_URL}/api/mobile/text-query", json=payload)
    end = time.time()
    
    user_id = None
    if resp.status_code == 200:
        data = resp.json()
        log(f"✅ Success! ({end-start:.2f}s)")
        log(f"   Intent: {data.get('intent', {}).get('intent')}")
        log(f"   Answer: {data.get('answer_text')[:100]}...")
        log(f"   Audio URL: {data.get('audio_url')}")
        user_id = data.get("user_id")
    else:
        log(f"❌ Failed! Status: {resp.status_code}")
        log(resp.text)

    if not user_id:
        log("⚠️ No User ID returned, skipping history/stats tests.")
        return

    # 3. History Test
    log(f"\n[3/5] Testing History Endpoint (/api/mobile/history/{user_id})...")
    resp = requests.get(f"{BASE_URL}/api/mobile/history/{user_id}")
    if resp.status_code == 200:
        history = resp.json()
        count = history.get('count', 0)
        log(f"✅ Success! Found {count} history entries.")
        if count > 0:
            first = history['history'][0]
            log(f"   Latest: '{first.get('original_text')}' -> '{first.get('response_text')[:50]}...'")
    else:
        log(f"❌ Failed! Status: {resp.status_code}")

    # 4. Stats Test
    log(f"\n[4/5] Testing Stats Endpoint (/api/mobile/stats/{user_id})...")
    resp = requests.get(f"{BASE_URL}/api/mobile/stats/{user_id}")
    if resp.status_code == 200:
        stats = resp.json().get('stats', {})
        log(f"✅ Success! Stats: {stats}")
    else:
        log(f"❌ Failed! Status: {resp.status_code}")

    # 5. Mobile Health Test
    log("\n[5/5] Testing Mobile Health Endpoint (/api/mobile/health-mobile)...")
    resp = requests.get(f"{BASE_URL}/api/mobile/health-mobile")
    if resp.status_code == 200:
        log(f"✅ Success! Services: {resp.json().get('services')}")
    else:
        log(f"❌ Failed! Status: {resp.status_code}")

    log("\n" + "="*60)
    log("🏁 INTEGRATION TEST COMPLETE")
    log("="*60)

if __name__ == "__main__":
    test_integration()
