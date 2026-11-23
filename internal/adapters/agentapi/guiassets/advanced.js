"use strict";

import { request } from "./transport.js";
import { pictureElement } from "./pictures.js";

const operationPollMilliseconds = 1000;

// renderAdvanced is the full generic renderer: one tab per registered module,
// every declared command and read for the selected module (behaviour moved
// unchanged from the single-file GUI).
export function renderAdvanced(container, modules) {
  container.replaceChildren();
  if (modules.length === 0) {
    container.append(paragraph("module-help", "This agent reported no modules."));
    return;
  }
  const tabsView = document.createElement("nav");
  tabsView.className = "nav nav-tabs mb-3";
  tabsView.setAttribute("aria-label", "Modules");
  const moduleView = document.createElement("div");
  moduleView.className = "module";
  let activeModuleID = modules[0].id;

  function renderTabs() {
    tabsView.replaceChildren();
    for (const module of modules) {
      const button = document.createElement("button");
      button.type = "button";
      button.className = "nav-link";
      button.textContent = (module.screen && module.screen.tab) || module.title || module.id;
      if (module.planned) {
        button.title = "Planned: " + module.planned;
      }
      if (module.id === activeModuleID) {
        button.classList.add("active");
      }
      button.addEventListener("click", () => {
        activeModuleID = module.id;
        renderTabs();
        renderActiveModule();
      });
      tabsView.append(button);
    }
  }

  function renderActiveModule() {
    const module = modules.find((candidate) => candidate.id === activeModuleID) || modules[0];
    renderModuleForms(moduleView, module);
  }

  renderTabs();
  renderActiveModule();
  container.append(tabsView, moduleView);
}

// renderModuleForms puts one module's heading and generic forms into container.
function renderModuleForms(container, module) {
  container.replaceChildren();
  const heading = document.createElement("h3");
  heading.className = "module-title";
  heading.textContent = module.title || module.id;
  container.append(heading);
  if (module.planned) {
    container.append(paragraph("module-help", "Planned, not callable yet: " + module.planned));
    return;
  }
  const commands = Array.isArray(module.commands) ? module.commands : [];
  const reads = Array.isArray(module.reads) ? module.reads : [];
  if (commands.length === 0 && reads.length === 0) {
    container.append(paragraph("module-help", "This module declares no commands or reads."));
  }
  for (const command of commands) {
    container.append(renderCommand(command));
  }
  for (const read of reads) {
    container.append(renderRead(read));
  }
}

function renderCommand(command) {
  const card = section("card");
  const heading = document.createElement("h3");
  heading.textContent = command.name;
  const badge = document.createElement("span");
  badge.className = "command-class " + (command.class === "maintenance" ? "maintenance" : "live");
  badge.textContent = command.class === "maintenance" ? "maintenance" : "live";
  heading.append(badge);
  card.append(heading);
  if (command.help) {
    card.append(paragraph("module-help", command.help));
  }
  const controls = [];
  for (const field of command.fields || []) {
    const control = createFieldControl(field);
    controls.push(control);
    card.append(control.row);
  }
  const reasonInput = createReasonInput(card);
  const button = document.createElement("button");
  button.type = "button";
  button.className = "btn btn-primary";
  button.textContent = "Run " + command.name;
  card.append(button);
  const output = section("result");
  card.append(output);
  button.addEventListener("click", () => runCommand(command, controls, reasonInput, output, button));
  return card;
}

function renderRead(read) {
  const card = section("card");
  const heading = document.createElement("h3");
  heading.textContent = read.name;
  card.append(heading);
  if (read.help) {
    card.append(paragraph("module-help", read.help));
  }
  const controls = [];
  for (const field of read.fields || []) {
    const control = createFieldControl(field);
    controls.push(control);
    card.append(control.row);
  }
  const button = document.createElement("button");
  button.type = "button";
  button.className = "btn btn-primary";
  button.textContent = "Run " + read.name;
  card.append(button);
  const output = section("result");
  card.append(output);
  button.addEventListener("click", () => runRead(read, controls, output, button));
  return card;
}

function createReasonInput(card) {
  const row = document.createElement("div");
  row.className = "field";
  const label = document.createElement("label");
  label.textContent = "Reason (required)";
  const input = document.createElement("input");
  input.type = "text";
  input.placeholder = "why this command runs";
  const identifier = "reason-" + String(Math.random()).slice(2);
  input.id = identifier;
  label.htmlFor = identifier;
  row.append(label, input);
  card.append(row);
  return input;
}

function createFieldControl(field) {
  const row = document.createElement("div");
  row.className = "field";
  const label = document.createElement("label");
  label.textContent = field.name + (field.required ? " (required)" : "");
  row.append(label);

  let control;
  let readValue;
  if (field.type === "bool") {
    control = document.createElement("input");
    control.type = "checkbox";
    control.checked = field.default === true;
    readValue = () => ({ present: true, value: control.checked });
  } else if (Array.isArray(field.enum) && field.enum.length > 0) {
    control = document.createElement("select");
    const blank = document.createElement("option");
    blank.value = "";
    blank.textContent = field.required ? "choose one" : "any";
    control.append(blank);
    for (const value of field.enum) {
      const option = document.createElement("option");
      option.value = String(value);
      option.textContent = String(value);
      control.append(option);
    }
    control.value = field.default === undefined || field.default === null ? "" : String(field.default);
    readValue = () => textValue(control.value, field);
  } else if (field.type === "int") {
    control = document.createElement("input");
    control.type = "number";
    control.step = "1";
    if (field.minimum !== undefined && field.minimum !== null) {
      control.min = String(field.minimum);
    }
    if (field.maximum !== undefined && field.maximum !== null) {
      control.max = String(field.maximum);
    }
    if (field.default !== undefined && field.default !== null) {
      control.value = String(field.default);
    }
    readValue = () => integerValue(control.value, field);
  } else if (field.type === "object" || field.type === "array") {
    control = document.createElement("textarea");
    control.placeholder = field.type === "array" ? "[...]" : "{...}";
    if (field.default !== undefined && field.default !== null) {
      control.value = JSON.stringify(field.default, null, 2);
    }
    readValue = () => jsonValue(control.value, field);
  } else {
    control = document.createElement("input");
    control.type = "text";
    if (field.type === "duration") {
      control.placeholder = "e.g. 3d, 36h, permanent";
    }
    if (field.type === "uuid") {
      control.placeholder = "uuid";
    }
    if (field.default !== undefined && field.default !== null) {
      control.value = String(field.default);
    }
    readValue = () => textValue(control.value, field);
  }
  control.id = "field-" + field.name;
  label.htmlFor = control.id;
  row.append(control);
  if (field.help) {
    row.append(paragraph("help", field.help));
  }
  return { row, readValue, field };
}

function textValue(raw, field) {
  const value = raw.trim();
  if (value === "") {
    return field.required ? { present: false, error: field.name + " is required" } : { present: false };
  }
  return { present: true, value };
}

function integerValue(raw, field) {
  const text = raw.trim();
  if (text === "") {
    return field.required ? { present: false, error: field.name + " is required" } : { present: false };
  }
  const value = Number(text);
  if (!Number.isInteger(value)) {
    return { present: false, error: field.name + " must be an integer" };
  }
  if (field.minimum !== undefined && field.minimum !== null && value < field.minimum) {
    return { present: false, error: field.name + " must be at least " + field.minimum };
  }
  if (field.maximum !== undefined && field.maximum !== null && value > field.maximum) {
    return { present: false, error: field.name + " must be at most " + field.maximum };
  }
  return { present: true, value };
}

function jsonValue(raw, field) {
  const text = raw.trim();
  if (text === "") {
    return field.required ? { present: false, error: field.name + " is required" } : { present: false };
  }
  let value;
  try {
    value = JSON.parse(text);
  } catch (error) {
    return { present: false, error: field.name + " is not valid JSON" };
  }
  if (field.type === "array" && !Array.isArray(value)) {
    return { present: false, error: field.name + " must be a JSON array" };
  }
  if (field.type === "object" && (value === null || Array.isArray(value) || typeof value !== "object")) {
    return { present: false, error: field.name + " must be a JSON object" };
  }
  return { present: true, value };
}

function collectValues(controls) {
  const payload = {};
  const errors = [];
  for (const control of controls) {
    const result = control.readValue();
    if (result.error) {
      errors.push(result.error);
    } else if (result.present) {
      payload[control.field.name] = result.value;
    }
  }
  return { payload, errors };
}

async function runCommand(command, controls, reasonInput, output, button) {
  output.replaceChildren();
  const { payload, errors } = collectValues(controls);
  const reason = reasonInput.value.trim();
  if (reason === "") {
    errors.push("A reason is required.");
  }
  if (errors.length > 0) {
    output.append(paragraph("status", errors.join("\n")));
    return;
  }
  const maintenanceClass = command.class === "maintenance";
  if (maintenanceClass && !window.confirm("This is a maintenance command and may restart clients. Run " + command.name + "?")) {
    return;
  }
  const semanticKey = newSemanticKey();
  button.disabled = true;
  let reply;
  if ((command.route || "backend") === "agent") {
    reply = await runAgentRoute(command.name, payload, reason, semanticKey);
  } else {
    reply = await request("/agent/v1/commands/" + encodeURIComponent(command.name), {
      method: "POST",
      body: { reason, semantic_key: semanticKey, payload },
    });
  }
  button.disabled = false;
  showReply(output, reply, semanticKey);
  const operationID = reply.body && typeof reply.body === "object" ? reply.body.operation_id : "";
  if (operationID) {
    await pollOperation(operationID, output);
  }
}

async function runRead(read, controls, output, button) {
  output.replaceChildren();
  const { payload, errors } = collectValues(controls);
  if (errors.length > 0) {
    output.append(paragraph("status", errors.join("\n")));
    return;
  }
  const query = new URLSearchParams();
  for (const [key, value] of Object.entries(payload)) {
    query.append(key, String(value));
  }
  const suffix = query.toString();
  button.disabled = true;
  const reply = await request("/agent/v1/reads/" + encodeURIComponent(read.name) + (suffix === "" ? "" : "?" + suffix));
  button.disabled = false;
  showReply(output, reply);
}

function runAgentRoute(name, payload, reason, semanticKey) {
  switch (name) {
    case "server.start":
      return request("/agent/v1/backend/start", { method: "POST", body: { closed: Boolean(payload.closed) } });
    case "server.stop":
      return request("/agent/v1/backend/stop", { method: "POST", body: {} });
    case "server.status":
      return request("/agent/v1/backend/status");
    case "ota.build":
      return request("/agent/v1/ota/build", {
        method: "POST",
        body: {
          lane: payload.lane,
          version: payload.version,
          rollback: Boolean(payload.rollback),
          lazy_refresh: Boolean(payload.lazy_refresh),
        },
      });
    case "ota.publish":
      return request("/agent/v1/ota/publish", {
        method: "POST",
        body: { version: payload.version, reason, semantic_key: semanticKey },
      });
    case "ota.withdraw":
      return request("/agent/v1/ota/withdraw", {
        method: "POST",
        body: { version: payload.version, reason, semantic_key: semanticKey },
      });
    case "backup.snapshot":
      return request("/agent/v1/backup/snapshot", {
        method: "POST",
        body: { kind: payload.kind, reason },
      });
    case "backup.list":
      return request("/agent/v1/backup/list");
    case "backup.prune":
      return request("/agent/v1/backup/prune", { method: "POST", body: { reason } });
    case "backup.restore":
      return request("/agent/v1/backup/restore", { method: "POST", body: { id: payload.id, reason } });
    case "backup.update_backend":
      return request("/agent/v1/backup/update-backend", { method: "POST", body: { reason } });
    default:
      return request("/agent/v1/commands/" + encodeURIComponent(name), {
        method: "POST",
        body: { reason, semantic_key: semanticKey, payload },
      });
  }
}

function showReply(output, reply, semanticKey) {
  output.replaceChildren();
  if (reply.unauthorized) {
    return;
  }
  const meta = paragraph("hint", "HTTP " + reply.status + (semanticKey ? " | semantic_key " + semanticKey : ""));
  output.append(meta);
  const raw = document.createElement("pre");
  raw.textContent = JSON.stringify(reply.body, null, 2);
  output.append(raw);
  const rows = findRows(reply.body);
  if (rows !== null) {
    output.append(buildTable(rows));
  }
}

async function pollOperation(operationID, output) {
  for (;;) {
    await delay(operationPollMilliseconds);
    const reply = await request("/agent/v1/ops/" + encodeURIComponent(operationID));
    if (reply.unauthorized) {
      return;
    }
    showReply(output, reply);
    const operationState = reply.body && typeof reply.body === "object" ? reply.body.state : "";
    if (operationState === "DONE" || operationState === "FAILED" || !reply.ok) {
      return;
    }
  }
}

function findRows(body) {
  if (Array.isArray(body)) {
    return body.length > 0 && isPlainObject(body[0]) ? body : null;
  }
  if (!isPlainObject(body)) {
    return null;
  }
  const arrays = Object.values(body).filter((value) => Array.isArray(value) && value.length > 0 && isPlainObject(value[0]));
  return arrays.length === 1 ? arrays[0] : null;
}

function buildTable(rows) {
  const table = document.createElement("table");
  const columns = [];
  for (const row of rows) {
    for (const key of Object.keys(row)) {
      if (!columns.includes(key)) {
        columns.push(key);
      }
    }
  }
  const head = document.createElement("thead");
  const headRow = document.createElement("tr");
  for (const column of columns) {
    const cell = document.createElement("th");
    cell.textContent = column;
    headRow.append(cell);
  }
  head.append(headRow);
  const body = document.createElement("tbody");
  for (const row of rows) {
    const tableRow = document.createElement("tr");
    for (const column of columns) {
      const cell = document.createElement("td");
      const value = row[column];
      if (column === "icon" && typeof value === "string" && value !== "") {
        cell.append(pictureElement(value));
      } else if (value !== null && typeof value === "object") {
        cell.textContent = JSON.stringify(value);
      } else {
        cell.textContent = value === undefined || value === null ? "" : String(value);
      }
      tableRow.append(cell);
    }
    body.append(tableRow);
  }
  table.append(head, body);
  return table;
}

function newSemanticKey() {
  if (window.crypto && typeof window.crypto.randomUUID === "function") {
    return window.crypto.randomUUID().replaceAll("-", "");
  }
  const bytes = new Uint8Array(16);
  window.crypto.getRandomValues(bytes);
  return Array.from(bytes, (value) => value.toString(16).padStart(2, "0")).join("");
}

function delay(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}

function isPlainObject(value) {
  return value !== null && typeof value === "object" && !Array.isArray(value);
}

function paragraph(className, text) {
  const element = document.createElement("p");
  element.className = className;
  element.textContent = text;
  return element;
}

function section(className) {
  const element = document.createElement("section");
  element.className = className;
  return element;
}
