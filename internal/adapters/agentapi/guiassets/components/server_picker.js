"use strict";

import { describeReply, request } from "../transport.js";
import { actionButton, createModal, errorParagraph } from "./modal.js";

const serverListRead = "/agent/v1/reads/server.list";

export async function loadServers() {
  const reply = await request(serverListRead);
  if (reply.unauthorized) {
    return { servers: [], error: "" };
  }
  if (!reply.ok) {
    return { servers: [], error: describeReply(reply) };
  }
  const body = reply.body && typeof reply.body === "object" ? reply.body : {};
  return { servers: Array.isArray(body.servers) ? body.servers : [], error: "" };
}

// mountServerPicker renders the registered logical servers in place (G4). A
// ticked Global clears and disables every server; in single mode one server at
// a time may be picked. value() answers {global, server_ids}.
export function mountServerPicker(container, options) {
  const settings = options || {};
  const includeGlobal = settings.includeGlobal !== false;
  const multiple = settings.multiple !== false;
  const identifierPrefix = settings.idPrefix || "server";
  const selected = new Set((settings.selected || []).map(Number));
  let global = settings.global === true;
  let servers = [];
  let loaded = false;

  container.replaceChildren();
  const list = document.createElement("div");
  list.className = "server-list";
  const status = errorParagraph();
  container.append(list, status);

  function value() {
    if (global) {
      return { global: true, server_ids: [] };
    }
    const serverIDs = Array.from(selected).sort((left, right) => left - right);
    return { global: false, server_ids: serverIDs };
  }

  function notify() {
    if (settings.onChange) {
      settings.onChange(value());
    }
  }

  function render() {
    list.replaceChildren();
    if (includeGlobal) {
      list.append(checkboxRow(identifierPrefix + "-global", "Global (all servers)", global, false, (checked) => {
        global = checked;
        if (global) {
          selected.clear();
        }
        render();
        notify();
      }));
    }
    for (const server of servers) {
      const serverID = Number(server.server_id);
      const state = server.open ? "" : " (closed)";
      const label = "#" + serverID + " " + server.name + state + " — " + server.online_count + " online";
      list.append(checkboxRow(identifierPrefix + "-" + serverID, label, selected.has(serverID), global, (checked) => {
        if (checked) {
          if (!multiple) {
            selected.clear();
          }
          selected.add(serverID);
        } else {
          selected.delete(serverID);
        }
        render();
        notify();
      }));
    }
    if (loaded && servers.length === 0 && !includeGlobal) {
      list.append(textParagraph("No servers are registered."));
    }
  }

  loadServers().then((result) => {
    servers = result.servers;
    loaded = true;
    if (result.error === "") {
      const known = new Set(servers.map((server) => Number(server.server_id)));
      for (const serverID of Array.from(selected)) {
        if (!known.has(serverID)) {
          selected.delete(serverID);
        }
      }
    }
    status.textContent = result.error;
    render();
  });

  render();
  return { value, ready: () => loaded };
}

function checkboxRow(identifier, label, checked, disabled, onChange) {
  const row = document.createElement("label");
  row.className = "form-check";
  const box = document.createElement("input");
  box.type = "checkbox";
  box.className = "form-check-input";
  box.id = identifier;
  box.checked = checked;
  box.disabled = disabled;
  box.addEventListener("change", () => onChange(box.checked));
  const text = document.createElement("span");
  text.className = "form-check-label";
  text.textContent = label;
  row.append(box, text);
  return row;
}

function textParagraph(text) {
  const element = document.createElement("p");
  element.className = "module-help mb-0";
  element.textContent = text;
  return element;
}

export function openServerPicker(options) {
  const settings = options || {};
  return new Promise((resolve) => {
    let settled = false;
    function settle(value) {
      if (settled) {
        return;
      }
      settled = true;
      resolve(value);
    }
    const dialog = createModal({
      title: settings.title || "Servers",
      modalId: "server-picker",
      onClose: () => settle(null),
    });
    const picker = mountServerPicker(dialog.body, {
      includeGlobal: true,
      multiple: settings.multiple !== false,
    });
    const status = errorParagraph();
    dialog.body.append(status);
    const cancel = actionButton("Cancel", false, "server-cancel");
    const confirm = actionButton(settings.confirmLabel || "Use servers", true, "server-confirm");
    cancel.addEventListener("click", () => dialog.close());
    confirm.addEventListener("click", () => {
      if (!picker.ready()) {
        status.textContent = "The server list has not loaded yet.";
        return;
      }
      const value = picker.value();
      if (!value.global && value.server_ids.length === 0) {
        status.textContent = "Select at least one server or Global.";
        return;
      }
      settle(value);
      dialog.close();
    });
    dialog.footer.append(cancel, confirm);
  });
}
