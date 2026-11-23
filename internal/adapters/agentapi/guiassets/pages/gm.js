"use strict";

import { confirmAction } from "../components/confirm_action.js";
import { pageHeader, setStatus } from "../components/format.js";
import { describeReply, request } from "../transport.js";

const answerFieldPattern = /answer|reply|response|message|text|content|body/i;
const catcherModeFieldPattern = /mode/i;
const catcherAllowListFieldPattern = /allow|list|uid|player/i;

// renderPage is the GM screen: the question inbox from gm.list, the answer to
// one selected message and the catcher-mode switch. The route and the payload
// field names come from the module list, because the GM owner is declared but
// its payload shape is not fixed in this tree (UNKNOWN stays UNKNOWN). A module
// the registry marks planned is not called (fail closed).
export function renderPage(container, context) {
  container.replaceChildren();
  container.append(pageHeader(context.page.label));
  const gmModule = findModule(context.modules, "gm");
  const inbox = buildInbox();
  const overview = buildOverview(gmModule);
  const answer = buildAnswer(gmModule, inbox);
  const catcher = buildCatcher(gmModule);
  container.append(overview.card, inbox.card, answer.card, catcher.card);

  async function loadInbox() {
    inbox.status.textContent = "";
    if (gmModule !== null && gmModule.planned) {
      inbox.entries = [];
      inbox.selectedIndex = -1;
      fillInbox(inbox, []);
      overview.count.textContent = "unknown";
      inbox.status.textContent = "The GM module is planned, not callable yet: " + gmModule.planned;
      return;
    }
    const read = gmModule ? findRead(gmModule, "gm.list") : null;
    const command = gmModule ? findCommand(gmModule, "gm.list") : null;
    let reply;
    if (read !== null) {
      reply = await request("/agent/v1/reads/gm.list");
    } else if (command !== null) {
      reply = await request("/agent/v1/commands/gm.list", {
        method: "POST",
        body: { reason: "open the GM inbox", semantic_key: newSemanticKey(), payload: {} },
      });
    } else {
      inbox.entries = [];
      inbox.selectedIndex = -1;
      fillInbox(inbox, []);
      overview.count.textContent = "unknown";
      inbox.status.textContent = "The agent's module list declares neither a gm.list read nor a gm.list command.";
      return;
    }
    if (reply.unauthorized) {
      return;
    }
    if (!reply.ok) {
      inbox.entries = [];
      inbox.selectedIndex = -1;
      fillInbox(inbox, []);
      overview.count.textContent = "unknown";
      setStatus(inbox.status, describeReply(reply), "error");
      return;
    }
    const body = reply.body && typeof reply.body === "object" ? reply.body : {};
    inbox.entries = extractEntries(body);
    inbox.selectedIndex = -1;
    clearSelection(inbox, answer);
    fillInbox(inbox, inbox.entries);
    overview.count.textContent = String(inbox.entries.length);
    if (typeof body.catcher_mode === "string" && body.catcher_mode !== "") {
      overview.catcher.textContent = body.catcher_mode;
    }
    inbox.status.textContent = "Loaded " + inbox.entries.length + " message" + (inbox.entries.length === 1 ? "." : "s.");
    inbox.status.classList.remove("text-danger");
  }

  inbox.refresh.addEventListener("click", () => {
    void loadInbox();
  });

  inbox.table.addEventListener("change", (event) => {
    const target = event.target;
    if (!(target instanceof HTMLInputElement) || target.name !== "gm-message") {
      return;
    }
    inbox.selectedIndex = Number(target.value);
    fillSelection(inbox, answer);
  });

  answer.button.addEventListener("click", async () => {
    const entry = selectedEntry(inbox);
    if (entry === null) {
      setStatus(answer.status, "Select a message first.", "error");
      return;
    }
    const text = answer.text.value.trim();
    if (text === "") {
      setStatus(answer.status, "Type an answer first.", "error");
      return;
    }
    const confirmation = await confirmAction({
      title: "Answer GM message",
      summary: "Send this answer to the player. It is stored as a GM answer row and served in the in-game GM chat (MID 4).",
      confirmLabel: "Send answer",
    });
    if (confirmation === null) {
      return;
    }
    const payload = buildAnswerPayload(answer.command, entry, text);
    const reply = await request("/agent/v1/commands/gm.answer", {
      method: "POST",
      body: { reason: confirmation.reason, semantic_key: confirmation.semantic_key, payload },
    });
    showReply(answer, reply, confirmation);
  });

  catcher.button.addEventListener("click", async () => {
    const confirmation = await confirmAction({
      title: "Catcher mode",
      summary:
        "Change how the /get catcher answers players. Off sends the automatic \"Functionality turned off!\" reply; " +
        "allow-list answers only the listed uids; everyone answers every player.",
      confirmLabel: "Apply mode",
    });
    if (confirmation === null) {
      return;
    }
    const payload = buildCatcherPayload(catcher, catcher.mode.value, catcher.allowList.value);
    const reply = await request("/agent/v1/commands/gm.catcher_mode", {
      method: "POST",
      body: { reason: confirmation.reason, semantic_key: confirmation.semantic_key, payload },
    });
    showReply(catcher, reply, confirmation);
  });

  catcher.mode.addEventListener("change", () => {
    catcher.allowList.disabled = catcher.mode.value !== "allow-list";
  });
  catcher.allowList.disabled = true;

  void loadInbox();
}

function findModule(modules, id) {
  if (!Array.isArray(modules)) {
    return null;
  }
  return modules.find((module) => module && module.id === id) || null;
}

function findRead(module, name) {
  if (module === null || !Array.isArray(module.reads)) {
    return null;
  }
  return module.reads.find((read) => read && read.name === name) || null;
}

function findCommand(module, name) {
  if (module === null || !Array.isArray(module.commands)) {
    return null;
  }
  return module.commands.find((command) => command && command.name === name) || null;
}

function declaredFields(command) {
  return command !== null && Array.isArray(command.fields) ? command.fields : [];
}

function fieldMatching(fields, pattern) {
  return fields.find((field) => field && typeof field.name === "string" && pattern.test(field.name)) || null;
}

function buildOverview(gmModule) {
  const card = document.createElement("div");
  card.className = "card card-body";
  const heading = document.createElement("h2");
  heading.className = "card-title";
  heading.textContent = "GM questions";
  const hint = document.createElement("p");
  hint.className = "hint";
  hint.textContent = "Player questions from the in-game GM window, answered here and served in MID 4.";
  const rows = document.createElement("dl");
  rows.className = "row";
  const state = overviewRow(rows, "Module", "gm-module-state");
  if (gmModule === null) {
    state.textContent = "absent from the module list";
  } else if (gmModule.planned) {
    state.textContent = "planned: " + gmModule.planned;
  } else {
    state.textContent = "registered";
  }
  const count = overviewRow(rows, "Open questions", "gm-open-count");
  const catcher = overviewRow(rows, "Catcher mode", "gm-catcher-state");
  const status = document.createElement("p");
  status.className = "status";
  status.id = "gm-status";
  status.setAttribute("role", "status");
  card.append(heading, hint, rows, status);
  return { card, count, catcher, status };
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

function buildInbox() {
  const card = document.createElement("div");
  card.className = "card card-body";
  const heading = document.createElement("h2");
  heading.className = "card-title";
  heading.textContent = "Inbox";
  const controls = document.createElement("div");
  controls.className = "btn-list mb-2";
  const refresh = document.createElement("button");
  refresh.type = "button";
  refresh.className = "btn btn-outline-secondary btn-sm";
  refresh.id = "gm-refresh";
  refresh.textContent = "Refresh inbox";
  controls.append(refresh);
  const table = document.createElement("table");
  table.className = "table table-sm table-vcenter card-table mb-0";
  table.id = "gm-inbox";
  const status = document.createElement("p");
  status.className = "status";
  status.id = "gm-inbox-status";
  status.setAttribute("role", "status");
  const tableWrap = document.createElement("div");
  tableWrap.className = "table-responsive";
  tableWrap.append(table);
  card.append(heading, controls, tableWrap, status);
  return { card, table, status, refresh, entries: [], selectedIndex: -1 };
}

function extractEntries(body) {
  if (Array.isArray(body)) {
    return body.filter((entry) => entry !== null && typeof entry === "object");
  }
  const arrays = Object.values(body).filter(
    (value) => Array.isArray(value) && value.length > 0 && value[0] !== null && typeof value[0] === "object" && !Array.isArray(value[0]),
  );
  if (arrays.length === 1) {
    return arrays[0];
  }
  const scalars = Object.values(body).filter((value) => value === null || typeof value !== "object");
  if (arrays.length === 0 && scalars.length > 0) {
    return [body];
  }
  return [];
}

function fillInbox(inbox, entries) {
  inbox.table.replaceChildren();
  inbox.table.append(tableHead(["Select", "Message"]));
  const body = document.createElement("tbody");
  if (entries.length === 0) {
    const row = document.createElement("tr");
    const cell = document.createElement("td");
    cell.colSpan = 2;
    cell.textContent = "The inbox is empty.";
    row.append(cell);
    body.append(row);
    inbox.table.append(body);
    return;
  }
  entries.forEach((entry, index) => {
    const row = document.createElement("tr");
    const selectCell = document.createElement("td");
    const radio = document.createElement("input");
    radio.type = "radio";
    radio.name = "gm-message";
    radio.className = "form-check-input";
    radio.value = String(index);
    radio.id = "gm-message-" + index;
    selectCell.append(radio);
    const textCell = document.createElement("td");
    const fields = document.createElement("dl");
    fields.className = "row mb-0";
    for (const key of Object.keys(entry)) {
      const term = document.createElement("dt");
      term.className = "col-sm-3";
      term.textContent = key;
      const value = document.createElement("dd");
      value.className = "col-sm-9";
      value.textContent = displayValue(entry[key]);
      fields.append(term, value);
    }
    textCell.append(fields);
    row.append(selectCell, textCell);
    body.append(row);
  });
  inbox.table.append(body);
}

function clearSelection(inbox, answer) {
  answer.selected.textContent = "No message selected.";
  refreshAnswerButton(inbox, answer);
}

function fillSelection(inbox, answer) {
  const entry = selectedEntry(inbox);
  answer.selected.textContent = entry === null ? "No message selected." : "Selected message row " + (inbox.selectedIndex + 1) + ".";
  refreshAnswerButton(inbox, answer);
}

function selectedEntry(inbox) {
  if (inbox.selectedIndex < 0 || inbox.selectedIndex >= inbox.entries.length) {
    return null;
  }
  return inbox.entries[inbox.selectedIndex];
}

function buildAnswer(gmModule, inbox) {
  const card = document.createElement("div");
  card.className = "card card-body";
  const heading = document.createElement("h2");
  heading.className = "card-title";
  heading.textContent = "Answer a message";
  const selected = document.createElement("p");
  selected.className = "hint";
  selected.id = "gm-selected";
  selected.textContent = "No message selected.";
  const label = document.createElement("label");
  label.className = "form-label";
  label.htmlFor = "gm-answer-text";
  label.textContent = "Answer";
  const text = document.createElement("textarea");
  text.className = "form-control";
  text.id = "gm-answer-text";
  const hint = document.createElement("p");
  hint.className = "hint";
  hint.id = "gm-answer-hint";
  const button = document.createElement("button");
  button.type = "button";
  button.className = "btn btn-primary";
  button.id = "gm-answer";
  button.textContent = "Answer selected message";
  const status = document.createElement("p");
  status.className = "status mt-2";
  status.setAttribute("role", "status");
  const result = document.createElement("pre");
  result.className = "component-output";
  card.append(heading, selected, label, text, hint, button, status, result);

  const command = gmModule ? findCommand(gmModule, "gm.answer") : null;
  const fields = declaredFields(command);
  const answerField = fieldMatching(fields, answerFieldPattern);
  const planned = gmModule !== null && Boolean(gmModule.planned);
  if (planned) {
    hint.textContent = "The GM module is planned, not callable yet: " + gmModule.planned;
  } else if (command === null) {
    hint.textContent = "gm.answer is not declared by this agent's module list.";
  } else if (fields.length === 0) {
    hint.textContent = "gm.answer declares no payload fields in this build, so the answer shape is UNKNOWN and cannot be sent from this page.";
  } else if (answerField === null) {
    hint.textContent = "gm.answer declares no answer field in this build, so the typed answer has no payload field.";
  } else {
    hint.textContent = "The typed answer fills the declared field '" + answerField.name + "'; matching fields of the selected message are sent with it.";
  }
  const answer = { card, selected, text, hint, button, status, result, command, answerField, planned };
  button.disabled = planned || command === null || answerField === null;
  text.addEventListener("input", () => refreshAnswerButton(inbox, answer));
  return answer;
}

function refreshAnswerButton(inbox, answer) {
  const ready =
    !answer.planned &&
    answer.command !== null &&
    answer.answerField !== null &&
    selectedEntry(inbox) !== null &&
    answer.text.value.trim() !== "";
  answer.button.disabled = !ready;
}

function buildAnswerPayload(command, entry, answer) {
  const payload = {};
  for (const field of declaredFields(command)) {
    if (field === null || typeof field.name !== "string") {
      continue;
    }
    if (Object.prototype.hasOwnProperty.call(entry, field.name)) {
      payload[field.name] = entry[field.name];
    }
  }
  const answerField = fieldMatching(declaredFields(command), answerFieldPattern);
  if (answerField !== null) {
    payload[answerField.name] = answer;
  }
  return payload;
}

function buildCatcher(gmModule) {
  const card = document.createElement("div");
  card.className = "card card-body";
  const heading = document.createElement("h2");
  heading.className = "card-title";
  heading.textContent = "Command catcher";
  const hint = document.createElement("p");
  hint.className = "hint";
  hint.id = "gm-catcher-hint";
  const label = document.createElement("label");
  label.className = "form-label";
  label.htmlFor = "gm-catcher-mode";
  label.textContent = "Mode";
  const mode = document.createElement("select");
  mode.className = "form-select";
  mode.id = "gm-catcher-mode";
  for (const value of ["off", "allow-list", "everyone"]) {
    const option = document.createElement("option");
    option.value = value;
    option.textContent = value;
    mode.append(option);
  }
  const listLabel = document.createElement("label");
  listLabel.className = "form-label";
  listLabel.htmlFor = "gm-catcher-list";
  listLabel.textContent = "Allow-list (uids, one per line)";
  const allowList = document.createElement("textarea");
  allowList.className = "form-control";
  allowList.id = "gm-catcher-list";
  const button = document.createElement("button");
  button.type = "button";
  button.className = "btn btn-primary";
  button.id = "gm-catcher-apply";
  button.textContent = "Apply catcher mode";
  const status = document.createElement("p");
  status.className = "status mt-2";
  status.setAttribute("role", "status");
  const result = document.createElement("pre");
  result.className = "component-output";
  card.append(heading, hint, label, mode, listLabel, allowList, button, status, result);

  const command = gmModule ? findCommand(gmModule, "gm.catcher_mode") : null;
  const fields = declaredFields(command);
  const modeField = fieldMatching(fields, catcherModeFieldPattern);
  const allowField = fieldMatching(fields, catcherAllowListFieldPattern);
  const planned = gmModule !== null && Boolean(gmModule.planned);
  if (planned) {
    hint.textContent = "The GM module is planned, not callable yet: " + gmModule.planned;
  } else if (command === null) {
    hint.textContent = "gm.catcher_mode is not declared by this agent's module list.";
  } else if (fields.length === 0) {
    hint.textContent = "gm.catcher_mode declares no payload fields in this build, so the mode shape is UNKNOWN and cannot be sent from this page.";
  } else if (modeField === null) {
    hint.textContent = "gm.catcher_mode declares no mode field in this build, so the selected mode has no payload field.";
  } else {
    hint.textContent = "The selected mode fills the declared field '" + modeField.name + "'" + (allowField === null ? "." : "; the allow-list fills '" + allowField.name + "' in allow-list mode.");
  }
  button.disabled = planned || command === null || modeField === null;
  return { card, mode, allowList, button, status, result, command, modeField, allowField };
}

function buildCatcherPayload(catcher, mode, allowListText) {
  const payload = {};
  if (catcher.modeField !== null) {
    payload[catcher.modeField.name] = mode;
  }
  if (catcher.allowField !== null && mode === "allow-list") {
    const tokens = allowListText.split(/[\s,]+/).filter((token) => token !== "");
    payload[catcher.allowField.name] = catcher.allowField.type === "array" ? tokens : tokens.join(",");
  }
  return payload;
}

function showReply(box, reply, confirmation) {
  box.status.textContent = "";
  box.result.textContent = "";
  if (reply.unauthorized) {
    return;
  }
  if (!reply.ok) {
    setStatus(box.status, describeReply(reply), "error");
    return;
  }
  const lines = ["HTTP " + reply.status, "reason: " + confirmation.reason, "semantic_key: " + confirmation.semantic_key];
  const body = reply.body && typeof reply.body === "object" ? reply.body : {};
  for (const key of Object.keys(body)) {
    lines.push(key + ": " + displayValue(body[key]));
  }
  box.result.textContent = lines.join("\n");
}

function tableHead(labels) {
  const head = document.createElement("thead");
  const row = document.createElement("tr");
  for (const label of labels) {
    const cell = document.createElement("th");
    cell.textContent = label;
    row.append(cell);
  }
  head.append(row);
  return head;
}

function displayValue(value) {
  if (value === null || value === undefined) {
    return "unknown";
  }
  if (typeof value === "object") {
    return JSON.stringify(value);
  }
  return String(value);
}

function newSemanticKey() {
  if (window.crypto && typeof window.crypto.randomUUID === "function") {
    return window.crypto.randomUUID();
  }
  const bytes = new Uint8Array(16);
  window.crypto.getRandomValues(bytes);
  return Array.from(bytes, (value) => value.toString(16).padStart(2, "0")).join("");
}
