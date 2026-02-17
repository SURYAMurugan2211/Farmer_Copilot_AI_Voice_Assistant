
import urllib.request
import json

url = "http://localhost:8000/api/mobile/text-query"
payload = {
    "text": "What is beekeeping called?",
    "lang": "en"
}
data = json.dumps(payload).encode('utf-8')

req = urllib.request.Request(url, data=data, headers={'Content-Type': 'application/json'})

try:
    with urllib.request.urlopen(req) as response:
        result = json.loads(response.read().decode('utf-8'))
        answer = result.get("answer_text", "")
        print(f"✅ API Success")
        print(f"Answer Length: {len(answer)}")
        print(f"Answer: {answer}")
except Exception as e:
    print(f"❌ API Error: {e}")
