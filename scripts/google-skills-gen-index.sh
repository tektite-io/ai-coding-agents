#!/usr/bin/env bash
# scripts/google-skills-gen-index.sh
# Generates generated/google-skills-index.local.json with absolute local paths.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
skills_dir="$repo_root/vendor/google-skills/skills/cloud"
output_dir="$repo_root/generated"
output_file="$output_dir/google-skills-index.local.json"

if ! command -v jq >/dev/null 2>&1; then
    echo "Error: jq is required but not installed." >&2
    exit 1
fi

if [ ! -d "$skills_dir" ]; then
    echo "Error: Submodule directory not found at $skills_dir" >&2
    echo "Please run: git submodule update --init --recursive" >&2
    exit 1
fi

mkdir -p "$output_dir"
temp_file="$(mktemp)"
trap 'rm -f "$temp_file"' EXIT

while IFS= read -r skill_file; do
    if [ -z "$skill_file" ]; then
        continue
    fi

    skill_dir="$(dirname "$skill_file")"
    skill_name="$(basename "$skill_dir")"

    # Exclude finding-google-skills
    if [ "$skill_name" = "finding-google-skills" ]; then
        continue
    fi

    parsed="$(awk '
    BEGIN { in_fm=0; name=""; desc=""; in_desc=0 }
    /^---$/ {
      if (in_fm == 0) { in_fm=1; next }
      else { exit }
    }
    in_fm {
      if ($1 == "name:") {
        name = $2
        in_desc = 0
      } else if ($1 == "description:" || $1 ~ /^description:/) {
        in_desc = 1
        sub(/^description:[ \t]*/, "")
        sub(/^[>|]-?[ \t]*/, "")
        desc = $0
      } else if (in_desc && /^[ \t]+/) {
        sub(/^[ \t]+/, "")
        if (desc == "") desc = $0
        else desc = desc " " $0
      } else if (/^[a-zA-Z0-9_-]+:/) {
        in_desc = 0
      }
    }
    END {
      printf "%s\n%s\n", name, desc
    }
    ' "$skill_file")"

    s_name="$(printf '%s\n' "$parsed" | head -n 1)"
    if [ -z "$s_name" ]; then
        s_name="$skill_name"
    fi
    s_desc="$(printf '%s\n' "$parsed" | tail -n +2 | tr '\n' ' ' | sed -e 's/[[:space:]]*$//')"

    jq -n --arg name "$s_name" --arg desc "$s_desc" --arg entry "$skill_file" \
      '{name: $name, description: $desc, entrypoint: $entry}' >> "$temp_file"
done < <(find "$skills_dir" -mindepth 2 -maxdepth 2 -name "SKILL.md" | sort)

jq -s '{skills: .}' "$temp_file" > "$output_file"

total="$(jq '.skills | length' "$output_file")"
echo "✓ Generated $output_file with $total skills"
