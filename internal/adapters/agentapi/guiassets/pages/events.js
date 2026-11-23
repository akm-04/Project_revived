"use strict";

import { describeReply, request } from "../transport.js";
import { confirmAction } from "../components/confirm_action.js";
import { openDurationPicker } from "../components/duration_picker.js";
import { formatTime, formatTimeText, pageHeader, setStatus } from "../components/format.js";
import { loadServers, mountServerPicker } from "../components/server_picker.js";
import { pictureElement } from "../pictures.js";

const readEventsList = "events.list";
const commandDefinitionList = "events.definition.list";
const commandSchedule = "events.schedule";
const commandExtend = "events.extend";
const commandEndNow = "events.end_now";
const commandSetPermanent = "events.set_permanent";
const eventsListLimit = 200;

// Events (G5): the running and scheduled occurrences of one logical server
// (events.list requires `server`; internal/application/events/module.go:48-55),
// the occurrences' lifecycle actions, and the schedule action.
export function renderPage(container, context) {
  container.replaceChildren();
  container.append(pageHeader(context.page.label));
  container.setAttribute("aria-label", context.page.label);

  const state = {
    serverID: null,
    occurrences: [],
    definitions: [],
    names: new Map(),
    scheduleDuration: null,
  };

  const overview = createCard("Events overview", "events-overview");
  const serverPickerHost = document.createElement("div");
  serverPickerHost.id = "events-server-picker";
  const refreshButton = actionButton("Refresh events", false, "events-refresh");
  const overviewStatus = errorParagraph();
  overviewStatus.id = "events-status";
  const tableHost = document.createElement("div");
  tableHost.className = "table-responsive";
  tableHost.id = "events-table-host";
  overview.body.append(serverPickerHost, refreshButton, overviewStatus, tableHost);

  const scheduleCard = createCard("Schedule an event", "events-schedule-card");
  const definitionsStatus = paragraph("hint", "Loading deployed event definitions…");
  definitionsStatus.id = "events-definitions-status";
  const definitionsHost = document.createElement("div");
  definitionsHost.id = "events-definitions";
  const pickScheduleDuration = actionButton("Choose duration", false, "events-schedule-duration");
  const scheduleDurationSummary = paragraph("hint", "No duration chosen.");
  scheduleDurationSummary.id = "events-schedule-duration-selected";
  const scheduleButton = actionButton("Schedule", true, "events-schedule");
  const scheduleResult = errorParagraph();
  scheduleResult.id = "events-schedule-result";
  scheduleCard.body.append(definitionsStatus, definitionsHost, pickScheduleDuration, scheduleDurationSummary, scheduleButton, scheduleResult);

  const actionCard = createCard("Change a running or scheduled event", "events-actions-card");
  const occurrenceSelect = createSelect(actionCard.body, "events-action-target", "Occurrence", []);
  const extendButton = actionButton("Extend", false, "events-extend");
  const endNowButton = actionButton("End now", false, "events-end-now");
  const permanentButton = actionButton("Make permanent", false, "events-permanent");
  const actionResult = errorParagraph();
  actionResult.id = "events-action-result";
  const actionRow = document.createElement("div");
  actionRow.className = "btn-list mb-3";
  actionRow.append(extendButton, endNowButton, permanentButton);
  actionCard.body.append(actionRow, actionResult);

  container.append(overview.card, scheduleCard.card, actionCard.card);

  refreshButton.addEventListener("click", refreshEvents);
  pickScheduleDuration.addEventListener("click", chooseScheduleDuration);
  scheduleButton.addEventListener("click", scheduleEvents);
  occurrenceSelect.addEventListener("change", updateActionAvailability);
  extendButton.addEventListener("click", extendOccurrence);
  endNowButton.addEventListener("click", endOccurrenceNow);
  permanentButton.addEventListener("click", makePermanent);

  start();

  async function start() {
    const loaded = await loadServers();
    if (loaded.error !== "") {
      setStatus(overviewStatus, loaded.error, "error");
    }
    if (loaded.servers.length > 0) {
      state.serverID = Number(loaded.servers[0].server_id);
    }
    mountServerPicker(serverPickerHost, {
      includeGlobal: false,
      multiple: false,
      selected: state.serverID === null ? [] : [state.serverID],
      idPrefix: "events-server",
      onChange: (value) => {
        state.serverID = value.server_ids.length === 1 ? value.server_ids[0] : null;
        void refreshEvents();
      },
    });
    await refreshEvents();
    await loadDefinitions();
  }

  async function refreshEvents() {
    overviewStatus.textContent = "";
    if (state.serverID === null) {
      overviewStatus.textContent = "No logical server is selected; events.list needs one.";
      state.occurrences = [];
      renderOccurrences();
      return;
    }
    overviewStatus.textContent = "Loading events…";
    const [running, scheduled] = await Promise.all([
      readOccurrences(state.serverID, "RUNNING"),
      readOccurrences(state.serverID, "SCHEDULED"),
    ]);
    if (running.error !== "" || scheduled.error !== "") {
      setStatus(overviewStatus, running.error !== "" ? running.error : scheduled.error, "error");
      state.occurrences = [];
      renderOccurrences();
      return;
    }
    state.occurrences = running.occurrences.concat(scheduled.occurrences);
    state.occurrences.sort((left, right) => String(left.starts_at).localeCompare(String(right.starts_at)));
    overviewStatus.textContent = state.occurrences.length === 0 ? "No running or scheduled events on this server." : "";
    renderOccurrences();
  }

  async function readOccurrences(serverID, phase) {
    const query = new URLSearchParams();
    query.set("server", String(serverID));
    query.set("state", phase);
    query.set("limit", String(eventsListLimit));
    const reply = await request("/agent/v1/reads/" + encodeURIComponent(readEventsList) + "?" + query.toString());
    if (reply.unauthorized) {
      return { occurrences: [], error: "" };
    }
    if (!reply.ok) {
      return { occurrences: [], error: describeReply(reply) };
    }
    const body = reply.body && typeof reply.body === "object" ? reply.body : {};
    return { occurrences: Array.isArray(body.occurrences) ? body.occurrences : [], error: "" };
  }

  function renderOccurrences() {
    tableHost.replaceChildren();
    occurrenceSelect.replaceChildren();
    const blank = document.createElement("option");
    blank.value = "";
    blank.textContent = state.occurrences.length === 0 ? "No occurrences" : "choose one";
    occurrenceSelect.append(blank);
    for (const occurrence of state.occurrences) {
      const option = document.createElement("option");
      option.value = String(occurrence.id);
      option.textContent = "#" + occurrence.id + " · " + activityLabel(occurrence.activity_id) + " · " + occurrence.state;
      occurrenceSelect.append(option);
    }
    if (state.occurrences.length === 0) {
      updateActionAvailability();
      return;
    }
    const table = document.createElement("table");
    table.className = "table table-sm table-vcenter card-table mb-0";
    const head = document.createElement("thead");
    const headRow = document.createElement("tr");
    for (const label of ["banner", "activity", "state", "starts", "ends", "claim until"]) {
      const cell = document.createElement("th");
      cell.textContent = label;
      headRow.append(cell);
    }
    head.append(headRow);
    const body = document.createElement("tbody");
    for (const occurrence of state.occurrences) {
      const row = document.createElement("tr");
      const banner = document.createElement("td");
      banner.append(pictureElement(activityBannerPath(occurrence.activity_id)));
      const activity = document.createElement("td");
      activity.textContent = activityLabel(occurrence.activity_id);
      const stateCell = document.createElement("td");
      stateCell.textContent = occurrence.state;
      row.append(
        banner,
        activity,
        stateCell,
        timeCell(occurrence.starts_at, "unknown"),
        timeCell(occurrence.ends_at, "permanent"),
        timeCell(occurrence.claim_until, "none"),
      );
      body.append(row);
    }
    table.append(head, body);
    tableHost.append(table);
    updateActionAvailability();
  }

  // events.definition.list carries the activity name (DefinitionSummary.Name,
  // internal/application/events/commands.go:173); events.list itself has only
  // the activity id, so the name shows when a deployed definition gives one.
  function activityLabel(activityID) {
    const identifier = String(activityID);
    const name = state.names.get(identifier);
    return name === undefined ? identifier : identifier + " · " + name;
  }

  async function loadDefinitions() {
    definitionsStatus.textContent = "Loading deployed event definitions…";
    definitionsHost.replaceChildren();
    const reply = await request("/agent/v1/commands/" + encodeURIComponent(commandDefinitionList), {
      method: "POST",
      body: {
        reason: "list deployed event definitions for the events page",
        semantic_key: newSemanticKey(),
        payload: { limit: eventsListLimit },
      },
    });
    if (reply.unauthorized) {
      return;
    }
    if (!reply.ok) {
      setStatus(definitionsStatus, describeReply(reply), "error");
      return;
    }
    const result = commandResult(reply);
    state.definitions = Array.isArray(result.definitions) ? result.definitions : [];
    state.names.clear();
    for (const definition of state.definitions) {
      if (typeof definition.name === "string" && definition.name !== "") {
        state.names.set(String(definition.activity_id), definition.name);
      }
    }
    if (state.definitions.length === 0) {
      definitionsStatus.textContent = "No event definitions are deployed; deploy one under Advanced.";
      renderOccurrences();
      return;
    }
    definitionsStatus.textContent = "Tick the events to schedule on the selected server.";
    for (const definition of state.definitions) {
      const row = document.createElement("label");
      row.className = "form-check";
      const box = document.createElement("input");
      box.type = "checkbox";
      box.className = "form-check-input";
      box.id = "event-definition-" + definition.activity_id;
      const text = document.createElement("span");
      text.className = "form-check-label";
      const name = typeof definition.name === "string" && definition.name !== "" ? definition.name + " · " : "";
      text.textContent = name + "activity " + definition.activity_id + " · " + (definition.archetype || "unknown") +
        " · readiness " + (definition.readiness || "unknown") +
        (Number.isInteger(definition.default_days) && definition.default_days > 0 ? " · default " + definition.default_days + "d" : "");
      row.append(box, text);
      definitionsHost.append(row);
    }
    renderOccurrences();
  }

  async function chooseScheduleDuration() {
    const duration = await openDurationPicker({ title: "Event duration" });
    if (duration === null) {
      return;
    }
    state.scheduleDuration = duration;
    scheduleDurationSummary.textContent = "From " + formatTimeText(duration.start) + " to " + formatTimeText(duration.end) + ".";
  }

  async function scheduleEvents() {
    scheduleResult.textContent = "";
    if (state.serverID === null) {
      setStatus(scheduleResult, "Select a server first.", "error");
      return;
    }
    if (state.scheduleDuration === null) {
      setStatus(scheduleResult, "Choose a duration first.", "error");
      return;
    }
    const duration = durationText(state.scheduleDuration);
    if (duration.error) {
      setStatus(scheduleResult, duration.error, "error");
      return;
    }
    const ticked = Array.from(definitionsHost.querySelectorAll("input[type=checkbox]:checked"));
    if (ticked.length === 0) {
      setStatus(scheduleResult, "Tick at least one event.", "error");
      return;
    }
    const activityIDs = ticked.map((box) => Number(box.id.slice("event-definition-".length)));
    const confirmation = await confirmAction({
      title: "Schedule events",
      summary: "Schedule activity " + activityIDs.join(", ") + " on server #" + state.serverID +
        " from " + formatTimeText(state.scheduleDuration.start) + " for " + duration.text + ".",
      confirmLabel: "Schedule",
    });
    if (confirmation === null) {
      return;
    }
    scheduleButton.disabled = true;
    const outcomes = [];
    let allApplied = true;
    for (let index = 0; index < activityIDs.length; index += 1) {
      const semanticKey = activityIDs.length === 1
        ? confirmation.semantic_key
        : confirmation.semantic_key + "-" + index;
      const reply = await request("/agent/v1/commands/" + encodeURIComponent(commandSchedule), {
        method: "POST",
        body: {
          reason: confirmation.reason,
          semantic_key: semanticKey,
          payload: {
            activity_id: activityIDs[index],
            logical_server_ids: [state.serverID],
            start: state.scheduleDuration.start,
            duration: duration.text,
          },
        },
      });
      if (reply.unauthorized) {
        scheduleButton.disabled = false;
        return;
      }
      if (!reply.ok) {
        allApplied = false;
      }
      outcomes.push("activity " + activityIDs[index] + ": " + describeOccurrenceReply(reply));
    }
    scheduleButton.disabled = false;
    setStatus(scheduleResult, outcomes.join("\n") + "\nreason: " + confirmation.reason, allApplied ? "success" : "error");
    if (allApplied) {
      await refreshEvents();
    }
  }

  function selectedOccurrence() {
    const identifier = occurrenceSelect.value;
    return state.occurrences.find((occurrence) => String(occurrence.id) === identifier) || null;
  }

  function updateActionAvailability() {
    const occurrence = selectedOccurrence();
    const timed = occurrence !== null && occurrence.ends_at !== null && occurrence.ends_at !== undefined;
    const editable = occurrence !== null && (occurrence.state === "SCHEDULED" || occurrence.state === "RUNNING");
    extendButton.disabled = !editable || !timed;
    permanentButton.disabled = !editable || !timed;
    endNowButton.disabled = occurrence === null || (occurrence.state !== "RUNNING" && occurrence.state !== "CLAIM_WINDOW");
  }

  async function extendOccurrence() {
    actionResult.textContent = "";
    const occurrence = selectedOccurrence();
    if (occurrence === null) {
      setStatus(actionResult, "Select an occurrence first.", "error");
      return;
    }
    const duration = await openDurationPicker({ title: "Extend by" });
    if (duration === null) {
      return;
    }
    const text = durationText(duration);
    if (text.error) {
      setStatus(actionResult, text.error, "error");
      return;
    }
    const confirmation = await confirmAction({
      title: "Extend occurrence",
      summary: "Extend occurrence #" + occurrence.id + " by " + text.text + ".",
      confirmLabel: "Extend",
    });
    if (confirmation === null) {
      return;
    }
    await runOccurrenceCommand(commandExtend, { occurrence_id: occurrence.id, duration: text.text }, occurrence, confirmation, "extend");
  }

  async function endOccurrenceNow() {
    actionResult.textContent = "";
    const occurrence = selectedOccurrence();
    if (occurrence === null) {
      setStatus(actionResult, "Select an occurrence first.", "error");
      return;
    }
    const confirmation = await confirmAction({
      title: "End occurrence now",
      summary: "End occurrence #" + occurrence.id + " now; its claim window still opens.",
      confirmLabel: "End now",
    });
    if (confirmation === null) {
      return;
    }
    await runOccurrenceCommand(commandEndNow, { occurrence_id: occurrence.id }, occurrence, confirmation, "end now");
  }

  async function makePermanent() {
    actionResult.textContent = "";
    const occurrence = selectedOccurrence();
    if (occurrence === null) {
      setStatus(actionResult, "Select an occurrence first.", "error");
      return;
    }
    const confirmation = await confirmAction({
      title: "Make occurrence permanent",
      summary: "Make occurrence #" + occurrence.id + " permanent; it then runs until ended by hand.",
      confirmLabel: "Make permanent",
    });
    if (confirmation === null) {
      return;
    }
    await runOccurrenceCommand(commandSetPermanent, { occurrence_id: occurrence.id }, occurrence, confirmation, "make permanent");
  }

  async function runOccurrenceCommand(name, payload, occurrence, confirmation, label) {
    const reply = await request("/agent/v1/commands/" + encodeURIComponent(name), {
      method: "POST",
      body: {
        reason: confirmation.reason,
        semantic_key: confirmation.semantic_key,
        expected_revision: occurrence.revision,
        payload,
      },
    });
    if (reply.unauthorized) {
      return;
    }
    setStatus(actionResult, label + ": " + describeOccurrenceReply(reply) + "\nreason: " + confirmation.reason, reply.ok ? "success" : "error");
    if (reply.ok) {
      await refreshEvents();
    }
  }
}

// The client activity table's icon column is images/activities/<id>.png for
// every row (data/tables/activity.lua); /agent/v1/res serves it.
function activityBannerPath(activityID) {
  return "images/activities/" + activityID + ".png";
}

function timeCell(value, fallback) {
  const cell = document.createElement("td");
  if (value === null || value === undefined) {
    cell.textContent = fallback;
    return cell;
  }
  cell.append(formatTime(value));
  return cell;
}

// durationText maps the picker's span onto the duration strings the events
// owner parses: the day presets, whole hours, or "permanent"
// (internal/domain/events/cycle.go:27-45).
function durationText(duration) {
  const span = Date.parse(duration.end) - Date.parse(duration.start);
  if (Number.isNaN(span) || span <= 0) {
    return { error: "The end must be after the start." };
  }
  const hours = span / 3600000;
  if (!Number.isInteger(hours)) {
    return { error: "Event durations are whole hours; adjust the end time." };
  }
  const presets = { 24: "1d", 72: "3d", 168: "7d", 336: "14d", 720: "30d" };
  if (presets[hours] !== undefined) {
    return { text: presets[hours] };
  }
  if (hours < 1 || hours > 24 * 365) {
    return { error: "Event durations are 1 to 8760 hours." };
  }
  return { text: hours + "h" };
}

function commandResult(reply) {
  const body = reply.body && typeof reply.body === "object" ? reply.body : {};
  return body.result && typeof body.result === "object" ? body.result : {};
}

function describeOccurrenceReply(reply) {
  if (!reply.ok) {
    return describeReply(reply);
  }
  const body = reply.body && typeof reply.body === "object" ? reply.body : {};
  const result = body.result && typeof body.result === "object" ? body.result : {};
  const parts = ["state " + (typeof body.state === "string" && body.state !== "" ? body.state : "unknown")];
  if (Array.isArray(result.occurrences)) {
    parts.push(result.occurrences.length + " occurrence(s)");
  }
  if (Number.isInteger(result.id)) {
    parts.push("occurrence #" + result.id + " " + (typeof result.state === "string" ? result.state : "unknown"));
  }
  if (result.ends_at === null) {
    parts.push("permanent");
  } else if (typeof result.ends_at === "string" && result.ends_at !== "") {
    parts.push("ends " + result.ends_at);
  }
  return parts.join(", ");
}

function newSemanticKey() {
  if (window.crypto && typeof window.crypto.randomUUID === "function") {
    return window.crypto.randomUUID();
  }
  const bytes = new Uint8Array(16);
  window.crypto.getRandomValues(bytes);
  return Array.from(bytes, (value) => value.toString(16).padStart(2, "0")).join("");
}

function createCard(title, identifier) {
  const card = document.createElement("section");
  card.className = "card mb-3";
  if (identifier) {
    card.id = identifier;
  }
  const header = document.createElement("div");
  header.className = "card-header";
  const heading = document.createElement("h2");
  heading.className = "card-title mb-0";
  heading.textContent = title;
  header.append(heading);
  const body = document.createElement("div");
  body.className = "card-body";
  card.append(header, body);
  return { card, body };
}

function createSelect(parent, identifier, label, options) {
  const wrapper = document.createElement("div");
  wrapper.className = "mb-3";
  const labelElement = document.createElement("label");
  labelElement.className = "form-label";
  labelElement.htmlFor = identifier;
  labelElement.textContent = label;
  const select = document.createElement("select");
  select.className = "form-select";
  select.id = identifier;
  for (const option of options) {
    const element = document.createElement("option");
    element.value = option.value;
    element.textContent = option.label;
    select.append(element);
  }
  wrapper.append(labelElement, select);
  parent.append(wrapper);
  return select;
}

function actionButton(label, primary, identifier) {
  const button = document.createElement("button");
  button.type = "button";
  button.className = "btn " + (primary ? "btn-primary" : "btn-outline-secondary");
  button.textContent = label;
  button.id = identifier;
  return button;
}

function paragraph(className, text) {
  const element = document.createElement("p");
  element.className = className;
  element.textContent = text;
  return element;
}

function errorParagraph() {
  const element = document.createElement("p");
  element.className = "status";
  element.setAttribute("role", "alert");
  return element;
}
