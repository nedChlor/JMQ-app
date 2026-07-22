#!/usr/bin/env python3
"""
Build search infrastructure for the app.
Adds:
1. ecu_categories table — ECU → category mapping for fast JOINs
2. dtc_document_links — exact code matches in document text (when available)
3. Search view for the Flutter app
"""
import sqlite3, re, time
from collections import defaultdict

DB_PATH = r'C:\Users\nedch\Documents\JMQ App\app_assets\db\jmq_service_manual.db'

conn = sqlite3.connect(DB_PATH)
conn.execute('PRAGMA synchronous=OFF')
conn.execute('PRAGMA journal_mode=MEMORY')

# ============================================================
# 1. ECU → Category mapping table
# ============================================================
conn.execute('DROP TABLE IF EXISTS ecu_categories')
conn.execute('''
    CREATE TABLE ecu_categories (
        ecu TEXT NOT NULL,
        category_id INTEGER NOT NULL,
        PRIMARY KEY (ecu, category_id)
    )
''')

ECU_CATS = {
    'EMS': [1, 2, 3], 'TCU': [4, 5],
    'ESP': [6, 7], 'ESC': [6, 7], 'ABS': [6, 7], 'EPS': [6, 7],
    'BCM': [7, 8, 10, 11, 12], 'SRS': [7],
    'TPMS': [12], 'HVAC': [7, 8], 'AVM': [11], 'ICM': [7, 8],
    'PDC': [7, 8], 'PEPS': [7], 'ESCL': [7],
    'FPCM': [7], 'APM': [8, 10], 'BSD': [7],
    'ACC': [11], 'APA': [11], 'MPC': [11], 'MP5': [13],
    'TBOX': [8, 10], 'GW': [8], 'AEB': [7], 'EPB': [7],
    'VCU': [8, 10], 'LBC': [8, 10], 'SJB': [7],
    'DCM': [5], 'ECAS': [6], 'ESS': [8], 'RAM': [8],
    'AWD': [6], 'LDWS': [7], 'IMMO': [7], 'ACM': [7], 'GSM': [7],
    'CFP': [7], 'ACFP': [7], 'SLC': [7], 'PCU': [8],
    'PLG': [11], 'AMB': [11], 'WLC': [11], 'S2': [6, 7, 8],
    'J4': [6, 7, 8], 'T8': [6, 8], 'IC5': [8, 10],
    'E10X': [8, 10], 'E40X': [8, 10],
}

for ecu, cats in ECU_CATS.items():
    for cat_id in cats:
        conn.execute("INSERT INTO ecu_categories VALUES (?, ?)", (ecu, cat_id))

# Add default mapping for any unknown ECU
conn.execute("INSERT OR IGNORE INTO ecu_categories VALUES ('DEFAULT', 6)")
conn.execute("INSERT OR IGNORE INTO ecu_categories VALUES ('DEFAULT', 7)")
conn.execute("INSERT OR IGNORE INTO ecu_categories VALUES ('DEFAULT', 8)")
conn.commit()

print(f'ECU categories: {conn.execute("SELECT COUNT(*) FROM ecu_categories").fetchone()[0]} mappings')

# ============================================================
# 2. Rebuild dtc_document_links with regex approach
# ============================================================
conn.execute('DROP TABLE IF EXISTS dtc_document_links')
conn.execute('''
    CREATE TABLE dtc_document_links (
        id INTEGER PRIMARY KEY,
        code TEXT NOT NULL,
        vehicle_model TEXT NOT NULL,
        document_id INTEGER NOT NULL,
        snippet_text TEXT DEFAULT '',
        FOREIGN KEY (document_id) REFERENCES documents(id)
    )
''')

rows = conn.execute("SELECT code, vehicle_model, ecu FROM dtc_codes").fetchall()
code_map = defaultdict(list)
for code, model, ecu in rows:
    code_map[code.upper()].append((model, ecu))

unique_codes = sorted(code_map.keys(), key=len, reverse=True)
code_pattern = re.compile(r'\b(' + '|'.join(re.escape(c) for c in unique_codes) + r')\b')

docs = conn.execute("SELECT id, category_id, content_text FROM documents").fetchall()
print(f'Scanning {len(docs)} documents for DTC codes...')

start = time.time()
link_id = 0
for doc_id, cat_id, text in docs:
    if not text:
        continue
    seen = set()
    for m in code_pattern.finditer(text):
        code = m.group(1).upper()
        for model, ecu in code_map[code]:
            cats = set(ECU_CATS.get(ecu, ECU_CATS.get('DEFAULT', [6, 7, 8])))
            if cat_id not in cats:
                continue
            key = (code, model)
            if key in seen:
                continue
            seen.add(key)
            link_id += 1
            s = max(0, m.start() - 80)
            e = min(len(text), m.end() + 80)
            snip = ('...' if s > 0 else '') + text[s:e].replace('\n', ' ') + ('...' if e < len(text) else '')
            conn.execute(
                "INSERT INTO dtc_document_links (id, code, vehicle_model, document_id, snippet_text) "
                "VALUES (?, ?, ?, ?, ?)",
                (link_id, code, model, doc_id, snip)
            )

conn.commit()
elapsed = time.time() - start
exact_links = conn.execute('SELECT COUNT(*) FROM dtc_document_links').fetchone()[0]
print(f'Exact matches built in {elapsed:.1f}s: {exact_links} links')

# ============================================================
# 3. Create search view
# ============================================================
conn.execute('DROP VIEW IF EXISTS dtc_search')
conn.execute('''
    CREATE VIEW dtc_search AS
    SELECT
        c.code,
        c.vehicle_model,
        c.ecu,
        c.meaning_en,
        c.meaning_ru,
        c.dtc_type,
        dl.document_id,
        dl.snippet_text AS doc_snippet,
        d.title_ru AS doc_title,
        d.category_id,
        ec.category_id AS matched_category
    FROM dtc_codes c
    LEFT JOIN ecu_categories ec ON ec.ecu = c.ecu
    LEFT JOIN dtc_document_links dl ON dl.code = c.code AND dl.vehicle_model = c.vehicle_model
    LEFT JOIN documents d ON d.id = dl.document_id
''')

# ============================================================
# 4. Indexes for speed
# ============================================================
conn.execute('CREATE INDEX IF NOT EXISTS idx_dcl_lookup ON dtc_document_links(code, vehicle_model)')
conn.execute('CREATE INDEX IF NOT EXISTS idx_dcl_doc ON dtc_document_links(document_id)')
conn.execute('CREATE INDEX IF NOT EXISTS idx_ecu_cats_ecu ON ecu_categories(ecu)')

# ============================================================
# 5. Document → Model mapping
# ============================================================
conn.execute('DROP TABLE IF EXISTS document_models')
conn.execute('''
    CREATE TABLE document_models (
        document_id INTEGER NOT NULL,
        vehicle_model TEXT NOT NULL,
        PRIMARY KEY (document_id, vehicle_model)
    )
''')

# All 21 documents belong to J7 (the only model with documents for MVP)
doc_ids = [r[0] for r in conn.execute('SELECT id FROM documents')]
for did in doc_ids:
    conn.execute('INSERT INTO document_models VALUES (?, ?)', (did, 'J7'))

print(f'Document models: {len(doc_ids)} documents for J7')
conn.commit()

# ============================================================
# 6. Example queries (verify)
# ============================================================
print('\n=== Search demo ===')
print('\nScenario: User enters P0765 + J7')

# Step 1: Lookup DTC
dtc = conn.execute(
    "SELECT code, ecu, meaning_en, meaning_ru FROM dtc_codes WHERE code=? AND vehicle_model=?",
    ('P0765', 'J7')
).fetchall()
if dtc:
    code, ecu, en, ru = dtc[0]
    print(f'  DTC: {code} | ECU: {ecu}')
    print(f'  EN:  {en}')
    print(f'  RU:  {ru}')

    # Step 2: Get relevant categories
    cats = conn.execute("SELECT category_id FROM ecu_categories WHERE ecu=?", (ecu,)).fetchall()
    cat_ids = [str(c[0]) for c in cats]
    print(f'  Categories: {cat_ids}')

    # Step 3: Extract keywords for FTS5
    words = [w for w in re.findall(r'[A-Za-z]{4,}', en or '') 
             if w.lower() not in {'this','that','with','from','the','and','for','not','has','have','been','were','was','are','will','can','but','its','his','her','also','than','then','circuit','signal','error','fault','failure','open','short','range','high','low','sensor','module','system','value','mode'}]
    keywords = words[:5]
    fts_query = f'{code} OR {" OR ".join(keywords)}' if keywords else code
    print(f'  FTS5 query: {fts_query}')

    # Step 4: FTS5 search in relevant documents
    placeholders = ','.join('?' * len(cat_ids))
    results = conn.execute(
        f"SELECT d.title_ru, snippet(documents_fts, 2, '<<<', '>>>', '...', 35), rank "
        f"FROM documents_fts "
        f"JOIN documents d ON d.id = documents_fts.rowid "
        f"WHERE documents_fts MATCH ? AND d.category_id IN ({placeholders}) "
        f"ORDER BY rank LIMIT 5",
        [fts_query] + cat_ids
    ).fetchall()

    if results:
        print(f'  Found {len(results)} relevant sections:')
        for title, snip, rank in results:
            print(f'    [{rank:.0f}] {title[:50]}')
            print(f'          ...{snip[:70]}...')
    else:
        print('  No FTS5 results. Broader search...')
        # Broader: search without code, just keywords
        if keywords:
            results = conn.execute(
                f"SELECT d.title_ru, snippet(documents_fts, 2, '<<<', '>>>', '...', 35), rank "
                f"FROM documents_fts "
                f"JOIN documents d ON d.id = documents_fts.rowid "
                f"WHERE documents_fts MATCH ? AND d.category_id IN ({placeholders}) "
                f"ORDER BY rank LIMIT 3",
                [' OR '.join(keywords)] + cat_ids
            ).fetchall()
            if results:
                print(f'  Found via broader search:')
                for title, snip, rank in results:
                    print(f'    [{rank:.0f}] {title[:50]}')
                    print(f'          ...{snip[:70]}...')

# Also test exact match
print('\n=== Exact match example (code appears in text) ===')
exact = conn.execute(
    "SELECT dl.code, d.title_ru, dl.snippet_text FROM dtc_document_links dl "
    "JOIN documents d ON d.id = dl.document_id LIMIT 3"
).fetchall()
for code, title, snip in exact:
    print(f'  [{code}] {title[:40]}')
    print(f'    ...{snip[:60]}...')

conn.close()
print('\nDone!')
