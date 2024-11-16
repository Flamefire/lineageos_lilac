#!/usr/bin/env python

import argparse
import pathlib
from typing import Tuple, List, Dict

parser = argparse.ArgumentParser(
                    prog = 'Get commit order',
                    description = 'Sort commits')

parser.add_argument('--target-log', type=pathlib.Path, required=True, help='git onelinelog of target commits')
parser.add_argument('--src-log', type=pathlib.Path, required=True, help='git onelinelog of source commits (the ones to reorder')

class MyProgramArgs(argparse.Namespace):
    target_log: pathlib.Path
    src_log: pathlib.Path

args : MyProgramArgs = parser.parse_args()

def get_duplicates(elements: List) -> List:
    seen = set()
    return [e for e in elements if e in seen or seen.add(e)]

def read_log(path: pathlib.Path, find_duplicates: bool) -> Tuple[List[str], Dict[str, str]]:
    with path.open(errors='replace') as f:
        # Get commit, title tuples
        line_nr = 0
        try:
            log_list = []
            hexdigits = '0123456789abcdef'
            for line in f:
                line_nr += 1
                commit, title = line.strip().split(' ', maxsplit=1)
                if any(c not in hexdigits for c in commit):
                    raise RuntimeError('Error at line %s: Invalid commit' % line_nr)
                if not title:
                    raise RuntimeError('Error at line %s: Missing title')
                log_list.append((commit, title))
        except UnicodeDecodeError as e:
            raise RuntimeError('Error at line %s: %s' % (line_nr, e))
    
    log_list = [p for p in log_list if len(p) == 2]
    commit_list : List[str] = [c[1] for c in log_list]
    if find_duplicates:
        dups = get_duplicates(commit_list)
        if dups:
            raise RuntimeError('Duplicate commit titles: ' + '\n'.join(dups))
    return commit_list, {c[1]: c[0] for c in log_list}

def clean_title(title: str) -> str:
    for prefix in ('BACKPORT: ', 'UPSTREAM: ', 'FROMLIST: ', 'BACKPORT [FROMLIST] '):
        if title.startswith(prefix):
            return title[len(prefix):]
    return title


target_commits, _ = read_log(args.target_log, find_duplicates=False)
src_commits, src_commit_dict = read_log(args.src_log, find_duplicates=True)
print('Read %d commits from target %s and %d to reorder from %s' % (len(target_commits), args.target_log, len(src_commits), args.src_log))

src_set = {clean_title(commit): commit for commit in src_commits} 
src_set.update({commit: commit for commit in src_commits})

# Add all target commits bottom to top
final_list = [src_set[commit] for commit in reversed(target_commits) if commit in src_set]
print('\n'.join('pick %s %s' % (src_commit_dict[commit], commit) for commit in final_list))
print('Unsure\n\n')
# Remove added commits from src and add the remaining ones not changing order
src_set = set(src_commits) - set(final_list)
final_list = [commit for commit in reversed(src_commits) if commit in src_set]
print('\n'.join('pick %s %s' % (src_commit_dict[commit], commit) for commit in final_list))
