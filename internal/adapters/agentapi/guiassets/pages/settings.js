"use strict";

import { describeReply, request } from "../transport.js";
import { pageHeader } from "../components/format.js";

const settingsRead = "/agent/v1/reads/agent.settings";
const serverListRead = "/agent/v1/reads/server.list";
const agentSettingsCommand = "/agent/v1/commands/agent.settings.set";
const otaSettingsCommand = "/agent/v1/commands/ota.settings.set";
const serverURLCommand = "/agent/v1/commands/server.url.set";
const serverRenameCommand = "/agent/v1/commands/server.rename";

// renderPage is the Settings screen (G22): the paths in agent.json and the OTA
// settings, the client-facing server URL, and the server names the client
// server-select popup reads. Every value is validated by its owner; a refused
// value keeps the old one.
export function renderPage(container, context) {
  container.replaceChildren();
  const heading = pageHeader(context.page.label);
  const help = document.createElement("p");
  help.className = "module-help";
  help.textContent = "The paths the operator tool and the backend read, the address the clients use, and the server names the client server-select popup shows.";
  const loadStatus = document.createElement("p");
  loadStatus.className = "status";
  loadStatus.id = "settings-load-status";
  loadStatus.setAttribute("role", "status");
  const paths = buildPathsSection();
  const serverURL = buildServerURLSection();
  const serverNames = buildServerNamesSection();
  container.append(heading, help, loadStatus, paths.card, serverURL.card, serverNames.card);

  const state = { otaSettings: null, serverNames: [] };

  async function loadSettings() {
    loadStatus.textContent = "";
    const reply = await request(settingsRead);
    if (reply.unauthorized) {
      return;
    }
    if (!reply.ok) {
      loadStatus.textContent = describeReply(reply);
      return;
    }
    const values = reply.body && typeof reply.body === "object" ? reply.body : {};
    state.otaSettings = values.ota_settings && typeof values.ota_settings === "object" ? values.ota_settings : null;
    paths.backendPath.value = presentText(values.backend_path, "");
    paths.backupPath.value = presentText(values.backup_path, "");
    paths.appRepackPath.value = presentText(values.app_repack_path, "");
    paths.toolchainPath.value = presentText(values.toolchain_path, "");
    paths.mediaPath.value = presentText(values.media_path, "");
    paths.resPath.value = presentText(values.res_path, "");
    paths.apkResPath.value = presentText(values.apk_res_path, "");
    paths.recoveredResPath.value = presentText(values.recovered_res_path, "");
    const url = presentText(values.server_url, "");
    serverURL.current.textContent = url === "" ? "not set" : url;
    serverURL.source.textContent = url === "" ? "" : " (" + serverURLSourceText(values.server_url_source) + ")";
    serverURL.input.value = url;
    paths.save.disabled = state.otaSettings === null;
  }

  async function loadServers() {
    const reply = await request(serverListRead);
    if (reply.unauthorized) {
      return;
    }
    if (!reply.ok) {
      serverNames.status.textContent = describeReply(reply);
      return;
    }
    const body = reply.body && typeof reply.body === "object" ? reply.body : {};
    fillServerTable(state, serverNames.table, Array.isArray(body.servers) ? body.servers : []);
  }

  paths.save.addEventListener("click", () => {
    void savePaths(paths, state, async () => {
      await loadSettings();
      await loadServers();
    });
  });
  serverURL.save.addEventListener("click", () => {
    void saveServerURL(serverURL);
  });

  async function saveNames() {
    serverNames.status.replaceChildren();
    const changes = [];
    for (const entry of state.serverNames) {
      const name = entry.input.value.trim();
      if (name !== entry.original) {
        changes.push({ server_id: entry.serverID, name });
      }
    }
    if (changes.length === 0) {
      serverNames.status.textContent = "No names changed.";
      return;
    }
    serverNames.save.disabled = true;
    const reply = await request(serverRenameCommand, commandBody({ names: changes }, "Settings: rename servers"));
    serverNames.save.disabled = false;
    if (reply.unauthorized) {
      return;
    }
    if (!reply.ok) {
      serverNames.status.textContent = describeReply(reply);
      return;
    }
    const body = reply.body && typeof reply.body === "object" ? reply.body : {};
    const result = body.result && typeof body.result === "object" ? body.result : {};
    const renames = Array.isArray(result.renames) ? result.renames : [];
    if (renames.length === 0) {
      serverNames.status.textContent = "The names are saved.";
    }
    for (const rename of renames) {
      const line = document.createElement("p");
      line.className = "mb-1";
      line.textContent = "Server " + presentText(String(rename.server_id), "unknown") + ": " +
        presentText(rename.old_name, "unknown") + " -> " + presentText(rename.new_name, "unknown");
      serverNames.status.append(line);
    }
    await loadServers();
  }

  function fillServerTable(state, table, servers) {
    state.serverNames = [];
    table.replaceChildren();
    const head = document.createElement("thead");
    const headRow = document.createElement("tr");
    for (const label of ["Server", "Current name", "New name"]) {
      const cell = document.createElement("th");
      cell.textContent = label;
      headRow.append(cell);
    }
    head.append(headRow);
    table.append(head);
    const body = document.createElement("tbody");
    if (servers.length === 0) {
      const row = document.createElement("tr");
      const cell = document.createElement("td");
      cell.colSpan = 3;
      cell.textContent = "No servers are registered.";
      row.append(cell);
      body.append(row);
      table.append(body);
      return;
    }
    for (const server of servers) {
      const entry = server && typeof server === "object" ? server : {};
      const serverID = Number(entry.server_id);
      const original = presentText(entry.name, "");
      const row = document.createElement("tr");
      const idCell = document.createElement("td");
      idCell.textContent = "#" + presentText(String(entry.server_id), "unknown");
      const currentCell = document.createElement("td");
      currentCell.textContent = presentText(entry.name, "unknown");
      const inputCell = document.createElement("td");
      const input = document.createElement("input");
      input.type = "text";
      input.className = "form-control form-control-sm";
      input.value = original;
      input.setAttribute("aria-label", "New name for server " + presentText(String(entry.server_id), ""));
      inputCell.append(input);
      row.append(idCell, currentCell, inputCell);
      body.append(row);
      state.serverNames.push({ serverID, original, input });
    }
    table.append(body);
  }

  serverNames.save.addEventListener("click", () => {
    void saveNames();
  });

  void loadSettings();
  void loadServers();
}

async function savePaths(paths, state, reloadAll) {
  paths.status.replaceChildren();
  const agentPayload = {
    backend_path: paths.backendPath.value.trim(),
    backup_path: paths.backupPath.value.trim(),
    app_repack_path: paths.appRepackPath.value.trim(),
    toolchain_path: paths.toolchainPath.value.trim(),
  };
  const otaPayload = Object.assign({}, state.otaSettings, {
    res_path: paths.resPath.value.trim(),
    apk_res_path: paths.apkResPath.value.trim(),
    recovered_res_path: paths.recoveredResPath.value.trim(),
  });
  const agentReply = await request(agentSettingsCommand, commandBody(agentPayload, "Settings: save the agent paths"));
  if (agentReply.unauthorized) {
    return;
  }
  paths.status.append(resultLine("Agent paths", agentReply));
  const otaReply = await request(otaSettingsCommand, commandBody(otaPayload, "Settings: save the OTA paths"));
  if (otaReply.unauthorized) {
    return;
  }
  paths.status.append(resultLine("OTA paths", otaReply));
  if (agentReply.ok && otaReply.ok) {
    await reloadAll();
  }
}

async function saveServerURL(section) {
  section.status.textContent = "";
  const reply = await request(serverURLCommand, commandBody({ url: section.input.value.trim() }, "Settings: set the server URL"));
  if (reply.unauthorized) {
    return;
  }
  if (!reply.ok) {
    section.status.textContent = describeReply(reply);
    return;
  }
  const body = reply.body && typeof reply.body === "object" ? reply.body : {};
  section.current.textContent = presentText(body.url, section.input.value.trim());
  section.status.textContent = presentText(body.message, "The server URL is saved.");
}

function buildPathsSection() {
  const card = document.createElement("section");
  card.className = "card card-body mb-3";
  const fieldset = document.createElement("fieldset");
  const legend = document.createElement("legend");
  legend.className = "card-title h3";
  legend.textContent = "Paths";
  const help = document.createElement("p");
  help.className = "module-help";
  help.textContent = "The agent and the OTA owner validate every path; a refused value keeps the old one. Agent paths take effect after the operator agent is restarted.";
  const form = document.createElement("form");
  form.id = "settings-paths-form";
  form.addEventListener("submit", (event) => {
    event.preventDefault();
  });
  const grid = document.createElement("div");
  grid.className = "row g-2";
  const fields = {
    backendPath: pathField(grid, "settings-backend-path", "Backend path", "absolute path of the gxb-api binary"),
    backupPath: pathField(grid, "settings-backup-path", "Backup folder", "empty uses the agent root's backups folder"),
    appRepackPath: pathField(grid, "settings-app-repack-path", "App repack folder", "absolute app_repack folder for the APK build"),
    toolchainPath: pathField(grid, "settings-toolchain-path", "Toolchain folder", "empty uses the system PATH"),
    mediaPath: pathField(grid, "settings-media-path", "Media folder", "set media_path in agent.json to change it"),
    resPath: pathField(grid, "settings-res-path", "Res path", "absolute asset folder the OTA server serves"),
    apkResPath: pathField(grid, "settings-apk-res-path", "APK res path", "optional second picture root"),
    recoveredResPath: pathField(grid, "settings-recovered-res-path", "Recovered res path", "absolute asset-recovery folder"),
  };
  fields.mediaPath.readOnly = true;
  const save = document.createElement("button");
  save.type = "button";
  save.className = "btn btn-primary mt-3";
  save.id = "settings-paths-save";
  save.textContent = "Save paths";
  save.disabled = true;
  const status = document.createElement("div");
  status.className = "status mt-2";
  status.id = "settings-paths-status";
  status.setAttribute("role", "status");
  form.append(grid, save, status);
  fieldset.append(legend, help, form);
  card.append(fieldset);
  return Object.assign({ card, save, status }, fields);
}

function pathField(grid, identifier, label, hint) {
  const column = document.createElement("div");
  column.className = "col-12 col-md-6";
  const labelElement = document.createElement("label");
  labelElement.className = "form-label";
  labelElement.htmlFor = identifier;
  labelElement.textContent = label;
  const input = document.createElement("input");
  input.type = "text";
  input.className = "form-control";
  input.id = identifier;
  input.autocomplete = "off";
  input.spellcheck = false;
  input.placeholder = hint;
  column.append(labelElement, input);
  grid.append(column);
  return input;
}

function buildServerURLSection() {
  const card = document.createElement("section");
  card.className = "card card-body mb-3";
  const fieldset = document.createElement("fieldset");
  const legend = document.createElement("legend");
  legend.className = "card-title h3";
  legend.textContent = "Server URL";
  const help = document.createElement("p");
  help.className = "module-help";
  help.textContent = "The address the client uses after the update check. The backend reads it from GXB_PUBLIC_ENGINE_URL in its env file.";
  const currentRow = document.createElement("p");
  currentRow.className = "mb-2";
  const currentLabel = document.createElement("strong");
  currentLabel.textContent = "Current: ";
  const current = document.createElement("span");
  current.id = "settings-url-current";
  current.textContent = "unknown";
  const source = document.createElement("span");
  source.id = "settings-url-source";
  source.className = "text-secondary";
  currentRow.append(currentLabel, current, source);
  const label = document.createElement("label");
  label.className = "form-label";
  label.htmlFor = "settings-url-input";
  label.textContent = "New URL";
  const input = document.createElement("input");
  input.type = "text";
  input.className = "form-control";
  input.id = "settings-url-input";
  input.autocomplete = "off";
  input.spellcheck = false;
  input.placeholder = "game.example";
  const warning = document.createElement("p");
  warning.className = "hint";
  warning.id = "settings-url-warning";
  warning.textContent = "Changing this URL requires rebuilding the APK with the app_repack folder: the APK carries the address that asks the backend for this URL.";
  const save = document.createElement("button");
  save.type = "button";
  save.className = "btn btn-primary mt-2";
  save.id = "settings-url-save";
  save.textContent = "Save URL";
  const status = document.createElement("p");
  status.className = "status mt-2";
  status.id = "settings-url-status";
  status.setAttribute("role", "status");
  fieldset.append(legend, help, currentRow, label, input, warning, save, status);
  card.append(fieldset);
  return { card, current, source, input, save, status };
}

// serverURLSourceText maps the settings read's server_url_source onto the
// plain words the review asks for (internal/application/operatoragent/settings.go:23-24).
function serverURLSourceText(source) {
  if (source === "env_file") {
    return "from the backend env file";
  }
  if (source === "agent_environment") {
    return "from the agent environment";
  }
  return "source unknown";
}

function buildServerNamesSection() {
  const card = document.createElement("section");
  card.className = "card card-body mb-3";
  const fieldset = document.createElement("fieldset");
  const legend = document.createElement("legend");
  legend.className = "card-title h3";
  legend.textContent = "Server names";
  const help = document.createElement("p");
  help.className = "module-help";
  help.textContent = "The client server-select popup shows these names. A name is 1 to 16 display characters; a non-ASCII character counts as two, and it must not be empty.";
  const responsive = document.createElement("div");
  responsive.className = "table-responsive";
  const table = document.createElement("table");
  table.className = "table table-sm";
  table.id = "settings-server-table";
  responsive.append(table);
  const save = document.createElement("button");
  save.type = "button";
  save.className = "btn btn-primary mt-2";
  save.id = "settings-server-save";
  save.textContent = "Save names";
  const status = document.createElement("div");
  status.className = "status mt-2";
  status.id = "settings-server-status";
  status.setAttribute("role", "status");
  fieldset.append(legend, help, responsive, save, status);
  card.append(fieldset);
  return { card, table, save, status };
}

function commandBody(payload, reason) {
  return {
    method: "POST",
    body: { reason: reason, semantic_key: newSemanticKey(), payload: payload },
  };
}

function newSemanticKey() {
  if (typeof crypto !== "undefined" && typeof crypto.randomUUID === "function") {
    return crypto.randomUUID();
  }
  return "gui-" + Date.now() + "-" + Math.random().toString(16).slice(2);
}

function resultLine(label, reply) {
  const line = document.createElement("p");
  line.className = "mb-1";
  if (!reply.ok) {
    line.textContent = label + ": " + describeReply(reply);
    return line;
  }
  const body = reply.body && typeof reply.body === "object" ? reply.body : {};
  line.textContent = label + ": saved." + (body.message ? " " + body.message : "");
  return line;
}

function presentText(value, fallback) {
  return typeof value === "string" && value !== "" ? value : fallback;
}
