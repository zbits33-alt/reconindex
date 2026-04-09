#!/usr/bin/env python3
"""
Recon — Evernode Documentation Indexer
Scrapes Evernode docs and extracts structured content for Society Libraries.
"""

import json
import os
import re
import requests
from datetime import datetime, timezone
from html.parser import HTMLParser

OUT_DIR = "/home/agent/workspace/intelligence/evernode"
HEADERS = {"User-Agent": "Recon-Indexer/1.0"}

EVERNODE_PAGES = {
    "index":              "https://docs.evernode.org/en/latest/",
    "hotpocket_index":    "https://docs.evernode.org/en/latest/sdk/hotpocket/index.html",
    "hotpocket_basics":   "https://docs.evernode.org/en/latest/sdk/hotpocket/tutorials/basics.html",
    "hotpocket_tutorials":"https://docs.evernode.org/en/latest/sdk/hotpocket/tutorials/index.html",
    "hotpocket_ref":      "https://docs.evernode.org/en/latest/sdk/hotpocket/reference/index.html",
    "hotpocket_libraries":"https://docs.evernode.org/en/latest/sdk/hotpocket/libraries.html",
    "evernode_sdk":       "https://docs.evernode.org/en/latest/sdk/evernode/",
    "evernode_jsclient":  "https://docs.evernode.org/en/latest/sdk/evernode/evernode-js-client/index.html",
}

class TextExtractor(HTMLParser):
    def __init__(self):
        super().__init__()
        self.text_parts = []
        self.skip_tags = {"script", "style", "nav", "footer", "head"}
        self.skip = 0
        self.current_tag = None

    def handle_starttag(self, tag, attrs):
        if tag in self.skip_tags:
            self.skip += 1
        self.current_tag = tag

    def handle_endtag(self, tag):
        if tag in self.skip_tags:
            self.skip -= 1

    def handle_data(self, data):
        if self.skip == 0:
            stripped = data.strip()
            if stripped and len(stripped) > 2:
                self.text_parts.append(stripped)

    def get_text(self):
        return "\n".join(self.text_parts)

def fetch_page(url):
    try:
        r = requests.get(url, timeout=20, headers=HEADERS)
        if r.status_code != 200:
            return None, f"HTTP {r.status_code}"
        parser = TextExtractor()
        parser.feed(r.text)
        text = parser.get_text()
        # Clean up whitespace
        text = re.sub(r'\n{3,}', '\n\n', text)
        return text, None
    except Exception as e:
        return None, str(e)

def extract_links(url):
    """Extract internal doc links from a page."""
    try:
        r = requests.get(url, timeout=15, headers=HEADERS)
        links = re.findall(r'href="([^"]*)"', r.text)
        base = "https://docs.evernode.org"
        internal = [base + l if l.startswith("/") else l for l in links
                    if "docs.evernode.org" in l or l.startswith("/en/latest/")]
        return list(set(internal))
    except:
        return []

def main():
    timestamp = datetime.now(timezone.utc).strftime("%Y-%m-%dT%H:%M:%SZ")
    print(f"[{timestamp}] Recon Evernode Indexer starting...")

    index = {"updated": timestamp, "pages": {}}
    all_text = []

    for name, url in EVERNODE_PAGES.items():
        print(f"  Fetching {name}: {url}")
        text, error = fetch_page(url)
        if error:
            print(f"    ERROR: {error}")
            index["pages"][name] = {"url": url, "error": error}
        else:
            char_count = len(text)
            print(f"    OK — {char_count} chars")
            index["pages"][name] = {"url": url, "chars": char_count, "status": "ok"}
            # Save individual page text
            page_path = os.path.join(OUT_DIR, f"{name}.txt")
            with open(page_path, "w") as f:
                f.write(f"# Evernode Docs — {name}\n")
                f.write(f"# Source: {url}\n")
                f.write(f"# Fetched: {timestamp}\n\n")
                f.write(text)
            all_text.append(f"\n\n{'='*60}\n# {name.upper()}\n# {url}\n{'='*60}\n\n{text}")

    # Save combined text
    combined_path = os.path.join(OUT_DIR, "evernode_docs_combined.txt")
    with open(combined_path, "w") as f:
        f.write(f"# Evernode Documentation — Combined Index\n")
        f.write(f"# Updated: {timestamp}\n")
        f.write("\n".join(all_text))
    print(f"  Saved combined: {combined_path}")

    # Save index JSON
    with open(os.path.join(OUT_DIR, "evernode_index.json"), "w") as f:
        json.dump(index, f, indent=2)

    # Write markdown summary
    md_lines = [
        f"# Evernode Documentation Index",
        f"> Updated: {timestamp}",
        f"> Source: docs.evernode.org",
        f"",
        f"## Pages Indexed",
        f"",
        f"| Page | URL | Status |",
        f"|------|-----|--------|",
    ]
    for name, info in index["pages"].items():
        status = "✅ OK" if info.get("status") == "ok" else f"❌ {info.get('error','unknown')}"
        chars = f"{info.get('chars', 0):,} chars" if info.get("chars") else ""
        md_lines.append(f"| {name} | {info['url']} | {status} {chars} |")

    md_lines += [
        f"",
        f"## Key Sections Available",
        f"",
        f"- **Concepts** — core Evernode and HotPocket concepts",
        f"- **HotPocket SDK Reference** — API reference for smart contracts",
        f"- **Evernode SDK** — host and tenant APIs",
        f"- **Tutorials** — step-by-step developer guides",
        f"- **EVR Token** — tokenomics and usage",
        f"- **Host Setup** — running an Evernode host",
    ]

    with open(os.path.join(OUT_DIR, "evernode_latest.md"), "w") as f:
        f.write("\n".join(md_lines))

    print(f"[{timestamp}] Evernode indexer complete.")

if __name__ == "__main__":
    main()
