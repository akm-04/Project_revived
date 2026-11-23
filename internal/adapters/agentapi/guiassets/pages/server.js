"use strict";

import { confirmAction } from "../components/confirm_action.js";
import { pageHeader, setStatus } from "../components/format.js";
import { describeReply, request } from "../transport.js";

const statusRead = "/agent/v1/backend/status";
const pingsRead = "/agent/v1/reads/dashboard.pings";
const serversRead = "/agent/v1/reads/server.list";
const settingsRead = "/agent/v1/reads/agent.settings";
const publicURLsCommand = "/agent/v1/commands/server.public_urls.set";
const startPath = "/agent/v1/backend/start";
const restartPath = "/agent/v1/backend/restart";
const stopPath = "/agent/v1/backend/stop";

// renderPage is the Server screen (G34): one Server controls card with a status
// line and Start, Restart and Stop, then the registered servers table.
export function renderPage(container, context) {
  container.replaceChildren();
  container.append(pageHeader(context.page.label));
  const controls = buildControls();
  const publicURLs = buildPublicURLsSection();
  const list = buildList();
  container.append(controls.card, publicURLs.card, list.card);

  async function loadStatus() {
    const [statusReply, pingsReply] = await Promise.all([request(statusRead), request(pingsRead)]);
    if (statusReply.unauthorized) {
      return;
    }
    const pings = pingsReply.ok && pingsReply.body && typeof pingsReply.body === "object" ? pingsReply.body : null;
    applyStatus(controls, statusReply, pings);
    if (!statusReply.ok) {
      setStatus(controls.status, describeReply(statusReply), "error");
    }
  }

  async function loadServers() {
    list.status.textContent = "";
    const reply = await request(serversRead);
    if (reply.unauthorized) {
      return;
    }
    if (!reply.ok) {
      controls.counts.textContent = "unknown";
      list.table.replaceChildren(noRowsRow(4, "The server list is unavailable."));
      setStatus(list.status, describeReply(reply), "error");
      return;
    }
    const body = reply.body && typeof reply.body === "object" ? reply.body : {};
    const servers = Array.isArray(body.servers) ? body.servers : [];
    fillServers(controls, servers);
    fillTable(list.table, servers);
    setStatus(list.status, "Loaded " + servers.length + " server" + (servers.length === 1 ? "." : "s."), "success");
  }

  async function loadPublicURLs() {
    publicURLs.status.textContent = "";
    const reply = await request(settingsRead);
    if (reply.unauthorized || !reply.ok) {
      publicURLs.status.textContent = reply.ok ? "" : describeReply(reply);
      return;
    }
    const values = reply.body && typeof reply.body === "object" ? reply.body : {};
    const urls = values.public_urls && typeof values.public_urls === "object" ? values.public_urls : {};
    publicURLs.sdk.value = presentText(urls.sdk, "");
    publicURLs.api.value = presentText(urls.api, presentText(values.server_url, ""));
    publicURLs.assets.value = presentText(urls.assets, "");
  }

  async function savePublicURLs() {
    publicURLs.status.textContent = "";
    publicURLs.save.disabled = true;
    const payload = {
      sdk: publicURLs.sdk.value.trim(),
      api: publicURLs.api.value.trim(),
      assets: publicURLs.assets.value.trim(),
    };
    const reply = await request(publicURLsCommand, {
      method: "POST",
      body: { reason: "Server: set the public URLs", semantic_key: newSemanticKey(), payload: { public_urls: payload } },
    });
    publicURLs.save.disabled = false;
    if (reply.unauthorized) {
      return;
    }
    if (!reply.ok) {
      setStatus(publicURLs.status, describeReply(reply), "error");
      return;
    }
    const body = reply.body && typeof reply.body === "object" ? reply.body : {};
    setStatus(publicURLs.status, presentText(body.message, "The public URLs are saved."), "success");
    await loadPublicURLs();
    await loadStatus();
  }

  publicURLs.save.addEventListener("click", () => {
    void savePublicURLs();
  });

  async function refresh() {
    await Promise.all([loadStatus(), loadServers(), loadPublicURLs()]);
  }

  async function runAction(action) {
    const reply = await request(action.path, { method: "POST", body: { closed: false } });
    showReply(controls, reply, action.reason);
    await refresh();
  }

  list.refresh.addEventListener("click", () => {
    void refresh();
  });

  controls.start.addEventListener("click", async () => {
    await runAction({ path: startPath, reason: "start from the Server page" });
  });

  controls.restart.addEventListener("click", async () => {
    const confirmation = await confirmAction({
      title: "Restart server",
      summary: "Stop the backend process and start it again. Every connected player is disconnected, and a failure after the stop leaves the server stopped.",
      confirmLabel: "Restart server",
    });
    if (confirmation === null) {
      return;
    }
    await runAction({ path: restartPath, reason: confirmation.reason });
  });

  controls.stop.addEventListener("click", async () => {
    const confirmation = await confirmAction({
      title: "Stop server",
      summary: "Stop the backend process. Every connected player is disconnected and the server stays down until it is started again.",
      confirmLabel: "Stop server",
    });
    if (confirmation === null) {
      return;
    }
    await runAction({ path: stopPath, reason: confirmation.reason });
  });

  void refresh();
}

// buildPublicURLsSection shows the three client-facing addresses by role
// instead of one unlabelled field. Each is optional and must be http(s); an
// unknown role or a malformed value is a 409 refusal from the agent.
function buildPublicURLsSection() {
  const card = document.createElement("div");
  card.className = "card card-body";
  card.id = "server-public-urls";
  const heading = document.createElement("h2");
  heading.className = "card-title";
  heading.textContent = "Public URLs";
  const help = document.createElement("p");
  help.className = "module-help";
  help.textContent = "The addresses clients use: the SDK endpoint, the game API and the asset server. Each is optional and must be an absolute http or https URL. The game API URL is also written to the backend env file.";
  const grid = document.createElement("div");
  grid.className = "row g-2";
  const sdk = urlField(grid, "server-public-url-sdk", "SDK URL", "sdk.example");
  const api = urlField(grid, "server-public-url-api", "Game API URL", "api.example");
  const assets = urlField(grid, "server-public-url-assets", "Assets URL", "assets.example");
  const save = document.createElement("button");
  save.type = "button";
  save.className = "btn btn-primary mt-2";
  save.id = "server-public-urls-save";
  save.textContent = "Save URLs";
  const status = document.createElement("p");
  status.className = "status mt-2";
  status.id = "server-public-urls-status";
  status.setAttribute("role", "status");
  card.append(heading, help, grid, save, status);
  return { card, sdk, api, assets, save, status };
}

function urlField(grid, identifier, labelText, placeholder) {
  const column = document.createElement("div");
  column.className = "col-12 col-md-4";
  const label = document.createElement("label");
  label.className = "form-label";
  label.htmlFor = identifier;
  label.textContent = labelText;
  const input = document.createElement("input");
  input.type = "text";
  input.className = "form-control";
  input.id = identifier;
  input.autocomplete = "off";
  input.spellcheck = false;
  input.placeholder = placeholder;
  column.append(label, input);
  grid.append(column);
  return input;
}

function newSemanticKey() {
  if (typeof crypto !== "undefined" && typeof crypto.randomUUID === "function") {
    return crypto.randomUUID();
  }
  return "gui-" + Date.now() + "-" + Math.random().toString(16).slice(2);
}

function buildControls() {
  const card = document.createElement("div");
  card.className = "card card-body";
  const heading = document.createElement("h2");
  heading.className = "card-title";
  heading.textContent = "Server controls";
  const statusLine = document.createElement("p");
  statusLine.className = "d-flex align-items-center gap-2 mb-2";
  statusLine.id = "server-status-line";
  statusLine.setAttribute("role", "status");
  const dot = document.createElement("span");
  dot.className = "status-dot status-secondary";
  dot.id = "server-status-dot";
  dot.setAttribute("aria-hidden", "true");
  const words = document.createElement("span");
  words.id = "server-status-words";
  words.textContent = "Unknown";
  statusLine.append(dot, words);
  const buttons = document.createElement("div");
  buttons.className = "btn-list";
  const start = actionButton("Start server", "server-start");
  const restart = actionButton("Restart server", "server-restart");
  const stop = actionButton("Stop server", "server-stop");
  start.disabled = true;
  restart.disabled = true;
  stop.disabled = true;
  buttons.append(start, restart, stop);
  const counts = document.createElement("p");
  counts.className = "small text-secondary mb-0";
  counts.id = "server-counts";
  counts.textContent = "unknown";
  const status = document.createElement("p");
  status.className = "status mt-2";
  status.id = "server-status";
  status.setAttribute("role", "status");
  const result = document.createElement("pre");
  result.className = "component-output";
  card.append(heading, statusLine, buttons, counts, status, result);
  return { card, dot, words, start, restart, stop, counts, status, result };
}

function applyStatus(controls, reply, pings) {
  const body = reply.ok && reply.body && typeof reply.body === "object" ? reply.body : null;
  if (body === null) {
    paintStatus(controls, "secondary", "Unknown");
    controls.start.disabled = false;
    controls.restart.disabled = true;
    controls.stop.disabled = true;
    return;
  }
  const state = serverState(body, pings);
  paintStatus(controls, state.tone, state.text);
  controls.start.disabled = state.running;
  controls.restart.disabled = !state.running;
  controls.stop.disabled = !state.running;
}

// serverState is green only when the backend runs and the internet target's
// last sample answered; a failing internet or public-URL target makes it
// yellow and names which one failed.
function serverState(status, pings) {
  if (status.running !== true) {
    return { tone: "danger", text: "Stopped", running: false };
  }
  const targets = pings && Array.isArray(pings.targets) ? pings.targets : [];
  const reasons = [];
  const internet = lastSample(targets, "internet");
  if (internet === null) {
    reasons.push("internet not measured yet");
  } else if (sampleFailed(internet)) {
    reasons.push("internet unreachable");
  }
  for (const target of targets) {
    if (typeof target.id !== "string" || !target.id.startsWith("public_")) {
      continue;
    }
    const sample = lastSample(targets, target.id);
    if (sample !== null && sampleFailed(sample)) {
      reasons.push(presentText(target.label, target.id) + " unreachable");
    }
  }
  if (reasons.length === 0) {
    return { tone: "success", text: "Running", running: true };
  }
  return { tone: "warning", text: "Running, no internet (" + reasons.join(", ") + ")", running: true };
}

function paintStatus(controls, tone, text) {
  controls.dot.className = "status-dot status-" + tone;
  controls.words.textContent = text;
  controls.words.className = "text-" + tone;
}

function lastSample(targets, id) {
  const target = targets.find((candidate) => candidate && candidate.id === id);
  if (!target || !Array.isArray(target.samples) || target.samples.length === 0) {
    return null;
  }
  return target.samples[target.samples.length - 1];
}

function sampleFailed(sample) {
  return !sample || typeof sample !== "object" || typeof sample.ms !== "number" || !Number.isFinite(sample.ms);
}

function fillServers(controls, servers) {
  const open = servers.filter((server) => server && server.open === true).length;
  const online = servers.reduce((total, server) => total + (server && typeof server.online_count === "number" ? server.online_count : 0), 0);
  controls.counts.textContent = servers.length + " servers, " + open + " open, " + online + " players online";
}

function buildList() {
  const card = document.createElement("div");
  card.className = "card card-body";
  const heading = document.createElement("h2");
  heading.className = "card-title";
  heading.textContent = "Registered servers";
  const controls = document.createElement("div");
  controls.className = "btn-list mb-2";
  const refresh = document.createElement("button");
  refresh.type = "button";
  refresh.className = "btn btn-outline-secondary btn-sm";
  refresh.id = "server-refresh";
  refresh.textContent = "Refresh";
  controls.append(refresh);
  const table = document.createElement("table");
  table.className = "table table-sm table-vcenter card-table mb-0";
  table.id = "server-table";
  const status = document.createElement("p");
  status.className = "status";
  status.id = "server-list-status";
  status.setAttribute("role", "status");
  const tableWrap = document.createElement("div");
  tableWrap.className = "table-responsive";
  tableWrap.append(table);
  card.append(heading, controls, tableWrap, status);
  return { card, table, status, refresh };
}

function fillTable(table, servers) {
  table.replaceChildren();
  const head = document.createElement("thead");
  const headRow = document.createElement("tr");
  for (const label of ["Server", "Open", "Online"]) {
    const cell = document.createElement("th");
    cell.textContent = label;
    headRow.append(cell);
  }
  head.append(headRow);
  table.append(head);
  const body = document.createElement("tbody");
  if (servers.length === 0) {
    body.append(noRowsRow(3, "No servers are registered."));
    table.append(body);
    return;
  }
  for (const server of servers) {
    const entry = server && typeof server === "object" ? server : {};
    const row = document.createElement("tr");
    row.append(
      textCell("#" + presentNumber(entry.server_id, "unknown") + " " + presentText(entry.name, "unknown")),
      textCell(entry.open === true ? "open" : entry.open === false ? "closed" : "unknown"),
      textCell(presentNumber(entry.online_count, "unknown")),
    );
    body.append(row);
  }
  table.append(body);
}

function textCell(value) {
  const cell = document.createElement("td");
  cell.textContent = value;
  return cell;
}

function noRowsRow(columns, text) {
  const row = document.createElement("tr");
  const cell = document.createElement("td");
  cell.colSpan = columns;
  cell.textContent = text;
  row.append(cell);
  return row;
}

function actionButton(label, identifier) {
  const button = document.createElement("button");
  button.type = "button";
  button.className = "btn btn-primary";
  button.textContent = label;
  button.id = identifier;
  return button;
}

function showReply(box, reply, reason) {
  box.status.textContent = "";
  box.result.textContent = "";
  if (reply.unauthorized) {
    return;
  }
  if (!reply.ok) {
    setStatus(box.status, describeReply(reply), "error");
    return;
  }
  const lines = ["HTTP " + reply.status, "reason: " + reason];
  const body = reply.body && typeof reply.body === "object" ? reply.body : {};
  for (const key of Object.keys(body)) {
    const value = body[key];
    lines.push(key + ": " + (value !== null && typeof value === "object" ? JSON.stringify(value) : String(value)));
  }
  box.result.textContent = lines.join("\n");
}

function presentText(value, fallback) {
  return typeof value === "string" && value !== "" ? value : fallback;
}

function presentNumber(value, fallback) {
  return typeof value === "number" && Number.isFinite(value) ? String(value) : fallback;
}
