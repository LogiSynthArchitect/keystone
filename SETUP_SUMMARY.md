# Keystone Dev Setup Summary

## Architecture
```
Flutter App  -->  localhost:3456  --[SSH tunnel]-->  blind-bridge (Hetzner)  -->  supabase-kong:8000
(no keys)        (tunnel)                             (has API keys in config)     (Hetzner Docker)
```

## Hetzner Server
- **IP**: 178.104.189.111
- **User**: root
- **SSH key**: `/tmp/hetzner_ssh_key`
- **Type**: CX33 (4 vCPU, 8GB RAM, 80GB NVMe)
- **Location**: Falkenstein, Germany
- **Cost**: ~€7.99/month (pay-as-you-go)

## Running Services (on Hetzner)
- `blind-bridge` — Reverse proxy injecting Supabase keys (port 3456)
- `supabase-kong` — API gateway (port 8000)
- `supabase-db` — PostgreSQL 15 (port 5432)
- `supabase-auth`, `supabase-studio`, `supabase-rest`, etc.

## Reconnect Script
```bash
~/bin/keystone-connect.sh {start|stop|status}
```
After reboot: `keystone-connect.sh start`

## Blind Bridge Config
Server: `/opt/blind-bridge/bridge-config.json`

## .env
`projects/keystone/.env` contains only `BLIND_BRIDGE_URL=http://localhost:3456`
