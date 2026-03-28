#!/usr/bin/env bash
# ─────────────────────────────────────────────────────────────────────────────
# create-cluster.sh — Create Talos KVM cluster nodes with auto IP allocation
#
# Usage:
#   ./create-cluster.sh --master 1 --node 4 --prefix dev
#
# VM naming: talos-vm-(master|worker)-(number)-(prefix)
#   e.g.  talos-vm-master-1-dev
#         talos-vm-worker-1-dev ... talos-vm-worker-4-dev
#
# Requirements (on localserver):
#   sudo, virsh, virt-install, python3, jq
#
# Metadata file (tracks all allocated IPs + MACs):
#   Defaults to same dir as this script → instance_state_metadata.json
# ─────────────────────────────────────────────────────────────────────────────

set -euo pipefail

# ── Config ────────────────────────────────────────────────────────────────────
ISO_PATH="/var/iso/metal-amd64.iso"
DISK_DIR="/var/lib/libvirt/images"
NETWORK="default"
LIBVIRT_SUBNET="192.168.122"
IP_RANGE_START=110   # allocate from .110 upward (avoid .100-.109 infra range)
IP_RANGE_END=190     # stop before .200 (service range)

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Metadata lives two levels up at the project root
METADATA_FILE="$(./instance_state_metadata.json")"

# ── Colours ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m'; NC='\033[0m'

log()  { echo -e "${GREEN}[✔]${NC} $*"; }
info() { echo -e "${CYAN}[→]${NC} $*"; }
warn() { echo -e "${YELLOW}[!]${NC} $*"; }
err()  { echo -e "${RED}[✘]${NC} $*" >&2; exit 1; }

# ── Argument parsing ──────────────────────────────────────────────────────────
MASTER_COUNT=1
WORKER_COUNT=1
PREFIX=""

usage() {
  echo -e "${BOLD}Usage:${NC} $0 --master <N> --node <N> --prefix <name>"
  echo "  --master   Number of control-plane nodes (default: 1)"
  echo "  --node     Number of worker nodes        (default: 1)"
  echo "  --prefix   Cluster prefix name           (required)"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --master) MASTER_COUNT="$2"; shift 2 ;;
    --node)   WORKER_COUNT="$2"; shift 2 ;;
    --prefix) PREFIX="$2";       shift 2 ;;
    -h|--help) usage ;;
    *) err "Unknown argument: $1" ;;
  esac
done

[[ -z "$PREFIX" ]] && err "--prefix is required"
[[ ! "$MASTER_COUNT" =~ ^[0-9]+$ ]] && err "--master must be a positive integer"
[[ ! "$WORKER_COUNT" =~ ^[0-9]+$ ]] && err "--node must be a positive integer"

# ── Ensure metadata file exists ───────────────────────────────────────────────
if [[ ! -f "$METADATA_FILE" ]]; then
  warn "Metadata file not found, creating: $METADATA_FILE"
  echo '{"instances":[]}' > "$METADATA_FILE"
fi

# ── IP allocation helpers ─────────────────────────────────────────────────────
get_used_ips() {
  # IPs from metadata file
  python3 -c "
import json, sys
with open('$METADATA_FILE') as f:
    data = json.load(f)
for inst in data.get('instances', []):
    print(inst['hostname'])
"
  # IPs from live DHCP leases (avoid race condition with other VMs)
  virsh net-dhcp-leases "$NETWORK" 2>/dev/null \
    | awk '/ipv4/ {split($5,a,"/"); print a[1]}' \
    || true
}

find_free_ip() {
  local used_ips
  used_ips=$(get_used_ips | sort -u)

  for last_octet in $(seq "$IP_RANGE_START" "$IP_RANGE_END"); do
    local candidate="${LIBVIRT_SUBNET}.${last_octet}"
    if ! echo "$used_ips" | grep -qxF "$candidate"; then
      echo "$candidate"
      return 0
    fi
  done
  err "No free IP available in ${LIBVIRT_SUBNET}.${IP_RANGE_START}-${IP_RANGE_END}"
}

# ── Metadata update helper ────────────────────────────────────────────────────
register_instance() {
  local host="$1" ip="$2" mac="$3"
  python3 - "$METADATA_FILE" "$host" "$ip" "$mac" <<'PYEOF'
import json, sys
path, host, ip, mac = sys.argv[1], sys.argv[2], sys.argv[3], sys.argv[4]
with open(path) as f:
    data = json.load(f)
# Remove existing entry for same host if any
data['instances'] = [i for i in data['instances'] if i['host'] != host]
data['instances'].append({"host": host, "hostname": ip, "mac_address": mac})
with open(path, 'w') as f:
    json.dump(data, f, indent=4)
PYEOF
  log "Saved to metadata: $host → $ip ($mac)"
}

# ── VM creation ───────────────────────────────────────────────────────────────
create_vm() {
  local name="$1" role="$2"

  # Resources per role
  local memory vcpus
  if [[ "$role" == "master" ]]; then
    memory=4096; vcpus=4
  else
    memory=2048; vcpus=2
  fi

  local disk_path="${DISK_DIR}/${name}.qcow2"

  # Check VM doesn't already exist
  if virsh dominfo "$name" &>/dev/null; then
    warn "VM '$name' already exists — skipping creation"
  else
    info "Creating VM: ${BOLD}$name${NC} (role=$role, mem=${memory}MB, cpu=$vcpus)"
    sudo virt-install \
      --name "$name" \
      --memory "$memory" \
      --vcpus "$vcpus" \
      --disk path="$disk_path",size=30,format=qcow2 \
      --cdrom "$ISO_PATH" \
      --os-variant unknown \
      --network network="${NETWORK}",model=virtio \
      --graphics vnc,listen=0.0.0.0,port=-1 \
      --graphics spice \
      --video qxl \
      --console pty,target_type=serial \
      --noautoconsole
    log "VM '$name' created"
  fi

  # ── Wait for MAC address to be assigned ──────────────────────────────────
  info "Waiting for network interface on '$name'..."
  local mac=""
  local retries=0
  while [[ -z "$mac" && $retries -lt 30 ]]; do
    mac=$(virsh domiflist "$name" 2>/dev/null | awk "/$NETWORK/ {print \$5}" | head -1)
    if [[ -z "$mac" ]]; then
      sleep 2
      ((retries++))
    fi
  done
  [[ -z "$mac" ]] && err "Could not get MAC for '$name' after 60s"
  log "MAC address: $mac"

  # ── Find free IP ──────────────────────────────────────────────────────────
  local ip
  ip=$(find_free_ip)
  info "Assigning IP: $ip → $name ($mac)"

  # ── Register DHCP reservation ─────────────────────────────────────────────
  # Remove existing reservation for this MAC if any
  local existing_xml
  existing_xml=$(virsh net-dumpxml "$NETWORK" | grep "mac='$mac'" || true)
  if [[ -n "$existing_xml" ]]; do
    warn "Existing DHCP entry for $mac — removing first"
    virsh net-update "$NETWORK" delete ip-dhcp-host \
      --xml "$existing_xml" --live --config 2>/dev/null || true
  fi

  virsh net-update "$NETWORK" add ip-dhcp-host \
    --xml "<host mac='$mac' name='$name' ip='$ip'/>" \
    --live --config
  log "DHCP reserved: $name → $ip"

  # ── Save to metadata ──────────────────────────────────────────────────────
  register_instance "$name" "$ip" "$mac"

  echo -e "${BOLD}${GREEN}✅ $name ready${NC} | IP: $ip | MAC: $mac"
  echo ""
}

# ── Main ──────────────────────────────────────────────────────────────────────
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════${NC}"
echo -e "${BOLD}  Talos Cluster Creator — prefix: $PREFIX${NC}"
echo -e "${BOLD}  Masters: $MASTER_COUNT  |  Workers: $WORKER_COUNT${NC}"
echo -e "${BOLD}${CYAN}═══════════════════════════════════════════════${NC}\n"

# Create master nodes
for i in $(seq 1 "$MASTER_COUNT"); do
  create_vm "talos-vm-master-${i}-${PREFIX}" "master"
done

# Create worker nodes
for i in $(seq 1 "$WORKER_COUNT"); do
  create_vm "talos-vm-worker-${i}-${PREFIX}" "worker"
done

echo -e "\n${BOLD}${GREEN}All nodes created! Current allocations:${NC}"
echo -e "${CYAN}────────────────────────────────────────${NC}"
python3 -c "
import json
with open('$METADATA_FILE') as f:
    data = json.load(f)
for i in data['instances']:
    if 'talos-vm' in i['host'] and '$PREFIX' in i['host']:
        print(f\"  {i['host']:<35} {i['hostname']:<20} {i['mac_address']}\")
"
echo -e "${CYAN}────────────────────────────────────────${NC}"
echo -e "\nNext step → apply Talos machine config:"
echo -e "  talosctl apply-config --insecure --nodes <IP> --file controlplane.yaml"
