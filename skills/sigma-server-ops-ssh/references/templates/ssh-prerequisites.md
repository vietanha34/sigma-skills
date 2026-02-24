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
  StrictHostKeyChecking accept-new
```

## 2) Remote user scope
- Dedicated user: `sigma_diag`
- Read-only access for:
  - `systemctl is-active/show sigma-media-server`
  - `journalctl -u sigma-media-server`
  - `uptime`, `free -m`, `df -h /`

## 3) Validation
- `ssh sigma-prod-01 'hostname'`
- `ssh sigma-prod-01 'systemctl is-active sigma-media-server'`
- `ssh sigma-prod-01 'journalctl -u sigma-media-server --since "30m ago" -n 50 --no-pager'`

## 4) Security notes
- Do not enable password-based automation.
- Rotate keys on schedule.
- Keep host aliases explicit by environment (`prod`, `stg`, `dev`).
