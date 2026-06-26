#!/usr/bin/env python3
"""Download and parse the Jera On Air timetable into bundled JSON."""

from __future__ import annotations

import json
import re
import sys
import urllib.request
from pathlib import Path

BASE_URL = "https://www.jeraonair.nl/nl/timetable/"
OUTPUT = Path(__file__).resolve().parent.parent / "JeraOnAir" / "timetable.json"

DAYS = {
    "THU": {"title": "Thursday", "shortTitle": "Thu", "date": "2026-06-25", "query": ""},
    "FRI": {"title": "Friday", "shortTitle": "Fri", "date": "2026-06-26", "query": "?day=FRI"},
    "SAT": {"title": "Saturday", "shortTitle": "Sat", "date": "2026-06-27", "query": "?day=SAT"},
}


def fetch(url: str) -> str:
    request = urllib.request.Request(url, headers={"User-Agent": "JeraOnAirTimetableSync/1.0"})
    with urllib.request.urlopen(request, timeout=30) as response:
        return response.read().decode("utf-8")


def parse_day(html: str) -> dict:
    bounds = re.search(r'class="current-time"[^>]*data-start="(\d+)"[^>]*data-end="(\d+)"', html)
    if not bounds:
        raise ValueError("Could not find timetable time bounds")

    start, end = int(bounds.group(1)), int(bounds.group(2))
    stage_labels = re.findall(r'class="stagename-label ([^"]+)"[^>]*>\s*([^<]+?)\s*<', html)
    stage_map = {stage_id: name.strip() for stage_id, name in stage_labels}

    rows = re.findall(
        r'<div class="stage-row ([^"\s]+)"\s+style="grid-template-columns: repeat\((\d+), 1fr\)">(.*?)</div>\s*(?=<div class="stage-row|<div class="current-time)',
        html,
        re.DOTALL,
    )

    stages = []
    for stage_id, col_count, block in rows:
        performances = []
        for match in re.finditer(
            r'<button class="performance[^"]*"[^>]*style="grid-column:\s*(\d+)\s*/\s*(\d+);"[^>]*data-band="(\d+)"[^>]*>(.*?)</button>',
            block,
            re.DOTALL,
        ):
            grid_start, grid_end, band_id, inner = match.groups()
            name_match = re.search(r'<span class="band-name">\s*([^<]+?)\s*</span>', inner)
            time_match = re.search(r'<span class="time-range">\s*([^<]+?)\s*</span>', inner, re.DOTALL)
            performances.append(
                {
                    "bandId": int(band_id),
                    "name": re.sub(r"\s+", " ", name_match.group(1)).strip() if name_match else "",
                    "time": re.sub(r"\s+", " ", time_match.group(1)).strip() if time_match else "",
                    "gridColumn": int(grid_start),
                    "gridSpan": int(grid_end) - int(grid_start),
                }
            )

        stages.append(
            {
                "id": stage_id,
                "name": stage_map.get(stage_id, stage_id),
                "columnCount": int(col_count),
                "performances": performances,
            }
        )

    time_labels = [
        {"gridColumn": int(column), "label": label.strip()}
        for column, label in re.findall(
            r'class="stage-time" style="grid-column: (\d+);">\s*([^<]+?)\s*<',
            html,
        )
    ]

    return {
        "startTimestamp": start,
        "endTimestamp": end,
        "slotMinutes": 5,
        "timeLabels": time_labels,
        "stages": stages,
    }


def main() -> int:
    result = {"days": {}}

    for day_id, meta in DAYS.items():
        url = BASE_URL + meta["query"]
        print(f"Fetching {day_id} from {url}")
        html = fetch(url)
        parsed = parse_day(html)
        parsed.update({key: meta[key] for key in ("title", "shortTitle", "date")})
        result["days"][day_id] = parsed
        print(
            f"  {len(parsed['stages'])} stages, "
            f"{sum(len(stage['performances']) for stage in parsed['stages'])} performances"
        )

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)
    OUTPUT.write_text(json.dumps(result, indent=2, ensure_ascii=False) + "\n", encoding="utf-8")
    print(f"Wrote {OUTPUT}")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
