#!/usr/bin/env bash
# --- jscp: bidirectional scp wrapper for jump-server asymmetric trust ---

# change jump_host and jump_port to your actual jump server credentials
jump_host="mihajlo@jump-gerniks"
jump_port=2222
# ---

recursive=""
target_host=""
usage="jscp - scp wrapper for pulling/pushing files through a jump server
USAGE:
  Pull:  jscp [-r] -t user@target target:/remote/path ./local/path
  Push:  jscp [-r] -t user@target ./local/path target:/remote/path
OPTIONS:
  -t user@host   Target host to connect to from the jump server (required)
  -r             Recursive - use for copying directories
  -h, --help     Show this help message
EXAMPLES:
  jscp -t root@aut-env target:/var/lib/postgresql/dumps/db.dump ./db.dump
  jscp -r -t root@aut-env target:/var/log/myapp ./myapp_logs
  jscp -t root@aut-env ./db.dump target:/var/lib/postgresql/dumps/db.dump
NOTES:
  - The literal word 'target:' marks which side is the remote target host;
    it is stripped before use and never sent over the network.
  - Jump host/port are fixed inside the script (currently $jump_host:$jump_port)."

while [[ "$1" == -* ]]; do
  case "$1" in
  -r)
    recursive="-r"
    shift
    ;;
  -t)
    if [[ -z "$2" ]]; then
      echo "Error: -t requires a value (user@host)"
      echo ""
      echo "$usage"
      exit 1
    fi
    target_host="$2"
    shift 2
    ;;
  -h | --help)
    echo "$usage"
    exit 0
    ;;
  *)
    echo "Unknown option: $1"
    echo ""
    echo "$usage"
    exit 1
    ;;
  esac
done

src="$1"
dst="$2"
stage_dir="/tmp/jscp_stage_${$}_${RANDOM}"

if [[ -z "$target_host" ]]; then
  echo "Error: you must specify the target host with -t user@host"
  echo ""
  echo "$usage"
  exit 1
fi
if [[ -z "$src" || -z "$dst" ]]; then
  echo "Error: you must specify both source and destination paths"
  echo ""
  echo "$usage"
  exit 1
fi

# PULL: target -> jump -> local
if [[ "$src" == target:* ]]; then
  remote_path="${src#target:}"
  ssh -p "$jump_port" "$jump_host" \
    "mkdir -p $stage_dir && shopt -s dotglob && scp $recursive $target_host:'$remote_path' $stage_dir/" || {
    echo "✗ Failed to stage file from target on jump"
    exit 1
  }
  scp -P "$jump_port" $recursive "$jump_host:$stage_dir/*" "$dst" || {
    echo "✗ Failed to pull staged file from jump to local"
    ssh -p "$jump_port" "$jump_host" "rm -rf $stage_dir"
    exit 1
  }
  ssh -p "$jump_port" "$jump_host" "rm -rf $stage_dir"
  echo "✓ Pulled $target_host:$remote_path -> $dst"

# PUSH: local -> jump -> target
elif [[ "$dst" == target:* ]]; then
  remote_path="${dst#target:}"
  ssh -p "$jump_port" "$jump_host" "mkdir -p $stage_dir" || {
    echo "✗ Failed to create staging dir on jump"
    exit 1
  }
  scp -P "$jump_port" $recursive "$src" "$jump_host:$stage_dir/" || {
    echo "✗ Failed to push local file to jump"
    ssh -p "$jump_port" "$jump_host" "rm -rf $stage_dir"
    exit 1
  }
  ssh -p "$jump_port" "$jump_host" \
    "shopt -s dotglob && scp $recursive $stage_dir/* $target_host:'$remote_path' && rm -rf $stage_dir" || {
    echo "✗ Failed to push staged file from jump to target"
    exit 1
  }
  echo "✓ Pushed $src -> $target_host:$remote_path"

else
  echo "Error: one side must be prefixed with 'target:' (e.g. target:/path/on/target)"
  exit 1
fi
