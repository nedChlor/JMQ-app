"""Convert all DOCX/PPTX to PDF using LibreOffice."""
import subprocess
from pathlib import Path

PROJECT = Path(__file__).resolve().parent.parent.parent
SRC = PROJECT / 'src' / 'data_raw' / 'documents'
OUT = PROJECT / 'app_assets' / 'pdf'
SOFFICE = r'C:\Program Files\LibreOffice\program\soffice.exe'

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
