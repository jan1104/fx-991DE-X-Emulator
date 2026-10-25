from pathlib import Path
import hashlib
import json
from pypdf import PdfReader
root = Path(__file__).resolve().parents[1]
out = root / 'tmp' / 'pdfs'
out.mkdir(parents=True, exist_ok=True)
manifest = []
for path in sorted((root / 'reference' / 'originals').glob('*.pdf')):
    doc = PdfReader(path)
    text = '\n'.join(f'\n--- PDF-SEITE {i+1} ---\n' + (page.extract_text() or '') for i, page in enumerate(doc.pages))
    (out / (path.stem + '.txt')).write_text(text, encoding='utf-8')
    manifest.append({'file':path.name,'bytes':path.stat().st_size,'sha256':hashlib.sha256(path.read_bytes()).hexdigest(),'pages':len(doc.pages),'metadata':dict(doc.metadata or {})})
(out / 'manifest.json').write_text(json.dumps(manifest,ensure_ascii=False,indent=2),encoding='utf-8')
print(json.dumps(manifest,ensure_ascii=False,indent=2))
