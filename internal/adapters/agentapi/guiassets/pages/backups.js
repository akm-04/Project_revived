"use strict";

import { confirmAction } from "../components/confirm_action.js";
import { formatTime, pageHeader, setStatus } from "../components/format.js";
import { describeReply, request } from "../transport.js";

const operationPollMilliseconds = 1000;

// renderPage is the Backups screen: the snapshot overview and table first, the
// three agent-run actions below. Update backend stays under Advanced.
export function renderPage(container, context) {
  container.replaceChildren();
  container.append(pageHeader(context.page.label));
  const overview = buildOverview();
  const list = buildList();
  const snapshot = buildAction("Snapshot now");
  const restore = buildAction("Restore selected snapshot");
  const prune = buildAction("Prune snapshots");
  container.append(overview.card, list.card, snapshot.card, restore.card, prune.card);
  restore.button.disabled = true;

  let selectedID = "";

  function selectSnapshot(id, damaged) {
    if (damaged) {
      return;
    }
    selectedID = id;
    restore.button.disabled = false;
  }

  async function loadList() {
    list.status.textContent = "";
    overview.status.textContent = "";
    const reply = await request("/agent/v1/backup/list");
    if (reply.unauthorized) {
      return;
    }
    if (!reply.ok) {
      fillOverview(overview, null);
      list.table.replaceChildren(noRowsRow(6, "The snapshot list is unavailable."));
      setStatus(list.status, describeReply(reply), "error");
      return;
    }
    const body = reply.body && typeof reply.body === "object" ? reply.body : {};
    const backups = Array.isArray(body.backups) ? body.backups : [];
    selectedID = "";
    restore.button.disabled = true;
    fillOverview(overview, body);
    fillTable(list.table, backups, selectSnapshot);
    setStatus(list.status, "Loaded " + backups.length + " snapshot" + (backups.length === 1 ? "." : "s."), "success");
  }

  snapshot.button.addEventListener("click", async () => {
    const confirmation = await confirmAction({
      title: "Snapshot now",
      summary: "Take a database snapshot of the running backend now.",
      confirmLabel: "Snapshot",
    });
    if (confirmation === null) {
      return;
    }
    const reply = await request("/agent/v1/backup/snapshot", {
      method: "POST",
      body: { kind: "manual", reason: confirmation.reason },
    });
    await showOperation(snapshot, reply, confirmation);
    if (reply.ok) {
      await loadList();
    }
  });

  restore.button.addEventListener("click", async () => {
    if (selectedID === "") {
      setStatus(restore.status, "Select a valid snapshot row first.", "error");
      return;
    }
    const confirmation = await confirmAction({
      title: "Restore snapshot",
      summary:
        "Restore replaces the current database with the selected snapshot. " +
        "The backend is stopped first and every player connection is lost; " +
        "it is then started from the restored data. A safety snapshot is taken before the swap.",
      confirmLabel: "Restore snapshot",
    });
    if (confirmation === null) {
      return;
    }
    const reply = await request("/agent/v1/backup/restore", {
      method: "POST",
      body: { id: selectedID, reason: confirmation.reason },
    });
    await showOperation(restore, reply, confirmation);
    if (reply.ok) {
      await loadList();
    }
  });

  prune.button.addEventListener("click", async () => {
    const confirmation = await confirmAction({
      title: "Prune snapshots",
      summary:
        "Delete every snapshot except the newest ones this installation keeps. " +
        "A damaged snapshot and one a running operation references are kept.",
      confirmLabel: "Prune",
    });
    if (confirmation === null) {
      return;
    }
    const reply = await request("/agent/v1/backup/prune", {
      method: "POST",
      body: { reason: confirmation.reason },
    });
    await showOperation(prune, reply, confirmation);
    if (reply.ok) {
      await loadList();
    }
  });

  list.refresh.addEventListener("click", () => {
    void loadList();
  });
  void loadList();
}

function buildOverview() {
  const card = document.createElement("div");
  card.className = "card card-body";
  const heading = document.createElement("h2");
  heading.className = "card-title";
  heading.textContent = "Backups";
  const hint = document.createElement("p");
  hint.className = "hint";
  hint.textContent = "Database snapshots owned by the operator agent; they stay readable while the backend is down.";
  const rows = document.createElement("dl");
  rows.className = "row";
  const directory = overviewRow(rows, "Snapshot directory", "backup-directory");
  const keep = overviewRow(rows, "Keep", "backup-keep");
  const count = overviewRow(rows, "Snapshots", "backup-count");
  const damaged = overviewRow(rows, "Damaged", "backup-damaged");
  const newest = overviewRow(rows, "Newest", "backup-newest-age");
  const status = document.createElement("p");
  status.className = "status";
  card.append(heading, hint, rows, status);
  return { card, directory, keep, count, damaged, newest, status };
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

function fillOverview(overview, body) {
  if (body === null) {
    overview.directory.textContent = "unknown";
    overview.keep.textContent = "unknown";
    overview.count.textContent = "unknown";
    overview.damaged.textContent = "unknown";
    overview.newest.textContent = "unknown";
    return;
  }
  const backups = Array.isArray(body.backups) ? body.backups : [];
  const damaged = backups.filter((backup) => backup && backup.damaged === true).length;
  overview.directory.textContent = presentText(body.directory, "unknown");
  overview.keep.textContent = presentNumber(body.keep, "unknown");
  overview.count.textContent = String(backups.length);
  overview.damaged.textContent = String(damaged);
  overview.newest.textContent = formatAge(body.newest_age_seconds);
}

function buildList() {
  const card = document.createElement("div");
  card.className = "card card-body";
  const heading = document.createElement("h2");
  heading.className = "card-title";
  heading.textContent = "Snapshots";
  const controls = document.createElement("div");
  controls.className = "btn-list mb-2";
  const refresh = document.createElement("button");
  refresh.type = "button";
  refresh.className = "btn btn-outline-secondary btn-sm";
  refresh.id = "backup-refresh";
  refresh.textContent = "Refresh";
  controls.append(refresh);
  const table = document.createElement("table");
  table.className = "table table-sm table-vcenter card-table mb-0";
  table.id = "backup-table";
  const status = document.createElement("p");
  status.className = "status";
  status.id = "backup-list-status";
  status.setAttribute("role", "status");
  const tableWrap = document.createElement("div");
  tableWrap.className = "table-responsive";
  tableWrap.append(table);
  card.append(heading, controls, tableWrap, status);
  return { card, table, status, refresh };
}

function buildAction(title) {
  const card = document.createElement("div");
  card.className = "card card-body";
  const heading = document.createElement("h2");
  heading.className = "card-title";
  heading.textContent = title;
  const button = document.createElement("button");
  button.type = "button";
  button.className = "btn btn-primary";
  button.textContent = title;
  const status = document.createElement("p");
  status.className = "status mt-2";
  status.setAttribute("role", "status");
  const result = document.createElement("pre");
  result.className = "component-output";
  card.append(heading, button, status, result);
  return { card, button, status, result };
}

function fillTable(table, backups, onSelect) {
  table.replaceChildren();
  table.append(tableHead(["Select", "Snapshot", "Time", "Size", "State", "Migration"]));
  const body = document.createElement("tbody");
  if (backups.length === 0) {
    body.append(noRowsRow(6, "No snapshots yet."));
    table.append(body);
    return;
  }
  backups.forEach((backup, index) => {
    const entry = backup && typeof backup === "object" ? backup : {};
    const row = document.createElement("tr");
    const damaged = entry.damaged === true;

    const selectCell = document.createElement("td");
    const radio = document.createElement("input");
    radio.type = "radio";
    radio.name = "backup-select";
    radio.className = "form-check-input";
    radio.value = presentText(entry.id, "");
    radio.id = "backup-select-" + index;
    radio.disabled = damaged;
    radio.addEventListener("change", () => onSelect(radio.value, damaged));
    selectCell.append(radio);

    row.append(
      selectCell,
      textCell(presentText(entry.id, "unknown")),
      textCell(formatTime(entry.created_at)),
      textCell(formatSize(entry.size)),
      stateCell(entry),
      textCell(presentNumber(entry.migration, "unknown")),
    );
    body.append(row);
  });
  table.append(body);
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

function textCell(value) {
  const cell = document.createElement("td");
  if (value instanceof Node) {
    cell.append(value);
  } else {
    cell.textContent = value;
  }
  return cell;
}

function stateCell(entry) {
  const cell = document.createElement("td");
  if (entry.damaged === true) {
    cell.textContent = "damaged";
    if (typeof entry.damaged_reason === "string" && entry.damaged_reason !== "") {
      cell.title = entry.damaged_reason;
    }
    return cell;
  }
  cell.textContent = "valid";
  return cell;
}

function noRowsRow(columns, text) {
  const row = document.createElement("tr");
  const cell = document.createElement("td");
  cell.colSpan = columns;
  cell.textContent = text;
  row.append(cell);
  return row;
}

async function showOperation(box, reply, confirmation) {
  box.status.textContent = "";
  box.result.textContent = "";
  if (reply.unauthorized) {
    return;
  }
  if (!reply.ok) {
    setStatus(box.status, describeReply(reply), "error");
    return;
  }
  const operation = reply.body && typeof reply.body === "object" ? reply.body : {};
  const header = "reason: " + confirmation.reason + "\nsemantic_key: " + confirmation.semantic_key;
  box.result.textContent = header + "\n" + describeOperation(operation);
  await followOperation(box, operation, header);
}

async function followOperation(box, operation, header) {
  let current = operation;
  while (current && typeof current.id === "string" && current.id !== "" && current.state !== "DONE" && current.state !== "FAILED") {
    await delay(operationPollMilliseconds);
    if (!box.card.isConnected) {
      return;
    }
    const reply = await request("/agent/v1/ops/" + encodeURIComponent(current.id));
    if (reply.unauthorized) {
      return;
    }
    if (!reply.ok) {
      setStatus(box.status, describeReply(reply), "error");
      return;
    }
    current = reply.body && typeof reply.body === "object" ? reply.body : {};
    box.result.textContent = header + "\n" + describeOperation(current);
  }
  if (current && current.state === "FAILED") {
    setStatus(box.status, "The operation failed at step " + presentText(current.failed_step, "unknown") + ".", "error");
  }
}

function describeOperation(operation) {
  const lines = ["state: " + presentText(operation.state, "unknown")];
  if (typeof operation.failed_step === "string" && operation.failed_step !== "") {
    lines.push("failed step: " + operation.failed_step);
  }
  if (typeof operation.error === "string" && operation.error !== "") {
    lines.push("error: " + operation.error);
  }
  const steps = Array.isArray(operation.steps) ? operation.steps : [];
  for (const step of steps) {
    const detail = typeof step.detail === "string" && step.detail !== "" ? " — " + step.detail : "";
    lines.push("- " + presentText(step.name, "step") + ": " + presentText(step.state, "unknown") + detail);
  }
  return lines.join("\n");
}

function presentText(value, fallback) {
  return typeof value === "string" && value !== "" ? value : fallback;
}

function presentNumber(value, fallback) {
  return typeof value === "number" && Number.isFinite(value) ? String(value) : fallback;
}

function formatSize(value) {
  if (typeof value !== "number" || !Number.isFinite(value) || value < 0) {
    return "unknown";
  }
  const units = ["B", "KiB", "MiB", "GiB", "TiB"];
  let size = value;
  let unit = 0;
  while (size >= 1024 && unit < units.length - 1) {
    size /= 1024;
    unit += 1;
  }
  const rounded = unit === 0 ? String(size) : size.toFixed(1);
  return rounded + " " + units[unit];
}

function formatAge(seconds) {
  if (typeof seconds !== "number" || !Number.isFinite(seconds) || seconds < 0) {
    return "unknown";
  }
  if (seconds < 60) {
    return Math.floor(seconds) + " s";
  }
  if (seconds < 3600) {
    return Math.floor(seconds / 60) + " min";
  }
  if (seconds < 86400) {
    return Math.floor(seconds / 3600) + " h";
  }
  return Math.floor(seconds / 86400) + " d";
}

function delay(milliseconds) {
  return new Promise((resolve) => setTimeout(resolve, milliseconds));
}
