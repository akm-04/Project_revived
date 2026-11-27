"use strict";

import { describeReply, request } from "../transport.js";
import { actionRow, navigateButton, pageHeader } from "../components/format.js";
import { confirmAction } from "../components/confirm_action.js";

const statusRead = "/agent/v1/reads/ota.status";
const releaseRead = "/agent/v1/reads/ota.release";
const buildPath = "/agent/v1/ota/build";
const publishPath = "/agent/v1/ota/publish";
const operationPollMilliseconds = 1000;
const operationPollLimit = 120;
const versionCheckDebounceMilliseconds = 250;
const firstReleaseVersion = "1.631.1";
const rollbackAcknowledgementText = "I understand clients must clear app data";
const rollbackWarningText = "installed clients will not step down by themselves: players must clear the app's data or reinstall to take the rolled-back release";
const publishWarningText = "Publish runs the maintenance window: the game closes, every player is logged out, the release goes live, the game reopens.";

const lanes = [
  { id: "assets", title: "Loud (assets)", action: "assets" },
  { id: "code", title: "Silent (code)", action: "code" },
];

// renderPage draws the two lane cards from ota.status (G6, G14, G23). The
// operator sees the proposed next version, may type another, and a lower
// number needs the rollback acknowledgement before Stage runs.
export function renderPage(container, context) {
  container.replaceChildren();
  const heading = pageHeader(context.page.label);
  const help = document.createElement("p");
  help.className = "module-help";
  help.textContent = "Stage builds the version you type, or the lane's next number; publish runs the maintenance window.";
  const refresh = actionButton("Refresh", true, "ota-refresh");
  const status = document.createElement("p");
  status.className = "status";
  status.id = "ota-status";
  status.setAttribute("role", "status");
  const laneRow = document.createElement("div");
  laneRow.className = "row row-cols-1 row-cols-md-2 g-3";
  container.append(heading, help, actionRow(refresh), status, laneRow);

  const views = new Map();
  for (const lane of lanes) {
    const view = createLaneCard(lane, reloadPage);
    views.set(lane.id, view);
    const column = document.createElement("div");
    column.className = "col";
    column.append(view.card);
    laneRow.append(column);
  }
  const buildSettings = createBuildSettingsCard();
  const activity = createActivityCard();
  container.append(buildSettings.card, activity.card, createReleaseCheck());
  function reloadPage() {
    return load(views, status, refresh, buildSettings, activity);
  }
  refresh.addEventListener("click", () => {
    void reloadPage();
  });
  void reloadPage();
}

function createLaneCard(lane, reloadPage) {
  const card = document.createElement("section");
  card.className = "card card-body h-100";
  card.id = "ota-lane-" + lane.id;
  const title = document.createElement("h3");
  title.className = "card-title";
  title.textContent = lane.title;
  const rows = document.createElement("table");
  rows.className = "table table-sm mb-2";
  const body = document.createElement("tbody");
  const values = new Map();
  for (const [label, key] of [
    ["Active version", "active"],
    ["Published", "published"],
    ["Staged build", "staged"],
    ["Staged built", "staged_at"],
    ["Staged size", "size"],
  ]) {
    const row = document.createElement("tr");
    const labelCell = document.createElement("th");
    labelCell.textContent = label;
    const valueCell = document.createElement("td");
    valueCell.id = "ota-" + lane.id + "-" + key;
    valueCell.textContent = "Loading…";
    row.append(labelCell, valueCell);
    body.append(row);
    values.set(key, valueCell);
  }
  rows.append(body);
  const staleWarning = document.createElement("p");
  staleWarning.className = "status";
  staleWarning.id = "ota-stale-warning-" + lane.id;
  staleWarning.hidden = true;

  const versionLabel = document.createElement("label");
  versionLabel.className = "form-label";
  versionLabel.htmlFor = "ota-version-" + lane.id;
  versionLabel.textContent = "Version";
  const versionInput = document.createElement("input");
  versionInput.type = "text";
  versionInput.className = "form-control";
  versionInput.id = "ota-version-" + lane.id;
  versionInput.autocomplete = "off";
  versionInput.placeholder = "1.631.1";
  const allowedInfo = document.createElement("p");
  allowedInfo.className = "hint mb-1";
  allowedInfo.id = "ota-allowed-" + lane.id;
  const nextVersionNote = document.createElement("p");
  nextVersionNote.className = "hint mb-1";
  nextVersionNote.id = "ota-next-version-note-" + lane.id;
  const versionHint = document.createElement("p");
  versionHint.className = "hint mb-1";
  versionHint.id = "ota-version-hint-" + lane.id;
  const rollbackWarning = document.createElement("p");
  rollbackWarning.className = "status";
  rollbackWarning.id = "ota-rollback-warning-" + lane.id;
  rollbackWarning.hidden = true;
  const acknowledgementLabel = document.createElement("label");
  acknowledgementLabel.className = "form-check mb-2";
  acknowledgementLabel.id = "ota-rollback-ack-label-" + lane.id;
  acknowledgementLabel.hidden = true;
  const acknowledgement = document.createElement("input");
  acknowledgement.type = "checkbox";
  acknowledgement.className = "form-check-input";
  acknowledgement.id = "ota-rollback-ack-" + lane.id;
  const acknowledgementText = document.createElement("span");
  acknowledgementText.textContent = rollbackAcknowledgementText;
  acknowledgementLabel.append(acknowledgement, acknowledgementText);

  const actions = document.createElement("div");
  actions.className = "d-flex flex-wrap gap-2";
  const stage = actionButton("Stage build", true, "ota-stage-" + lane.id);
  const publish = actionButton("Publish staged", false, "ota-publish-" + lane.id);
  publish.disabled = true;
  const publishHint = document.createElement("span");
  publishHint.className = "hint align-self-center";
  publishHint.id = "ota-publish-hint-" + lane.id;
  publishHint.textContent = "Stage a build first";
  actions.append(stage, publish, publishHint);
  const publishWarning = document.createElement("p");
  publishWarning.className = "status mt-2";
  publishWarning.id = "ota-publish-warning-" + lane.id;
  publishWarning.textContent = publishWarningText;
  const log = document.createElement("section");
  log.className = "result";
  log.id = "ota-log-" + lane.id;
  card.append(title, rows, staleWarning, versionLabel, versionInput, allowedInfo, nextVersionNote, versionHint, rollbackWarning, acknowledgementLabel, actions, publishWarning, log);

  let nextVersion = "";
  let activeVersion = "";
  let stagedVersion = "";
  let userEdited = false;
  let rollbackRequired = false;
  let checkGeneration = 0;
  let checkTimer = null;
  let checkedVersion = "";
  let usedRelease = null;

  // refreshPublish makes the publish state obvious: an active warning button
  // with no hint, or a disabled secondary button with the reason beside it.
  function refreshPublish() {
    const allowed = stagedVersion !== "";
    publish.disabled = !allowed;
    publish.className = "btn " + (allowed ? "btn-warning" : "btn-secondary");
    publishHint.hidden = allowed;
    publishHint.textContent = allowed ? "" : "Stage a build first";
  }

  function refreshForm() {
    const typed = versionInput.value.trim();
    const lineVersion = activeVersion === "" ? stagedVersion : activeVersion;
    const classification = classifyVersion(typed, activeVersion, lineVersion);
    rollbackRequired = classification.kind === "rollback";
    rollbackWarning.hidden = !rollbackRequired;
    acknowledgementLabel.hidden = !rollbackRequired;
    if (!rollbackRequired) {
      acknowledgement.checked = false;
    }
    allowedInfo.textContent = allowedVersionsText(nextVersion);
    if (rollbackRequired) {
      rollbackWarning.textContent = typed + " is below the active " + activeVersion + ". A rollback: " + rollbackWarningText +
        " To undo a change, revert the source and stage " + (nextVersion || "the next number") +
        ": clients update normally without clearing data. A rollback number must be lower than the active one and never used.";
    } else {
      rollbackWarning.textContent = "";
    }
    const checking = typed !== "" && parseVersion(typed) !== null && checkedVersion !== typed;
    const used = typed !== "" && checkedVersion === typed ? usedRelease : null;
    const usedReusable = used !== null && rollbackRequired && used.reusable;
    versionHint.textContent = versionHintText(typed, classification, checking, used, usedReusable, nextVersion);
    stage.disabled = classification.kind === "invalid" || classification.kind === "equal" ||
      classification.kind === "otherLine" ||
      (rollbackRequired && !acknowledgement.checked) ||
      (typed === "" && nextVersion === "") ||
      checking ||
      (used !== null && !usedReusable);
  }

  function scheduleVersionCheck() {
    if (checkTimer !== null) {
      clearTimeout(checkTimer);
      checkTimer = null;
    }
    const generation = ++checkGeneration;
    const typed = versionInput.value.trim();
    if (typed === "" || parseVersion(typed) === null) {
      checkedVersion = typed;
      usedRelease = null;
      refreshForm();
      return;
    }
    checkedVersion = "";
    usedRelease = null;
    refreshForm();
    checkTimer = setTimeout(() => {
      checkTimer = null;
      void runVersionCheck(typed, generation);
    }, versionCheckDebounceMilliseconds);
  }

  async function runVersionCheck(typed, generation) {
    const reply = await request(releaseRead + "?version=" + encodeURIComponent(typed));
    if (generation !== checkGeneration || reply.unauthorized) {
      return;
    }
    checkedVersion = typed;
    usedRelease = releaseFromReply(reply);
    refreshForm();
  }

  async function checkVersionNow(typed) {
    if (checkTimer !== null) {
      clearTimeout(checkTimer);
      checkTimer = null;
    }
    const generation = ++checkGeneration;
    checkedVersion = "";
    usedRelease = null;
    refreshForm();
    await runVersionCheck(typed, generation);
  }

  versionInput.addEventListener("input", () => {
    userEdited = true;
    refreshForm();
    scheduleVersionCheck();
  });
  acknowledgement.addEventListener("change", refreshForm);
  stage.addEventListener("click", () => {
    void stageLaneAfterCheck();
  });
  async function stageLaneAfterCheck() {
    const typed = versionInput.value.trim();
    if (typed !== "" && parseVersion(typed) !== null && checkedVersion !== typed) {
      await checkVersionNow(typed);
      refreshForm();
    }
    if (stage.disabled) {
      return;
    }
    await stageLane(lane, versionInput.value.trim(), rollbackRequired, activeVersion, log);
    await reloadPage();
  }
  publish.addEventListener("click", () => {
    void publishLane(lane, stagedVersion, isStale(stagedVersion, activeVersion), log).finally(() => reloadPage());
  });

  return {
    card,
    values,
    publish,
    setSummary(summary, proposedNextVersion) {
      nextVersion = typeof proposedNextVersion === "string" ? proposedNextVersion : "";
      activeVersion = optionalText(summary, "active_version").value;
      stagedVersion = optionalText(summary, "built_not_published").value;
      values.get("active").textContent = activeVersionText(summary);
      setPublishedTime(values.get("published"), summary);
      const stale = isStale(stagedVersion, activeVersion);
      values.get("staged").textContent = stagedVersionText(summary, stale);
      values.get("staged_at").textContent = stagedVersion === "" ? "Nothing staged" : "";
      if (stagedVersion !== "") {
        setLocalTime(values.get("staged_at"), summary && summary.built_at);
      }
      values.get("size").textContent = stagedVersion === "" ? "Nothing staged" : sizeText(summary && summary.size);
      nextVersionNote.textContent = nextVersionNoteText(nextVersion);
      refreshPublish();
      staleWarning.hidden = !stale;
      staleWarning.textContent = stale
        ? "The staged " + stagedVersion + " is not newer than the active " + activeVersion + ". Publishing it is a rollback: " + rollbackWarningText + "."
        : "";
      if (!userEdited) {
        versionInput.value = nextVersion;
        checkedVersion = nextVersion;
        usedRelease = null;
      }
      refreshForm();
    },
  };
}

// optionalText separates a missing field (unknown) from a present null or
// empty string (known, nothing published or staged).
function optionalText(object, key) {
  if (!object || typeof object !== "object" || !Object.prototype.hasOwnProperty.call(object, key)) {
    return { known: false, value: "" };
  }
  const value = object[key];
  if (value === null) {
    return { known: true, value: "" };
  }
  if (typeof value === "string") {
    return { known: true, value };
  }
  return { known: false, value: "" };
}

function activeVersionText(summary) {
  const active = optionalText(summary, "active_version");
  if (!active.known) {
    return "unknown";
  }
  return active.value === "" ? "Nothing published (clients use the stock client files)" : active.value;
}

function setPublishedTime(cell, summary) {
  const active = optionalText(summary, "active_version");
  if (active.known && active.value === "") {
    cell.textContent = "Nothing published";
    cell.removeAttribute("title");
    return;
  }
  const published = optionalText(summary, "published_at");
  if (!published.known) {
    cell.textContent = "unknown";
    cell.removeAttribute("title");
    return;
  }
  if (published.value === "") {
    cell.textContent = "Nothing published";
    cell.removeAttribute("title");
    return;
  }
  setLocalTime(cell, published.value);
}

function stagedVersionText(summary, stale) {
  const staged = optionalText(summary, "built_not_published");
  if (!staged.known) {
    // The lane summary omits the staged fields when nothing is staged, so a
    // present lane with no field is a known-empty value, not an unknown one.
    return summary && typeof summary === "object" ? "Nothing staged" : "unknown";
  }
  if (staged.value === "") {
    return "Nothing staged";
  }
  return staged.value + (stale ? " (stale)" : "");
}

// nextVersionNoteText explains the agent's rule in plain words: the proposed
// number is the highest built-or-active number of any lane plus one
// (internal/application/otarelease/status.go:256-272).
function nextVersionNoteText(nextVersion) {
  if (nextVersion !== "") {
    return "The proposed next number is the highest built or active number of any lane plus one.";
  }
  return "No release has been built yet, so the agent has no highest number to add one to. Type the first version (" + firstReleaseVersion + ") and choose Stage build; after the first release every stage fills in the next number.";
}

function createBuildSettingsCard() {
  const card = document.createElement("section");
  card.className = "card card-body mt-3";
  card.id = "ota-build-settings";
  const title = document.createElement("h3");
  title.className = "card-title";
  title.textContent = "Release build settings";
  const help = document.createElement("p");
  help.className = "module-help";
  help.textContent = "The asset folders the assets lane reads. The paths live in the OTA settings on the Settings page.";
  const list = document.createElement("dl");
  list.className = "row mb-0";
  const values = new Map();
  for (const [key, label] of [
    ["res_path", "Res path"],
    ["apk_res_path", "APK res path"],
    ["recovered_res_path", "Recovered res path"],
  ]) {
    const term = document.createElement("dt");
    term.className = "col-5 col-md-3";
    term.textContent = label;
    const description = document.createElement("dd");
    description.className = "col-7 col-md-9 text-break";
    description.id = "ota-setting-" + key;
    list.append(term, description);
    values.set(key, description);
  }
  const status = document.createElement("p");
  status.className = "status mt-2";
  status.id = "ota-build-settings-status";
  status.setAttribute("role", "status");
  card.append(title, help, list, status);
  return { card, values, status };
}

function renderBuildSettings(card, settings) {
  const present = settings && typeof settings === "object";
  for (const [key, cell] of card.values) {
    cell.replaceChildren();
    if (!present) {
      cell.textContent = "unknown";
      continue;
    }
    const value = optionalText(settings, key);
    if (!value.known) {
      cell.textContent = "unknown";
      continue;
    }
    if (value.value !== "") {
      cell.textContent = value.value;
      continue;
    }
    cell.append("Not set ", navigateButton("Open Settings", "settings"));
  }
  card.status.textContent = present ? "" : "The OTA settings are missing from the reply.";
}

function createActivityCard() {
  const card = document.createElement("section");
  card.className = "card card-body mt-3";
  card.id = "ota-activity";
  const title = document.createElement("h3");
  title.className = "card-title";
  title.textContent = "Release activity";
  const body = document.createElement("div");
  body.id = "ota-activity-body";
  card.append(title, body);
  return { card, body };
}

function renderActivity(card, body) {
  card.body.replaceChildren();
  for (const section of activitySections(body)) {
    card.body.append(activitySection(section));
  }
}

function activitySections(body) {
  return [
    {
      title: "Staged builds",
      field: listField(body, "built"),
      empty: "No builds are staged yet.",
      columns: ["Version", "Lane", "Size", "Built"],
      row: (entry) => [stringField(entry, "version"), stringField(entry, "lane"), sizeText(entry && entry.total_size), timeText(entry && entry.built_at)],
    },
    {
      title: "Publish and withdraw actions",
      field: listField(body, "activations"),
      empty: "Nothing has been published or withdrawn yet.",
      columns: ["Version", "Action", "When"],
      row: (entry) => [stringField(entry, "version"), stringField(entry, "action"), timeText(entry && entry.at)],
    },
    {
      title: "Served asset requests",
      field: listField(body, "served"),
      empty: "No asset requests have been served yet.",
      columns: ["Path", "Hits"],
      row: (entry) => [stringField(entry, "path"), presentCount(entry && entry.hits)],
    },
    {
      title: "Missed asset requests",
      field: listField(body, "misses"),
      empty: "No asset request has been missed yet.",
      columns: ["Path", "Hits", "Last seen"],
      row: (entry) => [stringField(entry, "path"), presentCount(entry && entry.hits), timeText(entry && entry.last_seen)],
    },
  ];
}

function listField(body, key) {
  if (!body || typeof body !== "object" || !Object.prototype.hasOwnProperty.call(body, key)) {
    return { known: false, list: [] };
  }
  return { known: true, list: Array.isArray(body[key]) ? body[key] : [] };
}

function activitySection(section) {
  const block = document.createElement("section");
  block.className = "mt-3";
  const title = document.createElement("h4");
  title.className = "module-title";
  title.textContent = section.title;
  block.append(title);
  if (!section.field.known) {
    const unknown = document.createElement("p");
    unknown.className = "status mb-0";
    unknown.textContent = "unknown";
    block.append(unknown);
    return block;
  }
  if (section.field.list.length === 0) {
    const empty = document.createElement("p");
    empty.className = "text-secondary mb-0";
    empty.textContent = section.empty;
    block.append(empty);
    return block;
  }
  const table = document.createElement("table");
  table.className = "table table-sm table-vcenter mb-0";
  const head = document.createElement("thead");
  const headRow = document.createElement("tr");
  for (const label of section.columns) {
    const cell = document.createElement("th");
    cell.textContent = label;
    headRow.append(cell);
  }
  head.append(headRow);
  const tableBody = document.createElement("tbody");
  for (const entry of section.field.list) {
    const row = document.createElement("tr");
    for (const value of section.row(entry && typeof entry === "object" ? entry : {})) {
      const cell = document.createElement("td");
      cell.textContent = value;
      row.append(cell);
    }
    tableBody.append(row);
  }
  table.append(head, tableBody);
  const wrap = document.createElement("div");
  wrap.className = "table-responsive";
  wrap.append(table);
  block.append(wrap);
  return block;
}

function presentCount(value) {
  return typeof value === "number" && Number.isFinite(value) ? String(value) : "unknown";
}

function timeText(value) {
  if (typeof value !== "string" || value === "" || value.startsWith("0001-01-01")) {
    return "unknown";
  }
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? "unknown" : date.toLocaleString();
}

async function load(views, status, button, buildSettings, activity) {
  button.disabled = true;
  const reply = await request(statusRead);
  button.disabled = false;
  if (reply.unauthorized) {
    return;
  }
  if (!reply.ok) {
    status.textContent = describeReply(reply);
    return;
  }
  status.textContent = "Loaded " + new Date().toLocaleTimeString();
  const body = reply.body && typeof reply.body === "object" ? reply.body : {};
  const summaries = Array.isArray(body.lanes) ? body.lanes : [];
  const nextVersion = stringField(body, "next_version");
  for (const lane of lanes) {
    const summary = summaries.find((candidate) => candidate.lane === lane.id);
    views.get(lane.id).setSummary(summary, nextVersion);
  }
  renderBuildSettings(buildSettings, body.settings);
  renderActivity(activity, body);
}

async function stageLane(lane, version, rollback, activeVersion, log) {
  const describedVersion = version === "" ? "the lane's next version" : version;
  const summary = rollback
    ? "Build " + describedVersion + ", below the active " + activeVersion + ". A rollback: " + rollbackWarningText + ". It stays BUILT until you publish it; clients are not affected yet."
    : "Build " + describedVersion + ". It stays BUILT until you publish it; clients are not affected.";
  const confirmed = await confirmAction({
    title: "Stage " + lane.title,
    confirmLabel: "Stage build",
    summary,
  });
  if (confirmed === null) {
    return;
  }
  log.replaceChildren();
  log.append(paragraph("status", "Building…"));
  const requestBody = { lane: lane.id, reason: confirmed.reason, semantic_key: confirmed.semantic_key };
  if (version !== "") {
    requestBody.version = version;
  }
  if (rollback) {
    requestBody.rollback = true;
  }
  const reply = await request(buildPath, { method: "POST", body: requestBody });
  if (reply.unauthorized) {
    return;
  }
  if (!reply.ok) {
    log.replaceChildren();
    log.append(paragraph("status", describeReply(reply)));
    return;
  }
  const operationID = reply.body && typeof reply.body === "object" ? reply.body.operation_id : "";
  if (typeof operationID !== "string" || operationID === "") {
    log.replaceChildren();
    log.append(paragraph("status", describeReply(reply)));
    return;
  }
  const operation = await pollOperation(operationID);
  if (operation === null) {
    log.replaceChildren();
    log.append(paragraph("status", "The operation did not finish; check it on the Logs page."));
    return;
  }
  log.replaceChildren();
  if (operation.unauthorized) {
    return;
  }
  if (!operation.ok) {
    log.append(paragraph("status", describeReply(operation)));
    return;
  }
  const record = operation.body && typeof operation.body === "object" ? operation.body : {};
  if (record.state === "FAILED") {
    log.append(paragraph("status", "The build failed: " + valueText(record.error)));
    return;
  }
  const builtVersion = stagedBuildVersion(record);
  log.append(paragraph("hint", builtVersion === "" ? "The backend finished the build." : "The backend registered version " + builtVersion + "."));
  log.append(logBox(record));
}

function stagedBuildVersion(operation) {
  const result = operation && typeof operation.result === "object" && operation.result !== null ? operation.result : null;
  if (result === null) {
    return "";
  }
  const release = result.release && typeof result.release === "object" ? result.release : null;
  if (release === null || typeof release.version !== "string") {
    return "";
  }
  return release.version;
}

async function publishLane(lane, version, rollback, log) {
  if (version === "") {
    log.replaceChildren();
    log.append(paragraph("status", "There is no staged build to publish."));
    return;
  }
  const summary = rollback
    ? "Publishing " + version + " is a rollback below the active version. " + rollbackWarningText + ". The maintenance window logs out every player. Continue?"
    : "Publishing takes the maintenance window and logs out every player. Continue?";
  const confirmed = await confirmAction({
    title: "Publish " + lane.title + " " + version,
    confirmLabel: "Publish",
    summary,
  });
  if (confirmed === null) {
    return;
  }
  log.replaceChildren();
  log.append(paragraph("status", "Publishing…"));
  const reply = await request(publishPath, {
    method: "POST",
    body: { version, reason: confirmed.reason, semantic_key: confirmed.semantic_key },
  });
  if (reply.unauthorized) {
    return;
  }
  log.replaceChildren();
  if (!reply.ok) {
    log.append(paragraph("status", describeReply(reply)));
    return;
  }
  const operation = reply.body && typeof reply.body === "object" ? reply.body : {};
  log.append(paragraph("hint", operation.state === "DONE" ? "Published " + version + "." : "The maintenance window is running."));
  log.append(logBox(operation));
}

async function pollOperation(operationID) {
  for (let attempt = 0; attempt < operationPollLimit; attempt += 1) {
    await delay(operationPollMilliseconds);
    const reply = await request("/agent/v1/ops/" + encodeURIComponent(operationID));
    if (reply.unauthorized || !reply.ok) {
      return reply;
    }
    const state = reply.body && typeof reply.body === "object" ? reply.body.state : "";
    if (state === "DONE" || state === "FAILED") {
      return reply;
    }
  }
  return null;
}

function createReleaseCheck() {
  const card = document.createElement("section");
  card.className = "card card-body mt-3";
  const title = document.createElement("h3");
  title.className = "card-title";
  title.textContent = "Check a release number";
  const help = document.createElement("p");
  help.className = "module-help";
  help.textContent = "Asks ota.release whether any lane holds this exact version.";
  const row = document.createElement("div");
  row.className = "row g-2 align-items-end";
  const inputColumn = document.createElement("div");
  inputColumn.className = "col-12 col-sm-4";
  const input = document.createElement("input");
  input.type = "text";
  input.className = "form-control";
  input.id = "ota-release-version";
  input.placeholder = "1.631.2";
  inputColumn.append(input);
  const buttonColumn = document.createElement("div");
  buttonColumn.className = "col-auto";
  const button = actionButton("Check", true, "ota-release-check");
  buttonColumn.append(button);
  row.append(inputColumn, buttonColumn);
  const result = document.createElement("p");
  result.className = "hint mt-2";
  result.id = "ota-release-result";
  card.append(title, help, row, result);
  button.addEventListener("click", () => {
    void checkRelease(input.value.trim(), result);
  });
  return card;
}

async function checkRelease(version, result) {
  result.className = "hint mt-2";
  if (version === "") {
    result.textContent = "Enter a release number.";
    return;
  }
  const reply = await request(releaseRead + "?version=" + encodeURIComponent(version));
  if (reply.unauthorized) {
    return;
  }
  if (!reply.ok) {
    result.textContent = describeReply(reply);
    return;
  }
  const exists = reply.body && typeof reply.body === "object" ? reply.body.exists === true : false;
  result.textContent = exists ? "Version " + version + " exists." : "Version " + version + " does not exist.";
}

// classifyVersion keeps the lane's line (G23): a different major.minor is
// refused on both the forward and the rollback path, because a client reads a
// changed line as a new APK.
function classifyVersion(text, activeVersion, lineVersion) {
  if (text === "") {
    return { kind: "auto" };
  }
  const version = parseVersion(text);
  if (version === null) {
    return { kind: "invalid" };
  }
  const line = parseVersion(lineVersion);
  if (line !== null && (version.major !== line.major || version.minor !== line.minor)) {
    return { kind: "otherLine", line: line.major + "." + line.minor };
  }
  const active = parseVersion(activeVersion);
  if (active === null) {
    return { kind: "forward" };
  }
  const order = compareVersions(version, active);
  if (order < 0) {
    return { kind: "rollback" };
  }
  if (order === 0) {
    return { kind: "equal" };
  }
  return { kind: "forward" };
}

// parseVersion mirrors the client's strict numeric x.y.z comparison
// (UpdateScene_64.lua:184-201); anything else cannot be compared.
function parseVersion(text) {
  if (typeof text !== "string" || !/^[0-9]+\.[0-9]+\.[0-9]+$/.test(text)) {
    return null;
  }
  const parts = text.split(".").map(Number);
  if (!parts.every((part) => Number.isSafeInteger(part))) {
    return null;
  }
  return { major: parts[0], minor: parts[1], patch: parts[2] };
}

function compareVersions(left, right) {
  if (left.major !== right.major) {
    return left.major < right.major ? -1 : 1;
  }
  if (left.minor !== right.minor) {
    return left.minor < right.minor ? -1 : 1;
  }
  if (left.patch !== right.patch) {
    return left.patch < right.patch ? -1 : 1;
  }
  return 0;
}

// versionHintText orders the form's guidance: a malformed or out-of-line number
// first, then the live duplicate check, then the shared next number (G44).
function versionHintText(typed, classification, checking, used, usedReusable, nextVersion) {
  if (classification.kind === "invalid") {
    return "Use a strict x.y.z number, e.g. " + (nextVersion || firstReleaseVersion) + ".";
  }
  if (classification.kind === "otherLine") {
    return typed + " is on another version line and is refused: keep " + classification.line + " and change only the last number.";
  }
  if (classification.kind === "equal") {
    return typed + " is already the active version.";
  }
  if (used !== null) {
    const usedBy = typed + " is already used by the " + used.lane + " release (" + used.state + ").";
    if (usedReusable) {
      return usedBy + " " + usedNumberReuseWarning(typed);
    }
    return usedBy + " A new release never reuses a number: a client that installed a number never downloads it again. Use " + (nextVersion || "the next number") + ".";
  }
  if (checking) {
    return "Checking whether " + typed + " is already used…";
  }
  if (typed === "" && nextVersion === "") {
    return "Enter the lane's first version.";
  }
  if (typed === "") {
    return "Empty stages the proposed next version " + nextVersion + ".";
  }
  return "The proposed next version is " + (nextVersion || "unknown") + ".";
}

// usedNumberReuseWarning is OA-10 clause 4: the rollback reuse is allowed, but
// players who keep their data keep the content they already hold.
function usedNumberReuseWarning(version) {
  return "Players who keep their data and already hold " + version + " keep the old " + version + " content without any prompt.";
}

// allowedVersionsText is the permanent line under the Version field: the one
// shared counter, the fixed line, and the only reuse exception (OA-10).
function allowedVersionsText(nextVersion) {
  if (nextVersion === "") {
    return "Allowed: " + firstReleaseVersion + " or higher";
  }
  const parsed = parseVersion(nextVersion);
  if (parsed === null) {
    return "Allowed: " + nextVersion + " or higher";
  }
  const line = parsed.major + "." + parsed.minor;
  return "Allowed: " + nextVersion + " or higher (" + line + ".x with x >= " + parsed.patch + "). " + line +
    " stays fixed (another line is a new APK); 1.631.0 is the APK's own number; numbers are shared by all lanes; only a rollback may reuse one (OA-10).";
}

// releaseFromReply reads the ota.release answer: lane, state and whether OA-10
// would let a rollback take the number over.
function releaseFromReply(reply) {
  if (!reply.ok || reply.body === null || typeof reply.body !== "object" || reply.body.exists !== true) {
    return null;
  }
  const state = stringField(reply.body, "state");
  return {
    lane: stringField(reply.body, "lane") || "unknown",
    state: state || "unknown",
    reusable: state === "SUPERSEDED" || state === "WITHDRAWN",
  };
}

function isStale(stagedText, activeText) {
  const staged = parseVersion(stagedText);
  const active = parseVersion(activeText);
  return staged !== null && active !== null && compareVersions(staged, active) <= 0;
}

function stringField(value, key) {
  return value && typeof value === "object" && typeof value[key] === "string" ? value[key] : "";
}

function setLocalTime(cell, value) {
  if (typeof value !== "string" || value === "" || value.startsWith("0001-01-01")) {
    cell.textContent = "unknown";
    cell.removeAttribute("title");
    return;
  }
  const date = new Date(value);
  if (Number.isNaN(date.getTime())) {
    cell.textContent = "unknown";
    cell.removeAttribute("title");
    return;
  }
  cell.textContent = date.toLocaleString();
  cell.title = value + " (UTC)";
}

function sizeText(size) {
  if (!Number.isFinite(Number(size)) || Number(size) <= 0) {
    return "unknown";
  }
  return Number(size) + " bytes";
}

function valueText(value) {
  if (value === undefined || value === null || value === "") {
    return "unknown";
  }
  return String(value);
}

function logBox(value) {
  const box = document.createElement("pre");
  box.textContent = JSON.stringify(value, null, 2);
  return box;
}

function paragraph(className, text) {
  const element = document.createElement("p");
  element.className = className;
  element.textContent = text;
  return element;
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

function delay(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}
