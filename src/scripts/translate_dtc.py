import sqlite3, re, json, time, os
from pathlib import Path
import urllib.request, urllib.error

PROJECT = Path(__file__).resolve().parent.parent.parent
DB_PATH = PROJECT / 'app_assets' / 'db' / 'jmq_service_manual.db'
CJK = re.compile(r'[\u4e00-\u9fff]')

API_KEY = os.environ.get('DEEPSEEK_API_KEY', '')
API_URL = 'https://api.deepseek.com/v1/chat/completions'

conn = sqlite3.connect(str(DB_PATH))
conn.isolation_level = None

batch_en = []
batch_cn = []

for r in conn.execute("SELECT id, code, COALESCE(meaning_en,''), COALESCE(meaning_ru,'') FROM dtc_codes"):
    did, code, en, ru = r
    if not ru and en and en != '/':
        batch_en.append((did, code, en))
    elif CJK.search(ru):
        batch_cn.append((did, code, ru))

total = len(batch_en) + len(batch_cn)
print(f'EN->RU: {len(batch_en)}, ZH->RU: {len(batch_cn)}, Total: {total}')
if not total:
    print('Nothing to translate.')
    conn.close()
    exit()

def call_deepseek(prompt, response_prefix=''):
    body = json.dumps({
        'model': 'deepseek-chat',
        'messages': [
            {'role': 'system', 'content': 'You are an automotive DTC code translator. Return ONLY a JSON array of translations in the same order as input. Each item: {"code": "...", "ru": "..."}'},
            {'role': 'user', 'content': prompt},
        ],
        'temperature': 0.1,
        'max_tokens': 4096,
    }).encode('utf-8')
    req = urllib.request.Request(API_URL, data=body, headers={
        'Content-Type': 'application/json',
        'Authorization': f'Bearer {API_KEY}',
    })
    try:
        with urllib.request.urlopen(req, timeout=60) as resp:
            data = json.loads(resp.read().decode('utf-8'))
            return data['choices'][0]['message']['content']
    except urllib.error.HTTPError as e:
        print(f'  API Error {e.code}: {e.read().decode()[:200]}')
        return None
    except Exception as e:
        print(f'  Error: {e}')
        return None

def translate_batch(items, source_lang, label):
    results = {}
    n = len(items)
    BATCH = 30
    for start in range(0, n, BATCH):
        batch = items[start:start+BATCH]
        lines = [json.dumps({'code': c, 'text': t}, ensure_ascii=False) for _, c, t in batch]
        prompt = f'Translate these DTC diagnostic codes from {source_lang} to Russian. Make it clear for an auto mechanic:\n' + '\n'.join(lines)
        resp = call_deepseek(prompt)
        if resp:
            resp = resp.strip()
            if resp.startswith('```'): resp = resp.strip('`').strip()
            if resp.startswith('json'): resp = resp[4:].strip()
            try:
                parsed = json.loads(resp)
                for item in parsed:
                    if isinstance(item, dict) and 'code' in item and 'ru' in item:
                        results[item['code']] = item['ru']
            except:
                print(f'  Failed to parse response, trying regex fallback')
                for c, t in [(c, t) for _, c, t in batch]:
                    results[c] = t
        else:
            for _, c, t in batch:
                results[c] = t
        done = min(start + BATCH, n)
        print(f'  {label}: {done}/{n}', end='\r')
        time.sleep(0.5)
    print(f'  {label}: {n}/{n}')
    return results

print('Translating EN->RU...')
ru_en = translate_batch(batch_en, 'English', 'EN')

print('Translating ZH->RU...')
ru_cn = translate_batch(batch_cn, 'Chinese', 'ZH')

updated = 0
for did, code, _ in batch_en:
    ru = ru_en.get(code, '')
    if ru and ru != code:
        conn.execute("UPDATE dtc_codes SET meaning_ru = ? WHERE id = ?", (ru, did))
        updated += 1

for did, code, _ in batch_cn:
    ru = ru_cn.get(code, '')
    if ru and ru != code:
        conn.execute("UPDATE dtc_codes SET meaning_ru = ? WHERE id = ?", (ru, did))
        updated += 1

conn.commit()
conn.close()
print(f'\nDone! Updated: {updated} codes.')
