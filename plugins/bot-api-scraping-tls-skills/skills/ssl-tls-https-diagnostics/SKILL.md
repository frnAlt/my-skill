---
name: ssl-tls-https-diagnostics
description: Diagnostic procedures for SSL/TLS certificates, HTTPS handshakes, certificate chain verification, and proxy debugging. Use when encountering UNABLE_TO_VERIFY_LEAF_SIGNATURE, CERT_HAS_EXPIRED, DEPTH_ZERO_SELF_SIGNED_CERT, ERR_TLS_CERT_ALTNAME_INVALID, or configuring custom root CA bundles without disabling TLS validation.
---

# SSL/TLS & HTTPS Diagnostics Specialist

This skill provides diagnostic workflows for analyzing TLS handshakes, certificate expiration, certificate chain incompleteness, and secure custom CA injection.

> [!CAUTION]
> **CRITICAL SECURITY DIRECTIVE: NEVER Globally Disable SSL Verification**
> - NEVER set `process.env.NODE_TLS_REJECT_UNAUTHORIZED = '0'` in application code or production scripts.
> - NEVER set `rejectUnauthorized: false` globally on HTTP clients.
> Disabling verification leaves traffic vulnerable to Man-In-The-Middle (MITM) credential interception and payload tampering. The correct solution is ALWAYS to inject the proper Root/Intermediate CA bundle or fix the server's certificate chain.

## 1. Fast OpenSSL Diagnosis Commands

Always test the server directly with `openssl s_client` to inspect the live TLS handshake and certificate chain:

```bash
# 1. Inspect complete certificate chain with Server Name Indication (SNI)
openssl s_client -connect example.com:443 -servername example.com -showcerts < /dev/null

# 2. Check certificate validity dates and expiration
echo | openssl s_client -connect example.com:443 -servername example.com 2>/dev/null | openssl x509 -noout -dates

# 3. Check Subject Alternative Names (SAN) to verify matching domain
echo | openssl s_client -connect example.com:443 -servername example.com 2>/dev/null | openssl x509 -noout -text | grep -A 1 "Subject Alternative Name"

# 4. Check TLS protocol versions supported (TLS 1.2 vs TLS 1.3)
openssl s_client -connect example.com:443 -tls1_2 < /dev/null
openssl s_client -connect example.com:443 -tls1_3 < /dev/null
```

## 2. Common Node.js TLS Error Codes & Fixes

### Error 1: `UNABLE_TO_VERIFY_LEAF_SIGNATURE`
- **Cause:** The server did not provide intermediate CA certificates in the TLS handshake, only the leaf certificate.
- **Verification:** Run `openssl s_client -connect host:443 -servername host`. If it returns `Verify return code: 21 (unable to verify the first certificate)`, the server configuration is missing intermediate certificates.
- **Solution:** 
  - On the server: Append the intermediate bundle (`fullchain.pem` rather than `cert.pem`).
  - On the client (internal/corporate APIs): Provide the intermediate CA to Node via `NODE_EXTRA_CA_CERTS`.

### Error 2: `DEPTH_ZERO_SELF_SIGNED_CERT`
- **Cause:** The server certificate was self-signed and is not signed by any recognized authority in the system trust store.
- **Secure Solution:** Export the self-signed certificate or custom internal Root CA and register it with the Node.js runtime:
  ```bash
  export NODE_EXTRA_CA_CERTS="/path/to/internal-root-ca.pem"
  node index.js
  ```

### Error 3: `ERR_TLS_CERT_ALTNAME_INVALID`
- **Cause:** The domain name requested does not match the Common Name (CN) or Subject Alternative Names (SAN) on the certificate (e.g., requesting an IP address or internal hostname that isn't listed).
- **Secure Solution:** Access the server via its approved SAN hostname, or re-issue the certificate with the target IP/domain added to `subjectAltName = DNS:myhost, IP:192.168.1.50`.

## 3. Scoped Custom CA in Node.js (Without Global Environment Variables)

When an isolated service requires a custom internal CA without modifying global environment flags:

```typescript
import https from 'https';
import fs from 'fs';
import axios from 'axios';

// Read specific corporate/internal Root CA
const caCert = fs.readFileSync('/path/to/corporate-ca.crt');

// Create an HTTPS Agent specifically bound to this trusted CA
const secureCustomAgent = new https.Agent({
  ca: caCert,
  // Strict verification remains active!
  rejectUnauthorized: true,
  keepAlive: true,
});

// Pass agent only to the target client instance
const internalClient = axios.create({
  baseURL: 'https://internal-service.local',
  httpsAgent: secureCustomAgent,
});
```

## 4. Diagnosing Corporate & Development Proxies (mitmproxy, Charles, ZAP)

When developing with local HTTPS inspection proxies:

1. Export the proxy's public certificate: `mitmproxy-ca-cert.pem`.
2. Launch the Node.js process with targeted CA registration:
   ```bash
   NODE_EXTRA_CA_CERTS=~/.mitmproxy/mitmproxy-ca-cert.pem node bot.js
   ```
3. In curl:
   ```bash
   curl --cacert ~/.mitmproxy/mitmproxy-ca-cert.pem https://example.com
   ```
