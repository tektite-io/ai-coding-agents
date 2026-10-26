#!/usr/bin/env bash
# scripts/update-google-skills.sh
# Checks upstream changes for vendor/google-skills, displays diff,
# and prompts for human confirmation before bumping the submodule pointer.

set -euo pipefail

script_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
repo_root="$(cd "$script_dir/.." && pwd)"
submod_dir="$repo_root/vendor/google-skills"

if [ ! -d "$submod_dir" ]; then
    echo "Error: Submodule directory not found at $submod_dir" >&2
    echo "Please initialize submodules first: git submodule update --init --recursive" >&2
    exit 1
fi

echo "Fetching latest upstream changes for google/skills..."
git -C "$submod_dir" fetch origin

current_commit="$(git -C "$submod_dir" rev-parse HEAD)"
upstream_branch="origin/main"
upstream_commit="$(git -C "$submod_dir" rev-parse "$upstream_branch")"

if [ "$current_commit" = "$upstream_commit" ]; then
    echo "✓ Submodule is already up to date at $current_commit ($upstream_branch)"
    exit 0
fi

echo ""
echo "=================================================="
echo "Upstream updates available for vendor/google-skills"
echo "Current pin:  $current_commit"
echo "Upstream pin: $upstream_commit ($upstream_branch)"
echo "=================================================="
echo ""
echo "Commit log:"
git -C "$submod_dir" log --oneline --graph "$current_commit..$upstream_commit"
echo ""
echo "Diff summary:"
git -C "$submod_dir" diff --stat "$current_commit" "$upstream_commit"
echo ""

read -r -p "Do you want to update the submodule pin to $upstream_commit? [y/N]: " confirm

case "$(printf '%s' "$confirm" | tr '[:upper:]' '[:lower:]')" in
    y|yes)
        echo "Updating submodule pin..."
        git -C "$submod_dir" checkout "$upstream_commit"
        git -C "$repo_root" add vendor/google-skills
        echo "✓ Submodule pin updated to $upstream_commit"

        echo "Regenerating local skills index..."
        "$script_dir/google-skills-gen-index.sh"

        echo "Done. Submodule bump is staged in git. Review and commit when ready:"
        echo "  git diff --cached vendor/google-skills"
        ;;
    *)
        echo "Submodule update cancelled. Submodule remains pinned at $current_commit."
        exit 0
        ;;
esac
