#!/usr/bin/env python3
"""Validate a filled mapping CSV; write the shared catalog only with --write."""
import argparse
import csv
import json
import re
from datetime import date
from pathlib import Path
from urllib.parse import urlparse, parse_qs

root = Path(__file__).resolve().parents[1]
parser = argparse.ArgumentParser(description=__doc__)
parser.add_argument('csv', type=Path)
parser.add_argument('--write', action='store_true')
args = parser.parse_args()
path = root / 'backend/internal/exercisecatalog/catalog.json'
catalog = json.loads(path.read_text())
entries = {e['id']: e for e in catalog['exercises']}
seen = set()
count = 0
for row in csv.DictReader(args.csv.open(encoding='utf-8-sig')):
    identity = row['id']
    if identity not in entries or identity in seen:
        raise SystemExit(f'ID desconhecido ou repetido: {identity}')
    seen.add(identity)
    entry = entries[identity]
    if row['exercise'] != entry['name'] or row['equipment'] != entry['equipment']:
        raise SystemExit(f'Nome/equipamento alterado: {identity}')
    raw = row['youtube_url'].strip()
    if not raw:
        continue  # An empty cell never deletes an existing reference.
    uri = urlparse(raw)
    if uri.scheme != 'https' or uri.username or uri.password or uri.port:
        raise SystemExit(f'URL inválida: {identity}')
    parts = uri.path.strip('/').split('/')
    video_id = None
    if uri.hostname == 'youtu.be':
        video_id = parts[0]
    elif uri.hostname in ('youtube.com', 'www.youtube.com', 'm.youtube.com'):
        if uri.path == '/watch':
            video_id = parse_qs(uri.query).get('v', [''])[0]
        elif len(parts) == 2 and parts[0] in ('shorts', 'embed'):
            video_id = parts[1]
    if not video_id or not re.fullmatch(r'[\w-]{11}', video_id, flags=re.ASCII):
        raise SystemExit(f'Link precisa apontar para um vídeo do YouTube: {identity}')
    if not row['language'].strip() or not row['channel'].strip():
        raise SystemExit(f'Informe idioma e canal: {identity}')
    url = f'https://www.youtube.com/watch?v={video_id}'
    if entry.get('video') and entry['video']['url'] == url:
        continue
    entry['video'] = dict(url=url, language=row['language'].strip(),
                          channel=row['channel'].strip(), checked_at=date.today().isoformat(),
                          check='Mapeamento fornecido; conferir conteúdo e incorporação antes de publicar')
    count += 1
if args.write and count:
    catalog['version'] += 1
    path.write_text(json.dumps(catalog, ensure_ascii=False, indent=2) + '\n')
print(f'{count} referências novas; ' + ('catálogo atualizado.' if args.write else 'validação concluída, sem alterar o catálogo.'))
