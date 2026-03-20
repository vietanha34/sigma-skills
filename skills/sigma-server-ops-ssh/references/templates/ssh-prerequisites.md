# SSH Prerequisites Template

## 1) Local SSH config

```sshconfig
Host sigma-prod-01
  HostName 10.10.1.25
  User sigma_diag
  IdentityFile ~/.ssh/sigma_diag_ed25519
  IdentitiesOnly yes
  BatchMode yes
  ConnectTimeout 8
  StrictHostKeyChecking yes
```

## 2) Credential/session resolver

- Prefer an ephemeral alias or short-lived key path returned by `scripts/resolve_credential.sh`.
- The resolver must never print the private key or access token itself.
- If using `vast-ssh`, use it only to resolve an approved alias/session handle, not to paste secret material into the conversation.

## 3) Remote user scope

- Dedicated user: `sigma_diag`
- Read-only access for:
  - `curl http://localhost:9999`
  - `/var/log/sigma-machine/*`
  - `/etc/sigma-machine/config/*`
  - `ps`, `ss`, `hostname`, `df`, `free`, `uptime`

## 4) Validation

- `./scripts/resolve_credential.sh --target sigma-prod-01`
- `ssh sigma-prod-01 'hostname'`
- `ssh sigma-prod-01 'curl -sS http://localhost:9999'`
- `ssh sigma-prod-01 'curl -sS -X POST -H "Content-Type: application/json" --data "{\"type\":\"progress\",\"name\":\"\"}" http://localhost:9999'`
- `ssh sigma-prod-01 'tail -n 50 /var/log/sigma-machine/now.debug'`

## 5) Security notes

- Do not enable password-based automation.
- Use approved aliases instead of raw IPs when possible.
- Rotate keys on schedule.
- Keep host aliases explicit by environment (`prod`, `stg`, `dev`).
