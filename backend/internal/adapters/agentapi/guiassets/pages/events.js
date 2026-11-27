"use strict";

import { describeReply, request } from "../transport.js";
import { confirmAction } from "../components/confirm_action.js";
import { openDurationPicker } from "../components/duration_picker.js";
import { actionRow, formatTime, formatTimeText, pageHeader, setStatus } from "../components/format.js";
import { loadServers, mountServerPicker } from "../components/server_picker.js";
import { pictureElement } from "../pictures.js";

const readEventsList = "events.list";
const commandDefinitionList = "events.definition.list";
const commandSchedule = "events.schedule";
const commandExtend = "events.extend";
const commandEndNow = "events.end_now";
const commandSetPermanent = "events.set_permanent";
const eventsListLimit = 200;

// Events (G5, EA-15): the global groups and the server-only occurrences, the
// occurrences' lifecycle actions, and the schedule action. The page opens on
// scope "All servers"; one server stays selectable for a server-only event.
export function renderPage(container, context) {
  container.replaceChildren();
  container.append(pageHeader(context.page.label));
  container.setAttribute("aria-label", context.page.label);

  const state = {
    scope: "global",
    serverID: null,
    occurrences: [],
    groups: [],
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
  const groupsHost = document.createElement("div");
  groupsHost.id = "events-groups";
  const tableHost = document.createElement("div");
  tableHost.className = "table-responsive";
  tableHost.id = "events-table-host";
  const overviewActions = actionRow(refreshButton);
  overview.body.append(serverPickerHost, overviewActions, overviewStatus, groupsHost, tableHost);

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
  scheduleCard.body.append(definitionsStatus, definitionsHost, scheduleDurationSummary, actionRow(pickScheduleDuration, scheduleButton), scheduleResult);

  const actionCard = createCard("Change a single-server event", "events-actions-card");
  const occurrenceSelect = createSelect(actionCard.body, "events-action-target", "Occurrence", []);
  const extendButton = actionButton("Extend", false, "events-extend");
  const endNowButton = actionButton("End now", false, "events-end-now");
  const permanentButton = actionButton("Make permanent", false, "events-permanent");
  const actionResult = errorParagraph();
  actionResult.id = "events-action-result";
  const occurrenceActions = document.createElement("div");
  occurrenceActions.className = "action-row";
  occurrenceActions.append(extendButton, endNowButton, permanentButton);
  actionCard.body.append(occurrenceActions, actionResult);

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
    if (loaded.servers.length > 0) {
      state.serverID = Number(loaded.servers[0].server_id);
    }
    mountServerPicker(serverPickerHost, {
      includeGlobal: true,
      multiple: false,
      global: true,
      selected: [],
      idPrefix: "events-server",
      onError: (message) => setStatus(overviewStatus, message, "error"),
      onChange: (value) => {
        state.scope = value.global ? "global" : "server";
        state.serverID = value.server_ids.length === 1 ? value.server_ids[0] : null;
        void refreshEvents();
      },
    });
    await refreshEvents();
    await loadDefinitions();
  }

  async function refreshEvents() {
    overviewStatus.textContent = "";
    if (state.scope === "global") {
      await refreshGlobalEvents();
      return;
    }
    if (state.serverID === null) {
      overviewStatus.textContent = "Select one server, or All servers.";
      state.occurrences = [];
      state.groups = [];
      renderEvents();
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
      state.groups = [];
      renderEvents();
      return;
    }
    state.groups = [];
    state.occurrences = running.occurrences.concat(scheduled.occurrences);
    state.occurrences.sort((left, right) => String(left.starts_at).localeCompare(String(right.starts_at)));
    overviewStatus.textContent = state.occurrences.length === 0 ? "No running or scheduled events on this server." : "";
    renderEvents();
  }

  // The global view reads groups plus server-only rows in one bounded page
  // (internal/application/events/service.go listGlobal); the page shows the
  // running and scheduled ones.
  async function refreshGlobalEvents() {
    overviewStatus.textContent = "Loading events…";
    const reply = await request("/agent/v1/reads/" + encodeURIComponent(readEventsList) + "?limit=" + eventsListLimit);
    if (reply.unauthorized) {
      return;
    }
    if (!reply.ok) {
      setStatus(overviewStatus, describeReply(reply), "error");
      state.groups = [];
      state.occurrences = [];
      renderEvents();
      return;
    }
    const body = reply.body && typeof reply.body === "object" ? reply.body : {};
    const groups = Array.isArray(body.groups) ? body.groups : [];
    const occurrences = Array.isArray(body.occurrences) ? body.occurrences : [];
    state.groups = groups.filter(isLiveEvent);
    state.occurrences = occurrences.filter(isLiveEvent);
    state.groups.sort((left, right) => String(left.starts_at).localeCompare(String(right.starts_at)));
    state.occurrences.sort((left, right) => String(left.starts_at).localeCompare(String(right.starts_at)));
    overviewStatus.textContent = state.groups.length === 0 && state.occurrences.length === 0
      ? "No running or scheduled events."
      : "";
    renderEvents();
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

  function renderEvents() {
    renderOccurrences();
    renderGroups();
    updateScheduleHint();
  }

  function updateScheduleHint() {
    if (state.definitions.length === 0) {
      return;
    }
    definitionsStatus.textContent = state.scope === "global"
      ? "Tick the events to schedule on all current and future servers."
      : "Tick the events to schedule on the selected server.";
  }

  function renderOccurrences() {
    tableHost.replaceChildren();
    occurrenceSelect.replaceChildren();
    const selectable = state.occurrences.filter(isServerOnly);
    const blank = document.createElement("option");
    blank.value = "";
    blank.textContent = selectable.length === 0 ? "No single-server occurrences" : "choose one";
    occurrenceSelect.append(blank);
    for (const occurrence of selectable) {
      const option = document.createElement("option");
      option.value = String(occurrence.id);
      option.textContent = "#" + occurrence.id + " · " + activityLabel(occurrence.activity_id) + " · " + occurrence.state;
      occurrenceSelect.append(option);
    }
    if (state.occurrences.length === 0) {
      updateActionAvailability();
      return;
    }
    tableHost.append(occurrenceTable(state.occurrences, state.scope === "global" ? "global" : "server"));
    updateActionAvailability();
  }

  // Each global group is one native <details> row: the summary carries the
  // activity, state and "all N servers" / "K of N", and expanding it shows the
  // per-server rows and the two group commands (EA-15 items 4-6).
  function renderGroups() {
    groupsHost.replaceChildren();
    if (state.scope !== "global" || state.groups.length === 0) {
      return;
    }
    const heading = document.createElement("h3");
    heading.className = "card-title mt-3";
    heading.textContent = "All-server events";
    const list = document.createElement("div");
    list.className = "d-flex flex-column gap-2";
    for (const group of state.groups) {
      list.append(groupDetails(group));
    }
    groupsHost.append(heading, list);
  }

  function groupDetails(group) {
    const details = document.createElement("details");
    details.className = "border rounded p-2";
    details.id = "event-group-" + group.id;

    const summary = document.createElement("summary");
    summary.className = "d-flex flex-wrap align-items-center gap-2";
    const title = document.createElement("span");
    title.className = "fw-bold";
    title.textContent = "activity " + activityLabel(group.activity_id);
    const stateBadge = document.createElement("span");
    stateBadge.className = "badge bg-secondary-lt text-secondary";
    stateBadge.textContent = group.state || "unknown";
    const coverage = document.createElement("span");
    coverage.className = "text-secondary";
    coverage.textContent = coverageText(group);
    summary.append(title, stateBadge, coverage);
    details.append(summary);

    const meta = document.createElement("p");
    meta.className = "mb-1";
    meta.textContent = "starts " + timeText(group.starts_at, "unknown") + " · ends " + timeText(group.ends_at, "permanent");
    details.append(meta);

    const missing = missingServers(group);
    if (missing !== "") {
      const missingLine = document.createElement("p");
      missingLine.className = "text-warning mb-1";
      missingLine.textContent = missing;
      details.append(missingLine);
    }

    const actions = document.createElement("div");
    actions.className = "action-row mb-2";
    const endButton = actionButton("End now", false, "event-group-end-" + group.id);
    endButton.disabled = group.state !== "RUNNING";
    const permanentButton = actionButton("Make permanent", false, "event-group-permanent-" + group.id);
    permanentButton.disabled = (group.state !== "RUNNING" && group.state !== "SCHEDULED") || group.ends_at === null || group.ends_at === undefined;
    endButton.addEventListener("click", () => endGroupNow(group));
    permanentButton.addEventListener("click", () => makeGroupPermanent(group));
    actions.append(endButton, permanentButton);
    details.append(actions);

    const result = errorParagraph();
    result.id = "event-group-result-" + group.id;
    details.append(result);

    details.append(occurrenceTable(Array.isArray(group.occurrences) ? group.occurrences : [], "global"));
    return details;
  }

  function coverageText(group) {
    if (!Number.isInteger(group.server_count) || !Number.isInteger(group.joined_count)) {
      return "unknown servers";
    }
    if (group.joined_count === group.server_count) {
      return "all " + group.server_count + " servers";
    }
    return group.joined_count + " of " + group.server_count + " servers";
  }

  function missingServers(group) {
    if (!Array.isArray(group.missing_servers) || group.missing_servers.length === 0) {
      return "";
    }
    const names = group.missing_servers.map((server) =>
      "#" + server.server_id + " " + (typeof server.name === "string" && server.name !== "" ? server.name : "unknown") +
      " (" + (typeof server.reason === "string" && server.reason !== "" ? server.reason : "unknown") + ")");
    return "not in this event: " + names.join(", ");
  }

  // occurrenceTable renders the run of one server's or one group's
  // occurrences. mode "global" starts with the server column; mode "server"
  // marks the group membership instead, so a group row is never mistaken for
  // a single-server event.
  function occurrenceTable(occurrenceRows, mode) {
    const wrap = document.createElement("div");
    wrap.className = "table-responsive";
    const table = document.createElement("table");
    table.className = "table table-sm table-vcenter card-table mb-0";
    const head = document.createElement("thead");
    const headRow = document.createElement("tr");
    const labels = mode === "global"
      ? ["server", "banner", "activity", "state", "starts", "ends", "claim until"]
      : ["banner", "activity", "scope", "state", "starts", "ends", "claim until"];
    for (const label of labels) {
      const cell = document.createElement("th");
      cell.textContent = label;
      headRow.append(cell);
    }
    head.append(headRow);
    const body = document.createElement("tbody");
    for (const occurrence of occurrenceRows) {
      const row = document.createElement("tr");
      if (mode === "global") {
        row.append(numberCell(occurrence.logical_server_id));
      }
      const banner = document.createElement("td");
      banner.append(pictureElement(activityBannerPath(occurrence.activity_id)));
      const activity = document.createElement("td");
      activity.textContent = activityLabel(occurrence.activity_id);
      if (mode !== "global") {
        const scopeCell = document.createElement("td");
        scopeCell.textContent = isServerOnly(occurrence) ? "single server" : "group #" + occurrence.global_group_id;
        row.append(banner, activity, scopeCell);
      } else {
        row.append(banner, activity);
      }
      const stateCell = document.createElement("td");
      stateCell.textContent = occurrence.state;
      row.append(
        stateCell,
        timeCell(occurrence.starts_at, "unknown"),
        timeCell(occurrence.ends_at, "permanent"),
        timeCell(occurrence.claim_until, "none"),
      );
      body.append(row);
    }
    table.append(head, body);
    wrap.append(table);
    return wrap;
  }

  function numberCell(value) {
    const cell = document.createElement("td");
    cell.textContent = Number.isInteger(value) ? "#" + value : "unknown";
    return cell;
  }

  function isServerOnly(occurrence) {
    return occurrence.global_group_id === null || occurrence.global_group_id === undefined;
  }

  function isLiveEvent(entry) {
    return entry.state === "RUNNING" || entry.state === "SCHEDULED";
  }

  function timeText(value, fallback) {
    return value === null || value === undefined ? fallback : formatTimeText(value);
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
      renderEvents();
      return;
    }
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
    renderEvents();
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
    if (state.scope === "server" && state.serverID === null) {
      setStatus(scheduleResult, "Select one server, or All servers.", "error");
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
    const target = state.scope === "global" ? "every current and future server" : "server #" + state.serverID;
    const confirmation = await confirmAction({
      title: "Schedule events",
      summary: "Schedule activity " + activityIDs.join(", ") + " on " + target +
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
      const payload = {
        activity_id: activityIDs[index],
        start: state.scheduleDuration.start,
        duration: duration.text,
      };
      if (state.scope === "global") {
        payload.scope = "global";
      } else {
        payload.scope = "server";
        payload.logical_server_ids = [state.serverID];
      }
      const reply = await request("/agent/v1/commands/" + encodeURIComponent(commandSchedule), {
        method: "POST",
        body: {
          reason: confirmation.reason,
          semantic_key: semanticKey,
          payload,
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

  async function endGroupNow(group) {
    const confirmation = await confirmAction({
      title: "End all-server event",
      summary: "End group #" + group.id + " now on every server; each claim window still opens.",
      confirmLabel: "End now",
    });
    if (confirmation === null) {
      return;
    }
    await runGroupCommand(commandEndNow, { group_id: group.id }, group, confirmation, "end now");
  }

  async function makeGroupPermanent(group) {
    const confirmation = await confirmAction({
      title: "Make all-server event permanent",
      summary: "Make group #" + group.id + " permanent on every server; it then runs until ended by hand.",
      confirmLabel: "Make permanent",
    });
    if (confirmation === null) {
      return;
    }
    await runGroupCommand(commandSetPermanent, { group_id: group.id }, group, confirmation, "make permanent");
  }

  async function runGroupCommand(name, payload, group, confirmation, label) {
    const reply = await request("/agent/v1/commands/" + encodeURIComponent(name), {
      method: "POST",
      body: {
        reason: confirmation.reason,
        semantic_key: confirmation.semantic_key,
        expected_revision: group.revision,
        payload,
      },
    });
    if (reply.unauthorized) {
      return;
    }
    const box = document.getElementById("event-group-result-" + group.id);
    const text = label + ": " + describeGroupReply(reply) + "\nreason: " + confirmation.reason;
    if (box === null) {
      setStatus(overviewStatus, text, reply.ok ? "success" : "error");
    } else {
      setStatus(box, text, reply.ok ? "success" : "error");
    }
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
  if (result.group && typeof result.group === "object" && Number.isInteger(result.group.group_id)) {
    parts.push("group #" + result.group.group_id + " " + (typeof result.group.state === "string" ? result.group.state : "unknown"));
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

function describeGroupReply(reply) {
  if (!reply.ok) {
    return describeReply(reply);
  }
  const result = commandResult(reply);
  const parts = [];
  if (Number.isInteger(result.group_id)) {
    parts.push("group #" + result.group_id);
  }
  if (typeof result.state === "string" && result.state !== "") {
    parts.push("state " + result.state);
  }
  if (Number.isInteger(result.occurrence_count)) {
    parts.push(result.occurrence_count + " occurrence(s)");
  }
  if (result.ends_at === null) {
    parts.push("permanent");
  } else if (typeof result.ends_at === "string" && result.ends_at !== "") {
    parts.push("ends " + result.ends_at);
  }
  return parts.length === 0 ? "unknown" : parts.join(", ");
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
