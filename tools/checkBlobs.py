#!/usr/bin/env python

import argparse
import hashlib
import os
import pathlib
from typing import List, Dict

def get_duplicates(elements):
    seen = set()
    return [e for e in elements if e in seen or seen.add(e)]

parser = argparse.ArgumentParser(
                    prog = 'CheckBlobs',
                    description = 'Check Blob checksums and gitignore')

parser.add_argument('--vendordir', type=pathlib.Path, required=True, nargs='+')
parser.add_argument('--no-gitignore', dest='gitignore', action='store_false')
parser.add_argument('--print-gitignore', action='store_true')
parser.add_argument('filelists', type=pathlib.Path, nargs='+')

args = parser.parse_args()

fixed_files : Dict[str, List[str]] = dict()
copied_files : List[str] = []

for p in args.filelists:
    with open(p, 'r') as f:
        for line in f:
            line = line.strip()
            if not line or line.startswith('#'):
                continue
            parts = line.lstrip('-').split('|')
            filename = parts[0].split(':')[-1]
            if len(parts) == 1:
                copied_files.append(filename)
            else:
                assert filename not in fixed_files
                fixed_files[filename] = parts[1:]

copied_and_pinned_files = [f for f in copied_files if f in fixed_files]
if copied_and_pinned_files:
    raise RuntimeError('Files copied AND pinned:\n\t' + '\n\t'.join(sorted(set(copied_and_pinned_files))))

errors : List[str] = []
def append_error_files(title, files):
    if files:
        files = set(files)
        errors.append('%s (%d):\n\t' % (title, len(files)) +
                    '\n\t'.join(sorted(files, key=str.casefold)))

append_error_files('Duplicate files', get_duplicates(copied_files))

prop_dirs: List[pathlib.Path] = [d / 'proprietary' for d in args.vendordir]

missing_files : List[str] = []
checksum_errors : List[str]  = []

for file, checksums in fixed_files.items():
    file_paths = [f for f in (prop_dir / file for prop_dir in prop_dirs) if f.exists()]
    if file_paths:
        shasum = hashlib.sha1(file_paths[0].read_bytes()).hexdigest()
        if shasum not in checksums:
            print(f'File {file}: {shasum}')
            checksum_errors.append(file)
    else:
        missing_files.append(file)

append_error_files('Missing files', missing_files)
append_error_files('Wrong checksum', checksum_errors)

if args.gitignore:
    # Ignore only copied files

    vendor_dir = args.vendordir[0]
    gitignore_is = [f for f in (vendor_dir / '.gitignore').read_text().split('\n') if f.startswith('proprietary')]
    # Exact duplicates
    duplicate_ignores = get_duplicates(gitignore_is)
    # Files already excluded by folder
    for p in gitignore_is:
        if p.endswith('/'):
            duplicate_ignores.extend(f for f in gitignore_is if f != p and f.startswith(p))
    append_error_files('Duplicate GitIgnores', duplicate_ignores)
    # Continue only with non-duplicates
    gitignore_is = set(gitignore_is)

    copied_files_prop = set(os.path.join('proprietary', f) for f in copied_files)

    # Find copied files missing in the current git ignore
    # a) by exact path
    missing_ignores = copied_files_prop - gitignore_is
    # b) by directory
    for p in gitignore_is:
        if p.endswith('/'):
            missing_ignores = [f for f in missing_ignores if not f.startswith(p)]

    append_error_files('Missing GitIgnores', missing_ignores)
 
    # Any entry not matching a copied file or a folder with a copied file
    wrong_ignores = set(p for p in gitignore_is
        if p not in copied_files_prop and
            (not p.endswith('/') or not any(f.startswith(p) for f in copied_files_prop))
    )
    append_error_files('Superflous GitIgnores', wrong_ignores)
    
    # Any entry matching a pinned file
    pinned_ignores = set(p for p in gitignore_is if p in fixed_files)
    # Any folder entry matching any pinned file
    pinned_ignores.update(p for p in gitignore_is if p.endswith('/')
                          and any(os.path.join('proprietary', f).startswith(p) for f in fixed_files.keys()))
    append_error_files('Wrong GitIgnores (pinned files)', pinned_ignores)

    wrong_ignores.update(pinned_ignores)
    append_error_files('All wrong GitIgnores', list(wrong_ignores) + duplicate_ignores) 

    if args.print_gitignore and (duplicate_ignores or missing_ignores or wrong_ignores):
        # Duplicates are already ignored
        gitignore = [f for f in gitignore_is if f not in wrong_ignores]
        gitignore.extend(missing_ignores)
        print("New .gitignore:")
        print('\n'.join(sorted(gitignore, key=str.casefold)))
        if errors:
            raise RuntimeError("%d errors" % len(errors))

if errors:
    raise RuntimeError('\n'.join(errors))
