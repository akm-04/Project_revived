"use strict";

import { describeReply, request } from "../transport.js";
import { confirmAction } from "../components/confirm_action.js";
import { formatTime, pageHeader, setStatus } from "../components/format.js";
import { mountServerPicker } from "../components/server_picker.js";

const onlineRead = "/agent/v1/reads/session.online";
const findRead = "/agent/v1/reads/player.find";
const summaryRead = "/agent/v1/reads/player.summary";
const serverListRead = "/agent/v1/reads/server.list";
const logoutCommand = "/agent/v1/commands/session.logout";
const logoutAllCommand = "/agent/v1/commands/session.logout_all";
const pageSize = 50;

// renderPage is the online-players view (G8): paged session.online, a server
// filter, player.find search, player.summary on a row click, and the three
// logout scopes with the backend's hold default (G11).
export function renderPage(container, context) {
  container.replaceChildren();
  container.append(pageHeader(context.page.label));
  const help = document.createElement("p");
  help.className = "module-help";
  help.textContent = "Live sessions, player search and logout by player, server or all servers.";
  const refresh = actionButton("Refresh online", true, "players-refresh");
  const status = document.createElement("p");
  status.className = "status";
  status.id = "players-status";
  status.setAttribute("role", "status");
  const overview = document.createElement("div");
  overview.className = "row g-2";
  overview.id = "players-overview";
  const selectedCount = overviewCard("Selected players", "0");
  selectedCount.value.id = "players-selected-count";
  const onlineCard = overviewCard("Players online", "unknown");
  onlineCard.value.id = "players-online-count";
  const serverCard = overviewCard("Registered servers", "unknown");
  serverCard.value.id = "players-server-count";
  overview.append(onlineCard.card, serverCard.card, selectedCount.card);

  const filterSection = section("card card-body mt-3");
  const filterTitle = document.createElement("h3");
  filterTitle.className = "card-title";
  filterTitle.textContent = "Online server filter";
  const filterHost = document.createElement("div");
  filterHost.id = "players-filter";
  filterSection.append(filterTitle, filterHost);

  const onlineSection = section("card card-body mt-3");
  const onlineTitle = document.createElement("h3");
  onlineTitle.className = "card-title";
  onlineTitle.textContent = "Online players";
  const onlineStatus = paragraph("module-help", "Loading live sessions…");
  onlineStatus.id = "players-online-status";
  const onlineTable = document.createElement("div");
  onlineTable.className = "player-table-scroll table-responsive";
  onlineTable.id = "players-online-table";
  const loadMore = actionButton("Load more", false, "players-online-more");
  loadMore.hidden = true;
  onlineSection.append(onlineTitle, onlineStatus, onlineTable, loadMore);

  const searchSection = section("card card-body mt-3");
  const searchTitle = document.createElement("h3");
  searchTitle.className = "card-title";
  searchTitle.textContent = "Find a player";
  const searchFields = document.createElement("div");
  searchFields.className = "row g-2 mb-2";
  const uidInput = labeledInput(searchFields, "players-search-uid", "Account uid");
  const nameInput = labeledInput(searchFields, "players-search-name", "Name prefix");
  const searchButton = actionButton("Search", true, "players-search-button");
  const searchActions = document.createElement("div");
  searchActions.className = "btn-list mb-2";
  searchActions.append(searchButton);
  const searchStatus = paragraph("module-help", "");
  searchStatus.id = "players-search-status";
  const searchTable = document.createElement("div");
  searchTable.className = "player-table-scroll table-responsive";
  searchTable.id = "players-search-table";
  searchSection.append(searchTitle, searchFields, searchActions, searchStatus, searchTable);

  const summarySection = section("card card-body mt-3");
  const summaryTitle = document.createElement("h3");
  summaryTitle.className = "card-title";
  summaryTitle.textContent = "Player summary";
  const summaryStatus = paragraph("module-help", "Click a player row to load its summary.");
  summaryStatus.id = "players-summary-status";
  const summaryHost = document.createElement("div");
  summaryHost.id = "players-summary";
  summarySection.append(summaryTitle, summaryStatus, summaryHost);

  const logoutSection = section("card card-body mt-3");
  const logoutTitle = document.createElement("h3");
  logoutTitle.className = "card-title";
  logoutTitle.textContent = "Logout";
  const holdDefault = holdDefaultSeconds(context.modules);
  const holdRow = document.createElement("div");
  holdRow.className = "row g-2 mb-3";
  const holdColumn = document.createElement("div");
  holdColumn.className = "col-md-3";
  const holdLabel = document.createElement("label");
  holdLabel.className = "form-label";
  holdLabel.htmlFor = "players-hold-seconds";
  holdLabel.textContent = "Hold seconds";
  const holdInput = document.createElement("input");
  holdInput.type = "number";
  holdInput.className = "form-control";
  holdInput.id = "players-hold-seconds";
  holdInput.min = "0";
  if (holdDefault !== null) {
    holdInput.value = String(holdDefault);
  }
  const holdHint = paragraph("hint", holdDefault === null ? "The backend did not report a hold default (unknown)." : "Backend default: " + holdDefault + " s.");
  holdHint.id = "players-hold-hint";
  holdColumn.append(holdLabel, holdInput, holdHint);
  holdRow.append(holdColumn);

  const scopeRow = document.createElement("fieldset");
  scopeRow.className = "mb-3";
  const scopeLegend = document.createElement("legend");
  scopeLegend.className = "form-label";
  scopeLegend.textContent = "Scope";
  const selectedScope = radioChoice("players-logout-scope-selected", "players-logout-scope", "Selected players", true);
  const serverScope = radioChoice("players-logout-scope-servers", "players-logout-scope", "Server or global", false);
  scopeRow.append(scopeLegend, selectedScope.label, serverScope.label);

  const selectedRow = document.createElement("div");
  selectedRow.className = "d-flex gap-2 align-items-center mb-2";
  const selectedButton = actionButton("Log out selected players", true, "players-logout-selected");
  selectedRow.append(selectedButton);
  const selectedResult = resultBox("players-logout-selected-result");

  const serverRow = document.createElement("div");
  serverRow.className = "mb-2";
  const serverHost = document.createElement("div");
  serverHost.className = "mb-2";
  serverHost.id = "players-logout-server-filter";
  const serverButton = actionButton("Log out selected servers", false, "players-logout-server");
  serverRow.append(serverHost, serverButton);
  const serverResult = resultBox("players-logout-server-result");

  logoutSection.append(logoutTitle, holdRow, scopeRow, selectedRow, selectedResult, serverRow, serverResult);

  container.append(help, refresh, status, overview, filterSection, onlineSection, searchSection, summarySection, logoutSection);

  const state = {
    serverFilter: { global: true, server_ids: [] },
    onlineRows: [],
    onlineAfter: "",
    onlineRequest: 0,
    searchRequest: 0,
    selected: new Map(),
    selectedCount: selectedCount.value,
    summaryStatus,
    summaryHost,
    summaryRequest: 0,
  };
  const logoutPicker = mountServerPicker(serverHost, {
    includeGlobal: true,
    multiple: true,
    idPrefix: "players-logout-server",
    onChange: (value) => {
      serverButton.textContent = value.global ? "Log out all servers" : "Log out selected servers";
    },
  });

  mountServerPicker(filterHost, {
    includeGlobal: true,
    multiple: false,
    idPrefix: "players-filter",
    onChange: (value) => {
      state.serverFilter = value;
      void loadOnline(state, onlineStatus, onlineTable, loadMore, true);
    },
  });
  refresh.addEventListener("click", () => {
    void loadOverview(onlineCard.value, serverCard.value, status);
    void loadOnline(state, onlineStatus, onlineTable, loadMore, true);
  });
  loadMore.addEventListener("click", () => {
    void loadOnline(state, onlineStatus, onlineTable, loadMore, false);
  });
  searchButton.addEventListener("click", () => {
    void runSearch(uidInput, nameInput, state, searchStatus, searchTable);
  });
  uidInput.addEventListener("keydown", (event) => {
    if (event.key === "Enter") {
      event.preventDefault();
      void runSearch(uidInput, nameInput, state, searchStatus, searchTable);
    }
  });
  nameInput.addEventListener("keydown", (event) => {
    if (event.key === "Enter") {
      event.preventDefault();
      void runSearch(uidInput, nameInput, state, searchStatus, searchTable);
    }
  });
  selectedButton.addEventListener("click", () => {
    void logoutSelected(state, holdInput, selectedResult);
  });
  serverButton.addEventListener("click", () => {
    if (logoutPicker.value().global) {
      void logoutGlobal(holdInput, serverResult);
      return;
    }
    void logoutServer(logoutPicker, holdInput, serverResult);
  });
  selectedScope.input.addEventListener("change", applyLogoutScope);
  serverScope.input.addEventListener("change", applyLogoutScope);

  function applyLogoutScope() {
    const servers = serverScope.input.checked;
    selectedRow.hidden = servers;
    selectedResult.hidden = servers;
    serverRow.hidden = !servers;
    serverResult.hidden = !servers;
  }

  applyLogoutScope();
  void loadOverview(onlineCard.value, serverCard.value, status);
  void loadOnline(state, onlineStatus, onlineTable, loadMore, true);
  updateSelectedCount(state);
}

function overviewCard(title, value) {
  const column = document.createElement("div");
  column.className = "col-sm-4";
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
  return { card: column, value: content };
}

async function loadOverview(onlineValue, serverValue, status) {
  const reply = await request(serverListRead);
  if (reply.unauthorized) {
    return;
  }
  if (!reply.ok) {
    onlineValue.textContent = "unknown";
    serverValue.textContent = "unknown";
    setStatus(status, describeReply(reply), "error");
    return;
  }
  const body = reply.body && typeof reply.body === "object" ? reply.body : {};
  const servers = Array.isArray(body.servers) ? body.servers : [];
  let online = 0;
  for (const server of servers) {
    online += Number(server.online_count) || 0;
  }
  onlineValue.textContent = String(online);
  serverValue.textContent = String(servers.length);
}

async function loadOnline(state, onlineStatus, onlineTable, loadMore, reset) {
  const ticket = ++state.onlineRequest;
  if (reset) {
    state.onlineRows = [];
    state.onlineAfter = "";
  }
  onlineStatus.textContent = reset ? "Loading live sessions…" : "Loading more…";
  const query = new URLSearchParams();
  query.set("limit", String(pageSize));
  if (!reset && state.onlineAfter !== "") {
    query.set("after", state.onlineAfter);
  }
  const serverID = serverIDFilter(state.serverFilter);
  if (serverID !== null) {
    query.set("server_id", String(serverID));
  }
  const reply = await request(onlineRead + "?" + query.toString());
  if (ticket !== state.onlineRequest) {
    return;
  }
  if (reply.unauthorized) {
    return;
  }
  if (!reply.ok) {
    setStatus(onlineStatus, describeReply(reply), "error");
    return;
  }
  const body = reply.body && typeof reply.body === "object" ? reply.body : {};
  const sessions = Array.isArray(body.sessions) ? body.sessions : [];
  state.onlineRows = reset ? sessions : state.onlineRows.concat(sessions);
  state.onlineAfter = typeof body.next_after === "string" ? body.next_after : "";
  onlineStatus.textContent = state.onlineRows.length === 0 ? "No players are online." : state.onlineRows.length + " session(s) listed.";
  loadMore.hidden = state.onlineAfter === "";
  renderOnline(state, onlineTable);
}

function renderOnline(state, onlineTable) {
  onlineTable.replaceChildren();
  if (state.onlineRows.length === 0) {
    return;
  }
  const columns = [
    { label: "Player", text: (row) => valueText(row.name) + " (#" + valueText(row.player_id) + ")" },
    { label: "Server", text: (row) => valueText(row.server_id) },
    { label: "Session length", text: (row) => formatDuration(durationFrom(row.started_at)) },
    { label: "Started", text: (row) => formatTime(row.started_at) },
    { label: "Last seen", text: (row) => formatTime(row.last_seen_at) },
  ];
  onlineTable.append(createRowTable(state, state.onlineRows, columns, "players-online-select-all"));
}

async function runSearch(uidInput, nameInput, state, searchStatus, searchTable) {
  const ticket = ++state.searchRequest;
  const uid = uidInput.value.trim();
  const namePrefix = nameInput.value.trim();
  if (uid === "" && namePrefix === "") {
    setStatus(searchStatus, "Enter an account uid or a name prefix.", "error");
    return;
  }
  searchStatus.textContent = "Searching…";
  const query = new URLSearchParams();
  if (uid !== "") {
    query.set("uid", uid);
  }
  if (namePrefix !== "") {
    query.set("name_prefix", namePrefix);
  }
  query.set("limit", String(pageSize));
  const serverID = serverIDFilter(state.serverFilter);
  if (serverID !== null) {
    query.set("server_id", String(serverID));
  }
  const reply = await request(findRead + "?" + query.toString());
  if (ticket !== state.searchRequest) {
    return;
  }
  if (reply.unauthorized) {
    return;
  }
  if (!reply.ok) {
    setStatus(searchStatus, describeReply(reply), "error");
    return;
  }
  const body = reply.body && typeof reply.body === "object" ? reply.body : {};
  const players = Array.isArray(body.players) ? body.players : [];
  searchTable.replaceChildren();
  searchStatus.textContent = players.length === 0 ? "No players match." : players.length + " match(es)." + (body.truncated === true ? " Narrow the search to see the rest." : "");
  if (players.length === 0) {
    return;
  }
  const rows = players.map((player) => ({
    player_id: player.player_id,
    name: player.name,
    server_id: player.logical_server_id,
    level: player.level,
  }));
  searchTable.append(createRowTable(
    state,
    rows,
    [
      { label: "Player", text: (row) => valueText(row.name) + " (#" + valueText(row.player_id) + ")" },
      { label: "Server", text: (row) => valueText(row.server_id) },
      { label: "Level", text: (row) => valueText(row.level) },
    ],
    "players-search-select-all",
  ));
}

function createRowTable(state, rows, columns, selectAllIdentifier) {
  const table = document.createElement("table");
  table.className = "table table-sm table-vcenter card-table mb-0";
  const head = document.createElement("thead");
  const headRow = document.createElement("tr");
  const selectCell = document.createElement("th");
  const selectAll = document.createElement("input");
  selectAll.type = "checkbox";
  selectAll.className = "form-check-input";
  selectAll.id = selectAllIdentifier;
  selectCell.append(selectAll);
  headRow.append(selectCell);
  for (const column of columns) {
    const cell = document.createElement("th");
    cell.textContent = column.label;
    headRow.append(cell);
  }
  head.append(headRow);
  const body = document.createElement("tbody");
  const visible = [];
  for (const row of rows) {
    const tableRow = document.createElement("tr");
    const checkCell = document.createElement("td");
    const box = document.createElement("input");
    box.type = "checkbox";
    box.className = "form-check-input";
    const key = selectionKey(row);
    box.id = selectAllIdentifier + "-" + key;
    box.checked = state.selected.has(key);
    box.addEventListener("change", () => {
      if (box.checked) {
        state.selected.set(key, { player_id: row.player_id, name: row.name, server_id: row.server_id });
      } else {
        state.selected.delete(key);
      }
      updateSelectedCount(state);
      refreshSelectAll();
    });
    checkCell.append(box);
    tableRow.append(checkCell);
    for (const column of columns) {
      const cell = document.createElement("td");
      const rendered = column.text(row);
      if (rendered instanceof Node) {
        cell.append(rendered);
      } else {
        cell.textContent = rendered;
      }
      tableRow.append(cell);
    }
    tableRow.addEventListener("click", (event) => {
      if (event.target === box) {
        return;
      }
      void loadSummary(row.player_id, state);
    });
    body.append(tableRow);
    visible.push({ row, box });
  }
  function refreshSelectAll() {
    selectAll.checked = visible.length > 0 && visible.every((entry) => entry.box.checked);
  }
  selectAll.addEventListener("change", () => {
    for (const entry of visible) {
      entry.box.checked = selectAll.checked;
      if (selectAll.checked) {
        state.selected.set(selectionKey(entry.row), {
          player_id: entry.row.player_id,
          name: entry.row.name,
          server_id: entry.row.server_id,
        });
      } else {
        state.selected.delete(selectionKey(entry.row));
      }
    }
    updateSelectedCount(state);
    refreshSelectAll();
  });
  refreshSelectAll();
  table.append(head, body);
  return table;
}

async function loadSummary(playerID, state) {
  const ticket = ++state.summaryRequest;
  state.summaryStatus.textContent = "Loading player summary…";
  state.summaryHost.replaceChildren();
  const reply = await request(summaryRead + "?player_id=" + encodeURIComponent(String(playerID)));
  if (ticket !== state.summaryRequest) {
    return;
  }
  if (reply.unauthorized) {
    return;
  }
  if (!reply.ok) {
    setStatus(state.summaryStatus, describeReply(reply), "error");
    return;
  }
  const player = reply.body && typeof reply.body === "object" ? reply.body : {};
  state.summaryStatus.textContent = "";
  const list = document.createElement("dl");
  list.className = "row mb-0";
  list.id = "players-summary-table";
  for (const [label, value] of [
    ["Player", player.name],
    ["Player id", player.player_id],
    ["Account uid", player.account_uid],
    ["Level", player.level],
    ["Server", player.logical_server_id],
    ["VIP level", player.vip_level],
    ["Gold", player.gold],
    ["Crystals", player.crystals],
    ["Created", player.created_at],
    ["Last login", player.last_login],
  ]) {
    const term = document.createElement("dt");
    term.className = "col-sm-4 text-secondary";
    term.textContent = label;
    const valueCell = document.createElement("dd");
    valueCell.className = "col-sm-8";
    if ((label === "Created" || label === "Last login") && typeof value === "string") {
      valueCell.append(formatTime(value));
    } else {
      valueCell.textContent = valueText(value);
    }
    list.append(term, valueCell);
  }
  state.summaryHost.append(list);
}

async function logoutSelected(state, holdInput, result) {
  const players = Array.from(state.selected.values());
  if (players.length === 0) {
    result.replaceChildren(paragraph("status text-danger", "Select at least one player first."));
    return;
  }
  const hold = parseHoldSeconds(holdInput);
  if (holdInput.value.trim() !== "" && hold === null) {
    result.replaceChildren(paragraph("status text-danger", "Hold seconds must be a whole number of seconds."));
    return;
  }
  const playerIDs = players.map((player) => Number(player.player_id));
  const confirmed = await confirmAction({
    title: "Log out selected players",
    confirmLabel: "Log out",
    summary: "Revoke every live session of " + playerIDs.length + " player(s). New logins are held for " + holdText(hold) + ".",
  });
  if (confirmed === null) {
    return;
  }
  const payload = { player_ids: playerIDs };
  if (hold !== null) {
    payload.hold_seconds = hold;
  }
  await runLogoutInto(result, logoutCommand, payload, confirmed.reason, confirmed.semantic_key, hold, "");
}

async function logoutServer(picker, holdInput, result) {
  const value = picker.value();
  if (value.global || value.server_ids.length === 0) {
    result.replaceChildren(paragraph("status text-danger", "Select at least one server first."));
    return;
  }
  const hold = parseHoldSeconds(holdInput);
  if (holdInput.value.trim() !== "" && hold === null) {
    result.replaceChildren(paragraph("status text-danger", "Hold seconds must be a whole number of seconds."));
    return;
  }
  const serverIDs = value.server_ids;
  const confirmed = await confirmAction({
    title: "Log out " + serverIDs.length + " server(s)",
    confirmLabel: "Log out servers",
    summary: "Revoke every live session on server(s) " + serverIDs.join(", ") + ". New logins are held for " + holdText(hold) + ".",
  });
  if (confirmed === null) {
    return;
  }
  result.replaceChildren(paragraph("hint", "One session.logout_all command per selected server."));
  for (const serverID of serverIDs) {
    const payload = { server_id: serverID };
    if (hold !== null) {
      payload.hold_seconds = hold;
    }
    // The bus keys idempotency by semantic key, so each server needs its own.
    const semanticKey = confirmed.semantic_key + "-server-" + serverID;
    const outcome = await runLogout(logoutAllCommand, payload, confirmed.reason, semanticKey, hold, "Server " + serverID + ": ");
    if (outcome === null) {
      return;
    }
    result.append(outcome.line);
    if (outcome.ok) {
      result.append(logBox(outcome.body));
    }
  }
}

async function logoutGlobal(holdInput, result) {
  const hold = parseHoldSeconds(holdInput);
  if (holdInput.value.trim() !== "" && hold === null) {
    result.replaceChildren(paragraph("status text-danger", "Hold seconds must be a whole number of seconds."));
    return;
  }
  const confirmed = await confirmAction({
    title: "Log out every server",
    confirmLabel: "Log out all",
    summary: "Revoke every live session on every server. All players log in again; new logins are held for " + holdText(hold) + ".",
  });
  if (confirmed === null) {
    return;
  }
  const payload = {};
  if (hold !== null) {
    payload.hold_seconds = hold;
  }
  await runLogoutInto(result, logoutAllCommand, payload, confirmed.reason, confirmed.semantic_key, hold, "");
}

async function runLogoutInto(result, path, payload, reason, semanticKey, hold, prefix) {
  result.replaceChildren(paragraph("hint", "Running…"));
  const outcome = await runLogout(path, payload, reason, semanticKey, hold, prefix);
  if (outcome === null) {
    return;
  }
  result.replaceChildren(outcome.line);
  if (outcome.ok) {
    result.append(logBox(outcome.body));
  }
}

async function runLogout(path, payload, reason, semanticKey, hold, prefix) {
  const reply = await request(path, {
    method: "POST",
    body: { reason, semantic_key: semanticKey, payload },
  });
  if (reply.unauthorized) {
    return null;
  }
  if (!reply.ok) {
    return { ok: false, line: paragraph("status text-danger", prefix + describeReply(reply)) };
  }
  const body = reply.body && typeof reply.body === "object" ? reply.body : {};
  const result = body.result && typeof body.result === "object" ? body.result : {};
  const revoked = Number.isFinite(Number(result.revoked)) ? String(result.revoked) : "unknown";
  return {
    ok: true,
    body: result,
    line: paragraph("hint", prefix + "Revoked sessions: " + revoked + ". Requested hold: " + holdText(hold) + "."),
  };
}

function holdDefaultSeconds(modules) {
  const session = Array.isArray(modules) ? modules.find((module) => module.id === "session") : null;
  const values = session && session.defaults && typeof session.defaults.values === "object" ? session.defaults.values : null;
  if (values === null || !Number.isInteger(values.hold_seconds)) {
    return null;
  }
  return values.hold_seconds;
}

function parseHoldSeconds(input) {
  const text = input.value.trim();
  if (text === "") {
    return null;
  }
  const value = Number(text);
  if (!Number.isInteger(value) || value < 0) {
    return null;
  }
  return value;
}

function holdText(hold) {
  return hold === null ? "the backend default" : hold + " s";
}

function serverIDFilter(filter) {
  if (!filter || filter.global === true || !Array.isArray(filter.server_ids) || filter.server_ids.length !== 1) {
    return null;
  }
  return filter.server_ids[0];
}

function selectionKey(row) {
  return row.player_id + ":" + row.server_id;
}

function updateSelectedCount(state) {
  state.selectedCount.textContent = String(state.selected.size);
}

function durationFrom(startedAt) {
  const started = Date.parse(startedAt);
  if (Number.isNaN(started)) {
    return null;
  }
  return Math.max(0, Math.floor((Date.now() - started) / 1000));
}

function formatDuration(seconds) {
  if (seconds === null) {
    return "unknown";
  }
  const hours = Math.floor(seconds / 3600);
  const minutes = Math.floor((seconds % 3600) / 60);
  if (hours > 0) {
    return hours + "h " + String(minutes).padStart(2, "0") + "m";
  }
  return minutes + "m " + String(seconds % 60).padStart(2, "0") + "s";
}

function valueText(value) {
  if (value === undefined || value === null || value === "") {
    return "unknown";
  }
  return String(value);
}

function labeledInput(container, identifier, label) {
  const column = document.createElement("div");
  column.className = "col-md-4";
  const element = document.createElement("label");
  element.className = "form-label";
  element.htmlFor = identifier;
  element.textContent = label;
  const input = document.createElement("input");
  input.type = "text";
  input.className = "form-control";
  input.id = identifier;
  column.append(element, input);
  container.append(column);
  return input;
}

function radioChoice(identifier, name, labelText, checked) {
  const label = document.createElement("label");
  label.className = "form-check form-check-inline";
  const input = document.createElement("input");
  input.type = "radio";
  input.className = "form-check-input";
  input.id = identifier;
  input.name = name;
  input.checked = checked;
  const text = document.createElement("span");
  text.className = "form-check-label";
  text.textContent = labelText;
  label.append(input, text);
  return { label, input };
}

function resultBox(identifier) {
  const box = section("result");
  box.id = identifier;
  return box;
}

function section(className) {
  const element = document.createElement("section");
  element.className = className;
  return element;
}

function paragraph(className, text) {
  const element = document.createElement("p");
  element.className = className;
  element.textContent = text;
  return element;
}

function logBox(value) {
  const box = document.createElement("pre");
  box.textContent = JSON.stringify(value, null, 2);
  return box;
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
