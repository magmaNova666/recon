# Nmap Scan Report — 192.168.63.129

| | |
|---|---|
| **Target** | `192.168.63.129` |
| **Scan Date** | June 22, 2026, 03:34 -0400 |
| **Scanner** | Nmap 7.99 |
| **Command** | `nmap -sV 192.168.63.129` |
| **Host Status** | Up (0.0014s latency) |
| **Scan Duration** | 33.43 seconds |
| **Open Ports Found** | 23 |
| **Closed Ports** | 977 (not shown) |

> **Note:** `192.168.63.129` is a private (RFC 1918) address, and the scan ran from a Kali Linux box against a local host — consistent with an isolated lab/VM environment rather than an internet-facing asset.

## Executive Summary

The scanned host is almost certainly **Metasploitable2**, Rapid7's intentionally vulnerable training virtual machine. This is confirmed by multiple identifiers in the scan itself, not just the service list:

- Nmap's own service-fingerprint database labels port 1524 directly as **"Metasploitable root shell"**
- The reverse-resolved hostnames are `metasploitable.localdomain` and `irc.Metasploitable.LAN`

Every open port maps to a deliberately outdated or backdoored service. This VM is *designed* to fail a security assessment — the findings below are exactly the lessons it's built to teach, not real exposure on a production system.

**Overall Risk Rating: Critical** (by design)

## Raw Scan Output

```
$ nmap -sV 192.168.63.129

Starting Nmap 7.99 ( https://nmap.org ) at 2026-06-22 03:34 -0400
Nmap scan report for 192.168.63.129
Host is up (0.0014s latency).
Not shown: 977 closed tcp ports (reset)
PORT     STATE SERVICE     VERSION
21/tcp   open  ftp         vsftpd 2.3.4
22/tcp   open  ssh         OpenSSH 4.7p1 Debian 8ubuntu1 (protocol 2.0)
23/tcp   open  telnet      Linux telnetd
25/tcp   open  smtp        Postfix smtpd
53/tcp   open  domain      ISC BIND 9.4.2
80/tcp   open  http        Apache httpd 2.2.8 ((Ubuntu) DAV/2)
111/tcp  open  rpcbind     2 (RPC #100000)
139/tcp  open  netbios-ssn Samba smbd 3.X - 4.X (workgroup: WORKGROUP)
445/tcp  open  netbios-ssn Samba smbd 3.X - 4.X (workgroup: WORKGROUP)
512/tcp  open  exec        netkit-rsh rexecd
513/tcp  open  login       OpenBSD or Solaris rlogind
514/tcp  open  tcpwrapped
1099/tcp open  java-rmi    GNU Classpath grmiregistry
1524/tcp open  bindshell   Metasploitable root shell
2049/tcp open  nfs         2-4 (RPC #100003)
2121/tcp open  ftp         ProFTPD 1.3.1
3306/tcp open  mysql       MySQL 5.0.51a-3ubuntu5
5432/tcp open  postgresql  PostgreSQL DB 8.3.0 - 8.3.7
5900/tcp open  vnc         VNC (protocol 3.3)
6000/tcp open  X11         (access denied)
6667/tcp open  irc         UnrealIRCd
8009/tcp open  ajp13       Apache Jserv (Protocol v1.3)
8180/tcp open  http        Apache Tomcat/Coyote JSP engine 1.1
MAC Address: 00:0C:29:F2:6D:11 (VMware)
Service Info: Hosts: metasploitable.localdomain, irc.Metasploitable.LAN; OSs: Unix, Linux; CPE: cpe:/o:linux:linux_kernel

Service detection performed. Please report any incorrect results at https://nmap.org/submit/ .
Nmap done: 1 IP address (1 host up) scanned in 33.43 seconds
```

## Findings

| Port | Service | Version | Severity | Issue |
|---|---|---|---|---|
| 21/tcp | ftp | vsftpd 2.3.4 | **Critical** | This exact build is publicly associated with a backdoor enabling unauthenticated remote command execution (CVE-2011-2523) |
| 22/tcp | ssh | OpenSSH 4.7p1 | Medium | Very old OpenSSH release with multiple historical CVEs; outdated key-exchange/cipher support |
| 23/tcp | telnet | Linux telnetd | High | Cleartext authentication and session data — credentials and traffic fully visible to anyone on the network path |
| 25/tcp | smtp | Postfix smtpd | Low–Medium | Worth checking for open relay / user-enumeration via `VRFY`, depending on config |
| 53/tcp | domain | ISC BIND 9.4.2 | High | End-of-life DNS server version with multiple publicly documented vulnerabilities |
| 80/tcp | http | Apache httpd 2.2.8 (DAV/2) | High | Long-EOL Apache release; WebDAV (`DAV/2`) module increases attack surface if writable |
| 111/tcp | rpcbind | RPC #100000 | Medium | Exposes the RPC service map, aiding enumeration of NFS/NIS and similar services |
| 139, 445/tcp | netbios-ssn | Samba 3.X–4.X | **Critical** | Samba builds from this era (as bundled with Metasploitable2) are commonly vulnerable to the `usermap_script` command-injection flaw (CVE-2007-2447) |
| 512/tcp | exec | netkit-rsh rexecd | High | Legacy r-services authenticate via cleartext/trust relationships rather than modern credentials |
| 513/tcp | login | rlogind | High | Same r-services family — trust-based, cleartext auth |
| 514/tcp | tcpwrapped | — | Info | Wrapped service; banner intentionally hidden by `tcpd` |
| 1099/tcp | java-rmi | GNU Classpath grmiregistry | High | Unauthenticated RMI registries are a well-known remote-code-execution vector in legacy Java RMI stacks |
| 1524/tcp | bindshell | "Metasploitable root shell" | **Critical** | Nmap's own fingerprint database identifies this as a pre-configured root-level shell — an intentional backdoor built into the Metasploitable2 image |
| 2049/tcp | nfs | 2-4 (RPC #100003) | Medium | Worth checking export permissions; misconfigured NFS shares can expose the filesystem to any host that can reach the port |
| 2121/tcp | ftp | ProFTPD 1.3.1 | Medium | Older ProFTPD release with several publicly documented vulnerabilities for this version line |
| 3306/tcp | mysql | MySQL 5.0.51a | High | End-of-life database version; long past patch support |
| 5432/tcp | postgresql | PostgreSQL 8.3.x | High | End-of-life database version; long past patch support |
| 5900/tcp | vnc | VNC protocol 3.3 | High | Very old VNC protocol version; commonly deployed historically with weak or no authentication |
| 6000/tcp | X11 | access denied | Info | Port open but the current probe was refused access — still worth confirming no X clients accept remote connections |
| 6667/tcp | irc | UnrealIRCd | **Critical** | UnrealIRCd builds from this era (notably 3.2.8.1, the version shipped with Metasploitable2) are associated with a publicly documented backdoor (CVE-2010-2075) |
| 8009/tcp | ajp13 | Apache Jserv 1.3 | Medium | AJP connector exposed directly to the network; should generally be restricted to local/trusted hosts only |
| 8180/tcp | http | Tomcat/Coyote JSP engine 1.1 | High | Old Tomcat release; Metasploitable-era Tomcat manager instances are frequently left on default/weak credentials, which allows WAR-based remote code execution if unchanged |

## Risk Summary

| Severity | Count | Examples |
|---|---|---|
| Critical | 4 | vsftpd backdoor, Samba usermap_script, root-shell backdoor (1524), UnrealIRCd backdoor |
| High | 9 | Telnet, BIND, Apache 2.2.8, r-services, Java RMI, MySQL, PostgreSQL, VNC, Tomcat |
| Medium | 6 | SSH, rpcbind, NFS, ProFTPD, AJP13, SMTP |
| Info | 2 | tcpwrapped service, X11 (access denied) |

## Recommendations

These apply if this were a real production host; on the actual Metasploitable2 lab VM, they're the intended teaching points rather than action items:

- **Patch or decommission** any service running an end-of-life version (vsftpd, BIND, Apache, MySQL, PostgreSQL, ProFTPD, Tomcat).
- **Remove cleartext protocols** (telnet, rexec, rlogin) in favor of SSH/SFTP equivalents.
- **Disable or firewall unused services** — rpcbind, NFS, AJP13, and X11 should not be reachable from untrusted networks.
- **Enforce authentication** on VNC and Java RMI registry; neither should be reachable without it.
- **Audit Samba and Tomcat configuration** for the specific known flaws noted above (`usermap_script`, default manager credentials).
- **Network-segment lab/training VMs** like this one away from any production network or the internet — Metasploitable2 should only ever run on an isolated, host-only/NAT virtual network.

## Conclusion

This scan profile is a textbook match for Rapid7's Metasploitable2 — every open port corresponds to a known, intentionally vulnerable service used for hands-on penetration-testing practice, and Nmap's own fingerprinting confirms it directly (the "Metasploitable root shell" label on port 1524, plus the `metasploitable.localdomain` / `irc.Metasploitable.LAN` hostnames). As long as this VM stays on an isolated lab network, the findings above are simply a confirmation that the target is set up correctly for training — not a real-world incident to remediate.
