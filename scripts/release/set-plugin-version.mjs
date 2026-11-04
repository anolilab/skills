// Writes the release version into the plugin's package.json and
// .claude-plugin/plugin.json. Claude Code reads only plugin.json, and caches a
// plugin by that version, so an unchanged string means users never get the
// release. Runs from the plugin directory, as @semantic-release/exec does.
import { readFileSync, writeFileSync } from "node:fs";

const version = process.argv[2];

if (!/^\d+\.\d+\.\d+(-[0-9A-Za-z.-]+)?$/.test(version ?? "")) {
    console.error(`set-plugin-version: expected a semver version, got "${version}"`);
    process.exit(1);
}

for (const file of ["package.json", ".claude-plugin/plugin.json"]) {
    const text = readFileSync(file, "utf8");
    const next = text.replace(/("version"\s*:\s*)"[^"]*"/, `$1"${version}"`);

    if (next === text && !text.includes(`"version": "${version}"`)) {
        console.error(`set-plugin-version: no "version" field in ${file}`);
        process.exit(1);
    }

    writeFileSync(file, next);
}
