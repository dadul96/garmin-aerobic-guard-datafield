#!/usr/bin/env -S uv run --script
# /// script
# requires-python = ">=3.10"
# dependencies = [
#   "fitdecode==0.11.0",
# ]
# ///
"""Inspect Garmin FIT messages and export them as reusable CSV/JSON data."""

from __future__ import annotations

import argparse
import csv
import datetime as dt
import json
import math
import pathlib
import sys
from collections import Counter, defaultdict
from typing import Any, Iterable

import fitdecode


def json_value(value: Any) -> Any:
    if isinstance(value, (dt.date, dt.datetime, dt.time)):
        return value.isoformat()
    if isinstance(value, bytes):
        return value.hex()
    if isinstance(value, tuple):
        return [json_value(item) for item in value]
    if isinstance(value, list):
        return [json_value(item) for item in value]
    if isinstance(value, float) and not math.isfinite(value):
        return None
    return value


def _read_fit(
    path: pathlib.Path,
    retain_developer_identity: bool,
) -> tuple[
    dict[str, list[dict[str, Any]]],
    Counter,
    list[dict[tuple[int, int], Any]],
]:
    """Decode a FIT file, checking both header and file CRCs."""
    messages: dict[str, list[dict[str, Any]]] = defaultdict(list)
    frame_counts: Counter = Counter()
    developer_records: list[dict[tuple[int, int], Any]] = []

    with fitdecode.FitReader(path, check_crc=fitdecode.CrcCheck.RAISE) as reader:
        for frame in reader:
            frame_counts[type(frame).__name__] += 1
            if not isinstance(frame, fitdecode.FitDataMessage):
                continue
            row = {field.name: json_value(field.value) for field in frame.fields}
            messages[frame.name].append(row)
            if retain_developer_identity and frame.name == "record":
                qualified: dict[tuple[int, int], Any] = {}
                for field in frame.fields:
                    field_definition = field.field_def
                    if not getattr(field_definition, "is_dev", False):
                        continue
                    qualified[
                        (
                            field_definition.dev_data_index,
                            field_definition.def_num,
                        )
                    ] = json_value(field.value)
                developer_records.append(qualified)

    return dict(messages), frame_counts, developer_records


def read_fit(path: pathlib.Path) -> tuple[dict[str, list[dict[str, Any]]], Counter]:
    messages, frame_counts, _ = _read_fit(path, False)
    return messages, frame_counts


def read_fit_with_developer_fields(
    path: pathlib.Path,
) -> tuple[
    dict[str, list[dict[str, Any]]],
    Counter,
    list[dict[tuple[int, int], Any]],
]:
    """Decode a FIT file while retaining developer field group identity."""
    return _read_fit(path, True)


def ordered_columns(rows: Iterable[dict[str, Any]]) -> list[str]:
    columns: list[str] = []
    seen: set[str] = set()
    for row in rows:
        for name in row:
            if name not in seen:
                columns.append(name)
                seen.add(name)
    return columns


def write_csv(path: pathlib.Path, rows: list[dict[str, Any]]) -> None:
    columns = ordered_columns(rows)
    with path.open("w", newline="", encoding="utf-8") as handle:
        writer = csv.DictWriter(handle, fieldnames=columns, extrasaction="ignore")
        writer.writeheader()
        for row in rows:
            writer.writerow(
                {
                    key: json.dumps(value, separators=(",", ":"))
                    if isinstance(value, (list, dict))
                    else value
                    for key, value in row.items()
                }
            )


def safe_message_name(name: str) -> str:
    return "".join(char if char.isalnum() or char in "-_" else "_" for char in name)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="CRC-check, inspect, and export messages from a Garmin FIT file."
    )
    parser.add_argument("fit_file", type=pathlib.Path)
    parser.add_argument(
        "--message",
        action="append",
        help="Only include this FIT message type; may be specified more than once.",
    )
    parser.add_argument(
        "--output-dir",
        type=pathlib.Path,
        help="Write one CSV file per selected message type.",
    )
    parser.add_argument(
        "--json",
        action="store_true",
        help="Write selected decoded messages as JSON to stdout.",
    )
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    if not args.fit_file.is_file():
        print(f"FIT file not found: {args.fit_file}", file=sys.stderr)
        return 2

    try:
        messages, frame_counts = read_fit(args.fit_file)
    except (fitdecode.FitError, OSError) as error:
        print(f"Could not decode {args.fit_file}: {error}", file=sys.stderr)
        return 1

    selected_names = args.message or sorted(messages)
    unknown = [name for name in selected_names if name not in messages]
    if unknown:
        print(f"Unknown message type(s): {', '.join(unknown)}", file=sys.stderr)
        return 2
    selected = {name: messages[name] for name in selected_names}

    if args.output_dir:
        args.output_dir.mkdir(parents=True, exist_ok=True)
        for name, rows in selected.items():
            write_csv(args.output_dir / f"{safe_message_name(name)}.csv", rows)

    if args.json:
        json.dump(selected, sys.stdout, indent=2, sort_keys=True)
        print()
    else:
        print(f"FIT CRC: OK")
        print(f"File: {args.fit_file}")
        print(f"Data messages: {sum(len(rows) for rows in messages.values())}")
        for name in sorted(messages):
            marker = "*" if name in selected else " "
            print(f"{marker} {name}: {len(messages[name])}")
        if args.output_dir:
            print(f"CSV output: {args.output_dir}")
        print(
            "Frames: "
            + ", ".join(f"{name}={count}" for name, count in sorted(frame_counts.items()))
        )

    return 0


if __name__ == "__main__":
    raise SystemExit(main())
