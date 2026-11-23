"use strict";

import { describeReply, request } from "../transport.js";

const summaryRead = "/agent/v1/reads/dashboard.summary";
const refreshChoices = [1, 3, 10, 30, 60];
const defaultRefreshSeconds = 10;
const refreshStorageKey = "gxbDashboardRefreshSeconds";

// renderPage draws dashboard.summary as overview cards (G7, G20, G21). The
// refresh choice is kept per browser; a tick is skipped while a request is in
// flight, and the timer stops once the page is left.
export function renderPage(container, context) {
  container.replaceChildren();
  const heading = document.createElement("h2");
  heading.className = "module-title";
  heading.textContent = "Dashboard";
  const help = document.createElement("p");
  help.className = "module-help";
  help.textContent = "Server URL, backend version, configured paths, servers, events, OTA lanes and lazy asset downloads at a glance.";
  const controls = document.createElement("div");
  controls.className = "d-flex flex-wrap gap-2 align-items-center mb-2";
  const refresh = actionButton("Refresh", true, "dashboard-refresh");
  const refreshLabel = document.createElement("label");
  refreshLabel.className = "form-label mb-0";
  refreshLabel.htmlFor = "dashboard-refresh-seconds";
  refreshLabel.textContent = "Auto-refresh";
  const refreshSelect = document.createElement("select");
  refreshSelect.className = "form-select form-select-sm w-auto";
  refreshSelect.id = "dashboard-refresh-seconds";
  for (const seconds of refreshChoices) {
    const option = document.createElement("option");
    option.value = String(seconds);
    option.textContent = seconds + " s";
    refreshSelect.append(option);
  }
  refreshSelect.value = String(readRefreshSeconds());
  controls.append(refresh, refreshLabel, refreshSelect);
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
  container.append(heading, help, controls, status, overview, details);

  let timer = null;
  let inFlight = false;

  async function tick() {
    if (inFlight) {
      return;
    }
    if (!container.isConnected) {
      stop();
      return;
    }
    inFlight = true;
    refresh.disabled = true;
    try {
      await load(overview, details, status);
    } finally {
      inFlight = false;
      refresh.disabled = false;
    }
  }

  function schedule(seconds) {
    if (timer !== null) {
      clearInterval(timer);
    }
    timer = setInterval(() => {
      void tick();
    }, seconds * 1000);
  }

  function stop() {
    if (timer !== null) {
      clearInterval(timer);
      timer = null;
    }
  }

  refresh.addEventListener("click", () => {
    void tick();
  });
  refreshSelect.addEventListener("change", () => {
    const seconds = readChoice(refreshSelect.value);
    writeRefreshSeconds(seconds);
    schedule(seconds);
  });

  void tick();
  schedule(readRefreshSeconds());
}

async function load(overview, details, status) {
  const reply = await request(summaryRead);
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
    card("Server URL", serverURLText(summary), "dashboard-server-url"),
    card("Backend version", versionText(summary.version), "dashboard-backend-version"),
    card("Backend", backendText(summary.backend), "dashboard-backend"),
    card("API ping", pingText(summary.api), "dashboard-api-ping"),
    card("Players online", onlineText(summary.servers, reachable), "dashboard-players-online"),
    card("Last DB snapshot", snapshotText(summary.db_snapshot), "dashboard-db-snapshot"),
    card("OTA code", laneText(summary.ota, "code"), "dashboard-ota-code"),
    card("OTA assets", laneText(summary.ota, "assets"), "dashboard-ota-assets"),
    card("OTA catalog", laneText(summary.ota, "catalog"), "dashboard-ota-catalog"),
    card("Active events", countText(summary.events), "dashboard-active-events"),
    card("Lazy asset downloads", assetText(summary.assets), "dashboard-lazy-assets", "Files the OTA server served, and files it could not find."),
    card("Cloudflare metrics", valueText(summary.cloudflare_metrics), "dashboard-cloudflare"),
    pathsCard(summary),
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

function card(title, value, identifier, note) {
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
  if (identifier) {
    content.id = identifier;
  }
  body.append(label, content);
  if (note) {
    const hint = document.createElement("div");
    hint.className = "text-secondary small mt-1";
    hint.textContent = note;
    if (identifier) {
      hint.id = identifier + "-note";
    }
    body.append(hint);
  }
  column.append(body);
  return column;
}

function pathsCard(summary) {
  const column = document.createElement("div");
  column.className = "col-12";
  const body = document.createElement("div");
  body.className = "card card-body";
  const title = document.createElement("h3");
  title.className = "card-title";
  title.textContent = "Configured paths";
  const list = document.createElement("dl");
  list.className = "row mb-0";
  list.id = "dashboard-paths";
  const settings = settingsOf(summary);
  const rows = [
    ["Backend path", settings.backend_path],
    ["Res path", settings.res_path],
    ["APK res path", settings.apk_res_path],
    ["Recovered res path", settings.recovered_res_path],
    ["Backup folder", settings.backup_path],
    ["App repack folder", settings.app_repack_path],
    ["Toolchain", settings.toolchain_path === "" ? "system-wide" : settings.toolchain_path],
  ];
  for (const [label, value] of rows) {
    const term = document.createElement("dt");
    term.className = "col-5 col-md-3";
    term.textContent = label;
    const description = document.createElement("dd");
    description.className = "col-7 col-md-9 text-break";
    description.textContent = presentText(value, "not set");
    list.append(term, description);
  }
  body.append(title, list);
  column.append(body);
  return column;
}

function settingsOf(summary) {
  return summary.settings && typeof summary.settings === "object" ? summary.settings : {};
}

function serverURLText(summary) {
  const settings = settingsOf(summary);
  if (typeof settings.server_url === "string" && settings.server_url !== "") {
    return settings.server_url;
  }
  return listText(summary.public_urls);
}

function valueText(value) {
  if (value === undefined || value === null || value === "") {
    return "unknown";
  }
  return String(value);
}

function presentText(value, fallback) {
  return typeof value === "string" && value !== "" ? value : fallback;
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
  return (assets.served_paths || 0) + " served, " + (assets.missing_paths || 0) + " missing";
}

// versionText shows the facts the backend reports. A source build has no module
// version, so the migration number is the real value it can prove.
function versionText(version) {
  if (!version || typeof version !== "object") {
    return "unknown";
  }
  const parts = [];
  if (typeof version.backend_version === "string" && version.backend_version !== "") {
    parts.push(version.backend_version);
  }
  if (typeof version.git_commit === "string" && version.git_commit !== "") {
    parts.push("commit " + version.git_commit.slice(0, 12));
  }
  if (typeof version.migration === "number" && version.migration > 0) {
    parts.push("migration " + version.migration);
  }
  return parts.length === 0 ? "unknown" : parts.join(", ");
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

function readChoice(value) {
  const seconds = Number(value);
  return refreshChoices.includes(seconds) ? seconds : defaultRefreshSeconds;
}

function readRefreshSeconds() {
  try {
    return readChoice(localStorage.getItem(refreshStorageKey));
  } catch (error) {
    return defaultRefreshSeconds;
  }
}

function writeRefreshSeconds(seconds) {
  try {
    localStorage.setItem(refreshStorageKey, String(seconds));
  } catch (error) {
    // A browser that refuses storage keeps the default for this session.
  }
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
