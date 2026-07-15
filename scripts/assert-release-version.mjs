import { readFileSync } from "node:fs";

const packageVersion = JSON.parse(readFileSync(new URL("../package.json", import.meta.url))).version;
const manifest = readFileSync(new URL("../herdr-plugin.toml", import.meta.url), "utf8");
const manifestVersion = manifest.match(/^version\s*=\s*"([^"]+)"\s*$/m)?.[1];

if (!manifestVersion || manifestVersion !== packageVersion) {
  throw new Error(`Version mismatch: package.json=${packageVersion}, herdr-plugin.toml=${manifestVersion ?? "missing"}`);
}

const tag = process.env.GITHUB_REF_NAME;
if (tag && tag !== `v${packageVersion}`) {
  throw new Error(`Tag ${tag} does not match package version v${packageVersion}`);
}

console.log(`Release version ${packageVersion} is consistent.`);
