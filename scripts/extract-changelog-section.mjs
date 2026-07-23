import { readFileSync } from "node:fs";

const version = JSON.parse(readFileSync(new URL("../package.json", import.meta.url))).version;
const changelog = readFileSync(new URL("../CHANGELOG.md", import.meta.url), "utf8").split("\n");

const start = changelog.findIndex((line) => line.trim() === `## ${version}`);
if (start === -1) {
  throw new Error(`CHANGELOG.md has no "## ${version}" section`);
}

let end = changelog.findIndex((line, index) => index > start && /^## /.test(line));
if (end === -1) end = changelog.length;

const section = changelog
  .slice(start + 1, end)
  .join("\n")
  .trim();

if (!section) {
  throw new Error(`CHANGELOG.md section for ${version} is empty`);
}

process.stdout.write(`${section}\n`);
