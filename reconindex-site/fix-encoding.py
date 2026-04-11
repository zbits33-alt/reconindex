#!/usr/bin/env python3
import os

def replace_utf8_with_entities(filepath):
    with open(filepath, 'r', encoding='utf-8') as f:
        content = f.read()
    
    # Replace common UTF-8 chars with HTML entities
    replacements = {
        '\u2014': '&#8212;',   # em dash
        '\u2026': '&#8230;',   # ellipsis
        '\u2018': '&#8216;',   # left single quote
        '\u2019': '&#8217;',   # right single quote
        '\u201c': '&#8220;',   # left double quote
        '\u201d': '&#8221;',   # right double quote
        '\u00a9': '&copy;',    # copyright
        '\u00ae': '&reg;',     # registered
        '\u2192': '&#8594;',   # right arrow
        '\u2190': '&#8592;',   # left arrow
        '\u2713': '&#10003;',  # checkmark
        '\u2717': '&#10007;',  # cross
        '\u26a0': '&#9888;',   # warning
        '\u26a1': '&#9889;',   # zap
        '\u2728': '&#10024;',  # sparkles
        '\u00b7': '&#183;',    # middle dot
    }
    
    changed = False
    for char, entity in replacements.items():
        if char in content:
            content = content.replace(char, entity)
            changed = True
    
    if changed:
        with open(filepath, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f'Fixed: {filepath}')
    else:
        print(f'No changes: {filepath}')

for f in os.listdir('.'):
    if f.endswith('.html'):
        replace_utf8_with_entities(f)
