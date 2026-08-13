#!/usr/bin/env python3

import json
import re
import sys
from pathlib import Path
from typing import Any

import yaml

REPOSITORY_ROOT = Path(__file__).resolve().parent.parent
SKILLS_ROOT = REPOSITORY_ROOT / "skills"
INTERFACE_KEYS = {"display_name", "short_description", "default_prompt"}
MARKDOWN_LINK = re.compile(r"\[[^]]+\]\(([^)]+)\)")
SKILL_PATH = re.compile(r"skills/([a-z0-9-]+)/SKILL\.md")
SENTENCE_BOUNDARY = re.compile(r"[.!?][\"')\]]*\s+[A-Z]")


def fail(message: str) -> None:
    print(message, file=sys.stderr)
    raise SystemExit(1)


def load_yaml(path: Path) -> Any:
    with path.open(encoding="utf-8") as stream:
        try:
            return yaml.safe_load(stream)
        except yaml.YAMLError as error:
            fail(f"invalid YAML in {path.relative_to(REPOSITORY_ROOT)}: {error}")


def load_skill_frontmatter(path: Path) -> dict[str, Any]:
    text = path.read_text(encoding="utf-8")
    match = re.match(r"\A---\n(.*?)\n---\n", text, re.DOTALL)
    if match is None:
        fail(f"skill frontmatter is missing: {path.relative_to(REPOSITORY_ROOT)}")
    try:
        metadata = yaml.safe_load(match.group(1))
    except yaml.YAMLError as error:
        fail(
            f"invalid skill frontmatter in {path.relative_to(REPOSITORY_ROOT)}: {error}"
        )
    if not isinstance(metadata, dict):
        fail(
            f"skill frontmatter must be a mapping: {path.relative_to(REPOSITORY_ROOT)}"
        )
    return metadata


def validate_plugin_manifest() -> None:
    path = REPOSITORY_ROOT / ".codex-plugin" / "plugin.json"
    try:
        manifest = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as error:
        fail(f"invalid plugin manifest: {error}")
    required_types = {
        "name": str,
        "version": str,
        "description": str,
        "author": dict,
        "skills": str,
        "interface": dict,
    }
    for field, expected_type in required_types.items():
        if not isinstance(manifest.get(field), expected_type):
            fail(f"plugin manifest field {field!r} must be {expected_type.__name__}")
    skills_path = (REPOSITORY_ROOT / manifest["skills"]).resolve()
    if skills_path != SKILLS_ROOT.resolve():
        fail("plugin manifest skills path must resolve to skills/")


def validate_skills() -> set[str]:
    names: set[str] = set()
    for skill_path in sorted(SKILLS_ROOT.iterdir()):
        if not skill_path.is_dir():
            continue
        skill_file = skill_path / "SKILL.md"
        agent_file = skill_path / "agents" / "openai.yaml"
        if not skill_file.is_file():
            fail(f"skill file is missing: {skill_file.relative_to(REPOSITORY_ROOT)}")
        if not agent_file.is_file():
            fail(
                f"agent metadata is missing: {agent_file.relative_to(REPOSITORY_ROOT)}"
            )
        metadata = load_skill_frontmatter(skill_file)
        if set(metadata) != {"name", "description"}:
            fail(
                f"skill frontmatter must contain only name and description: {skill_path.name}"
            )
        name = metadata.get("name")
        description = metadata.get("description")
        if name != skill_path.name:
            fail(f"skill name does not match its directory: {skill_path.name}")
        if name in names:
            fail(f"duplicate skill name: {name}")
        if not isinstance(description, str) or not description.strip():
            fail(f"skill description is missing: {skill_path.name}")
        names.add(name)
        validate_agent_metadata(agent_file, name)
    return names


def validate_agent_metadata(path: Path, skill_name: str) -> None:
    document = load_yaml(path)
    if not isinstance(document, dict) or set(document) != {"interface"}:
        fail(
            f"agent metadata must contain only interface: {path.relative_to(REPOSITORY_ROOT)}"
        )
    interface = document["interface"]
    if not isinstance(interface, dict) or set(interface) != INTERFACE_KEYS:
        fail(f"agent interface fields are invalid: {path.relative_to(REPOSITORY_ROOT)}")
    if not all(
        isinstance(interface[key], str) and interface[key] for key in INTERFACE_KEYS
    ):
        fail(
            f"agent interface values must be non-empty strings: {path.relative_to(REPOSITORY_ROOT)}"
        )
    short_description = interface["short_description"]
    if not 25 <= len(short_description) <= 64:
        fail(
            f"agent short_description must contain 25 to 64 characters: {path.relative_to(REPOSITORY_ROOT)}"
        )
    if f"${skill_name}" not in interface["default_prompt"]:
        fail(
            f"agent default_prompt must mention ${skill_name}: {path.relative_to(REPOSITORY_ROOT)}"
        )


def validate_yaml_resources() -> None:
    paths = [
        *SKILLS_ROOT.glob("*/agents/openai.yaml"),
        *(REPOSITORY_ROOT / "templates").glob("*.yaml"),
    ]
    for path in sorted(paths):
        load_yaml(path)


def validate_markdown_links() -> None:
    for path in sorted(REPOSITORY_ROOT.rglob("*.md")):
        if ".git" in path.parts:
            continue
        text = path.read_text(encoding="utf-8")
        if "—" in text:
            fail(f"em dash found in {path.relative_to(REPOSITORY_ROOT)}")
        for target in MARKDOWN_LINK.findall(text):
            target_path = target.split("#", maxsplit=1)[0]
            if (
                not target_path
                or "://" in target_path
                or target_path.startswith("mailto:")
            ):
                continue
            resolved = (path.parent / target_path).resolve()
            if not resolved.exists():
                fail(
                    f"broken Markdown link in {path.relative_to(REPOSITORY_ROOT)}: {target}"
                )


def validate_markdown_prose() -> None:
    for path in sorted(REPOSITORY_ROOT.rglob("*.md")):
        if ".git" in path.parts:
            continue
        in_frontmatter = False
        in_fence = False
        for line_number, line in enumerate(
            path.read_text(encoding="utf-8").splitlines(), start=1
        ):
            if line_number == 1 and line == "---":
                in_frontmatter = True
                continue
            if in_frontmatter and line == "---":
                in_frontmatter = False
                continue
            if line.startswith("```"):
                in_fence = not in_fence
                continue
            if in_frontmatter or in_fence or line.startswith("|"):
                continue
            prose = re.sub(r"^\s*\d+\.\s+", "", line)
            if SENTENCE_BOUNDARY.search(prose):
                fail(
                    f"multiple prose sentences on one line: {path.relative_to(REPOSITORY_ROOT)}:{line_number}"
                )


def validate_template_skill_references(skill_names: set[str]) -> None:
    for path in sorted((REPOSITORY_ROOT / "templates").glob("*.md")):
        for skill_name in SKILL_PATH.findall(path.read_text(encoding="utf-8")):
            if skill_name not in skill_names:
                fail(
                    f"template references missing skill {skill_name}: {path.relative_to(REPOSITORY_ROOT)}"
                )


def main() -> None:
    validate_plugin_manifest()
    skill_names = validate_skills()
    validate_yaml_resources()
    validate_markdown_links()
    validate_markdown_prose()
    validate_template_skill_references(skill_names)


if __name__ == "__main__":
    main()
