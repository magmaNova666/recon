# Reconnaissance and Vulnerability Assessment Report

**Target Domain:** `vulhub.com`  
**Date:** June 22, 2026  
**Tools Orchestrated:** Subfinder -> Httpx-toolkit -> Nuclei  
**Automation Wrapper:** `recon.sh`

---

## 1. Passive Asset Discovery & Mapping

### Subdomain Enumeration
Using the automated passive reconnaissance workflow, 7 key infrastructure endpoints were mapped out:
* `mail.vulhub.com`
* `www.vulhub.com`
* `download.vulhub.com`
* `api.vulhub.com`
* `wildcard.vulhub.com`
* `admin.vulhub.com`
* `ww1.vulhub.com`

### Perimeter Protection Observations (Httpx Response)
Initial active validation via `httpx-toolkit` revealed that the target perimeter utilizes aggressive request rate-limiting defense strategies. The majority of subdomains threw an **HTTP 429 (Too Many Requests)** status code, while `ww1.vulhub.com` responded with an active status of **HTTP 200 (OK)**.

---

## 2. Automated Vulnerability Scanning (Nuclei)

### Scan Summary
* **Templates Evaluated:** 10,365 active configurations
* **Scan Duration:** 12 minutes, 0 seconds
* **Total Signal Matches:** 25 security and informational records found

### Host Filtering & Unresponsive Scope
During active template execution, the scanner identified strict firewall rules or temporary service blocks on port 443 across several nodes, resulting in connection refusal and connection timeouts. The following nodes were safely dropped from aggressive fuzzing to prevent false positives:
* `ww1.vulhub.com:443` (Connection Refused)
* `www.vulhub.com:443`, `api.vulhub.com:443`, `download.vulhub.com:443`, `mail.vulhub.com:443` (I/O execution timeouts)

---

## 3. Key Vulnerability & Configuration Findings

### A. Wildcard DNS Detection (`[info]`)
The engine identified that `vulhub.com` uses a wildcard DNS record configuration. Any non-existent or arbitrary subdomain request maps directly to a set of specific perimeter load-balancer IPs:
* **Cluster 1 (`74.63.219.251`):** Associated with `mail` and `admin` subdomains.
* **Cluster 2 (`212.92.105.212`):** Associated with `www`, `download`, `api`, and `wildcard` routing paths.

### B. Missing HTTP Security Hardening Headers (`[info]`)
Target endpoint `https://ww1.vulhub.com` was found to be missing essential defensive web response headers. This omission allows common client-side web application attacks to execute unhindered:
* `Content-Security-Policy` (Mitigates Cross-Site Scripting / XSS attacks)
* `Strict-Transport-Security` (Enforces mandatory HTTPS communication)
* `X-Frame-Options` (Prevents Clickjacking UI redressing vectors)
* `X-Content-Type-Options` (Mitigates MIME-sniffing exploits)

### C. Fingerprints & Open Intelligence Data
* **Server Footprint:** `openresty-detect` logged on `ww1.vulhub.com` (running OpenResty web platform components).
* **Information Exposure:** An exposed `robots.txt` configuration file was discovered at `https://ww1.vulhub.com/robots.txt`.
* **DNS Third-Party Association:** `dns-saas-service-detection` flagged an external pointer mapping `ww1.vulhub.com` directly to `9145.searchmagnified.com`.

---

## 4. Remediation & Hardening Roadmap

1. **Implement Security Headers:** Configure the OpenResty/Nginx server block configurations on `ww1.vulhub.com` to inject standard protection headers (`X-Frame-Options: DENY`, strict `Content-Security-Policy`, etc.).
2. **Review Third-Party DNS Mapping:** Validate whether the routing path mapping to `searchmagnified.com` is intentional or represents a legacy domain pointer vulnerable to dangling DNS domain hijacking.
3. **Audit Wildcard Allocations:** Ensure that any dynamic routing directed by the global wildcard DNS records passes through centralized access controls to mitigate shadow asset deployment.
