"use strict";

import { describeReply, request } from "../transport.js";
import { actionButton, createModal, errorParagraph } from "./modal.js";
import { mountServerPicker } from "./server_picker.js";

const onlineRead = "/agent/v1/reads/session.online";
const findRead = "/agent/v1/reads/player.find";
const pageSize = 50;
const searchDebounceMilliseconds = 250;

export function openPlayerPicker(options) {
  const settings = options || {};
  const single = settings.single === true;
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
      title: settings.title || "Players",
      modalId: "player-picker",
      wide: true,
      onClose: () => {
        cancelPendingSearch();
        settle(null);
      },
    });
    const selected = new Map();
    const summary = document.createElement("p");
    summary.className = "module-help";
    const failure = errorParagraph();
    let serverFilter = { global: true, server_ids: [] };

    const filterSection = document.createElement("section");
    filterSection.className = "mb-3";
    const filterHeading = document.createElement("h3");
    filterHeading.className = "module-title";
    filterHeading.textContent = "Server filter";
    const filterView = document.createElement("div");
    filterSection.append(filterHeading, filterView);
    mountServerPicker(filterView, {
      includeGlobal: true,
      multiple: false,
      idPrefix: "player-server",
      onChange: (value) => {
        serverFilter = value;
        void loadOnline(true);
        if (!searchPanel.hidden) {
          cancelPendingSearch();
          void runSearch();
        }
      },
    });

    const tabs = document.createElement("nav");
    tabs.className = "nav nav-tabs mb-3";
    const onlineTab = tabButton("Online", "player-tab-online");
    const searchTab = tabButton("Search", "player-tab-search");
    tabs.append(onlineTab, searchTab);

    const onlinePanel = document.createElement("section");
    const onlineStatus = textParagraph("Loading live sessions…");
    onlineStatus.id = "player-online-status";
    const onlineTableHost = document.createElement("div");
    onlineTableHost.className = "player-table-scroll";
    const loadMore = actionButton("Load more online players", false, "player-online-more");
    loadMore.hidden = true;
    onlinePanel.append(onlineStatus, onlineTableHost, loadMore);

    const searchPanel = document.createElement("section");
    searchPanel.hidden = true;
    const searchFields = document.createElement("div");
    searchFields.className = "row g-2 mb-2";
    const uidInput = labeledInput(searchFields, "player-search-uid", "Account uid", "text");
    const nameInput = labeledInput(searchFields, "player-search-name", "Name prefix", "text");
    const searchButton = actionButton("Search", true, "player-search-button");
    searchButton.classList.add("mb-2");
    const searchStatus = textParagraph("");
    searchStatus.id = "player-search-status";
    const searchTableHost = document.createElement("div");
    searchTableHost.className = "player-table-scroll";
    searchPanel.append(searchFields, searchButton, searchStatus, searchTableHost);

    dialog.body.append(filterSection, tabs, failure, onlinePanel, searchPanel, summary);

    let onlineRows = [];
    let onlineAfter = "";
    let onlineRequest = 0;
    let searchRequest = 0;
    let searchRows = [];
    let searchTimer = null;

    function cancelPendingSearch() {
      if (searchTimer !== null) {
        clearTimeout(searchTimer);
        searchTimer = null;
      }
    }

    function scheduleSearch() {
      cancelPendingSearch();
      searchTimer = setTimeout(() => {
        searchTimer = null;
        void runSearch();
      }, searchDebounceMilliseconds);
    }

    onlineTab.addEventListener("click", () => selectTab(onlineTab, onlinePanel));
    searchTab.addEventListener("click", () => selectTab(searchTab, searchPanel));
    loadMore.addEventListener("click", () => void loadOnline(false));
    searchButton.addEventListener("click", () => {
      cancelPendingSearch();
      void runSearch();
    });
    uidInput.addEventListener("input", scheduleSearch);
    nameInput.addEventListener("input", scheduleSearch);
    uidInput.addEventListener("keydown", submitSearchOnEnter);
    nameInput.addEventListener("keydown", submitSearchOnEnter);
    selectTab(onlineTab, onlinePanel);
    updateSummary();

    const cancel = actionButton("Cancel", false, "player-cancel");
    const confirm = actionButton("Use players", true, "player-confirm");
    cancel.addEventListener("click", () => dialog.close());
    confirm.addEventListener("click", () => {
      if (selected.size === 0) {
        failure.textContent = "Select at least one player.";
        return;
      }
      if (single && selected.size !== 1) {
        failure.textContent = "Select one player.";
        return;
      }
      const players = Array.from(selected.values()).sort(comparePlayers);
      settle(players);
      dialog.close();
    });
    dialog.footer.append(cancel, confirm);
    void loadOnline(true);

    function selectTab(activeTab, activePanel) {
      onlineTab.classList.toggle("active", activeTab === onlineTab);
      searchTab.classList.toggle("active", activeTab === searchTab);
      onlinePanel.hidden = activePanel !== onlinePanel;
      searchPanel.hidden = activePanel !== searchPanel;
    }

    function submitSearchOnEnter(event) {
      if (event.key === "Enter") {
        event.preventDefault();
        cancelPendingSearch();
        void runSearch();
      }
    }

    function serverIDFilter() {
      if (serverFilter.global || serverFilter.server_ids.length !== 1) {
        return null;
      }
      return serverFilter.server_ids[0];
    }

    function selectionKey(row) {
      return row.player_id + ":" + row.server_id;
    }

    function toggleSelection(row, checked) {
      if (checked && single) {
        selected.clear();
      }
      if (checked) {
        selected.set(selectionKey(row), { player_id: row.player_id, name: row.name, server_id: row.server_id });
      } else {
        selected.delete(selectionKey(row));
      }
      updateSummary();
      if (single) {
        renderOnline();
        renderSearch();
      }
    }

    function updateSummary() {
      summary.textContent = selected.size + " player(s) selected";
    }

    async function loadOnline(reset) {
      const ticket = ++onlineRequest;
      if (reset) {
        onlineRows = [];
        onlineAfter = "";
      }
      onlineStatus.textContent = reset ? "Loading live sessions…" : "Loading more…";
      const query = new URLSearchParams();
      query.set("limit", String(pageSize));
      const cursor = reset ? "" : onlineAfter;
      if (cursor !== "") {
        query.set("after", cursor);
      }
      const serverID = serverIDFilter();
      if (serverID !== null) {
        query.set("server_id", String(serverID));
      }
      const reply = await request(onlineRead + "?" + query.toString());
      if (ticket !== onlineRequest) {
        return;
      }
      if (reply.unauthorized) {
        return;
      }
      if (!reply.ok) {
        onlineStatus.textContent = describeReply(reply);
        return;
      }
      const body = reply.body && typeof reply.body === "object" ? reply.body : {};
      const sessions = Array.isArray(body.sessions) ? body.sessions : [];
      onlineRows = reset ? sessions : onlineRows.concat(sessions);
      onlineAfter = typeof body.next_after === "string" ? body.next_after : "";
      onlineStatus.textContent = onlineRows.length === 0 ? "No players are online." : "";
      loadMore.hidden = onlineAfter === "";
      renderOnline();
    }

    function renderOnline() {
      onlineTableHost.replaceChildren();
      if (onlineRows.length === 0) {
        return;
      }
      onlineTableHost.append(createPlayerTable(
        onlineRows,
        [
          { label: "player", text: (row) => row.name + " (#" + row.player_id + ")" },
          { label: "server", text: (row) => String(row.server_id) },
          { label: "online since", text: (row) => row.started_at },
        ],
        "player-online-select-all",
      ));
    }

    async function runSearch() {
      const ticket = ++searchRequest;
      const uid = uidInput.value.trim();
      const namePrefix = nameInput.value.trim();
      if (uid === "" && namePrefix === "") {
        searchRows = [];
        renderSearch();
        searchStatus.textContent = "Enter an account uid or a name prefix.";
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
      const serverID = serverIDFilter();
      if (serverID !== null) {
        query.set("server_id", String(serverID));
      }
      const reply = await request(findRead + "?" + query.toString());
      if (ticket !== searchRequest) {
        return;
      }
      if (reply.unauthorized) {
        return;
      }
      if (!reply.ok) {
        searchStatus.textContent = describeReply(reply);
        return;
      }
      const body = reply.body && typeof reply.body === "object" ? reply.body : {};
      const players = Array.isArray(body.players) ? body.players : [];
      searchRows = players.map((player) => ({
        player_id: player.player_id,
        name: player.name,
        server_id: player.logical_server_id,
        level: player.level,
      }));
      const truncated = body.truncated === true ? " Narrow the search to see the rest." : "";
      if (searchRows.length === 0) {
        const typed = namePrefix !== "" ? namePrefix : uid;
        searchStatus.textContent = 'No player matches "' + typed + '"';
      } else {
        searchStatus.textContent = "Matches found." + truncated;
      }
      renderSearch();
    }

    function renderSearch() {
      searchTableHost.replaceChildren();
      if (searchRows.length === 0) {
        return;
      }
      searchTableHost.append(createPlayerTable(
        searchRows,
        [
          { label: "player", text: (row) => row.name + " (#" + row.player_id + ")" },
          { label: "server", text: (row) => String(row.server_id) },
          { label: "level", text: (row) => String(row.level) },
        ],
        "player-search-select-all",
      ));
    }

    function createPlayerTable(rows, columns, selectAllIdentifier) {
      const table = document.createElement("table");
      table.className = "table table-sm table-vcenter mb-0";
      const head = document.createElement("thead");
      const headRow = document.createElement("tr");
      const selectAllCell = document.createElement("th");
      const selectAll = document.createElement("input");
      selectAll.type = "checkbox";
      selectAll.className = "form-check-input";
      selectAll.id = selectAllIdentifier;
      if (!single) {
        selectAllCell.append(selectAll);
      }
      headRow.append(selectAllCell);
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
        box.id = selectAllIdentifier + "-" + selectionKey(row);
        box.checked = selected.has(selectionKey(row));
        box.addEventListener("change", () => {
          toggleSelection(row, box.checked);
          refreshSelectAll();
        });
        checkCell.append(box);
        tableRow.append(checkCell);
        for (const column of columns) {
          const cell = document.createElement("td");
          cell.textContent = column.text(row);
          tableRow.append(cell);
        }
        body.append(tableRow);
        visible.push({ row, box });
      }
      function refreshSelectAll() {
        selectAll.checked = visible.length > 0 && visible.every((entry) => entry.box.checked);
      }
      selectAll.addEventListener("change", () => {
        for (const entry of visible) {
          entry.box.checked = selectAll.checked;
          toggleSelection(entry.row, selectAll.checked);
        }
      });
      refreshSelectAll();
      table.append(head, body);
      return table;
    }
  });
}

function tabButton(label, identifier) {
  const button = document.createElement("button");
  button.type = "button";
  button.className = "nav-link";
  button.id = identifier;
  button.textContent = label;
  return button;
}

function labeledInput(container, identifier, label, type) {
  const column = document.createElement("div");
  column.className = "col-md-6";
  const element = document.createElement("label");
  element.className = "form-label";
  element.htmlFor = identifier;
  element.textContent = label;
  const input = document.createElement("input");
  input.type = type;
  input.className = "form-control";
  input.id = identifier;
  column.append(element, input);
  container.append(column);
  return input;
}

function textParagraph(text) {
  const element = document.createElement("p");
  element.className = "module-help";
  element.textContent = text;
  return element;
}

function comparePlayers(left, right) {
  if (left.player_id !== right.player_id) {
    return left.player_id - right.player_id;
  }
  return left.server_id - right.server_id;
}
