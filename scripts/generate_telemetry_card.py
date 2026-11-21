#!/usr/bin/env python3
"""
Local, privacy-safe generator for Agyhub README build-telemetry cards (SVG + 3x PNG).

Reads local Antigravity conversation transcripts (read-only), aggregates anonymous
project-level metrics (human-AI turns, total tokens, cache hit rate, estimated API bill),
writes bilingual SVGs with the Hakimi cat emblem, and renders 3x Retina PNGs via
headless Chrome (auto-detecting local LXGW WenKai font if installed).

No usernames, emails, absolute local paths, or private session contents are ever written.
"""

from __future__ import annotations

import argparse
import glob
import importlib.util
import json
import os
import subprocess
import sys
import tempfile
from pathlib import Path
from typing import Iterable


REPO_ROOT = Path(__file__).resolve().parent.parent
DEFAULT_ASSETS_DIR = REPO_ROOT / "assets"
DEFAULT_KEYWORDS = ("agyhub", "agy-hub", "agy-monitor", "agyhub.swift")
DEFAULT_CHROME_CANDIDATES = (
    "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome",
    "/Applications/Chromium.app/Contents/MacOS/Chromium",
)


def _load_monitor_module():
    """Dynamically import agy-monitor.py from the repository root."""
    monitor_path = REPO_ROOT / "agy-monitor.py"
    spec = importlib.util.spec_from_file_location("agy_monitor", str(monitor_path))
    if spec is None or spec.loader is None:
        raise RuntimeError(f"Unable to load monitor engine at {monitor_path}")
    mod = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(mod)
    return mod


def _find_lxgw_font() -> str | None:
    """Locate an installed LXGW WenKai font file under standard macOS font folders."""
    patterns = [
        os.path.expanduser("~/Library/Fonts/LXGWWenKai*Regular*.ttf"),
        os.path.expanduser("~/Library/Fonts/LXGWWenKai*.ttf"),
        "/Library/Fonts/LXGWWenKai*.ttf",
    ]
    for pat in patterns:
        matches = sorted(glob.glob(pat))
        if matches:
            return matches[0]
    return None


def _find_chrome() -> str | None:
    """Locate a headless-capable Chrome/Chromium binary."""
    env_chrome = os.environ.get("AGYHUB_CHROME_BIN", "").strip()
    if env_chrome and os.path.isfile(env_chrome):
        return env_chrome
    for cand in DEFAULT_CHROME_CANDIDATES:
        if os.path.isfile(cand):
            return cand
    return None


def collect_local_metrics(keywords: Iterable[str]) -> dict:
    """Aggregate anonymous telemetry metrics across matching local Antigravity sessions."""
    mod = _load_monitor_module()
    kw_lower = tuple(k.lower() for k in keywords if k.strip())
    kw_bytes = tuple(k.encode("utf-8") for k in kw_lower)

    data_dirs = [
        os.path.expanduser("~/.gemini/antigravity"),
        os.path.expanduser("~/.gemini/antigravity-cli"),
    ]
    matched_convs: dict[str, tuple[str, dict]] = {}

    for d in data_dirs:
        brain = os.path.join(d, "brain")
        if not os.path.isdir(brain):
            continue
        for conv in mod._load_conversations_from_dir(d, limit=2000):
            cid = conv.get("uuid") or ""
            if not cid or cid in matched_convs:
                continue
            title_low = (conv.get("title") or "").lower()
            tpath = os.path.join(brain, cid, ".system_generated", "logs", "transcript.jsonl")
            hit = any(k in title_low for k in kw_lower)
            if not hit and os.path.isfile(tpath):
                try:
                    raw_low = open(tpath, "rb").read().lower()
                    hit = any(kb in raw_low for kb in kw_bytes)
                except OSError:
                    hit = False
            if hit:
                matched_convs[cid] = (tpath, conv)

    human_turns = 0
    total_tokens = 0
    total_cache = 0
    total_cost = 0.0

    for _cid, (tpath, conv) in matched_convs.items():
        if os.path.isfile(tpath):
            try:
                with open(tpath, "r", encoding="utf-8", errors="ignore") as f:
                    for line in f:
                        line = line.strip()
                        if not line:
                            continue
                        try:
                            obj = json.loads(line)
                        except json.JSONDecodeError:
                            continue
                        if obj.get("type") == "USER_INPUT" and obj.get("source") in ("USER_EXPLICIT", None, "USER"):
                            human_turns += 1
            except OSError:
                pass

        for item in [conv] + list(conv.get("subagents") or []):
            total_tokens += int(item.get("total_tokens_consumed") or 0)
            total_cache += int(item.get("total_cache_consumed") or 0)
            total_cost += float(item.get("total_cost_usd") or 0.0)

    cache_hit_pct = (total_cache / total_tokens * 100.0) if total_tokens > 0 else 0.0
    return {
        "turns": human_turns,
        "tokens": total_tokens,
        "cache_hit_pct": cache_hit_pct,
        "cost_usd": total_cost,
    }


def _format_tokens(tokens: int) -> str:
    if tokens >= 1_000_000_000:
        return f"{tokens / 1_000_000_000:.2f}B"
    if tokens >= 1_000_000:
        return f"{tokens / 1_000_000:.1f}M"
    if tokens >= 1_000:
        return f"{tokens / 1_000:.1f}K"
    return str(tokens)


def _hakimi_cat_emblem_svg() -> str:
    """Minimal line-art sketch cat emblem with signature asymmetric glare (left squint, right glare)."""
    return """  <!-- Right Minimal Line-Art Cat Emblem (Hakimi Sketch) -->
  <g transform="translate(742, 13)" aria-label="Hakimi Line-Art Cat">
    <!-- Clean Cat Head Outline -->
    <path d="M4.2 14.8 L5.3 4.2 L12.0 9.1 Q16.0 8.3 20.0 9.1 L26.7 4.2 L27.8 14.8 Q28.6 25.0 16.0 25.8 Q3.4 25.0 4.2 14.8 Z"
          fill="none" stroke="#94A3B8" stroke-width="1.35" stroke-linejoin="round" stroke-linecap="round"/>
    <!-- Left Eye: Signature Slanted Squint -->
    <path d="M8.0 15.2 L13.8 16.6" fill="none" stroke="#22C55E" stroke-width="1.6" stroke-linecap="round"/>
    <!-- Right Eye: Open Glare -->
    <circle cx="20.8" cy="15.9" r="1.9" fill="#22C55E"/>
    <!-- Tiny Nose & Stern Mouth -->
    <path d="M15.0 19.6 L17.0 19.6 L16.0 20.8 Z" fill="#94A3B8"/>
    <path d="M13.9 22.7 L16.0 21.8 L18.1 22.7" fill="none" stroke="#64748B" stroke-width="1.05" stroke-linecap="round" stroke-linejoin="round"/>
    <!-- Minimal Whiskers -->
    <path d="M1.2 19.4 L6.0 20.1 M1.6 22.4 L6.2 22.0 M26.0 20.1 L30.8 19.4 M25.8 22.0 L30.4 22.4"
          stroke="#475569" stroke-width="1.0" stroke-linecap="round"/>
  </g>"""


def build_svg(lang: str, turns: int, tokens: int, cache_hit_pct: float, cost_usd: float) -> str:
    """Build bilingual precision-instrument SVG card with aligned 3-column layout."""
    tokens_str = _format_tokens(tokens)
    turns_str = f"{turns:,}"
    cost_str = f"${cost_usd:.2f}"
    ring_pct = int(round(cache_hit_pct))
    circ = 78.54
    dash = max(0.0, min(circ, circ * (cache_hit_pct / 100.0)))

    if lang == "zh":
        aria = f"使用 Google Antigravity 开发：{turns_str} 轮人机交互，{tokens_str} 总 Token（{cache_hit_pct:.1f}% 缓存命中），估算 API 账单 {cost_str}"
        header_text = "由 Google 反重力（Antigravity）驱动构建"
        header_font = "'LXGW WenKai', 'PingFang SC', -apple-system, sans-serif"
        header_size = "13.5"
        header_spacing = "0.6"
        col1_title = "01 / 人机交互轮次"
        col1_sub = "从想法到开源发布的真实对话"
        col2_title = "02 / 累计消耗 Token"
        col2_mid = f"缓存命中 {cache_hit_pct:.1f}%"
        col2_sub = "全周期真实上下文消耗"
        col3_title = "03 / 估算 API 账单"
        col3_sub = "纯代码离线核算 · 零额外大模型开销"
        label_font = "'LXGW WenKai', 'PingFang SC', sans-serif"
        label_size = "12.5"
        label_spacing = "0.5"
        num_font = "'JetBrains Mono', 'LXGW WenKai', ui-monospace, monospace"
    else:
        aria = f"Built with Google Antigravity: {turns_str} human-AI turns, {tokens_str} tokens with {cache_hit_pct:.1f}% cache hit, {cost_str} estimated API bill"
        header_text = "BUILT WITH GOOGLE ANTIGRAVITY"
        header_font = "'JetBrains Mono', ui-monospace, SFMono-Regular, Menlo, monospace"
        header_size = "11"
        header_spacing = "1.4"
        col1_title = "01 / HUMAN–AI TURNS"
        col1_sub = "Prompts from idea to ship"
        col2_title = "02 / COMPUTE VOLUME"
        col2_mid = f"{cache_hit_pct:.1f}% Cache Hit"
        col2_sub = "Tokens across full build"
        col3_title = "03 / EST. API BILL"
        col3_sub = "Offline log audit · zero LLM cost"
        label_font = "'JetBrains Mono', ui-monospace, SFMono-Regular, Menlo, monospace"
        label_size = "10.5"
        label_spacing = "1.1"
        num_font = "'JetBrains Mono', ui-monospace, SFMono-Regular, Menlo, monospace"

    sub_font = "'LXGW WenKai', 'IBM Plex Sans', -apple-system, sans-serif"

    return f"""<svg xmlns="http://www.w3.org/2000/svg" width="800" height="224" viewBox="0 0 800 224" role="img" aria-label="{aria}">
  <defs>
    <linearGradient id="bg" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#090E1A"/>
      <stop offset="55%" stop-color="#0D1526"/>
      <stop offset="100%" stop-color="#0B1322"/>
    </linearGradient>
    <linearGradient id="topBeam" x1="0%" y1="0%" x2="100%" y2="0%">
      <stop offset="0%" stop-color="#22C55E" stop-opacity="0"/>
      <stop offset="28%" stop-color="#38BDF8" stop-opacity="0.35"/>
      <stop offset="68%" stop-color="#22C55E" stop-opacity="0.75"/>
      <stop offset="100%" stop-color="#22C55E" stop-opacity="0"/>
    </linearGradient>
    <radialGradient id="billGlow" cx="84%" cy="58%" r="36%">
      <stop offset="0%" stop-color="#22C55E" stop-opacity="0.16"/>
      <stop offset="55%" stop-color="#22C55E" stop-opacity="0.04"/>
      <stop offset="100%" stop-color="#22C55E" stop-opacity="0"/>
    </radialGradient>
    <linearGradient id="sparkFill" x1="0%" y1="0%" x2="0%" y2="100%">
      <stop offset="0%" stop-color="#22C55E" stop-opacity="0.28"/>
      <stop offset="100%" stop-color="#22C55E" stop-opacity="0.0"/>
    </linearGradient>
    <linearGradient id="ringGrad" x1="0%" y1="0%" x2="100%" y2="100%">
      <stop offset="0%" stop-color="#38BDF8"/>
      <stop offset="100%" stop-color="#22C55E"/>
    </linearGradient>
    <pattern id="dotGrid" width="16" height="16" patternUnits="userSpaceOnUse">
      <circle cx="1.5" cy="1.5" r="0.85" fill="#94A3B8" fill-opacity="0.12"/>
    </pattern>
    <filter id="softGlow" x="-30%" y="-30%" width="160%" height="160%">
      <feGaussianBlur stdDeviation="2.5" result="blur"/>
      <feMerge>
        <feMergeNode in="blur"/>
        <feMergeNode in="SourceGraphic"/>
      </feMerge>
    </filter>
  </defs>

  <!-- Base Surface + Dot Matrix + Ambient Glow -->
  <rect x="0.75" y="0.75" width="798.5" height="222.5" rx="16" fill="url(#bg)" stroke="#1E293B" stroke-width="1.2"/>
  <rect x="1" y="1" width="798" height="222" rx="16" fill="url(#dotGrid)"/>
  <rect x="1" y="1" width="798" height="222" rx="16" fill="url(#billGlow)"/>
  <line x1="24" y1="1.2" x2="776" y2="1.2" stroke="url(#topBeam)" stroke-width="1.5"/>

  <!-- Precision Corner Reticles -->
  <g stroke="#334155" stroke-width="1" stroke-linecap="round">
    <path d="M14 10 V16 M11 13 H17"/>
    <path d="M786 10 V16 M783 13 H789"/>
    <path d="M14 208 V214 M11 211 H17"/>
    <path d="M786 208 V214 M783 211 H789"/>
  </g>

  <!-- Header Bar -->
  <circle cx="36" cy="31" r="6" fill="#22C55E" fill-opacity="0.18"/>
  <circle cx="36" cy="31" r="3" fill="#22C55E"/>
  <text x="51" y="35" fill="#E2E8F0" font-family="{header_font}" font-size="{header_size}" font-weight="600" letter-spacing="{header_spacing}">
    {header_text}
  </text>

{_hakimi_cat_emblem_svg()}

  <line x1="28" y1="54" x2="772" y2="54" stroke="#1E293B" stroke-width="1"/>
  <line x1="264" y1="74" x2="264" y2="196" stroke="#1E293B" stroke-width="1"/>
  <line x1="536" y1="74" x2="536" y2="196" stroke="#1E293B" stroke-width="1"/>

  <!-- COLUMN 1 -->
  <text x="36" y="88" fill="#94A3B8" font-family="{label_font}" font-size="{label_size}" font-weight="600" letter-spacing="{label_spacing}">
    {col1_title}
  </text>
  <text x="36" y="136" fill="#F8FAFC" font-family="{num_font}" font-size="40" font-weight="700" letter-spacing="-1.5">
    {turns_str}
  </text>
  <g transform="translate(36, 152)">
    <rect x="0" y="12" width="3" height="8" rx="1.5" fill="#334155"/>
    <rect x="9" y="6" width="3" height="14" rx="1.5" fill="#475569"/>
    <rect x="18" y="10" width="3" height="10" rx="1.5" fill="#334155"/>
    <rect x="27" y="3" width="3" height="17" rx="1.5" fill="#64748B"/>
    <rect x="36" y="8" width="3" height="12" rx="1.5" fill="#475569"/>
    <rect x="45" y="1" width="3" height="19" rx="1.5" fill="#94A3B8"/>
    <rect x="54" y="7" width="3" height="13" rx="1.5" fill="#64748B"/>
    <rect x="63" y="4" width="3" height="16" rx="1.5" fill="#94A3B8"/>
    <rect x="72" y="11" width="3" height="9" rx="1.5" fill="#475569"/>
    <rect x="81" y="2" width="3" height="18" rx="1.5" fill="#CBD5E1"/>
    <rect x="90" y="6" width="3" height="14" rx="1.5" fill="#94A3B8"/>
    <rect x="99" y="0" width="3" height="20" rx="1.5" fill="#38BDF8"/>
    <rect x="108" y="8" width="3" height="12" rx="1.5" fill="#64748B"/>
    <rect x="117" y="4" width="3" height="16" rx="1.5" fill="#CBD5E1"/>
    <rect x="126" y="9" width="3" height="11" rx="1.5" fill="#475569"/>
    <rect x="135" y="5" width="3" height="15" rx="1.5" fill="#22C55E"/>
  </g>
  <text x="36" y="194" fill="#64748B" font-family="{sub_font}" font-size="12">
    {col1_sub}
  </text>

  <!-- COLUMN 2 -->
  <text x="292" y="88" fill="#94A3B8" font-family="{label_font}" font-size="{label_size}" font-weight="600" letter-spacing="{label_spacing}">
    {col2_title}
  </text>
  <text x="292" y="136" fill="#F8FAFC" font-family="{num_font}" font-size="38" font-weight="700" letter-spacing="-1.5">
    {tokens_str}
  </text>
  <g transform="translate(305, 162)">
    <circle cx="0" cy="0" r="12.5" fill="none" stroke="#1E293B" stroke-width="2.6"/>
    <circle cx="0" cy="0" r="12.5" fill="none" stroke="url(#ringGrad)" stroke-width="2.6" stroke-linecap="round"
            stroke-dasharray="{dash:.2f} {circ:.2f}" transform="rotate(-90)"/>
    <text x="0" y="3" text-anchor="middle" fill="#E2E8F0" font-family="'JetBrains Mono', ui-monospace, monospace" font-size="7.5" font-weight="700">{ring_pct}%</text>
  </g>
  <text x="326" y="166.5" fill="#CBD5E1" font-family="{sub_font}" font-size="13" font-weight="600">
    {col2_mid}
  </text>
  <text x="292" y="194" fill="#64748B" font-family="{sub_font}" font-size="12">
    {col2_sub}
  </text>

  <!-- COLUMN 3 -->
  <text x="564" y="88" fill="#22C55E" font-family="{label_font}" font-size="{label_size}" font-weight="600" letter-spacing="{label_spacing}">
    {col3_title}
  </text>
  <text x="564" y="136" fill="#22C55E" font-family="{num_font}" font-size="40" font-weight="700" letter-spacing="-1.5" filter="url(#softGlow)">
    {cost_str}
  </text>
  <g transform="translate(564, 148)">
    <path d="M0 24 L26 22 L52 19 L78 18 L104 13 L130 10 L156 6 L184 2 L184 26 L0 26 Z" fill="url(#sparkFill)"/>
    <path d="M0 24 L26 22 L52 19 L78 18 L104 13 L130 10 L156 6 L184 2" fill="none" stroke="#22C55E" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"/>
    <circle cx="184" cy="2" r="5" fill="#22C55E" fill-opacity="0.25"/>
    <circle cx="184" cy="2" r="2.5" fill="#4ADE80"/>
  </g>
  <text x="564" y="194" fill="#64748B" font-family="{sub_font}" font-size="12">
    {col3_sub}
  </text>
</svg>
"""


def render_svg_to_png(svg_text: str, out_png: Path, chrome_bin: str, font_path: str | None) -> None:
    """Render an SVG string to a 3x Retina transparent PNG via headless Chrome."""
    font_css = ""
    if font_path and os.path.isfile(font_path):
        font_css = f"""
      @font-face {{
        font-family: 'LXGW WenKai';
        src: url('file://{font_path}') format('truetype');
        font-weight: 100 900;
        font-style: normal;
      }}"""
    html = f"""<!doctype html>
<html><head><meta charset="utf-8"><style>{font_css}
  html, body {{ margin: 0; padding: 0; background: transparent; width: 800px; height: 224px; overflow: hidden; }}
</style></head><body>{svg_text}</body></html>"""

    with tempfile.NamedTemporaryFile("w", suffix=".html", delete=False, encoding="utf-8") as f:
        f.write(html)
        html_path = f.name
    try:
        subprocess.run(
            [
                chrome_bin,
                "--headless=new",
                "--disable-gpu",
                "--hide-scrollbars",
                "--default-background-color=00000000",
                "--force-device-scale-factor=3",
                "--window-size=800,224",
                f"--screenshot={out_png}",
                f"file://{html_path}",
            ],
            check=True,
            stdout=subprocess.DEVNULL,
            stderr=subprocess.DEVNULL,
        )
    finally:
        if os.path.exists(html_path):
            os.unlink(html_path)


def main() -> int:
    parser = argparse.ArgumentParser(description="Generate Agyhub README build-telemetry SVG & 3x PNG cards.")
    parser.add_argument("--output-dir", default=str(DEFAULT_ASSETS_DIR), help="Output directory (default: assets/)")
    parser.add_argument("--keyword", action="append", dest="keywords", help="Session match keyword (repeatable)")
    parser.add_argument("--turns", type=int, default=None, help="Override human-AI turns")
    parser.add_argument("--tokens", type=int, default=None, help="Override total tokens")
    parser.add_argument("--cache-hit", type=float, default=None, help="Override cache hit percentage (0-100)")
    parser.add_argument("--cost", type=float, default=None, help="Override estimated API cost in USD")
    parser.add_argument("--font-path", default=None, help="Path to local LXGW WenKai .ttf font")
    parser.add_argument("--skip-png", action="store_true", help="Only write SVG files without rendering PNGs")
    args = parser.parse_args()

    out_dir = Path(args.output_dir)
    out_dir.mkdir(parents=True, exist_ok=True)

    if None in (args.turns, args.tokens, args.cache_hit, args.cost):
        keywords = args.keywords if args.keywords else DEFAULT_KEYWORDS
        metrics = collect_local_metrics(keywords)
    else:
        metrics = {"turns": 0, "tokens": 0, "cache_hit_pct": 0.0, "cost_usd": 0.0}

    turns = args.turns if args.turns is not None else metrics["turns"]
    tokens = args.tokens if args.tokens is not None else metrics["tokens"]
    cache_hit = args.cache_hit if args.cache_hit is not None else metrics["cache_hit_pct"]
    cost = args.cost if args.cost is not None else metrics["cost_usd"]

    en_svg = build_svg("en", turns, tokens, cache_hit, cost)
    zh_svg = build_svg("zh", turns, tokens, cache_hit, cost)

    (out_dir / "build-telemetry.svg").write_text(en_svg, encoding="utf-8")
    (out_dir / "build-telemetry-zh.svg").write_text(zh_svg, encoding="utf-8")
    print(f"Wrote SVGs -> {out_dir} (turns={turns}, tokens={_format_tokens(tokens)}, cache={cache_hit:.1f}%, cost=${cost:.2f})")

    if not args.skip_png:
        chrome = _find_chrome()
        if not chrome:
            print("Warning: Chrome/Chromium not found; skipped PNG rendering.", file=sys.stderr)
            return 0
        font_path = args.font_path or _find_lxgw_font()
        render_svg_to_png(en_svg, out_dir / "build-telemetry.png", chrome, font_path)
        render_svg_to_png(zh_svg, out_dir / "build-telemetry-zh.png", chrome, font_path)
        print(f"Rendered 3x PNGs -> {out_dir / 'build-telemetry.png'}, {out_dir / 'build-telemetry-zh.png'}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
