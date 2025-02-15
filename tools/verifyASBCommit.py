#!/bin/env python3
"""
Get the latest commit from the current directory which should be the LineageOS security string update.
Extract all fixes from the commit message and compare them against those listed on the corresponding
Google ASB page.
Error on missing and warn for superflous/unexpected fixes in the commit message.
For each fix in the commit message print the relevant patch (Repo and Summary).
"""

import os
import requests
import re
import subprocess
from bs4 import BeautifulSoup

def get_asb_commit_data(folder):
    """Extract data and fixes from latest commit in the folder

    Returns a tuple of the ASB date from the commit title and
    a list of fixes as pairs of CVE and Android reference.
    """
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

    fixes = []
    for line in lines[1:]:
        line = line.strip()
        if line.startswith("CVE-"):
            cve, ref, _ = line.split(maxsplit=2)
            if not ref.startswith('A-'):
                raise ValueError(f"Unexpected line {line}")
            fixes.append((cve, ref))
    
    return asb_date, fixes

def get_patch_data(url):
    """Get repository and commit message from a patch URL"""
    response = requests.get(url)
    if response.status_code != 200:
        raise RuntimeError(f"Failed to fetch URL: {url}")
    soup = BeautifulSoup(response.text, 'html.parser')
    repo = [s for s in soup.find('div', class_='Breadcrumbs').stripped_strings if s and s != '/']
    msg = next(soup.find('pre', class_='MetadataMessage').stripped_strings).split('\n', 1)[0]
    return '/'.join(repo[1:-1]), msg

    
def fetch_and_extract_asb(asb_date):
    """Parse the Google ASB page of the given date.

    Return mapping of CVE IDs to pairs of the Android reference (A-1234) and the links to the patches.
    """
    m = re.match(r'(\d{4}-\d{2})-\d{2}', asb_date)
    url = f"https://source.android.com/docs/security/bulletin/{m[1]}-01"
    response = requests.get(url)
    if response.status_code != 200:
        raise RuntimeError(f"Failed to fetch URL: {url}")
    
    soup = BeautifulSoup(response.text, 'html.parser')
    
    def is_start_el(tag):
        if tag.name != 'h2':
            return False
        # Make whitespace uniform
        txt = re.sub(r'\s+', ' ', tag.get_text())
        return tag and 'security patch level vulnerability details' in txt
    start_section = soup.find(is_start_el)
    if not start_section:
        raise RuntimeError("Start section not found.")

    def is_end_el(tag):
        if tag.name not in ('h2', 'h3'):
            return False
        txt = re.sub(r'\s+', ' ', tag.get_text())
        return txt in ('Common questions and answers', 'Kernel', 'Kernel components')
    end_element = soup.find(is_end_el)
    if not end_element:
        raise RuntimeError("End element not found.")
    
    data = {}
    current_tag = start_section.find_next()
    
    while current_tag and current_tag != end_element:
        if current_tag.name == 'table':
            for row in current_tag('tr')[1:]:  # Skip header row
                cells = row('td')
                if len(cells) >= 2:
                    cve_id = cells[0].get_text(strip=True)
                    if cve_id in data:
                        raise ValueError(f'Duplicate CVE {cve_id}')
                    references = [a.get_text(strip=True) for a in cells[1](string=re.compile(r'A-\d+'))]
                    if len(references) > 1:
                        raise ValueError(f' Found multiple bugs for {cve_id}: ' + ', '.join(references))
                    links = [a for a in cells[1]('a', href=True)]
                    # Skip the non-public patches
                    if len(links) == 1 and links[0].get_text() == '*':
                        continue
                    # Rows that are not patches for CVE should not have a reference or link
                    if not cve_id.startswith('CVE-'):
                        if references:
                            raise ValueError(f'Unexpected references {", ".join(references)} for non-CVE {cve_id}')
                        if links:
                            raise ValueError(f'Found {len(links)} for non-CVE {cve_id}')
                        continue
                    # Skip Qualcom CRs
                    if any(a.get_text().startswith('QC-CR#') for a in links):
                        continue
                    data[cve_id] = (references[0], [a['href'] for a in links])
        current_tag = current_tag.find_next()
    if current_tag != end_element:
        print("WARNING: Did not found the end element!")
    
    return data


def format_patches(patches):
    """Format list of (CVE, Android reference) tuples"""
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
    asb_date, fixes = get_asb_commit_data(asb_folder)
    print(f'ASB {asb_date}')
    asb_data = fetch_and_extract_asb(asb_date)
    commit_patches = set(fixes)
    expected_patches = set((cve_id, reference) for cve_id, (reference, _) in asb_data.items())
    missing_patches = expected_patches - commit_patches
    if missing_patches:
        raise ValueError(f"Missing patches: {', '.join(format_patches(missing_patches))}")
    print(f"All {len(expected_patches)} patches accounted for!")
    additional_patches = commit_patches - expected_patches
    if additional_patches:
        print(f"Additional patches: {', '.join(format_patches(additional_patches))}")

    for cve_id, ref in fixes:
        commits = []
        for link in asb_data.get(cve_id, (None,[]))[1]:
            if 'android.googlesource.com' in link:
                repo, msg = get_patch_data(link)
                commits.append(f'{repo}:\t{msg}')
            else:
                commits.append(link)
        print(f'{cve_id} ({ref}):\n\t' + '\n\t'.join(commits))


if __name__ == "__main__":
    main()
