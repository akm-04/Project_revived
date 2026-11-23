"use strict";

import { describeReply, request } from "../transport.js";

const summaryRead = "/agent/v1/reads/dashboard.summary";

// renderPage draws dashboard.summary as overview cards (G7): only values the
// read returns, and "unknown" for a section the agent could not fill.
export function renderPage(container, context) {
  container.replaceChildren();
  const heading = document.createElement("h2");
  heading.className = "module-title";
  heading.textContent = "Dashboard";
  const help = document.createElement("p");
  help.className = "module-help";
  help.textContent = "Backend, servers, events, OTA lanes and the asset front at a glance.";
  const refresh = actionButton("Refresh", true, "dashboard-refresh");
  const status = document.createElement("p");
  status.className = "status";
  status.id = "dashboard-status";
  status.setAttribute("role", "status");
  const overview = document.createElement("div");
  overview.className = "row g-2";
  overview.id = "dashboard-overview";
  const details = document.createElement("section");
  details.className = "mt-3";
  details.id = "dashboard-details";
  container.append(heading, help, refresh, status, overview, details);
  refresh.addEventListener("click", () => {
    void load(overview, details, status, refresh);
  });
  void load(overview, details, status, refresh);
}

async function load(overview, details, status, button) {
  button.disabled = true;
  const reply = await request(summaryRead);
  button.disabled = false;
  if (reply.unauthorized) {
    return;
  }
  if (!reply.ok) {
    status.textContent = describeReply(reply);
    return;
  }
  status.textContent = "Updated " + new Date().toLocaleTimeString();
  const summary = reply.body && typeof reply.body === "object" ? reply.body : {};
  const reachable = summary.api && summary.api.reachable === true;
  overview.replaceChildren();
  overview.append(
    card("Server URL", listText(summary.public_urls)),
    card("Backend", backendText(summary.backend)),
    card("API ping", pingText(summary.api)),
    card("Players online", onlineText(summary.servers, reachable)),
    card("Last DB snapshot", snapshotText(summary.db_snapshot)),
    card("OTA code", laneText(summary.ota, "code")),
    card("OTA assets", laneText(summary.ota, "assets")),
    card("OTA catalog", laneText(summary.ota, "catalog")),
    card("Active events", countText(summary.events)),
    card("Asset front", assetText(summary.assets)),
    card("Backend version", versionText(summary.version)),
    card("Cloudflare metrics", valueText(summary.cloudflare_metrics)),
  );
  details.replaceChildren();
  const errors = Array.isArray(summary.errors) ? summary.errors : [];
  if (errors.length === 0) {
    return;
  }
  const heading = document.createElement("h3");
  heading.className = "module-title";
  heading.textContent = "Partial readings";
  const list = document.createElement("ul");
  list.id = "dashboard-errors";
  for (const error of errors) {
    const item = document.createElement("li");
    item.textContent = String(error);
    list.append(item);
  }
  details.append(heading, list);
}

function card(title, value) {
  const column = document.createElement("div");
  column.className = "col-sm-6 col-lg-4";
  const body = document.createElement("div");
  body.className = "card card-body h-100";
  const label = document.createElement("div");
  label.className = "text-secondary";
  label.textContent = title;
  const content = document.createElement("div");
  content.className = "h3 mb-0";
  content.textContent = value;
  body.append(label, content);
  column.append(body);
  return column;
}

function valueText(value) {
  if (value === undefined || value === null || value === "") {
    return "unknown";
  }
  return String(value);
}

function listText(values) {
  if (!Array.isArray(values) || values.length === 0) {
    return "unknown";
  }
  return values.join(", ");
}

function countText(values) {
  return Array.isArray(values) ? String(values.length) : "unknown";
}

function backendText(backend) {
  if (!backend || typeof backend !== "object") {
    return "unknown";
  }
  const word = backend.running === true ? "running" : "stopped";
  const pid = backend.pid ? " (pid " + backend.pid + ")" : "";
  return word + pid;
}

function pingText(api) {
  if (!api || typeof api !== "object") {
    return "unknown";
  }
  if (api.reachable !== true) {
    return "unreachable";
  }
  if (api.ping_ms === undefined || api.ping_ms === null) {
    return "reachable";
  }
  return api.ping_ms + " ms";
}

function onlineText(servers, reachable) {
  if (!reachable || !Array.isArray(servers)) {
    return "unknown";
  }
  let total = 0;
  for (const server of servers) {
    total += Number(server.online_count) || 0;
  }
  return String(total);
}

function snapshotText(snapshot) {
  if (!snapshot || typeof snapshot !== "object") {
    return "unknown";
  }
  if (snapshot.age_seconds === undefined || snapshot.age_seconds === null) {
    return valueText(snapshot.status);
  }
  return formatAge(Number(snapshot.age_seconds)) + " ago (" + valueText(snapshot.status) + ")";
}

function laneText(ota, lane) {
  if (!ota || typeof ota !== "object") {
    return "unknown";
  }
  if (lane === "catalog") {
    return Array.isArray(ota.catalog) && ota.catalog.length > 0 ? ota.catalog.join(", ") : "none";
  }
  return valueText(ota[lane]);
}

function assetText(assets) {
  if (!assets || typeof assets !== "object") {
    return "unknown";
  }
  return "served " + (assets.served_paths || 0) + " paths, missing " + (assets.missing_paths || 0);
}

function versionText(version) {
  if (!version || typeof version !== "object") {
    return "unknown";
  }
  const name = valueText(version.backend_version);
  const commit = valueText(version.git_commit);
  if (name === "unknown" && commit === "unknown") {
    return "unknown";
  }
  return name + " (" + commit + ")";
}

function formatAge(seconds) {
  if (!Number.isFinite(seconds) || seconds < 0) {
    return "unknown";
  }
  if (seconds < 60) {
    return seconds + " s";
  }
  if (seconds < 3600) {
    return Math.floor(seconds / 60) + " min";
  }
  return Math.floor(seconds / 3600) + " h";
}

function actionButton(label, primary, identifier) {
  const button = document.createElement("button");
  button.type = "button";
  button.className = "btn " + (primary ? "btn-primary" : "btn-secondary");
  button.textContent = label;
  if (identifier) {
    button.id = identifier;
  }
  return button;
}
