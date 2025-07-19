# Repository Rulesets

GitHub repository rulesets defined as JSON files for easy management and version control.

## Import Instructions

1. Go to **Repository Settings** → **Rules** → **Rulesets**
2. Click **Import Ruleset**
3. Upload one of the JSON files below
4. Review and save

## Available Rulesets

- **`main-branch-protection.json`** - Protects main/master branches
  - Requires pull requests (no approval needed)
  - Enforces up-to-date branches before merge
  - Requires all CI checks to pass
  - Prevents force pushes and branch deletion
  - Repository owner can bypass all rules

- **`release-tag-protection.json`** - Protects version tags (v*)
  - Prevents tag deletion
  - Prevents tag modification

## Bypass Actors

The `bypass_actors` section allows certain users/roles to skip ruleset enforcement:

- **actor_type: "RepositoryRole"** with actor_id values:
  - `1` = Read access
  - `2` = Triage access  
  - `3` = Write access
  - `4` = Maintain access
  - `5` = Admin access (repository owners/admins)

- **bypass_mode** options:
  - `"always"` = Can bypass in all situations
  - `"pull_requests_only"` = Can only bypass via pull requests

## Customization

Edit the JSON files directly to modify rules, then re-import to GitHub.