#!/usr/bin/env python3
"""Portable Aerobic Guard release-contract validation."""
from __future__ import annotations

import json
import pathlib
import re
import struct
import sys
import xml.etree.ElementTree as ET

ROOT = pathlib.Path(__file__).resolve().parents[1]
NS = {"iq": "http://www.garmin.com/xml/connectiq"}
PRODUCTS = {"edge540", "edge550", "edge840", "edge850", "edge1040", "edge1050"}
REQUIRED_DOCS = {
    "README.md", "LICENSE", "PRIVACY.md", "CHANGELOG.md", "VERSION",
    "store/english.md", "docs/USER_GUIDE.md",
    "docs/RELEASING.md", "docs/HOST_RELEASE.md", "docs/RELEASE_PROGRESS.md",
}

def fail(message: str) -> None:
    raise SystemExit(f"contract: {message}")

manifest = ET.parse(ROOT / "manifest.xml").getroot()
app = manifest.find("iq:application", NS)
if app is None:
    fail("manifest application missing")
products = {node.get("id") for node in app.findall("iq:products/iq:product", NS)}
if products != PRODUCTS:
    fail(f"manifest products must be exactly {sorted(PRODUCTS)}")
api = tuple(map(int, (app.get("minApiLevel") or "0").split(".")))
if api < (6, 0, 0):
    fail("minimum API must be 6.0.0 or newer")
permissions = {node.get("id") for node in app.findall("iq:permissions/iq:uses-permission", NS)}
if permissions != {"UserProfile"}:
    fail("UserProfile must be the only permission")
manifest_text = (ROOT / "manifest.xml").read_text()
for forbidden in ("FitContributor", "Communications", "ActivityControl"):
    if forbidden in manifest_text:
        fail(f"forbidden capability: {forbidden}")
if any((ROOT / "resources/contributions").glob("**/*")) or any((ROOT / "resources/settings").glob("**/*")):
    fail("FIT contribution or phone settings resources are forbidden")

host_release = (ROOT / "tools/host-release").read_text()
production_uuid = app.get("id") or ""
uuid_values = dict(re.findall(r'^(production_uuid|beta_uuid)="([0-9a-f-]{36})"$', host_release, re.MULTILINE))
if uuid_values.get("production_uuid") != production_uuid:
    fail("host-release production UUID must match the manifest")
if not uuid_values.get("beta_uuid") or uuid_values["beta_uuid"] == production_uuid:
    fail("host-release beta UUID must be present and distinct")
example_uuids = {
    "a55c2d7d-f370-41c9-aa61-019346c4d878",
    "6e6db69a-0ac1-4adf-88eb-c9885438e060",
}
if set(uuid_values.values()) & example_uuids:
    fail("host-release UUID must not reuse the example app")

version = (ROOT / "VERSION").read_text().strip()
if not re.fullmatch(r"\d+\.\d+\.\d+", version):
    fail("public-release VERSION must be stable major.minor.patch")
if f"## {version}" not in (ROOT / "CHANGELOG.md").read_text():
    fail("CHANGELOG release heading must match VERSION")
for name in REQUIRED_DOCS:
    if not (ROOT / name).is_file():
        fail(f"required document missing: {name}")

def png_size(path: pathlib.Path, require_srgb: bool = True) -> tuple[int, int]:
    data = path.read_bytes()
    if not data.startswith(b"\x89PNG\r\n\x1a\n"):
        fail(f"not PNG: {path.relative_to(ROOT)}")
    if require_srgb and b"sRGB" not in data:
        fail(f"missing sRGB chunk: {path.relative_to(ROOT)}")
    return struct.unpack(">II", data[16:24])

for name, size in {
    "assets/store/icon-500.png": (500, 500),
    "assets/store/icon-128.png": (128, 128),
    "assets/device/launcher-35.png": (35, 35),
    "assets/device/launcher-40.png": (40, 40),
    "assets/device/launcher-56.png": (56, 56),
    "assets/device/launcher-68.png": (68, 68),
    "assets/store/hero-1440x720.png": (1440, 720),
}.items():
    if png_size(ROOT / name) != size:
        fail(f"wrong dimensions: {name}")
if (ROOT / "assets/store/icon-500.png").stat().st_size > 300 * 1024:
    fail("Connect IQ listing icon exceeds 300 KiB")
if (ROOT / "assets/store/hero-1440x720.png").stat().st_size > 300_000:
    fail("Connect IQ hero exceeds 300 KB")
screenshots = sorted((ROOT / "assets/screenshots").glob("*.png"))
if len(screenshots) != 5:
    fail("Connect IQ listing must contain the five reviewed screenshots")
for path in screenshots:
    png_size(path, require_srgb=False)
    if path.stat().st_size > 150 * 1024:
        fail(f"Connect IQ screenshot exceeds 150 KiB: {path.name}")
ET.parse(ROOT / "resources/drawables/launcher_icon.svg")
json.loads((ROOT / ".devcontainer/devcontainer.json").read_text())

public = "\n".join((ROOT / name).read_text(errors="ignore") for name in REQUIRED_DOCS)
if "dadul96/garmin-aerobic-guard-datafield" not in public:
    fail("Aerobic Guard repository URL missing")
store_text = (ROOT / "store/english.md").read_text()
for required in ("docs/USER_GUIDE.md", "PRIVACY.md", "/issues"):
    if required not in store_text:
        fail(f"store listing link missing: {required}")
scan_paths = [p for p in ROOT.rglob("*") if p.is_file()
              and ".git" not in p.parts and "example_app" not in p.parts
              and "bin" not in p.parts and p.name != "check_contract.py"]
for path in scan_paths:
    text = path.read_text(errors="ignore")
    for stale in ("Power" + " Lost", "power" + "-lost",
                  "a55c2d7d" + "-f370-41c9-aa61-019346c4d878",
                  "6e6db69a" + "-0ac1-4adf-88eb-c9885438e060"):
        if stale in text:
            fail(f"stale example-specific value in {path.relative_to(ROOT)}: {stale}")
print("Aerobic Guard release contract: OK")
