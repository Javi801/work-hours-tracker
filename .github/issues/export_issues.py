"""
Export all existing GitHub issues (including body/description) to a YAML file.

Output: .github/issues/existing-issues.yml

Usage (local):
    GH_TOKEN=<token> GITHUB_REPOSITORY=owner/repo python3 .github/issues/export_issues.py

Usage (GitHub Actions):
    Run the "Export existing issues" workflow from the Actions tab.
    The result is committed as .github/issues/existing-issues.yml
"""

import json
import os
import subprocess
import sys
from pathlib import Path

import yaml


def fetch_issues() -> list[dict]:
    result = subprocess.run(
        [
            "gh", "issue", "list",
            "--state", "all",
            "--limit", "500",
            "--json", "number,title,body,labels,milestone,state,url,assignees,createdAt,updatedAt",
        ],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"❌ Failed to fetch issues: {result.stderr}", file=sys.stderr)
        sys.exit(1)

    return json.loads(result.stdout)


def normalize(issues: list[dict]) -> list[dict]:
    normalized = []
    for issue in sorted(issues, key=lambda i: i["number"]):
        normalized.append({
            "number": issue["number"],
            "title": issue["title"],
            "state": issue["state"],
            "url": issue["url"],
            "body": issue.get("body") or "",
            "labels": [label["name"] for label in issue.get("labels", [])],
            "milestone": issue["milestone"]["title"] if issue.get("milestone") else None,
            "assignees": [a["login"] for a in issue.get("assignees", [])],
            "created_at": issue.get("createdAt", ""),
            "updated_at": issue.get("updatedAt", ""),
        })
    return normalized


def main() -> None:
    issues = fetch_issues()
    if not issues:
        print("No issues found.")
        sys.exit(0)

    normalized = normalize(issues)

    # Group by state for the summary header
    open_issues   = [i for i in normalized if i["state"] == "OPEN"]
    closed_issues = [i for i in normalized if i["state"] == "CLOSED"]

    print(f"📋 Total:  {len(normalized)} issues")
    print(f"   Open:   {len(open_issues)}")
    print(f"   Closed: {len(closed_issues)}")

    # Group by milestone
    by_milestone: dict[str, list] = {}
    for issue in normalized:
        key = issue["milestone"] or "No milestone"
        by_milestone.setdefault(key, []).append(issue)

    print("\n   By milestone:")
    for milestone, group in sorted(by_milestone.items()):
        print(f"   · {milestone}: {len(group)}")

    output_path = Path(__file__).parent / "existing-issues.yml"

    # Use a custom YAML representer so multiline strings stay readable
    class LiteralStr(str):
        pass

    def literal_representer(dumper, data):
        if "\n" in data:
            return dumper.represent_scalar("tag:yaml.org,2002:str", data, style="|")
        return dumper.represent_scalar("tag:yaml.org,2002:str", data)

    yaml.add_representer(LiteralStr, literal_representer)

    def prepare(issues):
        result = []
        for issue in issues:
            entry = dict(issue)
            entry["body"] = LiteralStr(entry["body"]) if entry["body"] else ""
            result.append(entry)
        return result

    with open(output_path, "w", encoding="utf-8") as f:
        f.write("# Existing GitHub issues — exported with full descriptions\n")
        f.write(f"# Total: {len(normalized)} · Open: {len(open_issues)} · Closed: {len(closed_issues)}\n")
        f.write("# Generated automatically by .github/issues/export_issues.py\n\n")
        yaml.dump(prepare(normalized), f, allow_unicode=True, sort_keys=False, default_flow_style=False)

    print(f"\n✅ Exported to {output_path}")


if __name__ == "__main__":
    main()
