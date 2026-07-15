const event = JSON.parse(process.env.HERDR_PLUGIN_EVENT_JSON ?? "{}");

for (const candidate of [event?.worktree?.path, event?.data?.worktree?.path, event?.payload?.worktree?.path]) {
  if (typeof candidate === "string" && candidate.startsWith("/")) {
    process.stdout.write(candidate);
    break;
  }
}
