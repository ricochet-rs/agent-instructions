#!/usr/bin/env python3
import argparse
import json
import re
import subprocess
import sys
import tempfile
from collections import Counter
from dataclasses import asdict, dataclass, field
from pathlib import Path
from typing import Any

import tomllib

Node = dict[str, Any]
RGBA = tuple[float, float, float, float]
CONFIG_NAME = "design-lint.toml"
DESCRIPTION = """Check a .figcraft file against a project's design system rules.

Reads the file through `figcraft-cli run`, so it needs no running app and never writes the file.
Project rules come from the nearest `design-lint.toml` above each file, or from --config.
Errors break a hard rule, warnings need a human look.
Exit code: 0 clean, 1 errors found (or warnings with --strict), 2 usage or figcraft-cli failure.
"""


@dataclass
class CopyRule:
    severity: str
    rule: str
    message: str
    pattern: re.Pattern[str]
    # Whether the rule also applies to text set in a monospace font, such as code and ids.
    mono: bool


# The shared prose rules ban these in every project, so they apply even without a config.
BASE_COPY_RULES = [
    CopyRule("error", "copy-em-dash", "em dash", re.compile("\u2014"), True),
    CopyRule(
        "error", "copy-en-dash", "spaced en dash", re.compile(r"\s\u2013\s"), True
    ),
]


@dataclass
class Config:
    source: str = "defaults"
    # Allowed font families. Empty skips the font check.
    fonts: tuple[str, ...] = ()
    mono_fonts: tuple[str, ...] = ("Menlo", "JetBrains Mono", "Geist Mono", "SF Mono")
    # Top-level frames named like this are exploration work and are skipped.
    ignored_frame_prefixes: tuple[str, ...] = ("Audit",)
    # Flag any corner radius short of a full circle or pill.
    sharp_corners: bool = False
    copy: list[CopyRule] = field(default_factory=lambda: list(BASE_COPY_RULES))


def load_config(path: Path | None) -> Config:
    if path is None:
        return Config()
    raw = tomllib.loads(path.read_text())
    config = Config(source=str(path))
    for key in ("fonts", "mono_fonts", "ignored_frame_prefixes"):
        if key in raw:
            setattr(config, key, tuple(raw[key]))
    config.sharp_corners = bool(raw.get("sharp_corners", False))
    for rule in raw.get("copy", []):
        flags = re.IGNORECASE if rule.get("ignore_case") else 0
        config.copy.append(
            CopyRule(
                rule.get("severity", "error"),
                rule["rule"],
                rule.get("message", rule["rule"]),
                re.compile(rule["pattern"], flags),
                bool(rule.get("mono", True)),
            )
        )
    return config


def find_config(file: Path) -> Path | None:
    for directory in file.resolve().parents:
        candidate = directory / CONFIG_NAME
        if candidate.is_file():
            return candidate
    return None


@dataclass
class Finding:
    severity: str
    rule: str
    page: str
    frame: str
    id: int
    name: str
    detail: str


def run_figcraft(path: Path, steps: list[dict[str, Any]]) -> list[Any]:
    with tempfile.NamedTemporaryFile("w", suffix=".json", delete=False) as script:
        json.dump(steps, script)
    try:
        proc = subprocess.run(
            ["figcraft-cli", "run", "--in", str(path), script.name],
            capture_output=True,
            text=True,
            check=False,
        )
    finally:
        Path(script.name).unlink()
    if proc.returncode != 0:
        sys.exit(
            f"design-lint: figcraft-cli failed on {path}: {proc.stderr.strip() or proc.stdout.strip()}"
        )
    results = []
    for line in proc.stdout.splitlines():
        step = json.loads(line)
        if not step.get("ok", False):
            sys.exit(f"design-lint: step {step.get('command')} failed: {line}")
        results.append(step["result"])
    return results


def load_document(path: Path) -> tuple[list[dict[str, Any]], dict[int, Node]]:
    pages = run_figcraft(path, [{"command": "page.list", "params": {}}])[0]
    finds = run_figcraft(
        path,
        [
            {"command": "node.find", "params": {"root": p["id"], "limit": 10000}}
            for p in pages
        ],
    )
    ids = [p["id"] for p in pages] + [i for f in finds for i in f["ids"]]
    for page, found in zip(pages, finds, strict=True):
        if found["total"] > len(found["ids"]):
            sys.exit(f"design-lint: page {page['name']} has more than 10000 layers")
    nodes = run_figcraft(
        path, [{"command": "node.get", "params": {"id": i}} for i in ids]
    )
    return pages, {n["id"]: n for n in nodes}


def parse_hex(value: str) -> RGBA:
    h = value.lstrip("#")
    alpha = int(h[6:8], 16) / 255 if len(h) == 8 else 1.0
    return (int(h[0:2], 16) / 255, int(h[2:4], 16) / 255, int(h[4:6], 16) / 255, alpha)


def paint_rgba(paint: dict[str, Any]) -> RGBA | None:
    if paint.get("type") != "solid" or paint.get("visible") is False:
        return None
    r, g, b, a = parse_hex(paint["color"])
    # `opacity` repeats the hex alpha when present, so take the hex value alone.
    return (r, g, b, a)


def over(top: RGBA, bottom: RGBA) -> RGBA:
    a = top[3]
    return (
        top[0] * a + bottom[0] * (1 - a),
        top[1] * a + bottom[1] * (1 - a),
        top[2] * a + bottom[2] * (1 - a),
        1.0,
    )


def luminance(c: RGBA) -> float:
    def channel(v: float) -> float:
        return v / 12.92 if v <= 0.04045 else ((v + 0.055) / 1.055) ** 2.4

    return 0.2126 * channel(c[0]) + 0.7152 * channel(c[1]) + 0.0722 * channel(c[2])


def contrast(a: RGBA, b: RGBA) -> float:
    la, lb = sorted((luminance(a), luminance(b)), reverse=True)
    return (la + 0.05) / (lb + 0.05)


def is_large_text(node: Node) -> bool:
    size = float(node.get("fontSize") or 0)
    bold = str(node.get("fontStyle", "")).lower() in (
        "semibold",
        "bold",
        "extrabold",
        "black",
    )
    return size >= 24 or (bold and size >= 18.66)


class Linter:
    def __init__(
        self, pages: list[dict[str, Any]], nodes: dict[int, Node], config: Config
    ) -> None:
        self.pages = pages
        self.nodes = nodes
        self.config = config
        self.parent: dict[int, int] = {}
        for node in nodes.values():
            for child in node.get("children") or []:
                self.parent[child["id"]] = node["id"]
        self.page_bg = {
            p["id"]: parse_hex(nodes[p["id"]].get("background", "#FFFFFF"))
            for p in pages
        }
        self.findings: list[Finding] = []

    def chain(self, node_id: int) -> list[int]:
        """Ancestors from the page down to the node itself."""
        out = [node_id]
        while out[-1] in self.parent:
            out.append(self.parent[out[-1]])
        return out[::-1]

    def report(self, severity: str, rule: str, node: Node, detail: str) -> None:
        chain = self.chain(node["id"])
        page = self.nodes[chain[0]]["name"]
        frame = self.nodes[chain[1]]["name"] if len(chain) > 1 else ""
        self.findings.append(
            Finding(severity, rule, page, frame, node["id"], node["name"], detail)
        )

    def skipped(self, node_id: int, frames: list[str]) -> bool:
        chain = self.chain(node_id)
        if any(self.nodes[i].get("visible") is False for i in chain):
            return True
        if len(chain) < 2:
            return True
        top = self.nodes[chain[1]]["name"]
        if self.config.ignored_frame_prefixes and top.startswith(
            self.config.ignored_frame_prefixes
        ):
            return True
        return bool(frames) and not any(f.lower() in top.lower() for f in frames)

    def background(self, node_id: int) -> RGBA:
        chain = self.chain(node_id)
        color = self.page_bg[chain[0]]
        for ancestor in chain[1:-1]:
            for paint in self.nodes[ancestor].get("fills") or []:
                rgba = paint_rgba(paint)
                if rgba is not None:
                    color = over(rgba, color)
        return color

    def lint(self, frames: list[str]) -> list[Finding]:
        for node in self.nodes.values():
            if node["type"] == "PAGE" or self.skipped(node["id"], frames):
                continue
            # A component set's dashed outline is editor chrome, not part of a design.
            if node["type"] != "COMPONENT_SET":
                self.check_paints(node)
                if self.config.sharp_corners:
                    self.check_corners(node)
            self.check_effects(node)
            if node["type"] == "TEXT":
                self.check_text(node)
        return self.findings

    def check_paints(self, node: Node) -> None:
        bound = node.get("boundVariables") or {}
        for key, binding in (("fills", "fill"), ("strokes", "stroke")):
            paints = [p for p in node.get(key) or [] if p.get("visible") is not False]
            if paints and binding not in bound:
                colors = ", ".join(p.get("color", p.get("type", "?")) for p in paints)
                self.report(
                    "error",
                    "unbound-paint",
                    node,
                    f"{key} {colors} not bound to a variable",
                )

    def check_corners(self, node: Node) -> None:
        radius = node.get("cornerRadius")
        if not radius:
            return
        radii = radius if isinstance(radius, list) else [radius]
        # Circles and pills (avatars, radios, switches) round fully, which the rules allow.
        full = min(node["width"], node["height"]) / 2 - 0.5
        if any(0 < r < full for r in radii):
            self.report(
                "error",
                "rounded-corner",
                node,
                f"corner radius {radius} on a sharp-cornered system",
            )

    def check_effects(self, node: Node) -> None:
        styles = node.get("styles") or {}
        if node.get("effects") and not styles.get("effect"):
            self.report(
                "error",
                "unstyled-effect",
                node,
                "effects not from a library effect style",
            )

    def check_text(self, node: Node) -> None:
        text = node.get("characters", "")
        styles = node.get("styles") or {}
        ranges = node.get("textStyleRanges") or []
        covered = sum(end - start for start, end, style in ranges if style)
        if not styles.get("text") and covered < len(text):
            self.report(
                "error",
                "unstyled-text",
                node,
                f"{len(text) - covered} of {len(text)} characters lack a text style",
            )
        family = node.get("fontFamily")
        if family and self.config.fonts and family not in self.config.fonts:
            self.report("error", "off-system-font", node, f"font {family}")
        mono = family in self.config.mono_fonts
        for rule in self.config.copy:
            if (rule.mono or not mono) and rule.pattern.search(text):
                self.report(
                    rule.severity, rule.rule, node, f"{rule.message}: {text[:80]!r}"
                )
        self.check_contrast(node)

    def check_contrast(self, node: Node) -> None:
        fills = [
            c for c in (paint_rgba(p) for p in node.get("fills") or []) if c is not None
        ]
        if not fills or not node.get("characters", "").strip():
            return
        bg = self.background(node["id"])
        fg = bg
        for rgba in fills:
            fg = over(rgba, fg)
        ratio = contrast(fg, bg)
        need = 3.0 if is_large_text(node) else 4.5
        if ratio < need:
            self.report(
                "warning",
                "low-contrast",
                node,
                f"contrast {ratio:.2f} below {need} for {node.get('fontSize')}px text {node['characters'][:40]!r}",
            )


def print_report(
    path: Path, config: Config, findings: list[Finding], verbose: bool
) -> None:
    errors = [f for f in findings if f.severity == "error"]
    warnings = [f for f in findings if f.severity == "warning"]
    print(
        f"{path}: {len(errors)} errors, {len(warnings)} warnings (rules: {config.source})"
    )
    for (severity, rule), count in sorted(
        Counter((f.severity, f.rule) for f in findings).items()
    ):
        print(f"  {severity:7} {rule:22} {count}")
    if verbose:
        for f in findings:
            print(
                f"  [{f.severity}] {f.rule} {f.page} / {f.frame} / {f.name} (#{f.id}): {f.detail}"
            )


def main() -> None:
    parser = argparse.ArgumentParser(
        description=DESCRIPTION, formatter_class=argparse.RawDescriptionHelpFormatter
    )
    parser.add_argument("files", nargs="+", type=Path, help=".figcraft files to check")
    parser.add_argument(
        "--frame",
        action="append",
        default=[],
        help="only top-level frames whose name contains this (repeatable)",
    )
    parser.add_argument(
        "--config",
        type=Path,
        help=f"rules file (default: the nearest {CONFIG_NAME} above each file)",
    )
    parser.add_argument(
        "--font",
        action="append",
        default=[],
        help="allowed font family, replacing the config's (repeatable)",
    )
    parser.add_argument("--json", action="store_true", help="print findings as JSON")
    parser.add_argument("--strict", action="store_true", help="fail on warnings too")
    parser.add_argument(
        "-v", "--verbose", action="store_true", help="list every finding"
    )
    args = parser.parse_args()

    if args.config and not args.config.is_file():
        sys.exit(f"design-lint: no such config: {args.config}")
    failed = False
    report: dict[str, Any] = {}
    for path in args.files:
        if not path.is_file():
            sys.exit(f"design-lint: no such file: {path}")
        config = load_config(args.config or find_config(path))
        if args.font:
            config.fonts = tuple(args.font)
        pages, nodes = load_document(path)
        findings = Linter(pages, nodes, config).lint(args.frame)
        errors = sum(f.severity == "error" for f in findings)
        failed |= errors > 0 or (args.strict and bool(findings))
        if args.json:
            report[str(path)] = {
                "rules": config.source,
                "layers": len(nodes) - len(pages),
                "errors": errors,
                "warnings": len(findings) - errors,
                "byRule": dict(Counter(f.rule for f in findings)),
                "findings": [asdict(f) for f in findings],
            }
        else:
            print_report(path, config, findings, args.verbose)
    if args.json:
        json.dump(report, sys.stdout, indent=2)
        print()
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
