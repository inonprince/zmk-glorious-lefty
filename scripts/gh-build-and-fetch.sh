#!/usr/bin/env bash
set -euo pipefail

usage() {
  cat <<'EOF'
Smart ZMK firmware build helper for GitHub Actions.

Behavior:
  - If a run already exists for the same target commit SHA, it reuses it.
  - Otherwise it triggers a new workflow_dispatch run.
  - It waits for completion, downloads artifacts on success, or prints failed logs.
  - Output is saved as <base>-<short-sha>.uf2 (e.g., glove80_lh-zmk-1a2b3c4d.uf2)
    and skips if all expected outputs already exist.

Usage:
  scripts/gh-build-and-fetch.sh [options]

Options:
  -r, --repo <owner/name>    GitHub repo (default: inferred from origin remote)
  -b, --ref <branch>         Git ref/branch to build (default: current branch)
  -w, --workflow <name>      Workflow file or name (default: build.yml)
  -o, --out <dir>            Artifact output directory (default: ./artifacts)
  -f, --force-trigger        Always trigger a new run (ignore reusable existing runs)
  -h, --help                 Show this help
EOF
}

repo=""
ref=""
workflow="build.yml"
out_dir="artifacts"
force_trigger=false

is_sha_ref() {
  [[ "$1" =~ ^[0-9a-fA-F]{7,40}$ ]]
}

short_sha() {
  local sha="$1"
  printf '%s' "${sha:0:8}"
}

expected_bases_from_build_yaml() {
  local repo_root="$1"
  local build_yaml="$repo_root/build.yaml"
  local line boards_raw

  if [[ ! -f "$build_yaml" ]]; then
    return 0
  fi

  line="$(awk -F'[][]' '/^board:/ {print $2; exit}' "$build_yaml" || true)"
  if [[ -z "$line" ]]; then
    return 0
  fi

  IFS=',' read -r -a boards_raw <<<"$line"
  for b in "${boards_raw[@]}"; do
    b="${b//\"/}"
    b="${b//\'/}"
    b="$(printf '%s' "$b" | sed -e 's/^[[:space:]]*//' -e 's/[[:space:]]*$//')"
    if [[ -n "$b" ]]; then
      printf '%s\n' "${b}-zmk"
    fi
  done
}

artifact_output_path() {
  local base="$1"
  local sha="$2"
  printf '%s/%s-%s.uf2' "$out_dir" "$base" "$(short_sha "$sha")"
}

download_artifacts() {
  local run_id="$1"
  local target_sha="$2"
  local tmp_dir extracted_dir
  local -a uf2_files zip_files

  mkdir -p "$out_dir"
  tmp_dir="$(mktemp -d "${out_dir%/}/.gh-run-${run_id}-XXXXXX")"

  if gh run download "$run_id" --repo "$repo" --name firmware --dir "$tmp_dir"; then
    :
  else
    echo "Named artifact 'firmware' not found, downloading all artifacts..."
    gh run download "$run_id" --repo "$repo" --dir "$tmp_dir"
  fi

  mapfile -t uf2_files < <(find "$tmp_dir" -type f -name '*.uf2')

  if [[ ${#uf2_files[@]} -eq 0 ]]; then
    mapfile -t zip_files < <(find "$tmp_dir" -type f -name '*.zip')
    if [[ ${#zip_files[@]} -gt 0 ]]; then
      extracted_dir="$tmp_dir/extracted"
      mkdir -p "$extracted_dir"
      for z in "${zip_files[@]}"; do
        unzip -q "$z" -d "$extracted_dir"
      done
      mapfile -t uf2_files < <(find "$extracted_dir" -type f -name '*.uf2')
    fi
  fi

  if [[ ${#uf2_files[@]} -eq 0 ]]; then
    echo "No .uf2 artifact file found in downloaded artifacts." >&2
    rm -rf "$tmp_dir"
    return 1
  fi

  for uf2 in "${uf2_files[@]}"; do
    local base_name output_path
    base_name="$(basename "$uf2" .uf2)"
    output_path="$(artifact_output_path "$base_name" "$target_sha")"
    if [[ -e "$output_path" ]]; then
      echo "Artifact already exists: $output_path"
      continue
    fi
    mv "$uf2" "$output_path"
    echo "Saved artifact: $output_path"
  done

  rm -rf "$tmp_dir"
}

print_failed_logs() {
  local run_id="$1"
  gh run view "$run_id" --repo "$repo" --log-failed || gh run view "$run_id" --repo "$repo" --log
}

process_run() {
  local run_id="$1"
  local status="" conclusion="" run_url=""

  run_url="$(gh run view "$run_id" --repo "$repo" --json url --jq '.url')"
  status="$(gh run view "$run_id" --repo "$repo" --json status --jq '.status')"

  echo "Run: $run_url"

  if [[ "$status" != "completed" ]]; then
    echo "Watching run..."
    if ! gh run watch "$run_id" --repo "$repo" --interval 10 --exit-status; then
      echo "Build failed. Printing failed log output..."
      print_failed_logs "$run_id"
      exit 1
    fi
  fi

  conclusion="$(gh run view "$run_id" --repo "$repo" --json conclusion --jq '.conclusion // ""')"
  if [[ "$conclusion" == "success" ]]; then
    download_artifacts "$run_id" "$target_sha"
    return 0
  fi

  echo "Run conclusion: ${conclusion:-unknown}"
  echo "Printing failed log output..."
  print_failed_logs "$run_id"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -r|--repo)
      repo="${2:-}"; shift 2 ;;
    -b|--ref)
      ref="${2:-}"; shift 2 ;;
    -w|--workflow)
      workflow="${2:-}"; shift 2 ;;
    -o|--out)
      out_dir="${2:-}"; shift 2 ;;
    -f|--force-trigger)
      force_trigger=true; shift ;;
    -h|--help)
      usage; exit 0 ;;
    *)
      echo "Unknown argument: $1" >&2
      usage
      exit 2 ;;
  esac
done

if ! command -v gh >/dev/null 2>&1; then
  echo "gh CLI is not installed or not in PATH." >&2
  exit 1
fi

if ! gh auth status -h github.com >/dev/null 2>&1; then
  echo "gh is not authenticated. Run: gh auth login -h github.com" >&2
  exit 1
fi

repo_root="$(git rev-parse --show-toplevel 2>/dev/null || true)"

if [[ -z "$repo" ]]; then
  if [[ -z "$repo_root" ]]; then
    echo "Not in a git repo and --repo was not provided." >&2
    exit 1
  fi
  origin_url="$(git -C "$repo_root" remote get-url origin)"
  repo="${origin_url#git@github.com:}"
  repo="${repo#https://github.com/}"
  repo="${repo%.git}"
fi

if [[ -z "$ref" ]]; then
  if [[ -z "$repo_root" ]]; then
    echo "--ref is required when not running inside a git repo." >&2
    exit 1
  fi
  ref="$(git -C "$repo_root" rev-parse --abbrev-ref HEAD)"
  if [[ "$ref" == "HEAD" ]]; then
    echo "Detached HEAD detected. Pass --ref <branch>." >&2
    exit 1
  fi
fi

target_sha="$(gh api "repos/$repo/commits/$ref" --jq '.sha')"
if [[ -z "$target_sha" || "$target_sha" == "null" ]]; then
  echo "Could not resolve target commit SHA for ref '$ref' in '$repo'." >&2
  exit 1
fi

if [[ -n "$repo_root" ]]; then
  mapfile -t expected_bases < <(expected_bases_from_build_yaml "$repo_root")
else
  expected_bases=()
fi

if [[ ${#expected_bases[@]} -gt 0 ]]; then
  all_present=true
  for base in "${expected_bases[@]}"; do
    path="$(artifact_output_path "$base" "$target_sha")"
    if [[ ! -e "$path" ]]; then
      all_present=false
      break
    fi
  done

  if [[ "$all_present" == true ]]; then
    echo "Artifacts already exist for commit $(short_sha "$target_sha"):"
    for base in "${expected_bases[@]}"; do
      echo "  $(artifact_output_path "$base" "$target_sha")"
    done
    echo "Nothing to do."
    exit 0
  fi
fi

run_list_args=(--repo "$repo" --workflow "$workflow")
if ! is_sha_ref "$ref"; then
  run_list_args+=(--branch "$ref")
fi

echo "Repo: $repo"
echo "Ref: $ref"
echo "Workflow: $workflow"
echo "Target SHA: $target_sha"

if [[ "$force_trigger" != true ]]; then
  existing_running_id=""
  existing_running_updated=""
  existing_completed_id=""
  existing_completed_updated=""

  while IFS=$'\t' read -r id sha status _conclusion _url _event _created updated; do
    [[ "$sha" == "$target_sha" ]] || continue

    if [[ "$status" != "completed" ]]; then
      if [[ -z "$existing_running_id" || "$updated" > "$existing_running_updated" ]]; then
        existing_running_id="$id"
        existing_running_updated="$updated"
      fi
    else
      if [[ -z "$existing_completed_id" || "$updated" > "$existing_completed_updated" ]]; then
        existing_completed_id="$id"
        existing_completed_updated="$updated"
      fi
    fi
  done < <(
    gh run list "${run_list_args[@]}" --limit 200 \
      --json databaseId,headSha,status,conclusion,url,event,createdAt,updatedAt \
      --jq '.[] | [.databaseId, .headSha, .status, (.conclusion // ""), .url, .event, .createdAt, .updatedAt] | @tsv'
  )

  if [[ -n "$existing_running_id" ]]; then
    echo "Reusing existing in-progress run for this SHA: $existing_running_id"
    process_run "$existing_running_id"
    exit 0
  fi

  if [[ -n "$existing_completed_id" ]]; then
    echo "Reusing existing completed run for this SHA: $existing_completed_id"
    process_run "$existing_completed_id"
    exit 0
  fi
fi

echo "No reusable run found. Triggering workflow..."
gh workflow run "$workflow" --repo "$repo" --ref "$ref"

echo "Waiting for new workflow_dispatch run for SHA $target_sha..."
new_run_id=""
for _ in $(seq 1 120); do
  while IFS=$'\t' read -r id sha; do
    if [[ "$sha" == "$target_sha" ]]; then
      new_run_id="$id"
      break
    fi
  done < <(
    gh run list "${run_list_args[@]}" --event workflow_dispatch --limit 100 \
      --json databaseId,headSha \
      --jq '.[] | [.databaseId, .headSha] | @tsv'
  )

  if [[ -n "$new_run_id" ]]; then
    break
  fi
  sleep 2
done

if [[ -z "$new_run_id" ]]; then
  echo "Could not find the newly triggered run for SHA $target_sha." >&2
  exit 1
fi

process_run "$new_run_id"
exit 0
