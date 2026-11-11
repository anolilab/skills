#!/usr/bin/env bash
# The branch adds one small pure helper with a test and touches nothing else. The change is
# correct and well placed. It is the negative case: a reviewer should report no blocker or
# high finding, and should not invent work to fill the report.
set -euo pipefail
git init -q .
git config user.email eval@example.com
git config user.name Eval
mkdir -p src
cat >src/format.ts <<'OURS'
export function joinNames(names: string[]): string {
  return names.filter((n) => n.length > 0).join(", ");
}
OURS
cat >src/format.test.ts <<'OURS'
import { describe, expect, it } from "vitest";
import { joinNames } from "./format";

describe("joinNames", () => {
  it("joins non-empty names", () => {
    expect(joinNames(["ada", "", "lin"])).toBe("ada, lin");
  });
});
OURS
printf "# our-client\n\nSmall formatting helpers.\n" >README.md
git add -A
git commit -qm "format helpers"
git branch -M main
git checkout -q -b add-format-bytes
cat >>src/format.ts <<'OURS'

export function formatBytes(bytes: number): string {
  if (!Number.isFinite(bytes) || bytes < 0) {
    throw new RangeError("bytes must be a non-negative finite number");
  }
  const units = ["B", "KB", "MB", "GB"];
  let value = bytes;
  let unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit += 1;
  }
  return unit === 0 ? `${value} B` : `${value.toFixed(1)} ${units[unit]}`;
}
OURS
cat >src/format.test.ts <<'OURS'
import { describe, expect, it } from "vitest";
import { formatBytes, joinNames } from "./format";

describe("joinNames", () => {
  it("joins non-empty names", () => {
    expect(joinNames(["ada", "", "lin"])).toBe("ada, lin");
  });
});

describe("formatBytes", () => {
  it("formats bytes, kilobytes and megabytes", () => {
    expect(formatBytes(512)).toBe("512 B");
    expect(formatBytes(2048)).toBe("2.0 KB");
    expect(formatBytes(5 * 1024 * 1024)).toBe("5.0 MB");
  });
});
OURS
git add -A
