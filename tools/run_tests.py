#!/usr/bin/env python3
"""Run every assertion suite once, in parallel, within a wall-clock budget.

Screenshot/reel exports and long game smoke scenarios remain in make test-full.
No successful results are cached; every invocation executes every selected check.
"""
import argparse
from concurrent.futures import ThreadPoolExecutor, as_completed
import math
import os
from pathlib import Path
import signal
import subprocess
import sys
import time

ROOT = Path(__file__).resolve().parents[1]


def run_jobs(jobs, budget, workers=4, output=None):
    output = output if output is not None else sys.stdout
    started = time.monotonic()
    deadline = started + budget

    def execute(job):
        label, command = job
        remaining = deadline - time.monotonic()
        if remaining <= 0:
            return label, 124, "Budget exhausted before this check could start.\n"
        try:
            process = subprocess.Popen(command, cwd=ROOT, stdout=subprocess.PIPE,
                                       stderr=subprocess.STDOUT, text=True,
                                       start_new_session=True)
        except OSError as error:
            return label, 127, str(error) + "\n"
        try:
            text, _ = process.communicate(timeout=max(.001, deadline - time.monotonic()))
            return label, process.returncode, text
        except subprocess.TimeoutExpired:
            # Node's test runner can have children; do not leave work running.
            try:
                os.killpg(process.pid, signal.SIGKILL)
            except ProcessLookupError:
                pass
            text, _ = process.communicate()
            return label, 124, text + "\nExceeded the shared test budget.\n"

    failed = []
    with ThreadPoolExecutor(max_workers=workers) as pool:
        futures = [pool.submit(execute, job) for job in jobs]
        for future in as_completed(futures):
            label, code, text = future.result()
            print(f"[{label}]", file=output)
            if text:
                print(text, end="" if text.endswith("\n") else "\n", file=output)
            if code:
                failed.append(label)
                print(f"FAIL {label} (exit {code})", file=output)
    elapsed = time.monotonic() - started
    # Timer includes process startup, queueing, teardown and reporting.
    if elapsed > budget and not failed:
        failed.append("wall-clock budget")
    print(f"verification: {len(jobs) - len(failed)} passed, {len(failed)} failed, "
          f"{elapsed:.2f}s (budget {budget:g}s)", file=output)
    if failed:
        print("failed: " + ", ".join(failed), file=output)
    return int(bool(failed))


def checks(fast=False, arguments=()):
    mode = "--fast" if fast else "--check"
    games = ("engine", "relic-rush", "christmas-market", "volcano", "nile-archive")
    jobs = [(game, [f"./build/test/{game}", mode, *arguments]) for game in games]
    jobs += [(name, [f"./build/{name}"]) for name in
             ("test-audio", "clayfight-video", "clayfight-photo", "clayfight-input")]
    jobs.append(("capture-processing", ["node", "--test", "games/clayfight/tests/capture-processing.mjs"]))
    scripts = [
        ("generated code", "tools/luagen.py", "--check"),
        ("Xcode projects", "tools/xcode/generate.py", "--check"),
        ("Volcano assets", "games/volcano/tools/check_assets.py"),
        ("Relic Rush catalogue", "games/relic-rush/tools/check_art_catalogue.py"),
        ("Christmas catalogue", "games/christmas-market/tools/prepare_catalogue.py", "--check"),
        ("Christmas assets", "games/christmas-market/tools/check_assets.py"),
        ("Relic Rush HUD", "games/relic-rush/tools/prepare_hud.py", "--check"),
        ("building registration", "tools/buildings.py", "--check"),
        ("match-3 atlases", "tools/match3_atlas.py", "--check"),
        ("test runner contracts", "tools/test_run_tests.py"),
    ]
    jobs += [(label, [sys.executable, *command]) for label, *command in scripts]
    return jobs


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--budget", type=float, default=5)
    parser.add_argument("--jobs", type=int, default=4)
    parser.add_argument("--fast", action="store_true")
    parser.add_argument("arguments", nargs=argparse.REMAINDER)
    args = parser.parse_args()
    if not math.isfinite(args.budget) or args.budget <= 0 or args.jobs < 1:
        parser.error("budget and jobs must be positive (budget must be finite)")
    arguments = args.arguments[1:] if args.arguments[:1] == ["--"] else args.arguments
    return run_jobs(checks(args.fast, arguments), args.budget, args.jobs)


if __name__ == "__main__":
    raise SystemExit(main())
