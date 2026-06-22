# Recon Toolkit

An interactive Bash menu for kicking off two common reconnaissance workflows — a full Nmap port/service scan, or a subdomain-enum → live-host-probe → vulnerability-scan pipeline (`subfinder` → `httpx-toolkit` → `nuclei`) — plus a real-world OSINT case study performed against `owasp.org` using purely passive tools.

> ⚠️ **Legal & Ethical Use**
> This script performs **active scanning** (full TCP port sweep, HTTP probing, template-based vulnerability checks). Only point it at assets you **own** or have **explicit written authorization** to test — e.g. your own lab, a CTF box, or a program whose scope explicitly allows it. Unauthorized scanning of third-party systems may be illegal in your jurisdiction. The author assumes no liability for misuse.

## Table of Contents

- [Overview](#overview)
- [Repository Structure](#repository-structure)
- [Prerequisites](#prerequisites)
- [Installation](#installation)
- [Usage](#usage)
  - [Option 1 — Nmap](#option-1--nmap)
  - [Option 2 — subfinder + httpx-toolkit + nuclei](#option-2--subfinder--httpx-toolkit--nuclei)
- [How It Works](#how-it-works)
- [Output Files](#output-files)
- [OSINT Case Study — owasp.org](#osint-case-study--owasporg)
- [Possible Improvements](#possible-improvements)
- [License](#license)

## Overview

This repo holds two things:

1. **`recon.sh`** — a small interactive menu that wraps two recon workflows so they're one command away instead of five.
2. **An OSINT case study** — a passive reconnaissance report against `owasp.org` (DNS, WHOIS, Shodan, DNSDumpster) showing the manual, non-intrusive side of recon that complements the active scanning this script does.

## Repository Structure

```
.
├── README.md                          # this file
├── recon.sh                           # the interactive recon script
└── docs/
    ├── OSINT-Report-owasp-org.md      # full passive OSINT report
    └── images/                        # screenshots referenced by the report
```

> Rename the script to whatever you've actually saved it as — the commands below assume `recon.sh`. If you're merging in the earlier OSINT report, rename its file from `README.md` to `docs/OSINT-Report-owasp-org.md` first, since a repo can only have one top-level `README.md`.

## Prerequisites

| Tool | Used for | Install |
|---|---|---|
| `nmap` | Full port + service/OS scan (Option 1) | `sudo apt install nmap` |
| `subfinder` | Passive subdomain enumeration (Option 2) | `sudo apt install subfinder` or `go install github.com/projectdiscovery/subfinder/v2/cmd/subfinder@latest` |
| `httpx-toolkit` | Live-host / HTTP probing (Option 2) | `sudo apt install httpx-toolkit` — on Kali, ProjectDiscovery's `httpx` is packaged under this name to avoid clashing with the unrelated `httpx` Python package |
| `nuclei` | Template-based vulnerability scanning (Option 2) | `sudo apt install nuclei` or `go install github.com/projectdiscovery/nuclei/v3/cmd/nuclei@latest` |

All four ship by default on Kali Linux. On other distros, the `go install` paths above work once `$GOPATH/bin` is on your `PATH`.

## Installation

```bash
git clone https://github.com/<your-username>/<your-repo>.git
cd <your-repo>
chmod +x recon.sh
```

## Usage

Run the script and pick an option:

```bash
./recon.sh
```

```
Enter the option you want to do:
1.Nmap
2.subfinder+httpx+nuclei
Your choice:
```

### Option 1 — Nmap

Prompts for a target, then runs an aggressive, all-ports scan:

```bash
nmap -A -sV -p1-65535 $target
```

| Flag | Meaning |
|---|---|
| `-A` | Enables OS detection, version detection, script scanning, and traceroute |
| `-sV` | Service/version detection (redundant with `-A`, kept explicit) |
| `-p1-65535` | Scans the full TCP port range, not just the top 1000 |

This is a **slow, noisy** scan — expect it to take a while on a full /65535 range, and expect it to be visible to any IDS/IPS in front of the target. Run with `sudo` for accurate OS fingerprinting (raw-socket access).

**Example:**
```
Your choice: 1
[*]You have selected nmap.
[*]Enter the target address to nmap scan: 192.168.1.10
```

### Option 2 — subfinder + httpx-toolkit + nuclei

Prompts for a domain, then chains three tools together:

```bash
subfinder -d $domain -silent > /tmp/subdomain.txt
httpx-toolkit -l /tmp/subdomain.txt > /tmp/httpx_output.txt
httpx-toolkit -l /tmp/subdomain.txt -status-code -title -silent
nuclei -l /tmp/httpx_output.txt
```

**Example:**
```
Your choice: 2
[*]About to start subfinder,httpx-toolkit and nuclei
Enter the domain to search: example.com
```

## How It Works

```mermaid
flowchart LR
    A[Domain] --> B["subfinder<br/>(passive subdomain enum)"]
    B --> C[/tmp/subdomain.txt]
    C --> D["httpx-toolkit<br/>(live host probing)"]
    D --> E[/tmp/httpx_output.txt]
    E --> F["nuclei<br/>(template-based vuln scan)"]
    F --> G[Findings printed to terminal]
    C -.-> H["httpx-toolkit -status-code -title<br/>(quick visual check, not saved)"]
```

1. **`subfinder -d $domain -silent`** passively enumerates subdomains from public sources and writes the raw list to `/tmp/subdomain.txt`.
2. **`httpx-toolkit -l /tmp/subdomain.txt`** probes each subdomain for a live HTTP/HTTPS service and saves the responding URLs to `/tmp/httpx_output.txt` — this is the file `nuclei` ultimately consumes.
3. A **second `httpx-toolkit` run** (with `-status-code -title -silent`) re-probes the same list and prints status codes and page titles straight to the terminal for a quick eyeballed overview. This run isn't saved to disk — it's purely for visual feedback while the scan is going.
4. **`/tmp/subdomain.txt` is deleted** once `httpx-toolkit` has consumed it, since it's no longer needed.
5. **`nuclei -l /tmp/httpx_output.txt`** runs its default template set against every live host found in step 2.

## Output Files

| File | Persists? | Notes |
|---|---|---|
| `/tmp/subdomain.txt` | No — removed automatically after `httpx-toolkit` runs | Raw subdomain list from `subfinder` |
| `/tmp/httpx_output.txt` | Yes | Live URLs from `httpx-toolkit`; input to `nuclei`; not cleaned up automatically — remove manually between runs if you don't want results from different targets mixing |

## OSINT Case Study — owasp.org

Alongside this script, a **fully passive** OSINT exercise was run against `owasp.org` to practice the reconnaissance phase without any active scanning. Full write-up: [`docs/OSINT-Report-owasp-org.md`](docs/OSINT-Report-owasp-org.md).

**Tools used:** `dig`, `whois`, Shodan, DNSDumpster — no `nmap`, no `httpx`, no `nuclei`, no exploitation.

**Highlights:**
- `owasp.org` resolves to two Cloudflare-proxied IPs; the real origin servers are masked.
- Registered via GoDaddy since 2001, expiring 2031; DNSSEC is **not** enabled.
- Mail is routed through Google Workspace; SPF correctly hard-fails unauthorized senders (`-all`).
- TXT records reveal Google, Atlassian, and Microsoft 365 SaaS integrations.
- Shodan indexed 25 hosts across DigitalOcean, AWS, and Cloudflare; only **one** directly-exposed login page was found outside the Cloudflare proxy — an AWS-hosted SecureFlag training subdomain (`secureflag.owasp.org`).
- No vulnerabilities were flagged by Shodan on any indexed host.

This pairs naturally with `recon.sh`: the case study shows what passive-only OSINT can (and can't) reveal — e.g. it couldn't see past Cloudflare to the AWS-hosted login page on its own — while `nmap`/`httpx`/`nuclei` represent the active follow-up steps you'd take next *with proper authorization*.

## Possible Improvements

A few ideas if you keep extending this:

- Replace the interactive `read -p` prompts with CLI flags (`-t`, `-d`, `--mode`) so the script can be run non-interactively/in CI.
- Namespace output files per run (e.g. `/tmp/recon_$domain_$(date +%s)/`) instead of fixed `/tmp/` paths, so concurrent or repeated runs don't overwrite each other.
- Drop the duplicate `httpx-toolkit` call in Option 2 — both invocations hit the same target list; consider running it once with `-status-code -title -o /tmp/httpx_output.txt -silent` instead of running it twice.
- Pass `-severity` or a specific `-t <templates>` flag to `nuclei` to scope/speed up the scan instead of running the full default template set.
- Clean up `/tmp/httpx_output.txt` at the end of the run (or move outputs out of `/tmp` entirely).

## License

Add a `LICENSE` file (MIT is a common choice for tooling like this) if you intend others to reuse or modify the script.
