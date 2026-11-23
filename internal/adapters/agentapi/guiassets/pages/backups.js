"use strict";

import { confirmAction } from "../components/confirm_action.js";
import { formatTime, pageHeader, setStatus } from "../components/format.js";
import { openPathPicker } from "../components/path_picker.js";
import { describeReply, request } from "../transport.js";

const operationPollMilliseconds = 1000;
const noBackupFolderMessage = "No backup folder set. Choose a folder to enable snapshots.";

// renderPage is the Backups screen: the snapshot overview and table first, the
// three agent-run actions below. Update backend stays under Advanced.
export function renderPage(container, context) {
  container.replaceChildren();
  container.append(pageHeader(context.page.label));
  const folder = buildFolderCard();
  const overview = buildOverview();
  const list = buildList();
  const snapshot = buildSnapshotAction();
  const restore = buildAction("Restore selected snapshot");
  const prune = buildAction("Prune snapshots");
  container.append(folder.card, overview.card, list.card, snapshot.card, restore.card, prune.card);
  restore.button.disabled = true;

  let selectedEntry = null;
  let backendMigration = null;

  function selectSnapshot(entry) {
    if (entry.damaged === true) {
      return;
    }
    selectedEntry = entry;
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
      list.table.replaceChildren(noRowsRow(9, "The snapshot list is unavailable."));
      setStatus(list.status, describeReply(reply), "error");
      return;
    }
    const body = reply.body && typeof reply.body === "object" ? reply.body : {};
    const backups = Array.isArray(body.backups) ? body.backups : [];
    const hasFolder = typeof body.directory === "string" && body.directory !== "";
    folder.input.value = hasFolder ? body.directory : "";
    snapshot.button.disabled = !hasFolder;
    if (hasFolder) {
      if (folder.status.textContent === noBackupFolderMessage) {
        folder.status.textContent = "";
      }
    } else {
      setStatus(folder.status, noBackupFolderMessage, "error");
    }
    selectedEntry = null;
    backendMigration =
      typeof body.backend_migration === "number" && Number.isFinite(body.backend_migration)
        ? body.backend_migration
        : null;
    restore.button.disabled = true;
    fillOverview(overview, body);
    fillTable(list.table, backups, selectSnapshot, loadList, list.status);
    setStatus(list.status, "Loaded " + backups.length + " snapshot" + (backups.length === 1 ? "." : "s."), "success");
  }

  snapshot.button.addEventListener("click", async () => {
    const name = snapshot.name.value.trim();
    const pin = snapshot.pin.checked;
    if (pin && name === "") {
      setStatus(snapshot.status, "A name is required to keep (pin) a snapshot.", "error");
      return;
    }
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
      body: { kind: "manual", name, pin, reason: confirmation.reason },
    });
    await showOperation(snapshot, reply, confirmation);
    if (reply.ok) {
      await loadList();
    }
  });

  restore.button.addEventListener("click", async () => {
    if (selectedEntry === null) {
      setStatus(restore.status, "Select a valid snapshot row first.", "error");
      return;
    }
    const name = presentText(selectedEntry.name, "unnamed");
    const confirmation = await confirmAction({
      title: "Restore snapshot",
      summary:
        "Restore snapshot \"" + name + "\" (" + presentText(selectedEntry.id, "unknown") + "). " +
        "Snapshot migration " + presentNumber(selectedEntry.migration, "unknown") +
        "; backend migration " + presentNumber(backendMigration, "unknown") + ". " +
        "Restore replaces the current database with the selected snapshot. " +
        "The backend is stopped first and every player connection is lost; " +
        "an older snapshot is migrated forward to the backend schema, then the backend starts. " +
        "A safety snapshot is taken before the swap.",
      confirmLabel: "Restore snapshot",
    });
    if (confirmation === null) {
      return;
    }
    const reply = await request("/agent/v1/backup/restore", {
      method: "POST",
      body: { id: selectedEntry.id, reason: confirmation.reason },
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

  folder.browse.addEventListener("click", async () => {
    const chosen = await openPathPicker({
      title: "Backup folder",
      start: folder.input.value.trim(),
      mode: "folder",
    });
    if (chosen !== null) {
      folder.input.value = chosen;
    }
  });

  folder.save.addEventListener("click", async () => {
    const path = folder.input.value.trim();
    if (path === "") {
      setStatus(folder.status, "Choose a backup folder first.", "error");
      return;
    }
    const reply = await request("/agent/v1/backup/path", { method: "POST", body: { path } });
    if (reply.unauthorized) {
      return;
    }
    if (!reply.ok) {
      setStatus(folder.status, describeReply(reply), "error");
      return;
    }
    setStatus(folder.status, "Backup folder set. Snapshots in it are listed.", "success");
    await loadList();
  });

  list.refresh.addEventListener("click", () => {
    void loadList();
  });
  void loadList();
}

// buildFolderCard is the configurable snapshot folder. Setting it validates and
// rescans the folder at once, so an existing snapshots folder needs no restart.
function buildFolderCard() {
  const card = document.createElement("div");
  card.className = "card card-body";
  const heading = document.createElement("h2");
  heading.className = "card-title";
  heading.textContent = "Backup folder";
  const hint = document.createElement("p");
  hint.className = "hint";
  hint.textContent =
    "Snapshots are written here. Setting a folder validates it and lists the snapshots already in it, with no restart.";
  const group = document.createElement("div");
  group.className = "input-group";
  const input = document.createElement("input");
  input.type = "text";
  input.className = "form-control";
  input.id = "backup-path";
  input.autocomplete = "off";
  input.spellcheck = false;
  input.placeholder = "absolute folder, for example /srv/gxb/backups";
  const browse = document.createElement("button");
  browse.type = "button";
  browse.className = "btn btn-outline-secondary";
  browse.id = "backup-path-browse";
  browse.textContent = "Browse...";
  const save = document.createElement("button");
  save.type = "button";
  save.className = "btn btn-primary";
  save.id = "backup-path-save";
  save.textContent = "Set folder";
  group.append(input, browse, save);
  const status = document.createElement("p");
  status.className = "status mt-2";
  status.id = "backup-path-status";
  status.setAttribute("role", "status");
  card.append(heading, hint, group, status);
  return { card, input, browse, save, status };
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
  overview.directory.textContent = presentText(body.directory, "No backup folder set");
  overview.keep.textContent = presentNumber(body.keep, "unknown");
  overview.count.textContent = String(backups.length);
  overview.damaged.textContent = String(damaged);
  overview.newest.textContent = backups.length === 0 ? "No snapshots yet" : formatAge(body.newest_age_seconds);
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

function buildAction(title, controls) {
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
  card.append(heading);
  for (const control of controls || []) {
    card.append(control);
  }
  card.append(button, status, result);
  return { card, button, status, result };
}

// buildSnapshotAction adds the optional name field and the keep (pin) toggle to
// the plain action card.
function buildSnapshotAction() {
  const nameLabel = document.createElement("label");
  nameLabel.className = "form-label";
  nameLabel.htmlFor = "backup-snapshot-name";
  nameLabel.textContent = "Name (optional, 1-80 characters; required to keep)";
  const name = document.createElement("input");
  name.type = "text";
  name.className = "form-control";
  name.id = "backup-snapshot-name";
  name.maxLength = 80;
  name.autocomplete = "off";
  const keepLabel = document.createElement("label");
  keepLabel.className = "form-check";
  const pin = document.createElement("input");
  pin.type = "checkbox";
  pin.className = "form-check-input";
  pin.id = "backup-snapshot-pin";
  const keepText = document.createElement("span");
  keepText.className = "form-check-label";
  keepText.textContent = "Keep (pin): never pruned";
  keepLabel.append(pin, keepText);
  const action = buildAction("Back up now", [nameLabel, name, keepLabel]);
  action.name = name;
  action.pin = pin;
  return action;
}

function fillTable(table, backups, onSelect, onKeepChanged, status) {
  table.replaceChildren();
  table.append(tableHead(["Select", "Snapshot", "Name", "Time", "Size", "Backend", "Migration", "State", "Keep", "Delete"]));
  const body = document.createElement("tbody");
  if (backups.length === 0) {
    body.append(noRowsRow(10, "No snapshots yet."));
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
    radio.addEventListener("change", () => onSelect(entry));
    selectCell.append(radio);

    row.append(
      selectCell,
      textCell(presentText(entry.id, "unknown")),
      textCell(presentText(entry.name, "—")),
      textCell(formatTime(entry.created_at)),
      textCell(formatSize(entry.size)),
      textCell(presentText(entry.backend_version, "unknown")),
      textCell(presentNumber(entry.migration, "unknown")),
      stateCell(entry),
      keepCell(entry, onKeepChanged, status),
      deleteCell(entry, onKeepChanged, status),
    );
    body.append(row);
  });
  table.append(body);
}

// keepCell pins an unnamed snapshot with the typed name, or unpins a kept one.
// Both reload the list so the row reflects the stored manifest.
function keepCell(entry, onKeepChanged, status) {
  const cell = document.createElement("td");
  const id = presentText(entry.id, "");
  if (entry.pinned === true) {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "btn btn-outline-secondary btn-sm";
    button.textContent = "Unpin";
    button.addEventListener("click", () => changeKeep("/agent/v1/backup/unpin", { id }, status, onKeepChanged));
    cell.append(button);
    return cell;
  }
  const name = document.createElement("input");
  name.type = "text";
  name.className = "form-control form-control-sm";
  name.placeholder = "name";
  name.maxLength = 80;
  name.autocomplete = "off";
  const button = document.createElement("button");
  button.type = "button";
  button.className = "btn btn-outline-primary btn-sm";
  button.textContent = "Pin";
  button.addEventListener("click", () => {
    if (name.value.trim() === "") {
      setStatus(status, "A name is required to pin a snapshot.", "error");
      return;
    }
    void changeKeep("/agent/v1/backup/pin", { id, name: name.value.trim() }, status, onKeepChanged);
  });
  cell.append(name, button);
  return cell;
}

// deleteCell offers Delete only for an unpinned, undamaged manual snapshot; the
// agent refuses anything else.
function deleteCell(entry, onChanged, status) {
  const cell = document.createElement("td");
  if (entry.kind !== "manual" || entry.pinned === true || entry.damaged === true) {
    return cell;
  }
  const button = document.createElement("button");
  button.type = "button";
  button.className = "btn btn-outline-danger btn-sm";
  button.textContent = "Delete";
  button.addEventListener("click", async () => {
    const confirmation = await confirmAction({
      title: "Delete snapshot",
      summary:
        "Delete manual snapshot \"" + presentText(entry.name, "unnamed") + "\" (" + presentText(entry.id, "unknown") + "). " +
        "This removes the dump and its manifest; it cannot be undone.",
      confirmLabel: "Delete snapshot",
    });
    if (confirmation === null) {
      return;
    }
    const reply = await request("/agent/v1/backup/delete", {
      method: "POST",
      body: { id: entry.id, reason: confirmation.reason },
    });
    if (reply.unauthorized) {
      return;
    }
    if (!reply.ok) {
      setStatus(status, describeReply(reply), "error");
      return;
    }
    await onChanged();
  });
  cell.append(button);
  return cell;
}

async function changeKeep(path, body, status, onKeepChanged) {
  const reply = await request(path, { method: "POST", body });
  if (reply.unauthorized) {
    return;
  }
  if (!reply.ok) {
    setStatus(status, describeReply(reply), "error");
    return;
  }
  await onKeepChanged();
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
  if (entry.pinned === true) {
    cell.textContent = "pinned";
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
