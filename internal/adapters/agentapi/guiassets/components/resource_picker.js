"use strict";

import { describeReply, request } from "../transport.js";
import { actionButton, createModal, errorParagraph } from "./modal.js";
import { pictureElement } from "../pictures.js";

const catalogRead = "/agent/v1/reads/catalog.search";
const pageSize = 60;
// The backend's per-line grant cap (operatorgrant.DefaultLineCap,
// internal/application/operatorgrant/commands.go); a line above it is refused.
const maxLineAmount = 1000000;
const kindOptions = ["STACK_ITEM", "SCALAR_CURRENCY", "PLAYER_EXP", "TEMPORAL", "SPECIALIZED_DOMAIN", "PARTNER_ENTITY"];
const grantReasonTexts = {
  SPECIALIZED_DOMAIN: "not grantable yet: needs its own grant rules",
  OWNER_REQUIRED: "needs owner approval",
  FAIL_CLOSED: "not grantable yet: its content is not activated",
};

// openResourcePicker returns catalogue grant lines in the exact {id, amount}
// shape grant.items, mail.send attachments and redeem.create take.
export function openResourcePicker(options) {
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
      title: settings.title || "Resources",
      modalId: "resource-picker",
      wide: true,
      onClose: () => settle(null),
    });
    const selected = new Map();

    const fields = document.createElement("div");
    fields.className = "row g-2 mb-2";
    const searchInput = labeledControl(fields, "resource-search", "Name or id", "search");
    const categorySelect = labeledSelect(fields, "resource-category", "Category", [], "All");
    const kindSelect = labeledSelect(fields, "resource-kind", "Kind", kindOptions);
    const raritySelect = labeledSelect(fields, "resource-rarity", "Rarity", ["1", "2", "3", "4", "5", "6"]);
    fields.append(searchButtonCell(actionButton("Search", true, "resource-search-button")));
    const onlyGrantable = document.createElement("label");
    onlyGrantable.className = "form-check mb-2";
    const onlyGrantableBox = document.createElement("input");
    onlyGrantableBox.type = "checkbox";
    onlyGrantableBox.className = "form-check-input";
    onlyGrantableBox.id = "resource-only-grantable";
    onlyGrantableBox.checked = true;
    const onlyGrantableText = document.createElement("span");
    onlyGrantableText.className = "form-check-label";
    onlyGrantableText.textContent = "Only grantable";
    onlyGrantable.append(onlyGrantableBox, onlyGrantableText);

    const status = textParagraph("");
    status.id = "resource-status";
    const grid = document.createElement("div");
    grid.className = "resource-grid";
    grid.id = "resource-grid";
    const loadMore = actionButton("Load more results", false, "resource-load-more");
    loadMore.hidden = true;
    const summary = textParagraph("0 selected");
    const failure = errorParagraph();
    dialog.body.append(fields, onlyGrantable, status, grid, loadMore, summary, failure);

    let nextAfter = "";
    let requestTicket = 0;
    let contentRevision = "";

    searchInput.addEventListener("keydown", (event) => {
      if (event.key === "Enter") {
        event.preventDefault();
        void runSearch(true);
      }
    });
    categorySelect.addEventListener("change", () => void runSearch(true));
    kindSelect.addEventListener("change", () => void runSearch(true));
    raritySelect.addEventListener("change", () => void runSearch(true));
    onlyGrantableBox.addEventListener("change", applyGrantableFilter);
    loadMore.addEventListener("click", () => void runSearch(false));
    grid.addEventListener("click", (event) => {
      const card = event.target.closest(".resource-card");
      if (card === null || card.classList.contains("fail-closed")) {
        return;
      }
      if (event.target instanceof HTMLInputElement) {
        return;
      }
      const box = card.querySelector(".resource-select");
      box.checked = !box.checked;
      applySelection(card, box.checked);
    });

    const cancel = actionButton("Cancel", false, "resource-cancel");
    const confirm = actionButton("Use lines", true, "resource-confirm");
    cancel.addEventListener("click", () => dialog.close());
    confirm.addEventListener("click", () => {
      const lines = [];
      for (const [identifier, pick] of selected) {
        if (!Number.isInteger(pick.amount) || pick.amount <= 0 || pick.amount > maxLineAmount) {
          failure.textContent = "The amount of " + identifier + " must be a whole number from 1 to " + maxLineAmount + ".";
          return;
        }
        lines.push({ id: identifier, amount: pick.amount });
      }
      if (lines.length === 0) {
        failure.textContent = "Select at least one resource.";
        return;
      }
      lines.sort((left, right) => (left.id < right.id ? -1 : left.id > right.id ? 1 : 0));
      settle(lines);
      dialog.close();
    });
    dialog.footer.append(cancel, confirm);
    void runSearch(true);

    function updateSummary() {
      summary.textContent = selected.size + " selected";
    }

    async function runSearch(reset) {
      const ticket = ++requestTicket;
      if (reset) {
        nextAfter = "";
        grid.replaceChildren();
      }
      status.textContent = reset ? "Searching…" : "Loading more…";
      const query = new URLSearchParams();
      query.set("limit", String(pageSize));
      const category = categorySelect.value;
      if (category !== "") {
        query.set("category", category);
      }
      const kind = kindSelect.value;
      if (kind !== "") {
        query.set("kind", kind);
      }
      const rarity = raritySelect.value;
      if (rarity !== "") {
        query.set("rarity", rarity);
      }
      const text = searchInput.value.trim();
      if (text !== "") {
        query.set("query", text);
      }
      if (!reset && nextAfter !== "") {
        query.set("after", nextAfter);
      }
      const reply = await request(catalogRead + "?" + query.toString());
      if (ticket !== requestTicket) {
        return;
      }
      if (reply.unauthorized) {
        return;
      }
      if (!reply.ok) {
        status.textContent = describeReply(reply);
        return;
      }
      const body = reply.body && typeof reply.body === "object" ? reply.body : {};
      fillCategories(body.categories);
      const entries = Array.isArray(body.entries) ? body.entries : [];
      nextAfter = typeof body.next_after === "string" ? body.next_after : "";
      loadMore.hidden = nextAfter === "";
      for (const entry of entries) {
        grid.append(resourceCard(entry));
      }
      contentRevision = typeof body.content_revision === "string" && body.content_revision !== "" ? " · content " + body.content_revision.slice(0, 12) : "";
      applyGrantableFilter();
    }

    // The reply carries the whole document's item type buckets, so the select
    // fills from the same search and keeps "All" as the first choice.
    function fillCategories(categories) {
      if (categorySelect.dataset.filled === "yes" || !Array.isArray(categories) || categories.length === 0) {
        return;
      }
      const chosen = categorySelect.value;
      const all = document.createElement("option");
      all.value = "";
      all.textContent = "All";
      categorySelect.replaceChildren(all);
      for (const category of categories) {
        if (typeof category.item_type !== "number") {
          continue;
        }
        const option = document.createElement("option");
        option.value = String(category.item_type);
        const label = typeof category.label === "string" && category.label !== "" ? category.label : "Other (type " + category.item_type + ")";
        option.textContent = label + " (" + category.count + ")";
        categorySelect.append(option);
      }
      categorySelect.value = chosen;
      categorySelect.dataset.filled = "yes";
    }

    function applyGrantableFilter() {
      const only = onlyGrantableBox.checked;
      let visible = 0;
      for (const card of grid.querySelectorAll(".resource-card")) {
        const allowed = !only || card.dataset.grantable === "yes";
        card.hidden = !allowed;
        if (allowed) {
          visible += 1;
        }
      }
      status.textContent = visible === 0 ? "No resources match." : "Showing " + visible + " resources" + contentRevision;
    }

    function resourceCard(entry) {
      const card = document.createElement("div");
      card.className = "resource-card";
      card.dataset.id = entry.id;
      card.dataset.itemType = typeof entry.item_type === "number" ? String(entry.item_type) : "";
      const enabled = entry.grantable === "ENABLED";
      card.dataset.grantable = enabled ? "yes" : "no";
      if (!enabled) {
        card.classList.add("fail-closed");
        card.title = describeGrantReason(entry.reason);
      }
      const header = document.createElement("div");
      header.className = "d-flex align-items-center justify-content-between";
      const box = document.createElement("input");
      box.type = "checkbox";
      box.className = "form-check-input resource-select";
      box.disabled = !enabled;
      box.id = "resource-select-" + entry.id;
      box.addEventListener("change", () => applySelection(card, box.checked));
      header.append(box, pictureElement(entry.icon || ""));
      const name = document.createElement("div");
      name.className = "resource-name";
      name.textContent = entry.name === "" ? entry.id : entry.name;
      const meta = document.createElement("div");
      meta.className = "resource-meta";
      const details = [entry.id, entry.kind];
      if (typeof entry.category === "string" && entry.category !== "") {
        details.push(entry.category);
      }
      if (entry.rarity) {
        details.push(entry.rarity + "★");
      }
      if (typeof entry.stack_cap === "number" && entry.stack_cap > 0) {
        details.push("stack holds " + entry.stack_cap);
      }
      meta.textContent = details.join(" · ");
      const amount = document.createElement("input");
      amount.type = "number";
      amount.className = "form-control resource-amount";
      amount.min = "1";
      amount.max = String(maxLineAmount);
      amount.step = "1";
      amount.value = "1";
      amount.disabled = true;
      amount.setAttribute("aria-label", "Amount of " + entry.id);
      amount.addEventListener("input", () => {
        const pick = selected.get(entry.id);
        if (pick !== undefined) {
          pick.amount = Number(amount.value);
        }
      });
      card.append(header, name, meta, amount);
      if (!enabled) {
        const reason = document.createElement("div");
        reason.className = "resource-meta text-danger";
        reason.textContent = describeGrantReason(entry.reason);
        card.append(reason);
      }
      return card;
    }

    function applySelection(card, checked) {
      const box = card.querySelector(".resource-select");
      const amount = card.querySelector(".resource-amount");
      const identifier = card.dataset.id;
      if (checked) {
        const existing = Number(amount.value);
        selected.set(identifier, { amount: Number.isInteger(existing) && existing > 0 ? existing : 1 });
        amount.disabled = false;
        card.classList.add("selected");
      } else {
        selected.delete(identifier);
        amount.disabled = true;
        card.classList.remove("selected");
      }
      box.checked = checked;
      updateSummary();
    }
  });
}

function labeledControl(container, identifier, label, type) {
  const column = document.createElement("div");
  column.className = "col-md-5";
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

function labeledSelect(container, identifier, label, values, anyLabel) {
  const column = document.createElement("div");
  column.className = "col-md-3";
  const element = document.createElement("label");
  element.className = "form-label";
  element.htmlFor = identifier;
  element.textContent = label;
  const select = document.createElement("select");
  select.className = "form-select";
  select.id = identifier;
  const any = document.createElement("option");
  any.value = "";
  any.textContent = anyLabel || "any";
  select.append(any);
  for (const value of values) {
    const option = document.createElement("option");
    option.value = value;
    option.textContent = value;
    select.append(option);
  }
  column.append(element, select);
  container.append(column);
  return select;
}

function searchButtonCell(button) {
  const column = document.createElement("div");
  column.className = "col-md-2 d-flex align-items-end";
  column.append(button);
  return column;
}

function textParagraph(text) {
  const element = document.createElement("p");
  element.className = "module-help";
  element.textContent = text;
  return element;
}

// The catalogue sends a class or activation code (SPECIALIZED_DOMAIN,
// OWNER_REQUIRED, FAIL_CLOSED); the picker spells out what it means (G25).
function describeGrantReason(code) {
  if (typeof code !== "string" || code === "") {
    return "not grantable yet";
  }
  const text = Object.prototype.hasOwnProperty.call(grantReasonTexts, code) ? grantReasonTexts[code] : "not grantable yet";
  return text + " (" + code + ")";
}
