"""
Create GitHub issues from .github/issues/pending.yml

Usage (local):
    GH_TOKEN=<token> GITHUB_REPOSITORY=owner/repo python3 .github/issues/create_issues.py

Usage (GitHub Actions):
    Called automatically by .github/workflows/create-issues.yml
"""

import json
import os
import subprocess
import sys

import yaml


def get_existing_titles() -> set[str]:
    result = subprocess.run(
        ["gh", "issue", "list", "--state", "all", "--json", "title", "--limit", "500"],
        capture_output=True,
        text=True,
    )
    if result.returncode != 0:
        print(f"❌ Could not fetch existing issues: {result.stderr}", file=sys.stderr)
        sys.exit(1)
    return {issue["title"] for issue in json.loads(result.stdout)}


def ensure_milestones(issues: list[dict]) -> None:
    milestones = {i.get("milestone") for i in issues if i.get("milestone")}
    repo = os.environ.get("GITHUB_REPOSITORY", "")
    for milestone in sorted(milestones):
        result = subprocess.run(
            [
                "gh", "api",
                f"repos/{repo}/milestones",
                "--method", "POST",
                "-f", f"title={milestone}",
                "-f", "state=open",
            ],
            capture_output=True,
            text=True,
        )
        if result.returncode == 0:
            print(f"🏁 Created milestone: {milestone}")
        else:
            # 422 means it already exists — that's fine
            print(f"   Milestone already exists: {milestone}")


def create_issue(issue: dict) -> bool:
    cmd = [
        "gh", "issue", "create",
        "--title", issue["title"],
        "--body", issue.get("body", ""),
    ]
    for label in issue.get("labels", []):
        cmd += ["--label", label]
    if "milestone" in issue:
        cmd += ["--milestone", issue["milestone"]]

    result = subprocess.run(cmd, capture_output=True, text=True)
    if result.returncode == 0:
        url = result.stdout.strip()
        print(f"✅ Created: {issue['title']}\n   {url}")
        return True
    else:
        print(f"❌ Failed:  {issue['title']}\n   {result.stderr.strip()}", file=sys.stderr)
        return False


def main() -> None:
    yaml_path = os.path.join(os.path.dirname(__file__), "pending.yml")
    with open(yaml_path, "r") as f:
        issues = yaml.safe_load(f)

    if not issues:
        print("No issues found in pending.yml")
        sys.exit(0)

    print(f"📋 Found {len(issues)} issues in pending.yml\n")

    ensure_milestones(issues)
    print()

    existing = get_existing_titles()
    print(f"🔍 Found {len(existing)} existing issues in the repository\n")

    created = skipped = failed = 0

    for issue in issues:
        title = issue.get("title", "").strip()
        if not title:
            print("⚠️  Skipping issue with no title")
            continue

        if title in existing:
            print(f"⏭  Skipped (exists): {title}")
            skipped += 1
            continue

        if create_issue(issue):
            existing.add(title)  # Avoid duplicates within the same run
            created += 1
        else:
            failed += 1

    print(f"\n{'─' * 60}")
    print(f"📊 Summary: {created} created · {skipped} skipped · {failed} failed")

    if failed > 0:
        sys.exit(1)


if __name__ == "__main__":
    main()
