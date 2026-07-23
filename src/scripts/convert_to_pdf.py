"""Convert all DOCX/PPTX to PDF using LibreOffice."""
import shutil, subprocess
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent.parent
SRC = PROJECT / 'src' / 'data_raw' / 'documents'
OUT = PROJECT / 'app_assets' / 'pdf'

# Try to find soffice in PATH first, then fall back to common locations
SOFFICE = shutil.which('soffice')
if SOFFICE is None:
    candidates = [
        r'C:\Program Files\LibreOffice\program\soffice.exe',
        r'C:\Program Files (x86)\LibreOffice\program\soffice.exe',
        '/usr/bin/libreoffice',
        '/usr/local/bin/libreoffice',
    ]
    SOFFICE = next((p for p in candidates if Path(p).exists()), None)

if SOFFICE is None:
    print('ERROR: LibreOffice not found. Install it or set SOFFICE env var.')
    exit(1)

converted, skipped = 0, 0

for f in sorted(SRC.rglob('*')):
    if f.suffix.lower() not in ('.docx', '.pptx'):
        continue
    rel = f.relative_to(SRC).parent
    dest_dir = OUT / rel
    dest_dir.mkdir(parents=True, exist_ok=True)
    pdf = dest_dir / f'{f.stem}.pdf'
    if pdf.exists():
        skipped += 1
        continue
    print(f'  {f.relative_to(PROJECT)} ... ', end='', flush=True)
    r = subprocess.run([
        SOFFICE, '--headless', '--convert-to', 'pdf',
        '--outdir', str(dest_dir), str(f.resolve())
    ], capture_output=True, text=True, timeout=300)
    if r.returncode == 0:
        print('OK')
        converted += 1
    else:
        print(f'FAIL: {r.stderr[:100] if r.stderr else r.stdout[:100]}')

print(f'\nConverted: {converted}, Skipped: {skipped}')
