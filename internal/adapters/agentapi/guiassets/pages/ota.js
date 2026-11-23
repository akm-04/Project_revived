"use strict";

import { describeReply, request } from "../transport.js";
import { confirmAction } from "../components/confirm_action.js";

const statusRead = "/agent/v1/reads/ota.status";
const releaseRead = "/agent/v1/reads/ota.release";
const buildPath = "/agent/v1/ota/build";
const publishPath = "/agent/v1/ota/publish";
const operationPollMilliseconds = 1000;
const operationPollLimit = 120;

const lanes = [
  { id: "assets", title: "Loud (assets)", action: "assets" },
  { id: "code", title: "Silent (code)", action: "code" },
];

// renderPage draws the two lane cards from ota.status (G6, G14). The operator
// never types a version: Stage builds the lane's next number and the card shows
// what the backend registered.
export function renderPage(container, context) {
  container.replaceChildren();
  const heading = document.createElement("h2");
  heading.className = "module-title";
  heading.textContent = "OTA releases";
  const help = document.createElement("p");
  help.className = "module-help";
  help.textContent = "Stage builds the lane's next version; publish runs the maintenance window.";
  const refresh = actionButton("Refresh", true, "ota-refresh");
  const status = document.createElement("p");
  status.className = "status";
  status.id = "ota-status";
  status.setAttribute("role", "status");
  const laneRow = document.createElement("div");
  laneRow.className = "row g-3";
  container.append(heading, help, refresh, status, laneRow);

  const views = new Map();
  for (const lane of lanes) {
    const view = createLaneCard(lane);
    views.set(lane.id, view);
    laneRow.append(view.card);
  }
  container.append(createReleaseCheck());
  refresh.addEventListener("click", () => {
    void load(views, status, refresh);
  });
  void load(views, status, refresh);
}

function createLaneCard(lane) {
  const card = document.createElement("section");
  card.className = "card card-body col-md-6";
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
    valueCell.textContent = "unknown";
    row.append(labelCell, valueCell);
    body.append(row);
    values.set(key, valueCell);
  }
  rows.append(body);
  const actions = document.createElement("div");
  actions.className = "d-flex gap-2";
  const stage = actionButton("Stage next build", true, "ota-stage-" + lane.id);
  const publish = actionButton("Publish staged", false, "ota-publish-" + lane.id);
  publish.disabled = true;
  actions.append(stage, publish);
  const log = document.createElement("section");
  log.className = "result";
  log.id = "ota-log-" + lane.id;
  card.append(title, rows, actions, log);

  let stagedVersion = "";
  stage.addEventListener("click", () => {
    void stageLane(lane, log);
  });
  publish.addEventListener("click", () => {
    void publishLane(lane, stagedVersion, log);
  });
  return {
    card,
    values,
    publish,
    setSummary(summary) {
      const active = summary && summary.active_version ? summary.active_version : "unknown";
      const staged = summary && summary.built_not_published ? summary.built_not_published : "";
      const size = summary && summary.built_not_published ? sizeText(summary.size) : "unknown";
      values.get("active").textContent = active;
      values.get("published").textContent = dateText(summary && summary.published_at);
      values.get("staged").textContent = staged === "" ? "none" : staged;
      values.get("staged_at").textContent = staged === "" ? "unknown" : dateText(summary.built_at);
      values.get("size").textContent = size;
      stagedVersion = staged;
      publish.disabled = staged === "";
    },
  };
}

async function load(views, status, button) {
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
  for (const lane of lanes) {
    const summary = summaries.find((candidate) => candidate.lane === lane.id);
    views.get(lane.id).setSummary(summary);
  }
}

async function stageLane(lane, log) {
  const confirmed = await confirmAction({
    title: "Stage " + lane.title,
    confirmLabel: "Stage build",
    summary: "Build and register the lane's next version. It stays BUILT until you publish it; clients are not affected.",
  });
  if (confirmed === null) {
    return;
  }
  log.replaceChildren();
  log.append(paragraph("status", "Building…"));
  const reply = await request(buildPath, {
    method: "POST",
    body: { lane: lane.id, reason: confirmed.reason, semantic_key: confirmed.semantic_key },
  });
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
  const version = builtVersion(record);
  log.append(paragraph("hint", version === "" ? "The backend finished the build." : "The backend registered version " + version + "."));
  log.append(logBox(record));
}

function builtVersion(operation) {
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

async function publishLane(lane, version, log) {
  if (version === "") {
    log.replaceChildren();
    log.append(paragraph("status", "There is no staged build to publish."));
    return;
  }
  const confirmed = await confirmAction({
    title: "Publish " + lane.title + " " + version,
    confirmLabel: "Publish",
    summary: "Publishing takes the maintenance window and logs out every player. Continue?",
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
  row.className = "row g-2";
  const column = document.createElement("div");
  column.className = "col-md-4";
  const input = document.createElement("input");
  input.type = "text";
  input.className = "form-control";
  input.id = "ota-release-version";
  input.placeholder = "1.631.2";
  column.append(input);
  const button = actionButton("Check", true, "ota-release-check");
  row.append(column, button);
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

function dateText(value) {
  if (typeof value !== "string" || value === "" || value.startsWith("0001-01-01")) {
    return "unknown";
  }
  return value;
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
