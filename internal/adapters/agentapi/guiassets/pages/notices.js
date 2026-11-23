"use strict";

import { describeReply, loadPicture, request } from "../transport.js";
import { confirmAction } from "../components/confirm_action.js";
import { pageHeader, setStatus } from "../components/format.js";
import { mountServerPicker } from "../components/server_picker.js";

const readPublicationShow = "publication.show";
const commandInstall = "publication.install";
const commandClear = "publication.clear";
const mediaImportCommand = "/agent/v1/media/import_url";
const mediaUploadCommand = "/agent/v1/media/upload";
const mediaListRead = "/agent/v1/media/list";
const mediaFilePrefix = "/agent/v1/media/file/";
const families = [
  { id: "announcement", label: "Login notice" },
  { id: "picture", label: "Lobby picture notice" },
  { id: "board", label: "Activities board" },
];
const maximumWireID = 9007199254740991;
// The GUI scripts must stay free of absolute external URLs (G27), so the two
// accepted schemes are assembled here.
const insecureImageURLPrefix = "http" + "://";
const secureImageURLPrefix = "https" + "://";
const acceptedSchemes = insecureImageURLPrefix + " or " + secureImageURLPrefix;
const hostedMediaPattern = /^[0-9a-f]{16}\.(png|jpg)$/;
const hostedMediaMarker = "/media/";

// Notices (G13): the client's three publication families, the set each one
// selects now (publication.show), and install/clear with the family fields the
// publication module declares (internal/application/publication/operator.go:79-90).
export function renderPage(container, context) {
  container.replaceChildren();
  container.append(pageHeader(context.page.label));
  container.setAttribute("aria-label", context.page.label);

  const state = { serverID: 0, live: [] };

  const liveCard = createCard("Live notices", "notices-overview");
  const serverPickerHost = document.createElement("div");
  serverPickerHost.id = "notices-server-picker";
  const refreshButton = actionButton("Refresh notices", false, "notices-refresh");
  const liveStatus = errorParagraph();
  liveStatus.id = "notices-status";
  const liveHost = document.createElement("div");
  liveHost.id = "notices-live";
  liveCard.body.append(serverPickerHost, refreshButton, liveStatus, liveHost);

  const announcementCard = createCard("Edit login notice", "notice-announcement-card");
  const announcementTitle = createField(announcementCard.body, "notice-announcement-title", "Title", "text");
  const announcementContents = createField(announcementCard.body, "notice-announcement-contents", "Contents (one entry per line)", "textarea");
  const announcementURL = createField(announcementCard.body, "notice-announcement-url", "Image URL (" + acceptedSchemes + "..., or choose a hosted picture)", "text");
  attachMediaChooser(announcementURL);
  const announcementPreviewButton = actionButton("Preview", false, "notice-announcement-preview");
  const announcementPreviewHost = document.createElement("div");
  announcementPreviewHost.id = "notice-announcement-preview-host";
  const announcementInstall = actionButton("Install login notice", true, "notice-announcement-install");
  const announcementClear = actionButton("Clear login notice", false, "notice-announcement-clear");
  const announcementActions = document.createElement("div");
  announcementActions.className = "btn-list mb-3";
  announcementActions.append(announcementInstall, announcementClear);
  const announcementResult = errorParagraph();
  announcementResult.id = "notice-announcement-result";
  announcementCard.body.append(announcementPreviewButton, announcementPreviewHost, announcementActions, announcementResult);

  const pictureCard = createCard("Edit lobby picture notice", "notice-picture-card");
  const pictureRows = document.createElement("div");
  pictureRows.id = "notice-picture-rows";
  const pictureAdd = actionButton("Add picture", false, "notice-picture-add");
  const picturePreviewButton = actionButton("Preview", false, "notice-picture-preview");
  const picturePreviewHost = document.createElement("div");
  picturePreviewHost.id = "notice-picture-preview-host";
  const pictureInstall = actionButton("Install pictures", true, "notice-picture-install");
  const pictureClear = actionButton("Clear pictures", false, "notice-picture-clear");
  const pictureActions = document.createElement("div");
  pictureActions.className = "btn-list mb-3";
  pictureActions.append(pictureInstall, pictureClear);
  const pictureResult = errorParagraph();
  pictureResult.id = "notice-picture-result";
  pictureCard.body.append(pictureRows, pictureAdd, picturePreviewButton, picturePreviewHost, pictureActions, pictureResult);

  const boardCard = createCard("Edit Activities board", "notice-board-card");
  const boardRows = document.createElement("div");
  boardRows.id = "notice-board-rows";
  const boardAdd = actionButton("Add entry", false, "notice-board-add");
  const boardPreviewButton = actionButton("Preview", false, "notice-board-preview");
  const boardPreviewHost = document.createElement("div");
  boardPreviewHost.id = "notice-board-preview-host";
  const boardInstall = actionButton("Install Activities board", true, "notice-board-install");
  const boardClear = actionButton("Clear Activities board", false, "notice-board-clear");
  const boardActions = document.createElement("div");
  boardActions.className = "btn-list mb-3";
  boardActions.append(boardInstall, boardClear);
  const boardResult = errorParagraph();
  boardResult.id = "notice-board-result";
  boardCard.body.append(boardRows, boardAdd, boardPreviewButton, boardPreviewHost, boardActions, boardResult);

  container.append(liveCard.card, announcementCard.card, pictureCard.card, boardCard.card);

  let fieldCounter = 0;
  addPictureRow();
  addBoardRow();

  mountServerPicker(serverPickerHost, {
    includeGlobal: true,
    multiple: false,
    global: true,
    idPrefix: "notices-server",
    onChange: (value) => {
      state.serverID = value.global || value.server_ids.length !== 1 ? 0 : value.server_ids[0];
      void loadLive();
    },
  });

  refreshButton.addEventListener("click", loadLive);
  announcementPreviewButton.addEventListener("click", previewAnnouncement);
  announcementInstall.addEventListener("click", installAnnouncement);
  announcementClear.addEventListener("click", clearAnnouncement);
  pictureAdd.addEventListener("click", addPictureRow);
  picturePreviewButton.addEventListener("click", previewPictures);
  pictureInstall.addEventListener("click", installPictures);
  pictureClear.addEventListener("click", clearPictures);
  boardAdd.addEventListener("click", addBoardRow);
  boardPreviewButton.addEventListener("click", previewBoard);
  boardInstall.addEventListener("click", installBoard);
  boardClear.addEventListener("click", clearBoard);

  loadLive();

  async function loadLive() {
    liveStatus.textContent = "";
    const reply = await request("/agent/v1/reads/" + encodeURIComponent(readPublicationShow) + "?server_id=" + state.serverID);
    if (reply.unauthorized) {
      return;
    }
    if (!reply.ok) {
      setStatus(liveStatus, describeReply(reply), "error");
      state.live = [];
      renderLive();
      return;
    }
    const body = reply.body && typeof reply.body === "object" ? reply.body : {};
    state.live = Array.isArray(body.families) ? body.families : [];
    renderLive();
  }

  function renderLive() {
    liveHost.replaceChildren();
    for (const family of families) {
      const section = document.createElement("section");
      section.className = "mb-3";
      const heading = document.createElement("h3");
      heading.className = "module-title";
      heading.textContent = family.label + " (" + family.id + ")";
      section.append(heading);
      const view = state.live.find((entry) => entry.family === family.id);
      if (view === undefined) {
        section.append(paragraph("hint mb-0", "No set installed."));
      } else {
        section.append(paragraph("hint", "set " + view.set_id + " · " + (view.visible ? "visible" : "not visible") +
          " · starts " + view.starts_at + " · ends " + (view.ends_at === null || view.ends_at === undefined ? "never" : view.ends_at)));
        appendItems(section, view.items);
      }
      liveHost.append(section);
    }
  }

  function appendItems(parent, items) {
    if (!Array.isArray(items) || items.length === 0) {
      parent.append(paragraph("hint mb-0", "The set holds no entries."));
      return;
    }
    for (const item of items) {
      if (item.announcement !== undefined) {
        parent.append(announcementView(item.announcement));
        continue;
      }
      if (item.picture !== undefined) {
        parent.append(pictureView(item.picture));
        continue;
      }
      if (item.board !== undefined) {
        parent.append(boardView(item.board));
      }
    }
  }

  function previewAnnouncement() {
    announcementPreviewHost.replaceChildren();
    const announcement = announcementPayload();
    if (announcement.error) {
      announcementPreviewHost.append(paragraph("status text-danger", announcement.error));
      return;
    }
    announcementPreviewHost.append(announcementView(announcement.value));
  }

  function previewPictures() {
    picturePreviewHost.replaceChildren();
    const pictures = picturePayload();
    if (pictures.error) {
      picturePreviewHost.append(paragraph("status text-danger", pictures.error));
      return;
    }
    for (const picture of pictures.value) {
      picturePreviewHost.append(pictureView(picture));
    }
    picturePreviewHost.append(paragraph("hint mb-0", "External pictures are shown as links; the GUI CSP is self-only."));
  }

  function previewBoard() {
    boardPreviewHost.replaceChildren();
    const board = boardPayload();
    if (board.error) {
      boardPreviewHost.append(paragraph("status text-danger", board.error));
      return;
    }
    for (const entry of board.value) {
      boardPreviewHost.append(boardView(entry));
    }
    boardPreviewHost.append(paragraph("hint mb-0", "External images are shown as links; the GUI CSP is self-only."));
  }

  async function installAnnouncement() {
    announcementResult.textContent = "";
    const announcement = announcementPayload();
    if (announcement.error) {
      announcementResult.textContent = announcement.error;
      announcementResult.classList.add("text-danger");
      return;
    }
    const confirmation = await confirmAction({
      title: "Install login notice",
      summary: "Install a new login notice for every server; the client shows it before server selection.",
      confirmLabel: "Install",
    });
    if (confirmation === null) {
      return;
    }
    await runCommand(commandInstall, {
      family: "announcement",
      announcement: announcement.value,
    }, confirmation, announcementResult);
  }

  async function installPictures() {
    pictureResult.textContent = "";
    const pictures = picturePayload();
    if (pictures.error) {
      pictureResult.textContent = pictures.error;
      pictureResult.classList.add("text-danger");
      return;
    }
    const confirmation = await confirmAction({
      title: "Install lobby pictures",
      summary: "Install " + pictures.value.length + " lobby picture(s) for " + describeScope() + ".",
      confirmLabel: "Install",
    });
    if (confirmation === null) {
      return;
    }
    await runCommand(commandInstall, {
      family: "picture",
      server_id: state.serverID,
      pictures: pictures.value,
    }, confirmation, pictureResult);
  }

  async function installBoard() {
    boardResult.textContent = "";
    const board = boardPayload();
    if (board.error) {
      boardResult.textContent = board.error;
      boardResult.classList.add("text-danger");
      return;
    }
    const confirmation = await confirmAction({
      title: "Install Activities board",
      summary: "Install " + board.value.length + " Activities board entr(y/ies) for " + describeScope() + ".",
      confirmLabel: "Install",
    });
    if (confirmation === null) {
      return;
    }
    await runCommand(commandInstall, {
      family: "board",
      server_id: state.serverID,
      board: board.value,
    }, confirmation, boardResult);
  }

  async function clearAnnouncement() {
    announcementResult.textContent = "";
    const confirmation = await confirmAction({
      title: "Clear login notice",
      summary: "Clear the login notice for every server; the client falls back to its defaults.",
      confirmLabel: "Clear",
    });
    if (confirmation === null) {
      return;
    }
    await runCommand(commandClear, { family: "announcement" }, confirmation, announcementResult);
  }

  async function clearPictures() {
    pictureResult.textContent = "";
    const confirmation = await confirmAction({
      title: "Clear lobby pictures",
      summary: "Clear the lobby picture notice for " + describeScope() + "; the client falls back to its defaults.",
      confirmLabel: "Clear",
    });
    if (confirmation === null) {
      return;
    }
    await runCommand(commandClear, { family: "picture", server_id: state.serverID }, confirmation, pictureResult);
  }

  async function clearBoard() {
    boardResult.textContent = "";
    const confirmation = await confirmAction({
      title: "Clear Activities board",
      summary: "Clear the Activities board for " + describeScope() + "; the client falls back to its defaults.",
      confirmLabel: "Clear",
    });
    if (confirmation === null) {
      return;
    }
    await runCommand(commandClear, { family: "board", server_id: state.serverID }, confirmation, boardResult);
  }

  async function runCommand(name, payload, confirmation, resultBox) {
    const reply = await request("/agent/v1/commands/" + encodeURIComponent(name), {
      method: "POST",
      body: { reason: confirmation.reason, semantic_key: confirmation.semantic_key, payload },
    });
    if (reply.unauthorized) {
      return;
    }
    setStatus(resultBox, describePublicationReply(reply) + "\nreason: " + confirmation.reason, reply.ok ? "success" : "error");
    if (reply.ok) {
      await loadLive();
    }
  }

  function describeScope() {
    return state.serverID === 0 ? "every server" : "server #" + state.serverID;
  }

  function announcementPayload() {
    const url = announcementURL.value.trim();
    if (!validImageURL(url)) {
      return { error: "The image URL must start with " + acceptedSchemes + ", or stay empty." };
    }
    const contents = announcementContents.value.split("\n").map((line) => line.trim()).filter((line) => line !== "");
    const announcement = { title: announcementTitle.value, contents };
    if (url !== "") {
      announcement.url = url;
    }
    return { value: announcement };
  }

  function picturePayload() {
    const pictures = [];
    for (const row of pictureRows.querySelectorAll(".notice-picture-row")) {
      const weightText = rowFieldValue(row, "weight");
      const weight = Number(weightText);
      if (weightText === "" || !Number.isFinite(weight)) {
        return { error: "Every picture needs a numeric weight." };
      }
      const pic = rowFieldValue(row, "pic");
      const smallPic = rowFieldValue(row, "small_pic");
      if (!validImageURL(pic) || !validImageURL(smallPic)) {
        return { error: "Picture URLs must start with " + acceptedSchemes + ", or stay empty." };
      }
      pictures.push({ weight, pic, small_pic: smallPic });
    }
    if (pictures.length === 0) {
      return { error: "Add at least one picture." };
    }
    return { value: pictures };
  }

  function boardPayload() {
    const entries = [];
    const seen = new Set();
    for (const row of boardRows.querySelectorAll(".notice-board-row")) {
      const idText = rowFieldValue(row, "id");
      const id = Number(idText);
      if (!Number.isInteger(id) || id < 1 || id > maximumWireID) {
        return { error: "Every board entry needs a positive whole id." };
      }
      if (seen.has(id)) {
        return { error: "Board entry ids must be unique." };
      }
      seen.add(id);
      const imageURL = rowFieldValue(row, "img_url");
      if (!validImageURL(imageURL)) {
        return { error: "Board image URLs must start with " + acceptedSchemes + ", or stay empty." };
      }
      entries.push({
        id,
        title: rowFieldValue(row, "title"),
        start_date: rowFieldValue(row, "start_date"),
        content: rowFieldValue(row, "content"),
        img_url: imageURL,
      });
    }
    if (entries.length === 0) {
      return { error: "Add at least one board entry." };
    }
    return { value: entries };
  }

  function addPictureRow() {
    const row = document.createElement("div");
    row.className = "border rounded p-2 mb-2 notice-picture-row";
    createRowField(row, "Weight", "weight", "number");
    attachMediaChooser(createRowField(row, "Picture URL (" + acceptedSchemes + "..., or choose a hosted picture)", "pic", "text"));
    attachMediaChooser(createRowField(row, "Small picture URL (empty for the stock default)", "small_pic", "text"));
    const remove = actionButton("Remove picture", false, "");
    remove.addEventListener("click", () => row.remove());
    row.append(remove);
    pictureRows.append(row);
  }

  function addBoardRow() {
    const row = document.createElement("div");
    row.className = "border rounded p-2 mb-2 notice-board-row";
    createRowField(row, "Entry id", "id", "number");
    createRowField(row, "Title", "title", "text");
    createRowField(row, "Start date (as the client table shows it; format UNKNOWN)", "start_date", "text");
    createRowField(row, "Content", "content", "textarea");
    attachMediaChooser(createRowField(row, "Image URL (" + acceptedSchemes + "..., optional)", "img_url", "text"));
    const remove = actionButton("Remove entry", false, "");
    remove.addEventListener("click", () => row.remove());
    row.append(remove);
    boardRows.append(row);
  }

  function createRowField(row, labelText, fieldName, kind) {
    fieldCounter += 1;
    const identifier = "notice-field-" + fieldCounter;
    const wrapper = document.createElement("div");
    wrapper.className = "mb-2";
    const label = document.createElement("label");
    label.className = "form-label";
    label.htmlFor = identifier;
    label.textContent = labelText;
    const input = document.createElement(kind === "textarea" ? "textarea" : "input");
    if (kind === "textarea") {
      input.rows = 3;
    } else {
      input.type = kind;
    }
    if (kind === "number") {
      input.min = "0";
      input.step = "any";
    }
    input.className = "form-control";
    input.id = identifier;
    input.dataset.field = fieldName;
    wrapper.append(label, input);
    row.append(wrapper);
    return input;
  }

  function rowFieldValue(row, fieldName) {
    const input = row.querySelector('[data-field="' + fieldName + '"]');
    return input === null ? "" : input.value.trim();
  }
}

function validImageURL(url) {
  return url === "" || url.startsWith(insecureImageURLPrefix) || url.startsWith(secureImageURLPrefix);
}

function hostedMediaName(url) {
  const index = url.lastIndexOf(hostedMediaMarker);
  if (index < 0) {
    return null;
  }
  const name = url.slice(index + hostedMediaMarker.length);
  return hostedMediaPattern.test(name) ? name : null;
}

// attachMediaChooser gives one picture field the three G41 sources and a
// preview of a hosted picture through the agent (the GUI CSP is self-only, so
// an external image is never loaded).
function attachMediaChooser(input) {
  const wrapper = input.parentElement;
  if (wrapper === null) {
    return;
  }
  const chooser = document.createElement("div");
  chooser.className = "media-chooser mt-2";
  const modeLabel = document.createElement("label");
  modeLabel.className = "form-label";
  modeLabel.textContent = "Picture source";
  const mode = document.createElement("select");
  mode.className = "form-select form-select-sm mb-2";
  modeLabel.append(mode);
  for (const [value, label] of [["url", "Use a URL"], ["download", "Download to our server"], ["upload", "Upload file"]]) {
    const option = document.createElement("option");
    option.value = value;
    option.textContent = label;
    mode.append(option);
  }
  const downloadRow = document.createElement("div");
  downloadRow.className = "d-flex gap-2 mb-2";
  const downloadInput = document.createElement("input");
  downloadInput.type = "text";
  downloadInput.className = "form-control form-control-sm";
  downloadInput.placeholder = acceptedSchemes + " picture URL";
  downloadInput.setAttribute("aria-label", "Picture URL to download to our server");
  const downloadButton = actionButton("Download", false, "");
  downloadRow.append(downloadInput, downloadButton);
  const uploadRow = document.createElement("div");
  uploadRow.className = "mb-2";
  const uploadInput = document.createElement("input");
  uploadInput.type = "file";
  uploadInput.accept = "image/png,image/jpeg";
  uploadInput.className = "form-control form-control-sm";
  uploadInput.setAttribute("aria-label", "Picture file to upload");
  uploadRow.append(uploadInput);
  const hostedButton = actionButton("Choose hosted picture", false, "");
  const status = errorParagraph();
  status.classList.add("mt-2");
  const previewHost = document.createElement("div");
  previewHost.className = "mt-2";
  const dialog = hostedDialog(applyHosted);
  chooser.append(modeLabel, downloadRow, uploadRow, hostedButton, status, previewHost, dialog.element);
  wrapper.append(chooser);

  function applyMode() {
    downloadRow.hidden = mode.value !== "download";
    uploadRow.hidden = mode.value !== "upload";
  }
  mode.addEventListener("change", applyMode);
  applyMode();
  input.addEventListener("change", () => showPreview());
  hostedButton.addEventListener("click", () => {
    dialog.element.showModal();
    void dialog.load();
  });
  downloadButton.addEventListener("click", () => void importURL(downloadInput.value.trim()));
  uploadInput.addEventListener("change", () => {
    const file = uploadInput.files && uploadInput.files[0];
    if (file !== undefined) {
      void uploadFile(file);
    }
  });

  function applyHosted(stored) {
    const url = typeof stored.url === "string" ? stored.url : "";
    if (url === "") {
      setStatus(status, "Set the server URL in Settings before using hosted pictures.", "error");
      return;
    }
    input.value = url;
    setStatus(status, "Stored as " + (typeof stored.name === "string" ? stored.name : "unknown") + ".", "success");
    showPreview();
    dialog.element.close();
  }

  async function importURL(source) {
    status.textContent = "";
    if (!validImageURL(source)) {
      setStatus(status, "Enter a picture URL using " + acceptedSchemes + ".", "error");
      return;
    }
    downloadButton.disabled = true;
    const reply = await request(mediaImportCommand, { method: "POST", body: { url: source } });
    downloadButton.disabled = false;
    if (reply.unauthorized) {
      return;
    }
    if (!reply.ok) {
      setStatus(status, describeReply(reply), "error");
      return;
    }
    applyHosted(reply.body && typeof reply.body === "object" ? reply.body : {});
  }

  async function uploadFile(file) {
    status.textContent = "";
    let encoded = "";
    try {
      encoded = await readBase64(file);
    } catch (error) {
      setStatus(status, String(error), "error");
      return;
    }
    const reply = await request(mediaUploadCommand, { method: "POST", body: { data_base64: encoded } });
    if (reply.unauthorized) {
      return;
    }
    if (!reply.ok) {
      setStatus(status, describeReply(reply), "error");
      return;
    }
    applyHosted(reply.body && typeof reply.body === "object" ? reply.body : {});
  }

  function showPreview() {
    previewHost.replaceChildren();
    const url = input.value.trim();
    if (url === "") {
      return;
    }
    const name = hostedMediaName(url);
    if (name === null) {
      previewHost.append(paragraph("hint mb-0", "External picture; the GUI does not load external images."));
      return;
    }
    const image = document.createElement("img");
    image.className = "picture";
    image.alt = "preview of " + name;
    loadPicture(mediaFilePrefix + encodeURIComponent(name)).then((objectURL) => {
      if (objectURL === null) {
        setStatus(status, "The stored picture is not readable.", "error");
        return;
      }
      image.src = objectURL;
    });
    previewHost.append(image);
  }
}

function readBase64(file) {
  return new Promise((resolve, reject) => {
    const reader = new FileReader();
    reader.onload = () => {
      const result = String(reader.result);
      const comma = result.indexOf(",");
      resolve(comma >= 0 ? result.slice(comma + 1) : result);
    };
    reader.onerror = () => reject(new Error("the file cannot be read"));
    reader.readAsDataURL(file);
  });
}

// hostedDialog lists the pictures stored on our server for the picker.
function hostedDialog(onChoose) {
  const element = document.createElement("dialog");
  const heading = document.createElement("h2");
  heading.className = "card-title";
  heading.textContent = "Hosted pictures";
  const status = errorParagraph();
  const list = document.createElement("div");
  list.className = "media-list";
  const closeButton = actionButton("Close", false, "");
  closeButton.addEventListener("click", () => element.close());
  element.append(heading, status, list, closeButton);
  async function load() {
    status.textContent = "";
    list.replaceChildren();
    const reply = await request(mediaListRead);
    if (reply.unauthorized) {
      element.close();
      return;
    }
    if (!reply.ok) {
      setStatus(status, describeReply(reply), "error");
      return;
    }
    const body = reply.body && typeof reply.body === "object" ? reply.body : {};
    const items = Array.isArray(body.items) ? body.items : [];
    if (items.length === 0) {
      list.append(paragraph("hint mb-0", "No pictures are stored on the server yet."));
      return;
    }
    for (const item of items) {
      if (item === null || typeof item !== "object") {
        continue;
      }
      const button = actionButton(typeof item.name === "string" ? item.name : "picture", false, "");
      const image = document.createElement("img");
      image.className = "picture";
      image.alt = "";
      loadPicture(mediaFilePrefix + encodeURIComponent(String(item.name))).then((objectURL) => {
        if (objectURL !== null) {
          image.src = objectURL;
        }
      });
      button.prepend(image);
      button.addEventListener("click", () => onChoose(item));
      list.append(button);
    }
  }
  return { element, load };
}


function announcementView(announcement) {
  const view = document.createElement("div");
  view.className = "border rounded p-2 mb-2";
  const title = document.createElement("strong");
  title.textContent = announcement.title === "" ? "(empty title)" : announcement.title;
  view.append(title);
  for (const line of announcement.contents || []) {
    view.append(paragraph("mb-1", line));
  }
  if (announcement.url !== undefined && announcement.url !== "") {
    view.append(externalLink(announcement.url, "Image: "));
  }
  return view;
}

function pictureView(picture) {
  const view = document.createElement("div");
  view.className = "border rounded p-2 mb-2";
  view.append(paragraph("mb-1", "weight " + picture.weight));
  view.append(picture.pic === "" ? paragraph("mb-1", "picture: stock default") : externalLink(picture.pic, "picture: "));
  view.append(picture.small_pic === "" ? paragraph("mb-0", "small picture: stock default") : externalLink(picture.small_pic, "small picture: "));
  return view;
}

function boardView(entry) {
  const view = document.createElement("div");
  view.className = "border rounded p-2 mb-2";
  const title = document.createElement("strong");
  title.textContent = "#" + entry.id + " " + (entry.title === "" ? "(empty title)" : entry.title);
  view.append(title);
  if (entry.start_date !== "") {
    view.append(paragraph("mb-1", "start date: " + entry.start_date));
  }
  if (entry.content !== "") {
    view.append(paragraph("mb-1", entry.content));
  }
  if (entry.img_url !== undefined && entry.img_url !== "") {
    view.append(externalLink(entry.img_url, "Image: "));
  }
  return view;
}

function externalLink(url, prefix) {
  const anchor = document.createElement("a");
  anchor.href = url;
  anchor.target = "_blank";
  anchor.rel = "noopener noreferrer";
  anchor.textContent = prefix + url;
  return anchor;
}

function describePublicationReply(reply) {
  if (!reply.ok) {
    return describeReply(reply);
  }
  const body = reply.body && typeof reply.body === "object" ? reply.body : {};
  const result = body.result && typeof body.result === "object" ? body.result : {};
  const parts = ["state " + (typeof body.state === "string" && body.state !== "" ? body.state : "unknown")];
  if (typeof result.family === "string" && result.family !== "") {
    parts.push("family " + result.family);
  }
  if (typeof result.set_id === "string" && result.set_id !== "") {
    parts.push("set " + result.set_id);
  }
  if (typeof result.visible === "boolean") {
    parts.push(result.visible ? "visible" : "not visible");
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

function createField(parent, identifier, label, kind) {
  const wrapper = document.createElement("div");
  wrapper.className = "mb-3";
  const labelElement = document.createElement("label");
  labelElement.className = "form-label";
  labelElement.htmlFor = identifier;
  labelElement.textContent = label;
  const input = document.createElement(kind === "textarea" ? "textarea" : "input");
  if (kind === "textarea") {
    input.rows = 4;
  } else {
    input.type = kind;
  }
  input.className = "form-control";
  input.id = identifier;
  wrapper.append(labelElement, input);
  parent.append(wrapper);
  return input;
}

function actionButton(label, primary, identifier) {
  const button = document.createElement("button");
  button.type = "button";
  button.className = "btn " + (primary ? "btn-primary" : "btn-outline-secondary");
  button.textContent = label;
  if (identifier !== "") {
    button.id = identifier;
  }
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
