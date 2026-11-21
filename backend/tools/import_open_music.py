#!/usr/bin/env python3
"""Import a bounded CC0 music catalog from Openverse, verifying Freesound source pages."""
import argparse
import hashlib
import json
import os
from pathlib import Path
import re
import subprocess
import tempfile
import time
from urllib.parse import urlencode, urlparse
from urllib.request import Request, urlopen

LICENSE = 'https://creativecommons.org/publicdomain/zero/1.0/'
HEADERS = {'User-Agent': 'MeteMarchaMusicImporter/1.0'}

def fetch(url, limit, hosts):
    if urlparse(url).scheme != 'https' or urlparse(url).hostname not in hosts:
        raise ValueError('Unapproved source URL')
    with urlopen(Request(url, headers=HEADERS), timeout=30) as response:
        if urlparse(response.url).hostname not in hosts or urlparse(response.url).scheme != 'https':
            raise ValueError('Unapproved redirect')
        data = response.read(limit + 1)
        if len(data) > limit:
            raise ValueError('Source exceeds size limit')
        return data

def atomic_json(path, data):
    with tempfile.NamedTemporaryFile(mode='w', dir=path.parent, delete=False, encoding='utf-8') as out:
        json.dump(data, out, ensure_ascii=False, indent=2)
        out.write('\n')
        temporary = out.name
    os.replace(temporary, path)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', type=Path, required=True)
    parser.add_argument('--limit', type=int, default=50)
    parser.add_argument('--queries', nargs='+', default=['music loop', 'electronic beat', 'hip hop beat', 'guitar music', 'ambient music', 'drum loop'])
    args = parser.parse_args()
    if not 1 <= args.limit <= 200:
        parser.error('--limit must be 1–200')
    args.output.mkdir(parents=True, exist_ok=True)
    catalog_path = args.output / 'catalog.json'
    catalog = json.loads(catalog_path.read_text()) if catalog_path.exists() else {'tracks': []}
    tracks = {track['id']: track for track in catalog['tracks']}
    imported = 0
    seen = set()
    for query in args.queries:
        for page in range(1, 4):
            params = urlencode({'q':query, 'license':'cc0', 'page_size':20, 'page':page})
            try:
                result = json.loads(fetch('https://api.openverse.org/v1/audio/?'+params, 4*1024*1024, {'api.openverse.org'}))
            except Exception as exc:
                print(f'Search skipped: {query}: {exc}', flush=True)
                break
            if not result.get('results'):
                break
            for item in result['results']:
                identifier = 'open-' + item['id'].replace('-', '')[:32]
                if identifier in seen:
                    continue
                seen.add(identifier)
                if identifier in tracks:
                    imported += 1
                    if imported >= args.limit:
                        atomic_json(catalog_path, {'tracks': list(tracks.values())})
                        return
                    continue
                if item.get('license') != 'cc0' or item.get('source') != 'freesound' or item.get('duration', 0) < 15000:
                    continue
                try:
                    source = item['foreign_landing_url'].replace('http://', 'https://', 1)
                    html = fetch(source, 2*1024*1024, {'freesound.org', 'www.freesound.org'}).decode('utf-8')
                    if not re.search(r'href=[\"\']https?://creativecommons\.org/publicdomain/zero/1\.0/?[\"\']', html):
                        raise ValueError('CC0 not confirmed on original source')
                    audio = fetch(item['url'], 15*1024*1024, {'cdn.freesound.org'})
                    filename = identifier + '.mp3'
                    path = args.output / filename
                    with tempfile.NamedTemporaryFile(dir=args.output, suffix='.mp3', delete=False) as out:
                        out.write(audio)
                        temp = Path(out.name)
                    try:
                        probe = json.loads(subprocess.check_output(['ffprobe','-v','error','-show_entries','format=duration:stream=codec_type','-of','json',str(temp)],timeout=15))
                        duration = round(float(probe['format']['duration'])*1000)
                        if not any(s.get('codec_type')=='audio' for s in probe['streams']) or not 15000 <= duration <= 600000:
                            raise ValueError('Not a supported music duration')
                        os.replace(temp, path)
                    finally:
                        temp.unlink(missing_ok=True)
                    tracks[identifier] = {'id':identifier,'title':item['title'],'artist':item.get('creator') or 'Autor não informado', 'file':filename,'duration_ms':duration,'license':f'CC0 1.0 | {LICENSE} | Fonte: {source}', 'source_url':source,'license_url':LICENSE,'sha256':hashlib.sha256(audio).hexdigest()}
                    atomic_json(catalog_path, {'tracks':list(tracks.values())})
                    imported += 1
                    print(f'[{imported}/{args.limit}] {item["title"]}', flush=True)
                    if imported >= args.limit:
                        return
                except Exception as exc:
                    print(f'Skipped {item["title"]}: {exc}', flush=True)
                time.sleep(0.3)
            time.sleep(1)
    print(f'Imported {imported} matching tracks; catalog contains {len(tracks)} tracks.', flush=True)
    if not imported:
        raise SystemExit(1)

if __name__ == '__main__':
    main()
