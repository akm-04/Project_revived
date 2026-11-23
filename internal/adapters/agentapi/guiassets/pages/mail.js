"use strict";

import { describeReply, request } from "../transport.js";
import { confirmAction } from "../components/confirm_action.js";
import { openDurationPicker } from "../components/duration_picker.js";
import { openPlayerPicker } from "../components/player_picker.js";
import { openResourcePicker } from "../components/resource_picker.js";
import { mountServerPicker } from "../components/server_picker.js";

const commandMailSend = "mail.send";
const maximumAfterReadDays = 36500;
const secondsPerDay = 86400;

// Mail (M1, M11, G10): recipients from the shared pickers, custom title, body,
// sender, attachments and the three delivery expiry forms mail.send declares
// (internal/application/operatorgrant/mail.go:53-66).
export function renderPage(container, context) {
  container.replaceChildren();
  container.setAttribute("aria-label", context.page.label);

  const state = {
    players: [],
    attachments: [],
    expiry: null,
    serverPicker: null,
  };

  const overview = createCard("Mail overview", "mail-overview");
  const overviewText = paragraph("hint mb-0", "");
  overviewText.id = "mail-overview-text";
  overview.body.append(overviewText);

  const targetCard = createCard("Recipients", "mail-target");
  const modeSelect = createSelect(targetCard.body, "mail-target-mode", "Target", [
    { value: "players", label: "Selected players" },
    { value: "servers", label: "Servers or global" },
  ]);
  const playersSection = document.createElement("div");
  const pickPlayers = actionButton("Choose players", false, "mail-pick-players");
  const playersSummary = paragraph("hint", "No players selected.");
  playersSummary.id = "mail-players-selected";
  playersSection.append(pickPlayers, playersSummary);
  const serversSection = document.createElement("div");
  serversSection.hidden = true;
  const serverPickerHost = document.createElement("div");
  serverPickerHost.id = "mail-server-picker";
  serversSection.append(serverPickerHost);
  targetCard.body.append(playersSection, serversSection);

  const contentCard = createCard("Mail content", "mail-content");
  const senderInput = createInput(contentCard.body, "mail-sender", "Sender (optional, default GM)", "text");
  senderInput.maxLength = 64;
  const titleInput = createInput(contentCard.body, "mail-title", "Title", "text");
  titleInput.maxLength = 64;
  const bodyInput = createTextarea(contentCard.body, "mail-body", "Body");
  bodyInput.maxLength = 2000;

  const attachmentCard = createCard("Attachments", "mail-attachments");
  const pickAttachments = actionButton("Choose attachments", false, "mail-pick-attachments");
  const attachmentSummary = paragraph("hint", "No attachments.");
  attachmentSummary.id = "mail-attachments-selected";
  attachmentCard.body.append(pickAttachments, attachmentSummary);

  const expiryCard = createCard("Expiry", "mail-expiry-card");
  const expiryMode = createSelect(expiryCard.body, "mail-expiry-mode", "Expiry form", [
    { value: "fixed", label: "Fixed time" },
    { value: "after_read", label: "Days after opening" },
    { value: "on_read", label: "As soon as opened" },
  ]);
  const fixedSection = document.createElement("div");
  const pickExpiry = actionButton("Choose fixed expiry", false, "mail-expiry");
  const fixedSummary = paragraph("hint", "No expiry chosen.");
  fixedSummary.id = "mail-expiry-selected";
  fixedSection.append(pickExpiry, fixedSummary);
  const afterReadSection = document.createElement("div");
  afterReadSection.hidden = true;
  const afterReadDays = createInput(afterReadSection, "mail-after-read-days", "Delete this many days after opening", "number");
  afterReadDays.min = "1";
  afterReadDays.max = String(maximumAfterReadDays);
  afterReadDays.step = "1";
  const onReadSection = document.createElement("div");
  onReadSection.hidden = true;
  onReadSection.append(paragraph("hint mb-0", "The mail is deleted as soon as the player opens it."));
  expiryCard.body.append(fixedSection, afterReadSection, onReadSection);

  const sendCard = createCard("Send", "mail-send-card");
  const sendButton = actionButton("Send mail", true, "mail-send");
  const sendResult = errorParagraph();
  sendResult.id = "mail-result";
  sendCard.body.append(sendButton, sendResult);

  container.append(overview.card, targetCard.card, contentCard.card, attachmentCard.card, expiryCard.card, sendCard.card);

  modeSelect.addEventListener("change", () => updateTargetMode());
  pickPlayers.addEventListener("click", choosePlayers);
  pickAttachments.addEventListener("click", chooseAttachments);
  pickExpiry.addEventListener("click", chooseFixedExpiry);
  expiryMode.addEventListener("change", updateExpiryMode);
  expiryMode.addEventListener("change", updateOverview);
  afterReadDays.addEventListener("input", updateOverview);
  senderInput.addEventListener("input", updateOverview);
  titleInput.addEventListener("input", updateOverview);
  sendButton.addEventListener("click", sendMail);

  updateTargetMode();
  updateExpiryMode();
  updateOverview();

  function updateTargetMode() {
    const servers = modeSelect.value === "servers";
    playersSection.hidden = servers;
    serversSection.hidden = !servers;
    if (servers) {
      ensureServerPicker();
    }
    updateOverview();
  }

  function ensureServerPicker() {
    if (state.serverPicker !== null) {
      return;
    }
    state.serverPicker = mountServerPicker(serverPickerHost, {
      includeGlobal: true,
      multiple: true,
      idPrefix: "mail-server",
      onChange: updateOverview,
    });
  }

  function updateExpiryMode() {
    const mode = expiryMode.value;
    fixedSection.hidden = mode !== "fixed";
    afterReadSection.hidden = mode !== "after_read";
    onReadSection.hidden = mode !== "on_read";
  }

  async function choosePlayers() {
    const players = await openPlayerPicker({ title: "Mail recipients" });
    if (players === null) {
      return;
    }
    state.players = players;
    playersSummary.textContent = players.length + " player(s) selected.";
    updateOverview();
  }

  async function chooseAttachments() {
    const lines = await openResourcePicker({ title: "Mail attachments" });
    if (lines === null) {
      return;
    }
    state.attachments = lines;
    attachmentSummary.textContent = describeLines(lines);
    updateOverview();
  }

  async function chooseFixedExpiry() {
    const duration = await openDurationPicker({ title: "Mail expiry" });
    if (duration === null) {
      return;
    }
    state.expiry = duration.end;
    fixedSummary.textContent = "Expires at " + duration.end + ".";
    updateOverview();
  }

  function currentExpire() {
    const mode = expiryMode.value;
    if (mode === "fixed") {
      if (state.expiry === null) {
        return { error: "Choose a fixed expiry time." };
      }
      return { expire: { fixed: state.expiry } };
    }
    if (mode === "after_read") {
      const days = Number(afterReadDays.value);
      if (!Number.isInteger(days) || days < 1 || days > maximumAfterReadDays) {
        return { error: "Enter a whole number of days from 1 to " + maximumAfterReadDays + "." };
      }
      return { expire: { after_read: days * secondsPerDay } };
    }
    return { expire: { on_read: true } };
  }

  function describeTarget() {
    if (modeSelect.value === "players") {
      return state.players.length + " player(s)";
    }
    if (state.serverPicker === null) {
      return "no server selected";
    }
    const value = state.serverPicker.value();
    if (value.global) {
      return "every player (global)";
    }
    if (value.server_ids.length === 0) {
      return "no server selected";
    }
    return "server(s) " + value.server_ids.map((serverID) => "#" + serverID).join(", ");
  }

  function updateOverview() {
    const expire = currentExpire();
    const expiryText = expire.error ? "not set" : describeExpire(expire.expire);
    overviewText.textContent =
      "Recipients: " + describeTarget() +
      " · Attachments: " + (state.attachments.length === 0 ? "none" : describeLines(state.attachments)) +
      " · Expiry: " + expiryText;
  }

  async function sendMail() {
    sendResult.textContent = "";
    if (titleInput.value.trim() === "") {
      sendResult.textContent = "Enter a mail title.";
      return;
    }
    if (bodyInput.value.trim() === "") {
      sendResult.textContent = "Enter a mail body.";
      return;
    }
    const expire = currentExpire();
    if (expire.error) {
      sendResult.textContent = expire.error;
      return;
    }
    const targets = collectTargets();
    if (targets.error) {
      sendResult.textContent = targets.error;
      return;
    }
    const confirmation = await confirmAction({
      title: "Send mail",
      summary: "Send \"" + titleInput.value.trim() + "\" to " + describeTarget() +
        " with " + (state.attachments.length === 0 ? "no attachments" : state.attachments.length + " attachment line(s)") +
        " and expiry " + describeExpire(expire.expire) + ".",
      confirmLabel: "Send mail",
    });
    if (confirmation === null) {
      return;
    }
    sendButton.disabled = true;
    const outcomes = [];
    for (let index = 0; index < targets.entries.length; index += 1) {
      const entry = targets.entries[index];
      const payload = {
        target: entry.target,
        title: titleInput.value.trim(),
        body: bodyInput.value.trim(),
        expire: expire.expire,
      };
      const sender = senderInput.value.trim();
      if (sender !== "") {
        payload.sender = sender;
      }
      if (state.attachments.length > 0) {
        payload.attachments = state.attachments;
      }
      const semanticKey = targets.entries.length === 1
        ? confirmation.semantic_key
        : confirmation.semantic_key + "-" + index;
      const reply = await request("/agent/v1/commands/" + encodeURIComponent(commandMailSend), {
        method: "POST",
        body: { reason: confirmation.reason, semantic_key: semanticKey, payload },
      });
      if (reply.unauthorized) {
        sendButton.disabled = false;
        return;
      }
      outcomes.push(entry.label + ": " + describeMailReply(reply));
    }
    sendButton.disabled = false;
    sendResult.textContent = (targets.entries.length > 1 ? "One command per selected server.\n" : "") +
      outcomes.join("\n") + "\nreason: " + confirmation.reason;
  }

  function collectTargets() {
    if (modeSelect.value === "players") {
      if (state.players.length === 0) {
        return { error: "Select at least one player." };
      }
      return {
        entries: [{
          label: state.players.length + " player(s)",
          target: { player_ids: state.players.map((player) => player.player_id) },
        }],
      };
    }
    if (state.serverPicker === null) {
      return { error: "The server list has not loaded yet." };
    }
    const value = state.serverPicker.value();
    if (value.global) {
      return { entries: [{ label: "global", target: { global: true } }] };
    }
    if (value.server_ids.length === 0) {
      return { error: "Select at least one server or Global." };
    }
    return {
      entries: value.server_ids.map((serverID) => ({
        label: "server #" + serverID,
        target: { server_id: serverID },
      })),
    };
  }
}

function describeExpire(expire) {
  if (expire.fixed !== undefined) {
    return "fixed at " + expire.fixed;
  }
  if (expire.after_read !== undefined) {
    return expire.after_read / secondsPerDay + " day(s) after opening";
  }
  return "as soon as opened";
}

function describeLines(lines) {
  return lines.map((line) => line.id + " x" + line.amount).join(", ");
}

function describeMailReply(reply) {
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

function createTextarea(parent, identifier, label) {
  const wrapper = document.createElement("div");
  wrapper.className = "mb-3";
  const labelElement = document.createElement("label");
  labelElement.className = "form-label";
  labelElement.htmlFor = identifier;
  labelElement.textContent = label;
  const input = document.createElement("textarea");
  input.className = "form-control";
  input.id = identifier;
  input.rows = 6;
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
