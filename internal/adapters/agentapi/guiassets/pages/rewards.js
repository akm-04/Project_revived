"use strict";

import { describeReply, request } from "../transport.js";
import { confirmAction } from "../components/confirm_action.js";
import { openDurationPicker } from "../components/duration_picker.js";
import { openPlayerPicker } from "../components/player_picker.js";
import { openResourcePicker } from "../components/resource_picker.js";

const commandGrantItems = "grant.items";
const commandRedeemCreate = "redeem.create";
const commandRedeemDisable = "redeem.disable";
const redeemListLimit = 200;

// Rewards and Redeem (M8, M4): a grant to selected players (grant.items) and
// the redeem codes the redeem module declares (internal/application/operatorgrant/redeem.go).
export function renderPage(container, context) {
  container.replaceChildren();
  container.setAttribute("aria-label", context.page.label);

  const state = {
    grantPlayers: [],
    grantLines: [],
    redeemLines: [],
    redeemExpiry: null,
    codes: [],
  };

  const codesCard = createCard("Redeem codes", "rewards-overview");
  const refreshCodes = actionButton("Refresh codes", false, "redeem-refresh");
  const codesStatus = errorParagraph();
  codesStatus.id = "redeem-list-result";
  const codesHost = document.createElement("div");
  codesHost.id = "redeem-list";
  codesCard.body.append(refreshCodes, codesStatus, codesHost);

  const grantCard = createCard("Grant", "grant-card");
  const pickGrantPlayers = actionButton("Choose players", false, "grant-pick-players");
  const grantPlayersSummary = paragraph("hint", "No players selected.");
  grantPlayersSummary.id = "grant-players-selected";
  const pickGrantLines = actionButton("Choose resources", false, "grant-pick-resources");
  const grantLinesSummary = paragraph("hint", "No resource lines.");
  grantLinesSummary.id = "grant-lines-selected";
  const grantButton = actionButton("Grant resources", true, "grant-submit");
  const grantResult = errorParagraph();
  grantResult.id = "grant-result";
  grantCard.body.append(pickGrantPlayers, grantPlayersSummary, pickGrantLines, grantLinesSummary, grantButton, grantResult);

  const createCardView = createCard("Create a redeem code", "redeem-create-card");
  const codeInput = createInput(createCardView.body, "redeem-code", "Code (optional; generated when empty)", "text");
  codeInput.maxLength = 256;
  const pickRedeemLines = actionButton("Choose rewards", false, "redeem-pick-resources");
  const redeemLinesSummary = paragraph("hint", "No reward lines.");
  redeemLinesSummary.id = "redeem-lines-selected";
  const pickRedeemExpiry = actionButton("Choose expiry (optional)", false, "redeem-expiry");
  const redeemExpirySummary = paragraph("hint", "No expiry; the code stays usable until disabled.");
  redeemExpirySummary.id = "redeem-expiry-selected";
  const totalCapInput = createInput(createCardView.body, "redeem-total-cap", "Total uses over all players (optional)", "number");
  totalCapInput.min = "1";
  totalCapInput.step = "1";
  const createButton = actionButton("Create code", true, "redeem-create");
  const createResult = errorParagraph();
  createResult.id = "redeem-create-result";
  createCardView.body.append(pickRedeemLines, redeemLinesSummary, pickRedeemExpiry, redeemExpirySummary, createButton, createResult);

  const disableCard = createCard("Disable a redeem code", "redeem-disable-card");
  const disableSelect = createSelect(disableCard.body, "redeem-disable-select", "Active code", []);
  const disableButton = actionButton("Disable code", true, "redeem-disable");
  const disableResult = errorParagraph();
  disableResult.id = "redeem-disable-result";
  disableCard.body.append(disableButton, disableResult);

  container.append(codesCard.card, grantCard.card, createCardView.card, disableCard.card);

  refreshCodes.addEventListener("click", loadCodes);
  pickGrantPlayers.addEventListener("click", chooseGrantPlayers);
  pickGrantLines.addEventListener("click", chooseGrantLines);
  grantButton.addEventListener("click", grant);
  pickRedeemLines.addEventListener("click", chooseRedeemLines);
  pickRedeemExpiry.addEventListener("click", chooseRedeemExpiry);
  createButton.addEventListener("click", createRedeemCode);
  disableButton.addEventListener("click", disableRedeemCode);

  loadCodes();

  async function loadCodes() {
    codesStatus.textContent = "";
    const reply = await request("/agent/v1/reads/redeem.list?limit=" + redeemListLimit);
    if (reply.unauthorized) {
      return;
    }
    if (!reply.ok) {
      codesStatus.textContent = describeReply(reply);
      renderCodes([]);
      return;
    }
    const body = reply.body && typeof reply.body === "object" ? reply.body : {};
    state.codes = Array.isArray(body.entries) ? body.entries : [];
    renderCodes(state.codes);
  }

  function renderCodes(entries) {
    codesHost.replaceChildren();
    const active = entries.filter((entry) => entry.state === "ACTIVE");
    disableSelect.replaceChildren();
    const blank = document.createElement("option");
    blank.value = "";
    blank.textContent = active.length === 0 ? "No active codes" : "choose one";
    disableSelect.append(blank);
    for (const entry of active) {
      const option = document.createElement("option");
      option.value = entry.code;
      option.textContent = entry.code;
      disableSelect.append(option);
    }
    if (entries.length === 0) {
      codesHost.append(paragraph("hint mb-0", "No redeem codes."));
      return;
    }
    const table = document.createElement("table");
    table.className = "table table-sm table-vcenter mb-0";
    const head = document.createElement("thead");
    const headRow = document.createElement("tr");
    for (const label of ["code", "state", "used", "total cap", "ends at", "reward lines"]) {
      const cell = document.createElement("th");
      cell.textContent = label;
      headRow.append(cell);
    }
    head.append(headRow);
    const body = document.createElement("tbody");
    for (const entry of entries) {
      const row = document.createElement("tr");
      const values = [
        entry.code,
        entry.state,
        String(entry.used_count),
        entry.total_cap === null || entry.total_cap === undefined ? "none" : String(entry.total_cap),
        entry.ends_at === null || entry.ends_at === undefined ? "none" : String(entry.ends_at),
        describeLines(Array.isArray(entry.lines) ? entry.lines : []),
      ];
      for (const value of values) {
        const cell = document.createElement("td");
        cell.textContent = value;
        row.append(cell);
      }
      body.append(row);
    }
    table.append(head, body);
    codesHost.append(table);
  }

  async function chooseGrantPlayers() {
    const players = await openPlayerPicker({ title: "Grant recipients" });
    if (players === null) {
      return;
    }
    state.grantPlayers = players;
    grantPlayersSummary.textContent = players.length + " player(s) selected.";
  }

  async function chooseGrantLines() {
    const lines = await openResourcePicker({ title: "Grant resources" });
    if (lines === null) {
      return;
    }
    state.grantLines = lines;
    grantLinesSummary.textContent = describeLines(lines);
  }

  async function grant() {
    grantResult.textContent = "";
    if (state.grantPlayers.length === 0) {
      grantResult.textContent = "Select at least one player.";
      return;
    }
    if (state.grantLines.length === 0) {
      grantResult.textContent = "Select at least one resource line.";
      return;
    }
    const confirmation = await confirmAction({
      title: "Grant resources",
      summary: "Grant " + describeLines(state.grantLines) + " to " + state.grantPlayers.length + " player(s).",
      confirmLabel: "Grant",
    });
    if (confirmation === null) {
      return;
    }
    grantButton.disabled = true;
    const reply = await request("/agent/v1/commands/" + encodeURIComponent(commandGrantItems), {
      method: "POST",
      body: {
        reason: confirmation.reason,
        semantic_key: confirmation.semantic_key,
        payload: {
          target: { player_ids: state.grantPlayers.map((player) => player.player_id) },
          lines: state.grantLines,
        },
      },
    });
    grantButton.disabled = false;
    if (reply.unauthorized) {
      return;
    }
    grantResult.textContent = describeBulkReply(reply) + "\nreason: " + confirmation.reason;
  }

  async function chooseRedeemLines() {
    const lines = await openResourcePicker({ title: "Redeem rewards" });
    if (lines === null) {
      return;
    }
    state.redeemLines = lines;
    redeemLinesSummary.textContent = describeLines(lines);
  }

  async function chooseRedeemExpiry() {
    const duration = await openDurationPicker({ title: "Redeem code expiry" });
    if (duration === null) {
      return;
    }
    state.redeemExpiry = duration.end;
    redeemExpirySummary.textContent = "Expires at " + duration.end + ".";
  }

  async function createRedeemCode() {
    createResult.textContent = "";
    if (state.redeemLines.length === 0) {
      createResult.textContent = "Select at least one reward line.";
      return;
    }
    const totalCapText = totalCapInput.value.trim();
    let totalCap;
    if (totalCapText !== "") {
      totalCap = Number(totalCapText);
      if (!Number.isInteger(totalCap) || totalCap < 1) {
        createResult.textContent = "The total use cap must be a positive whole number.";
        return;
      }
    }
    const confirmation = await confirmAction({
      title: "Create redeem code",
      summary: "Create a code for " + describeLines(state.redeemLines) + " with " +
        (state.redeemExpiry === null ? "no expiry" : "expiry " + state.redeemExpiry) + ".",
      confirmLabel: "Create code",
    });
    if (confirmation === null) {
      return;
    }
    const payload = { lines: state.redeemLines };
    const code = codeInput.value.trim();
    if (code !== "") {
      payload.code = code;
    }
    if (state.redeemExpiry !== null) {
      payload.expires_at = state.redeemExpiry;
    }
    if (totalCap !== undefined) {
      payload.total_cap = totalCap;
    }
    createButton.disabled = true;
    const reply = await request("/agent/v1/commands/" + encodeURIComponent(commandRedeemCreate), {
      method: "POST",
      body: { reason: confirmation.reason, semantic_key: confirmation.semantic_key, payload },
    });
    createButton.disabled = false;
    if (reply.unauthorized) {
      return;
    }
    createResult.textContent = describeRedeemReply(reply) + "\nreason: " + confirmation.reason;
    if (reply.ok) {
      await loadCodes();
    }
  }

  async function disableRedeemCode() {
    disableResult.textContent = "";
    const code = disableSelect.value;
    if (code === "") {
      disableResult.textContent = "Select an active code.";
      return;
    }
    const confirmation = await confirmAction({
      title: "Disable redeem code",
      summary: "Disable the code " + code + "; no player can use it afterwards.",
      confirmLabel: "Disable code",
    });
    if (confirmation === null) {
      return;
    }
    disableButton.disabled = true;
    const reply = await request("/agent/v1/commands/" + encodeURIComponent(commandRedeemDisable), {
      method: "POST",
      body: { reason: confirmation.reason, semantic_key: confirmation.semantic_key, payload: { code } },
    });
    disableButton.disabled = false;
    if (reply.unauthorized) {
      return;
    }
    disableResult.textContent = describeRedeemReply(reply) + "\nreason: " + confirmation.reason;
    if (reply.ok) {
      await loadCodes();
    }
  }
}

function describeBulkReply(reply) {
  if (!reply.ok) {
    return describeReply(reply);
  }
  const body = reply.body && typeof reply.body === "object" ? reply.body : {};
  const result = body.result && typeof body.result === "object" ? body.result : {};
  const parts = ["state " + (typeof body.state === "string" && body.state !== "" ? body.state : "unknown")];
  if (result.bulk === true) {
    parts.push("bulk job " + (typeof result.semantic_key === "string" ? result.semantic_key : "unknown"));
  }
  if (Number.isInteger(result.player_count)) {
    parts.push(result.player_count + " recipient(s)");
  }
  if (Number.isInteger(result.applied)) {
    parts.push(result.applied + " applied");
  }
  if (Number.isInteger(result.refused) && result.refused > 0) {
    parts.push(result.refused + " refused");
  }
  return parts.join(", ");
}

function describeRedeemReply(reply) {
  if (!reply.ok) {
    return describeReply(reply);
  }
  const body = reply.body && typeof reply.body === "object" ? reply.body : {};
  const result = body.result && typeof body.result === "object" ? body.result : {};
  const parts = ["state " + (typeof body.state === "string" && body.state !== "" ? body.state : "unknown")];
  if (typeof result.code === "string" && result.code !== "") {
    parts.push("code " + result.code);
  }
  if (typeof result.state === "string" && result.state !== "") {
    parts.push("code state " + result.state);
  }
  if (typeof result.expires_at === "string" && result.expires_at !== "") {
    parts.push("expires " + result.expires_at);
  }
  if (result.total_cap !== undefined && result.total_cap !== null) {
    parts.push("total cap " + result.total_cap);
  }
  return parts.join(", ");
}

function describeLines(lines) {
  return lines.map((line) => line.id + " x" + line.amount).join(", ");
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

function createInput(parent, identifier, label, type) {
  const wrapper = document.createElement("div");
  wrapper.className = "mb-3";
  const labelElement = document.createElement("label");
  labelElement.className = "form-label";
  labelElement.htmlFor = identifier;
  labelElement.textContent = label;
  const input = document.createElement("input");
  input.type = type;
  input.className = "form-control";
  input.id = identifier;
  wrapper.append(labelElement, input);
  parent.append(wrapper);
  return input;
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
