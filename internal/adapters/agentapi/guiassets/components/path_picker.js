"use strict";

import { describeReply, request } from "../transport.js";
import { actionButton, createModal, errorParagraph } from "./modal.js";

const fileListRead = "/agent/v1/reads/agent.fs.list";

// openPathPicker asks the agent for its folders and resolves the absolute path
// the operator picks, or null. File mode lists files too and returns the file;
// a browser file input can never reveal a full path, so the agent lists names.
export function openPathPicker(options) {
  const settings = options || {};
  const mode = settings.mode === "file" ? "file" : "folder";
  return new Promise((resolve) => {
    let settled = false;
    let currentPath = "";
    let parentPath = "";
    let selectedFile = "";
    function settle(value) {
      if (settled) {
        return;
      }
      settled = true;
      resolve(value);
    }
    const dialog = createModal({
      title: settings.title || (mode === "file" ? "Choose a file" : "Choose a folder"),
      modalId: "path-picker-modal",
      wide: true,
      onClose: () => settle(null),
    });

    const navigation = document.createElement("div");
    navigation.className = "d-flex gap-2 mb-2";
    const upButton = actionButton("Up", false, "path-picker-up");
    upButton.disabled = true;
    const pathInput = document.createElement("input");
    pathInput.type = "text";
    pathInput.className = "form-control";
    pathInput.id = "path-picker-input";
    pathInput.autocomplete = "off";
    pathInput.spellcheck = false;
    pathInput.setAttribute("aria-label", "Folder path");
    const goButton = actionButton("Go", false, "path-picker-go");
    navigation.append(upButton, pathInput, goButton);

    const drives = document.createElement("div");
    drives.className = "d-flex flex-wrap gap-2 mb-2";
    drives.id = "path-picker-drives";
    drives.hidden = true;

    const list = document.createElement("div");
    list.className = "list-group path-picker-list";
    list.id = "path-picker-list";
    list.setAttribute("role", "listbox");
    list.setAttribute("aria-label", "Folders");

    const status = errorParagraph();
    status.id = "path-picker-status";
    status.classList.add("mt-2");

    const choose = actionButton(mode === "file" ? "Select" : "Select this folder", true, "path-picker-select");
    choose.disabled = true;
    const cancel = actionButton("Cancel", false, "path-picker-cancel");
    dialog.body.append(navigation, drives, list, status);
    dialog.footer.append(cancel, choose);

    upButton.addEventListener("click", () => {
      if (parentPath !== "") {
        void navigate(parentPath);
      }
    });
    goButton.addEventListener("click", () => void navigate(pathInput.value.trim()));
    pathInput.addEventListener("keydown", (event) => {
      if (event.key === "Enter") {
        event.preventDefault();
        void navigate(pathInput.value.trim());
      }
    });
    cancel.addEventListener("click", () => dialog.close());
    choose.addEventListener("click", () => {
      const chosen = selectedFile !== "" ? selectedFile : currentPath;
      if (chosen === "") {
        return;
      }
      settle(chosen);
      dialog.close();
    });

    async function navigate(path) {
      status.textContent = "";
      list.replaceChildren();
      choose.disabled = true;
      const query = "?path=" + encodeURIComponent(path) + (mode === "file" ? "&show_files=true" : "");
      const reply = await request(fileListRead + query);
      if (reply.unauthorized) {
        return;
      }
      if (!reply.ok) {
        status.textContent = describeReply(reply);
        return;
      }
      const listing = reply.body && typeof reply.body === "object" ? reply.body : {};
      currentPath = typeof listing.path === "string" ? listing.path : "";
      parentPath = typeof listing.parent === "string" ? listing.parent : "";
      selectedFile = "";
      pathInput.value = currentPath;
      upButton.disabled = parentPath === "";
      renderDrives(Array.isArray(listing.drive_roots) ? listing.drive_roots : []);
      renderEntries(Array.isArray(listing.entries) ? listing.entries : []);
      if (listing.truncated === true) {
        status.textContent = "This folder has more than 2000 entries; only the first 2000 are shown.";
      }
      if (mode === "folder") {
        choose.disabled = currentPath === "";
      }
    }

    function renderDrives(roots) {
      drives.replaceChildren();
      drives.hidden = roots.length === 0;
      for (const root of roots) {
        const button = actionButton(String(root), false, "");
        button.classList.add("btn-sm");
        button.addEventListener("click", () => void navigate(String(root)));
        drives.append(button);
      }
    }

    function renderEntries(entries) {
      list.replaceChildren();
      for (const entry of entries) {
        const item = entry && typeof entry === "object" ? entry : {};
        const name = typeof item.name === "string" ? item.name : "";
        if (name === "") {
          continue;
        }
        const isDirectory = item.is_dir === true;
        const button = document.createElement("button");
        button.type = "button";
        button.className = "list-group-item list-group-item-action d-flex justify-content-between align-items-center path-picker-entry";
        button.setAttribute("role", "option");
        button.setAttribute("aria-selected", "false");
        button.setAttribute("aria-label", (isDirectory ? "Open folder " : "Choose file ") + name);
        const entryName = document.createElement("span");
        entryName.className = "path-picker-name";
        entryName.textContent = name;
        const kind = document.createElement("span");
        kind.className = "text-secondary small";
        kind.textContent = isDirectory ? "folder" : "file";
        button.append(entryName, kind);
        button.addEventListener("click", () => {
          if (isDirectory) {
            selectedFile = "";
            void navigate(joinPath(currentPath, name));
            return;
          }
          selectFile(button, joinPath(currentPath, name));
        });
        list.append(button);
      }
    }

    function selectFile(button, path) {
      selectedFile = path;
      pathInput.value = path;
      for (const item of list.querySelectorAll(".path-picker-entry")) {
        const active = item === button;
        item.classList.toggle("active", active);
        item.setAttribute("aria-selected", active ? "true" : "false");
      }
      choose.disabled = false;
    }

    const start = typeof settings.start === "string" ? settings.start.trim() : "";
    pathInput.focus();
    void navigate(mode === "file" ? parentOf(start) : start);
  });
}

// joinPath adds one name to a folder path with the folder's own separator.
function joinPath(folder, name) {
  const separator = folder.includes("\\") && !folder.includes("/") ? "\\" : "/";
  if (folder.endsWith("/") || folder.endsWith("\\")) {
    return folder + name;
  }
  return folder + separator + name;
}

// parentOf finds the folder of a file path on either platform; a path with no
// folder answers the empty agent-root start.
export function parentOf(value) {
  const trimmed = value.replace(/[\\/]+$/, "");
  const slash = Math.max(trimmed.lastIndexOf("/"), trimmed.lastIndexOf("\\"));
  if (slash < 0) {
    return "";
  }
  const parent = trimmed.slice(0, slash);
  if (parent === "") {
    return "/";
  }
  if (/^[A-Za-z]:$/.test(parent)) {
    return parent + "\\";
  }
  return parent;
}
