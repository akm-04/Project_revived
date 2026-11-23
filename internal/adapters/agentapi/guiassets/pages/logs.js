"use strict";

import { confirmAction } from "../components/confirm_action.js";
import { describeReply, request } from "../transport.js";

const followPollMilliseconds = 2000;

const logSources = [
  { value: "tool", label: "Tool log" },
  { value: "backend", label: "Backend log" },
  { value: "database", label: "Database log" },
  { value: "client", label: "Client journal" },
];

const logLevels = [
  { value: "", label: "Any level" },
  { value: "info", label: "Info" },
  { value: "warn", label: "Warning" },
  { value: "error", label: "Error" },
];

const journalOutcomes = [
  "",
  "OK",
  "CLIENT_ERROR",
  "SERVER_ERROR",
  "UNKNOWN_MID",
  "UNDECODABLE",
  "INACTIVE_MODE",
];

// renderPage is the Logs screen: an overview of the tool log, the Tail, Search
// and Timeline reads, and the attributed Clear command.
export function renderPage(container) {
  container.replaceChildren();
  const overview = buildOverview();
  const tabs = buildTabs();
  const clear = buildClear();
  container.append(overview.card, tabs.card, clear.card);

  let tailCursor = "";
  let tailTimer = null;
  let tailBusy = false;

  function stopFollow() {
    if (tailTimer !== null) {
      clearInterval(tailTimer);
      tailTimer = null;
    }
  }

  async function runTail(follow) {
    if (tailBusy) {
      return;
    }
    tailBusy = true;
    tabs.tail.status.textContent = "";
    const query = new URLSearchParams();
    query.set("source", tabs.tail.source.value);
    query.set("limit", tabs.tail.limit.value === "" ? "100" : tabs.tail.limit.value);
    if (tabs.tail.level.value !== "") {
      query.set("level", tabs.tail.level.value);
    }
    if (follow && tailCursor !== "") {
      query.set("after_cursor", tailCursor);
    }
    const reply = await request("/agent/v1/reads/logs.tail?" + query.toString());
    tailBusy = false;
    if (reply.unauthorized) {
      stopFollow();
      return;
    }
    if (!reply.ok) {
      stopFollow();
      tabs.tail.status.textContent = describeReply(reply);
      return;
    }
    const body = reply.body && typeof reply.body === "object" ? reply.body : {};
    if (body.absent === true) {
      stopFollow();
      tabs.tail.result.textContent = "";
      tabs.tail.status.textContent = "The source is unavailable: " + presentText(body.reason, "unknown reason");
      return;
    }
    if (typeof body.next_cursor === "string" && body.next_cursor !== "") {
      tailCursor = body.next_cursor;
    }
    const lines = Array.isArray(body.lines) ? body.lines : [];
    const text = lines.map(describeTailLine).join("\n");
    if (follow) {
      tabs.tail.result.textContent = appendText(tabs.tail.result.textContent, text);
    } else {
      tabs.tail.result.textContent = text === "" ? "No log lines." : text;
    }
  }

  function startFollow() {
    if (tailTimer !== null) {
      return;
    }
    tailCursor = "";
    tabs.tail.result.textContent = "";
    const poll = () => {
      if (!tabs.card.isConnected) {
        stopFollow();
        return;
      }
      void runTail(true);
    };
    poll();
    tailTimer = setInterval(poll, followPollMilliseconds);
  }

  tabs.tail.run.addEventListener("click", () => {
    stopFollow();
    tailCursor = "";
    void runTail(false);
  });
  tabs.tail.live.addEventListener("click", startFollow);
  tabs.tail.stop.addEventListener("click", stopFollow);
  tabs.tail.source.addEventListener("change", () => {
    stopFollow();
    tailCursor = "";
  });

  tabs.search.run.addEventListener("click", async () => {
    tabs.search.status.textContent = "";
    const query = new URLSearchParams();
    query.set("source", tabs.search.source.value);
    query.set("limit", tabs.search.limit.value === "" ? "100" : tabs.search.limit.value);
    if (tabs.search.player.value !== "" && tabs.search.source.value === "client") {
      query.set("player", tabs.search.player.value.trim());
    }
    setIfPresent(query, "from", toRFC3339(tabs.search.from.value));
    setIfPresent(query, "to", toRFC3339(tabs.search.to.value));
    setIfPresent(query, "level", tabs.search.level.value);
    const reply = await request("/agent/v1/reads/logs.search?" + query.toString());
    if (reply.unauthorized) {
      return;
    }
    if (!reply.ok) {
      tabs.search.result.textContent = "";
      tabs.search.status.textContent = describeReply(reply);
      return;
    }
    const body = reply.body && typeof reply.body === "object" ? reply.body : {};
    if (body.absent === true) {
      tabs.search.result.textContent = "";
      tabs.search.status.textContent = "The source is unavailable: " + presentText(body.reason, "unknown reason");
      return;
    }
    const entries = Array.isArray(body.entries) ? body.entries : [];
    tabs.search.result.textContent = entries.length === 0 ? "No entries match." : entries.map(describeSearchEntry).join("\n");
  });

  tabs.timeline.run.addEventListener("click", async () => {
    tabs.timeline.status.textContent = "";
    const query = new URLSearchParams();
    query.set("limit", tabs.timeline.limit.value === "" ? "50" : tabs.timeline.limit.value);
    setIfPresent(query, "player_id", tabs.timeline.playerID.value.trim());
    setIfPresent(query, "uid", tabs.timeline.uid.value.trim());
    setIfPresent(query, "from", toRFC3339(tabs.timeline.from.value));
    setIfPresent(query, "to", toRFC3339(tabs.timeline.to.value));
    setIfPresent(query, "outcome", tabs.timeline.outcome.value);
    setIfPresent(query, "level", tabs.timeline.level.value);
    setIfPresent(query, "mid", tabs.timeline.mid.value.trim());
    setIfPresent(query, "cursor", tabs.timeline.cursor.value.trim());
    const reply = await request("/agent/v1/reads/logs.timeline?" + query.toString());
    if (reply.unauthorized) {
      return;
    }
    if (!reply.ok) {
      tabs.timeline.result.textContent = "";
      tabs.timeline.status.textContent = describeReply(reply);
      return;
    }
    const body = reply.body && typeof reply.body === "object" ? reply.body : {};
    const entries = Array.isArray(body.entries) ? body.entries : [];
    tabs.timeline.result.textContent = entries.length === 0 ? "No entries match." : entries.map(describeTimelineEntry).join("\n");
    if (typeof body.next_cursor === "string" && body.next_cursor !== "") {
      tabs.timeline.result.textContent += "\n\nnext_cursor: " + body.next_cursor;
    }
  });

  clear.button.addEventListener("click", async () => {
    clear.status.textContent = "";
    clear.result.textContent = "";
    const source = clear.source.value;
    const scope = clear.scope.value;
    const payload = { source, scope };
    if (scope === "player") {
      if (clear.player.value.trim() === "") {
        clear.status.textContent = "A player id or name is required for the player scope.";
        return;
      }
      payload.player = clear.player.value.trim();
    }
    if (scope === "older_than") {
      const boundary = toRFC3339(clear.olderThan.value);
      if (boundary === "") {
        clear.status.textContent = "A time is required for the older_than scope.";
        return;
      }
      payload.older_than = boundary;
    }
    if (scope === "player" && source !== "client") {
      clear.status.textContent = "The backend log has no player attribution; the player scope applies to the client journal.";
      return;
    }
    const confirmation = await confirmAction({
      title: "Clear logs",
      summary:
        "Clear the " + source + " logs for the " + scope + " scope. " +
        (source === "client"
          ? "The client journal rows are deleted for good."
          : "The agent's dated backend log files are deleted for good.") +
        " The tool log is never cleared by command.",
      confirmLabel: "Clear logs",
    });
    if (confirmation === null) {
      return;
    }
    const reply = await request("/agent/v1/commands/logs.clear", {
      method: "POST",
      body: { reason: confirmation.reason, semantic_key: confirmation.semantic_key, payload },
    });
    if (reply.unauthorized) {
      return;
    }
    if (!reply.ok) {
      clear.status.textContent = describeReply(reply);
      return;
    }
    const body = reply.body && typeof reply.body === "object" ? reply.body : {};
    const removed = typeof body.removed_files === "number" ? body.removed_files : body.removed;
    const count = typeof removed === "number" ? String(removed) : "unknown";
    clear.result.textContent =
      "Cleared " + count + " from " + presentText(body.source, source) + " (" + presentText(body.scope, scope) + ").\n" +
      "reason: " + confirmation.reason + "\nsemantic_key: " + confirmation.semantic_key;
  });

  clear.scope.addEventListener("change", () => {
    clear.player.disabled = clear.scope.value !== "player";
    clear.olderThan.disabled = clear.scope.value !== "older_than";
  });
  clear.player.disabled = true;
  clear.olderThan.disabled = true;

  void loadOverview(overview);
}

function buildOverview() {
  const card = document.createElement("div");
  card.className = "card card-body";
  const heading = document.createElement("h2");
  heading.className = "card-title";
  heading.textContent = "Logs";
  const hint = document.createElement("p");
  hint.className = "hint";
  hint.textContent = "Tool and backend process logs from the agent; client journal rows from the backend.";
  const rows = document.createElement("dl");
  rows.className = "row";
  const state = overviewRow(rows, "Tool log", "logs-overview-state");
  const sources = overviewRow(rows, "Sources", "logs-overview-sources");
  sources.textContent = "tool, backend, database, client";
  const status = document.createElement("p");
  status.className = "status";
  status.id = "logs-overview-status";
  status.setAttribute("role", "status");
  card.append(heading, hint, rows, status);
  return { card, state, status };
}

async function loadOverview(overview) {
  const reply = await request("/agent/v1/reads/logs.tail?source=tool&limit=5");
  if (reply.unauthorized) {
    return;
  }
  if (!reply.ok) {
    overview.state.textContent = "unknown";
    overview.status.textContent = describeReply(reply);
    return;
  }
  const body = reply.body && typeof reply.body === "object" ? reply.body : {};
  if (body.absent === true) {
    overview.state.textContent = "unavailable: " + presentText(body.reason, "unknown reason");
    return;
  }
  const lines = Array.isArray(body.lines) ? body.lines : [];
  if (lines.length === 0) {
    overview.state.textContent = "no lines written yet";
    return;
  }
  const newest = lines[lines.length - 1];
  overview.state.textContent = lines.length + " newest lines; last " + presentText(newest.at, "time unknown") + " " + presentText(newest.level, "info");
}

function overviewRow(list, label, valueID) {
  const term = document.createElement("dt");
  term.className = "col-4";
  term.textContent = label;
  const value = document.createElement("dd");
  value.className = "col-8";
  value.id = valueID;
  value.textContent = "unknown";
  list.append(term, value);
  return value;
}

function buildTabs() {
  const card = document.createElement("div");
  card.className = "card card-body";
  const nav = document.createElement("nav");
  nav.className = "nav nav-tabs mb-3";
  const panels = document.createElement("div");
  const tail = buildTailPanel();
  const search = buildSearchPanel();
  const timeline = buildTimelinePanel();
  const tabs = [
    { id: "tail", label: "Tail", panel: tail.panel },
    { id: "search", label: "Search", panel: search.panel },
    { id: "timeline", label: "Timeline", panel: timeline.panel },
  ];
  const buttons = [];
  function activate(activeID) {
    for (const tab of tabs) {
      const active = tab.id === activeID;
      tab.panel.hidden = !active;
      const button = buttons.find((candidate) => candidate.dataset.tab === tab.id);
      if (button) {
        button.classList.toggle("active", active);
      }
    }
  }
  for (const tab of tabs) {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "nav-link";
    button.id = "logs-tab-" + tab.id;
    button.dataset.tab = tab.id;
    button.textContent = tab.label;
    button.addEventListener("click", () => activate(tab.id));
    buttons.push(button);
    nav.append(button);
  }
  panels.append(tail.panel, search.panel, timeline.panel);
  card.append(nav, panels);
  activate("tail");
  return { card, tail, search, timeline };
}

function buildTailPanel() {
  const panel = document.createElement("section");
  panel.id = "logs-panel-tail";
  const source = selectControl("logs-tail-source", logSources);
  const level = selectControl("logs-tail-level", logLevels);
  const limit = inputControl("logs-tail-limit", "number", "100");
  limit.min = "1";
  const row = formRow([field("Source", source), field("Level", level), field("Limit", limit)]);
  const run = buttonControl("logs-tail-run", "Tail", "btn btn-primary");
  const live = buttonControl("logs-tail-live", "Start live", "btn btn-outline-secondary");
  const stop = buttonControl("logs-tail-stop", "Stop", "btn btn-outline-secondary");
  const controls = document.createElement("div");
  controls.className = "d-flex gap-2 mb-2";
  controls.append(run, live, stop);
  const status = statusParagraph("logs-tail-status");
  const result = resultBox("logs-tail-result");
  panel.append(row, controls, status, result);
  return { panel, source, level, limit, run, live, stop, status, result };
}

function buildSearchPanel() {
  const panel = document.createElement("section");
  panel.id = "logs-panel-search";
  panel.hidden = true;
  const source = selectControl("logs-search-source", logSources);
  const player = inputControl("logs-search-player", "text", "");
  player.placeholder = "player id or name (client source)";
  const from = inputControl("logs-search-from", "datetime-local", "");
  const to = inputControl("logs-search-to", "datetime-local", "");
  const level = selectControl("logs-search-level", logLevels);
  const limit = inputControl("logs-search-limit", "number", "100");
  limit.min = "1";
  const row = formRow([
    field("Source", source),
    field("Player", player),
    field("From", from),
    field("To", to),
    field("Level", level),
    field("Limit", limit),
  ]);
  const run = buttonControl("logs-search-run", "Search", "btn btn-primary");
  const status = statusParagraph("logs-search-status");
  const result = resultBox("logs-search-result");
  panel.append(row, run, status, result);
  return { panel, source, player, from, to, level, limit, run, status, result };
}

function buildTimelinePanel() {
  const panel = document.createElement("section");
  panel.id = "logs-panel-timeline";
  panel.hidden = true;
  const playerID = inputControl("logs-timeline-player", "number", "");
  const uid = inputControl("logs-timeline-uid", "text", "");
  const from = inputControl("logs-timeline-from", "datetime-local", "");
  const to = inputControl("logs-timeline-to", "datetime-local", "");
  const outcome = selectControl(
    "logs-timeline-outcome",
    journalOutcomes.map((value) => ({ value, label: value === "" ? "Any outcome" : value })),
  );
  const level = selectControl("logs-timeline-level", logLevels);
  const mid = inputControl("logs-timeline-mid", "number", "");
  const limit = inputControl("logs-timeline-limit", "number", "50");
  limit.min = "1";
  limit.max = "200";
  const cursor = inputControl("logs-timeline-cursor", "text", "");
  const row = formRow([
    field("Player id", playerID),
    field("Account uid", uid),
    field("From", from),
    field("To", to),
    field("Outcome", outcome),
    field("Level", level),
    field("MID", mid),
    field("Limit", limit),
    field("Cursor", cursor),
  ]);
  const run = buttonControl("logs-timeline-run", "Read timeline", "btn btn-primary");
  const status = statusParagraph("logs-timeline-status");
  const result = resultBox("logs-timeline-result");
  panel.append(row, run, status, result);
  return { panel, playerID, uid, from, to, outcome, level, mid, limit, cursor, run, status, result };
}

function buildClear() {
  const card = document.createElement("div");
  card.className = "card card-body";
  const heading = document.createElement("h2");
  heading.className = "card-title";
  heading.textContent = "Clear logs";
  const hint = document.createElement("p");
  hint.className = "hint";
  hint.textContent =
    "The client source deletes journal rows through the backend; the backend source deletes the agent's dated log files. " +
    "The tool log is the audit trail and is never cleared.";
  const source = selectControl("logs-clear-source", [
    { value: "client", label: "Client journal" },
    { value: "backend", label: "Backend log" },
  ]);
  const scope = selectControl("logs-clear-scope", [
    { value: "all", label: "All" },
    { value: "player", label: "One player" },
    { value: "older_than", label: "Older than" },
  ]);
  const player = inputControl("logs-clear-player", "text", "");
  player.placeholder = "player id or name";
  const olderThan = inputControl("logs-clear-older-than", "datetime-local", "");
  const row = formRow([field("Source", source), field("Scope", scope), field("Player", player), field("Older than", olderThan)]);
  const button = buttonControl("logs-clear", "Clear", "btn btn-danger");
  const status = statusParagraph("logs-clear-status");
  const result = resultBox("logs-clear-result");
  card.append(heading, hint, row, button, status, result);
  return { card, source, scope, player, olderThan, button, status, result };
}

function selectControl(id, options) {
  const select = document.createElement("select");
  select.className = "form-select";
  select.id = id;
  for (const option of options) {
    const element = document.createElement("option");
    element.value = option.value;
    element.textContent = option.label;
    select.append(element);
  }
  return select;
}

function inputControl(id, type, value) {
  const input = document.createElement("input");
  input.className = "form-control";
  input.id = id;
  input.type = type;
  input.value = value;
  return input;
}

function buttonControl(id, label, className) {
  const button = document.createElement("button");
  button.type = "button";
  button.className = className;
  button.id = id;
  button.textContent = label;
  return button;
}

function field(label, control) {
  const wrapper = document.createElement("div");
  wrapper.className = "col-md-4 mb-2";
  const text = document.createElement("label");
  text.className = "form-label";
  text.htmlFor = control.id;
  text.textContent = label;
  wrapper.append(text, control);
  return wrapper;
}

function formRow(fields) {
  const row = document.createElement("div");
  row.className = "row";
  for (const item of fields) {
    row.append(item);
  }
  return row;
}

function statusParagraph(id) {
  const status = document.createElement("p");
  status.className = "status mt-2";
  status.id = id;
  status.setAttribute("role", "status");
  return status;
}

function resultBox(id) {
  const result = document.createElement("pre");
  result.className = "component-output";
  result.id = id;
  return result;
}

function setIfPresent(query, key, value) {
  if (value !== "") {
    query.set(key, value);
  }
}

function toRFC3339(value) {
  if (value === "") {
    return "";
  }
  const parsed = new Date(value);
  return Number.isNaN(parsed.getTime()) ? "" : parsed.toISOString();
}

function describeTailLine(line) {
  if (line === null || typeof line !== "object") {
    return String(line);
  }
  const at = presentText(line.at, "");
  const level = presentText(line.level, "info");
  const prefix = at === "" ? level : at + " " + level;
  return prefix + " " + presentText(line.text, "");
}

function describeSearchEntry(entry) {
  if (entry === null || typeof entry !== "object") {
    return String(entry);
  }
  if (typeof entry.text === "string") {
    return describeTailLine(entry);
  }
  return describeJournalEntry(entry);
}

function describeTimelineEntry(entry) {
  if (entry === null || typeof entry !== "object") {
    return String(entry);
  }
  return describeJournalEntry(entry);
}

function describeJournalEntry(entry) {
  const parts = [
    presentText(entry.received_at, "time unknown"),
    presentText(entry.outcome, "outcome unknown"),
    "player=" + presentNumber(entry.player_id, "unknown"),
    "mid=" + presentNumber(entry.mid, "unknown"),
    "http=" + presentNumber(entry.http_status, "unknown"),
    "latency_us=" + presentNumber(entry.latency_microseconds, "unknown"),
  ];
  if (typeof entry.error_class === "string" && entry.error_class !== "") {
    parts.push("error_class=" + entry.error_class);
  }
  if (entry.error_code !== undefined && entry.error_code !== null) {
    parts.push("error_code=" + String(entry.error_code));
  }
  if (typeof entry.cause === "string" && entry.cause !== "") {
    parts.push("cause=" + entry.cause);
  }
  return parts.join(" ");
}

function appendText(existing, addition) {
  if (addition === "") {
    return existing;
  }
  if (existing === "") {
    return addition;
  }
  return existing + "\n" + addition;
}

function presentText(value, fallback) {
  return typeof value === "string" && value !== "" ? value : fallback;
}

function presentNumber(value, fallback) {
  return typeof value === "number" && Number.isFinite(value) ? String(value) : fallback;
}
