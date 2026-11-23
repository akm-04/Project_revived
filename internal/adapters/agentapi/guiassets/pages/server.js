"use strict";

import { confirmAction } from "../components/confirm_action.js";
import { describeReply, request } from "../transport.js";

// renderPage is the Server screen: the process status card, the registered
// server.list table, then Start and Stop through ConfirmAction.
export function renderPage(container) {
  container.replaceChildren();
  const overview = buildOverview();
  const list = buildList();
  const start = buildAction("Start backend");
  const stop = buildAction("Stop backend");
  container.append(overview.card, list.card, start.card, stop.card);

  async function loadStatus() {
    overview.status.textContent = "";
    const reply = await request("/agent/v1/backend/status");
    if (reply.unauthorized) {
      return;
    }
    if (!reply.ok) {
      fillStatus(overview, null);
      overview.status.textContent = describeReply(reply);
      return;
    }
    fillStatus(overview, reply.body);
  }

  async function loadServers() {
    list.status.textContent = "";
    const reply = await request("/agent/v1/reads/server.list");
    if (reply.unauthorized) {
      return;
    }
    if (!reply.ok) {
      fillServers(overview, []);
      list.table.replaceChildren(noRowsRow(4, "The server list is unavailable."));
      list.status.textContent = describeReply(reply);
      return;
    }
    const body = reply.body && typeof reply.body === "object" ? reply.body : {};
    const servers = Array.isArray(body.servers) ? body.servers : [];
    fillServers(overview, servers);
    fillTable(list.table, servers);
    list.status.textContent = "Loaded " + servers.length + " server" + (servers.length === 1 ? "." : "s.");
  }

  async function refresh() {
    await Promise.all([loadStatus(), loadServers()]);
  }

  list.refresh.addEventListener("click", () => {
    void refresh();
  });

  start.button.addEventListener("click", async () => {
    const confirmation = await confirmAction({
      title: "Start backend",
      summary: "Start the backend process with its game listener bound.",
      confirmLabel: "Start",
    });
    if (confirmation === null) {
      return;
    }
    const reply = await request("/agent/v1/backend/start", { method: "POST", body: { closed: false } });
    showReply(start, reply, confirmation);
    if (reply.ok) {
      await refresh();
    }
  });

  stop.button.addEventListener("click", async () => {
    const confirmation = await confirmAction({
      title: "Stop backend",
      summary: "Stop the backend process. Every connected player is disconnected and the server stays down until it is started again.",
      confirmLabel: "Stop backend",
    });
    if (confirmation === null) {
      return;
    }
    const reply = await request("/agent/v1/backend/stop", { method: "POST", body: {} });
    showReply(stop, reply, confirmation);
    if (reply.ok) {
      await refresh();
    }
  });

  void refresh();
}

function buildOverview() {
  const card = document.createElement("div");
  card.className = "card card-body";
  const heading = document.createElement("h2");
  heading.className = "card-title";
  heading.textContent = "Server";
  const hint = document.createElement("p");
  hint.className = "hint";
  hint.textContent = "Process state from the operator agent, registered servers from the backend.";
  const rows = document.createElement("dl");
  rows.className = "row";
  const running = overviewRow(rows, "Backend", "server-running");
  const pid = overviewRow(rows, "Process id", "server-pid");
  const state = overviewRow(rows, "State", "server-state");
  const count = overviewRow(rows, "Registered servers", "server-count");
  const open = overviewRow(rows, "Open servers", "server-open-count");
  const online = overviewRow(rows, "Players online", "server-online-count");
  const status = document.createElement("p");
  status.className = "status";
  status.id = "server-status";
  status.setAttribute("role", "status");
  card.append(heading, hint, rows, status);
  return { card, running, pid, state, count, open, online, status };
}

function overviewRow(list, label, valueID) {
  const term = document.createElement("dt");
  term.className = "col-5";
  term.textContent = label;
  const value = document.createElement("dd");
  value.className = "col-7";
  value.id = valueID;
  value.textContent = "unknown";
  list.append(term, value);
  return value;
}

function fillStatus(overview, body) {
  if (body === null || typeof body !== "object") {
    overview.running.textContent = "unknown";
    overview.pid.textContent = "unknown";
    overview.state.textContent = "unknown";
    return;
  }
  overview.running.textContent = body.running === true ? "running" : body.running === false ? "stopped" : "unknown";
  overview.pid.textContent = typeof body.pid === "number" ? String(body.pid) : "unknown";
  overview.state.textContent = presentText(body.state, "unknown");
}

function fillServers(overview, servers) {
  overview.count.textContent = String(servers.length);
  overview.open.textContent = String(servers.filter((server) => server && server.open === true).length);
  const online = servers.reduce((total, server) => total + (server && typeof server.online_count === "number" ? server.online_count : 0), 0);
  overview.online.textContent = String(online);
}

function buildList() {
  const card = document.createElement("div");
  card.className = "card card-body";
  const heading = document.createElement("h2");
  heading.className = "card-title";
  heading.textContent = "Registered servers";
  const controls = document.createElement("div");
  controls.className = "d-flex gap-2 mb-2";
  const refresh = document.createElement("button");
  refresh.type = "button";
  refresh.className = "btn btn-outline-secondary btn-sm";
  refresh.id = "server-refresh";
  refresh.textContent = "Refresh";
  controls.append(refresh);
  const table = document.createElement("table");
  table.id = "server-table";
  const status = document.createElement("p");
  status.className = "status";
  status.id = "server-list-status";
  status.setAttribute("role", "status");
  card.append(heading, controls, table, status);
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

function buildAction(title) {
  const card = document.createElement("div");
  card.className = "card card-body";
  const heading = document.createElement("h2");
  heading.className = "card-title";
  heading.textContent = title;
  const button = document.createElement("button");
  button.type = "button";
  button.className = "btn btn-primary";
  button.textContent = title;
  const status = document.createElement("p");
  status.className = "status mt-2";
  status.setAttribute("role", "status");
  const result = document.createElement("pre");
  result.className = "component-output";
  card.append(heading, button, status, result);
  return { card, button, status, result };
}

function showReply(box, reply, confirmation) {
  box.status.textContent = "";
  box.result.textContent = "";
  if (reply.unauthorized) {
    return;
  }
  if (!reply.ok) {
    box.status.textContent = describeReply(reply);
    return;
  }
  const lines = ["HTTP " + reply.status, "reason: " + confirmation.reason, "semantic_key: " + confirmation.semantic_key];
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
