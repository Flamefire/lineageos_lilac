#!/bin/env python3

import os
import requests
import re
import subprocess
from bs4 import BeautifulSoup

def get_asb_commit_data(folder):
    try:
        result = subprocess.run(
            ['git', '-C', folder, 'log', '-1', '--pretty=format:%s%n%b'],
            capture_output=True, text=True, check=True
        )
    except subprocess.CalledProcessError as e:
        raise ValueError("Error: Not a git repository or no commits found.") from e
    lines = result.stdout.strip().split('\n')
    m = re.match(r'Bump Security String to (.*)', lines[0])
    if not m:
        raise ValueError(f"Not an ASB commit: {lines[0]}")
    asb_date = m[1]

    patches = []
    for line in lines[1:]:
        line = line.strip()
        if line.startswith("CVE-"):
            cve, ref, _ = line.split(maxsplit=2)
            if not ref.startswith('A-'):
                raise ValueError(f"Unexpected line {line}")
            patches.append((cve, ref))
    
    return asb_date, patches

def get_patch_data(url):
    response = requests.get(url)
    if response.status_code != 200:
        raise RuntimeError(f"Failed to fetch URL: {url}")
    soup = BeautifulSoup(response.text, 'html.parser')
    repo = [s for s in soup.find('div', class_='Breadcrumbs').stripped_strings if s and s != '/']
    msg = next(soup.find('pre', class_='MetadataMessage').stripped_strings).split('\n', 1)[0]
    return '/'.join(repo[1:-1]), msg

    
def fetch_and_extract_asb(asb_date):
    m = re.match(r'(\d{4}-\d{2})-\d{2}', asb_date)
    url = f"https://source.android.com/docs/security/bulletin/{m[1]}-01"
    response = requests.get(url)
    if response.status_code != 200:
        raise RuntimeError(f"Failed to fetch URL: {url}")
    
    soup = BeautifulSoup(response.text, 'html.parser')
    
    framework_section = soup.find('h3', {'id': 'Framework'})
    if not framework_section:
        print("Framework section not found.")
        return []
    
    data = {}
    current_tag = framework_section.find_next()
    
    while current_tag and (not (current_tag.name == 'h3' and current_tag.get('id') == 'Google-Play-system-updates')):
        if current_tag.name == 'table':
            for row in current_tag('tr')[1:]:  # Skip header row
                cells = row('td')
                if len(cells) >= 2:
                    cve_id = cells[0].get_text(strip=True)
                    references = [a.get_text(strip=True) for a in cells[1](string=re.compile(r'A-\d+'))]
                    if len(references) > 1:
                        raise ValueError(f' Found multiple bugs for {cve_id}: ' + ', '.join(references))
                    links = [a['href'] for a in cells[1]('a', href=True)]
                    if cve_id in data:
                        raise ValueError(f'Duplicate CVE {cve_id}')
                    data[cve_id] = (references[0], links)
        current_tag = current_tag.find_next()
    
    return data


def format_patches(patches):
    return [f'({cve}: {ref})' for cve, ref in sorted(patches)]


def main():
    root_folder = os.getcwd()
    while True:
        asb_folder = os.path.join(root_folder, 'build', 'make')
        if os.path.isdir(asb_folder):
            break
        parent_folder = os.path.dirname(root_folder)
        if parent_folder == root_folder:
            raise ValueError('Did not found repo root')
        root_folder = parent_folder
    asb_date, patches = get_asb_commit_data(asb_folder)
    asb_data = fetch_and_extract_asb(asb_date)
    commit_patches = set(patches)
    expected_patches = set((cve_id, references) for cve_id, (references, _) in asb_data.items())
    missing_patches = expected_patches - commit_patches
    if missing_patches:
        raise ValueError(f"Missing patches: {', '.join(format_patches(missing_patches))}")
    print("All patches accounted for!")
    additional_patches = commit_patches - expected_patches
    if additional_patches:
        print(f"Additional patches: {', '.join(format_patches(additional_patches))}")

    for cve_id, _ in patches:
        commits = []
        for link in asb_data.get(cve_id, (None,[]))[1]:
            if 'android.googlesource.com' in link:
                repo, msg = get_patch_data(link)
                commits.append(f'{repo}:\t{msg}')
            else:
                commits.append(link)
        print(f'{cve_id}:\n\t' + '\n\t'.join(commits))


if __name__ == "__main__":
    s = get_patch_data('https://android.googlesource.com/platform/packages/modules/Bluetooth/+/bfe316cf9f026d5b48bcfb2f457685b537baa9a3')
    main()