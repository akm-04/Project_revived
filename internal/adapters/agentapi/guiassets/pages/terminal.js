"use strict";

import { pageHeader } from "../components/format.js";
import { getToken, request, describeReply } from "../transport.js";

const terminalPrefix = "/agent/v1/terminal/";
const openPath = terminalPrefix + "open";
const fontSizeStorageKey = "gxbOperatorTerminalFontSize";
const appearanceStorageKey = "gxbOperatorTerminalAppearance";
const defaultFontSize = 16;
const minimumFontSize = 8;
const maximumFontSize = 40;
const reconnectDelayMilliseconds = 500;
const resizeDelayMilliseconds = 150;
const appearanceChoices = ["black", "dark", "light", "theme"];
const appearanceLabels = {
  black: "Black",
  dark: "Dark",
  light: "Light",
  theme: "Follow theme",
};
const blackTheme = { background: "#000000", foreground: "#e6e6e6", cursor: "#e6e6e6", selectionBackground: "#3a3a3a" };
const darkTheme = { background: "#1b1d21", foreground: "#e6e6e6", cursor: "#e6e6e6", selectionBackground: "#3a3f45" };
const lightTheme = { background: "#ffffff", foreground: "#1b1d21", cursor: "#1b1d21", selectionBackground: "#cfe3f7" };

// renderPage is the Terminal screen (G42): a shell as the agent's own user,
// opened only after the root password is entered again and only while the
// agent listens on loopback.
export function renderPage(container) {
  container.replaceChildren();
  container.append(pageHeader("Terminal"));

  const state = {
    password: "",
    terminalID: "",
    terminal: null,
    fit: null,
    libraries: null,
    streamController: null,
    reconnectTimer: null,
    resizeTimer: null,
    fontSize: readFontSize(),
    appearance: readAppearance(),
  };

  const panel = document.createElement("section");
  panel.className = "card";
  const bar = document.createElement("div");
  bar.className = "card-header d-flex align-items-center gap-2 flex-wrap";
  const identity = document.createElement("span");
  identity.id = "terminal-identity";
  identity.className = "font-monospace me-auto";
  identity.textContent = "not connected";

  const fontDecrease = createButton("−", "Decrease font size", "btn btn-sm btn-outline-secondary");
  fontDecrease.id = "terminal-font-decrease";
  const fontSizeValue = document.createElement("output");
  fontSizeValue.id = "terminal-font-size";
  fontSizeValue.className = "font-monospace px-1";
  fontSizeValue.setAttribute("aria-label", "Font size");
  fontSizeValue.textContent = String(state.fontSize);
  const fontIncrease = createButton("+", "Increase font size", "btn btn-sm btn-outline-secondary");
  fontIncrease.id = "terminal-font-increase";

  const fontLabel = document.createElement("span");
  fontLabel.className = "me-2";
  fontLabel.textContent = "Font size";
  const fontGroup = document.createElement("div");
  fontGroup.className = "d-flex align-items-center";
  fontGroup.append(fontLabel, fontDecrease, fontSizeValue, fontIncrease);

  const appearanceLabel = document.createElement("label");
  appearanceLabel.className = "form-label mb-0 ms-2";
  appearanceLabel.htmlFor = "terminal-appearance";
  appearanceLabel.textContent = "Appearance";
  const appearance = document.createElement("select");
  appearance.id = "terminal-appearance";
  appearance.className = "form-select form-select-sm";
  appearance.style.width = "auto";
  for (const choice of appearanceChoices) {
    const option = document.createElement("option");
    option.value = choice;
    option.textContent = appearanceLabels[choice];
    appearance.append(option);
  }
  appearance.value = state.appearance;
  const appearanceGroup = document.createElement("div");
  appearanceGroup.className = "d-flex align-items-center";
  appearanceGroup.append(appearanceLabel, appearance);

  const reset = createButton("Reset", "Reset the terminal", "btn btn-sm btn-outline-secondary");
  reset.id = "terminal-reset";
  bar.append(identity, fontGroup, appearanceGroup, reset);

  const screen = document.createElement("div");
  screen.className = "card-body p-0";
  screen.style.background = "#000000";
  const terminalHost = document.createElement("div");
  terminalHost.id = "terminal-screen";
  terminalHost.style.height = "calc(100vh - 260px)";
  terminalHost.style.minHeight = "320px";
  terminalHost.style.padding = "4px";
  screen.append(terminalHost);

  const status = document.createElement("p");
  status.id = "terminal-status";
  status.className = "status px-3 py-2 mb-0";
  status.setAttribute("role", "status");

  const passwordPrompt = buildPasswordDialog();
  const dialog = passwordPrompt.dialog;
  const dialogForm = passwordPrompt.form;
  const dialogPassword = passwordPrompt.password;
  const dialogStatus = passwordPrompt.status;
  const dialogCancel = passwordPrompt.cancel;
  panel.append(bar, screen, status);
  container.append(panel, dialog);

  function setStatus(text, tone) {
    status.textContent = text;
    status.classList.toggle("text-danger", tone === "error");
  }

  async function ensureLibraries() {
    if (state.libraries !== null) {
      return state.libraries;
    }
    await loadStyle("/gui/vendor/xterm/xterm.css");
    await loadScript("/gui/vendor/xterm/xterm.js");
    await loadScript("/gui/vendor/xterm/addon-fit.js");
    const Terminal = window.Terminal;
    const FitAddon = window.FitAddon && window.FitAddon.FitAddon;
    if (typeof Terminal !== "function" || typeof FitAddon !== "function") {
      throw new Error("the terminal library did not load");
    }
    state.libraries = { Terminal, FitAddon };
    return state.libraries;
  }

  function createTerminal() {
    const { Terminal, FitAddon } = state.libraries;
    const terminal = new Terminal({
      fontSize: state.fontSize,
      fontFamily: 'ui-monospace, SFMono-Regular, Menlo, Consolas, "Liberation Mono", monospace',
      cursorBlink: true,
      scrollback: 5000,
      theme: resolveTheme(state.appearance),
    });
    const fit = new FitAddon();
    terminal.loadAddon(fit);
    terminal.open(terminalHost);
    terminal.onData((data) => {
      void sendInput(data);
    });
    state.terminal = terminal;
    state.fit = fit;
    fit.fit();
    terminal.focus();
  }

  function fitTerminal() {
    if (state.fit === null || state.terminal === null) {
      return;
    }
    state.fit.fit();
    scheduleResize();
  }

  function scheduleResize() {
    if (state.resizeTimer !== null) {
      clearTimeout(state.resizeTimer);
    }
    state.resizeTimer = setTimeout(() => {
      state.resizeTimer = null;
      if (state.terminal === null || state.terminalID === "") {
        return;
      }
      const columns = state.terminal.cols;
      const rows = state.terminal.rows;
      void request(terminalPrefix + state.terminalID + "/resize", { method: "POST", body: { cols: columns, rows: rows } });
    }, resizeDelayMilliseconds);
  }

  async function sendInput(data) {
    if (state.terminalID === "") {
      return;
    }
    const reply = await request(terminalPrefix + state.terminalID + "/input", {
      method: "POST",
      body: { data: encodeBase64(new TextEncoder().encode(data)) },
    });
    if (reply.unauthorized) {
      return;
    }
    if (reply.ok) {
      return;
    }
    const code = reply.body && typeof reply.body === "object" ? reply.body.error_code : "";
    if (code === "AGENT_TERMINAL_UNKNOWN") {
      endTerminal("session ended");
      return;
    }
    setStatus(describeReply(reply), "error");
  }

  function applyFontSize() {
    fontSizeValue.textContent = String(state.fontSize);
    if (state.terminal !== null) {
      state.terminal.options.fontSize = state.fontSize;
      fitTerminal();
    }
  }

  function changeFontSize(delta) {
    const next = Math.min(maximumFontSize, Math.max(minimumFontSize, state.fontSize + delta));
    if (next === state.fontSize) {
      return;
    }
    state.fontSize = next;
    writeStored(fontSizeStorageKey, String(next));
    applyFontSize();
  }

  function applyAppearance() {
    if (state.terminal !== null) {
      state.terminal.options.theme = resolveTheme(state.appearance);
    }
  }

  async function openTerminal() {
    if (state.terminalID !== "") {
      return;
    }
    if (state.password === "") {
      dialogPassword.value = "";
      dialog.showModal();
      dialogPassword.focus();
      return;
    }
    setStatus("Opening the terminal…");
    if (state.libraries === null) {
      try {
        await ensureLibraries();
      } catch (error) {
        setStatus(String(error.message || error), "error");
        return;
      }
    }
    const reply = await request(openPath, { method: "POST", body: { password: state.password } });
    if (reply.unauthorized) {
      return;
    }
    if (!reply.ok) {
      const code = reply.body && typeof reply.body === "object" ? reply.body.error_code : "";
      if (code === "AGENT_LOGIN_REFUSED") {
        state.password = "";
        setStatus("Wrong password. Enter the root password to open the terminal.", "error");
        dialog.showModal();
        dialogPassword.focus();
        return;
      }
      setStatus(describeReply(reply), "error");
      return;
    }
    const opened = reply.body && typeof reply.body === "object" ? reply.body : {};
    if (typeof opened.terminal_id !== "string" || opened.terminal_id === "") {
      setStatus("The agent reply carried no terminal id.", "error");
      return;
    }
    state.terminalID = opened.terminal_id;
    identity.textContent = terminalIdentityText(opened);
    setStatus("");
    if (state.terminal === null) {
      try {
        createTerminal();
      } catch (error) {
        setStatus(String(error.message || error), "error");
        return;
      }
    }
    applyFontSize();
    applyAppearance();
    fitTerminal();
    state.terminal.focus();
    void connectStream(state.terminalID);
  }

  function terminalIdentityText(opened) {
    const user = typeof opened.user === "string" && opened.user !== "" ? opened.user : "unknown";
    const host = typeof opened.host === "string" && opened.host !== "" ? opened.host : "unknown";
    return user + "@" + host + ": ~";
  }

  function stopStream() {
    if (state.streamController !== null) {
      state.streamController.abort();
      state.streamController = null;
    }
    if (state.reconnectTimer !== null) {
      clearTimeout(state.reconnectTimer);
      state.reconnectTimer = null;
    }
  }

  async function connectStream(terminalID) {
    const controller = new AbortController();
    state.streamController = controller;
    while (!controller.signal.aborted && state.terminalID === terminalID) {
      let response = null;
      try {
        response = await fetch(terminalPrefix + terminalID + "/stream", {
          headers: { Authorization: "Bearer " + getToken() },
          signal: controller.signal,
        });
      } catch (error) {
        if (controller.signal.aborted) {
          return;
        }
        await delay(reconnectDelayMilliseconds);
        continue;
      }
      if (response.status === 401) {
        // Route the expiry through the shared transport handler, which drops
        // the token and shows the login view.
        void request("/agent/v1/modules");
        setStatus("Session expired; log in again.", "error");
        return;
      }
      if (response.status === 404 || response.status === 409) {
        endTerminal("session ended");
        return;
      }
      if (!response.ok || response.body === null) {
        setStatus("The terminal stream answered HTTP " + response.status + ".", "error");
        await delay(reconnectDelayMilliseconds);
        continue;
      }
      await readStream(response.body, controller);
      if (controller.signal.aborted) {
        return;
      }
      await delay(reconnectDelayMilliseconds);
    }
  }

  async function readStream(body, controller) {
    const reader = body.getReader();
    const decoder = new TextDecoder();
    let buffer = "";
    try {
      while (!controller.signal.aborted) {
        const { value, done } = await reader.read();
        if (done) {
          break;
        }
        buffer += decoder.decode(value, { stream: true });
        let boundary = buffer.indexOf("\n\n");
        while (boundary >= 0) {
          handleStreamBlock(buffer.slice(0, boundary));
          buffer = buffer.slice(boundary + 2);
          boundary = buffer.indexOf("\n\n");
        }
      }
    } catch (error) {
      // The stream was aborted or the connection dropped; the caller decides
      // whether to reconnect.
    } finally {
      try {
        await reader.cancel();
      } catch (error) {
        // The reader is already closed.
      }
    }
  }

  function handleStreamBlock(block) {
    const data = [];
    for (const line of block.split("\n")) {
      if (line.startsWith(":")) {
        continue;
      }
      if (line.startsWith("data:")) {
        data.push(line.slice(5).trimStart());
      }
    }
    if (data.length === 0 || state.terminal === null) {
      return;
    }
    const bytes = decodeBase64(data.join("\n"));
    if (bytes !== null) {
      state.terminal.write(bytes);
    }
  }

  function endTerminal(reason) {
    const terminalID = state.terminalID;
    stopStream();
    state.terminalID = "";
    if (terminalID !== "") {
      void request(terminalPrefix + terminalID + "/close", { method: "POST", body: {} });
    }
    if (state.terminal !== null) {
      state.terminal.write("\r\n[" + reason + "]\r\n");
    }
    identity.textContent = "not connected: " + reason;
    setStatus("The terminal " + reason + ". Choose Reset to open a new one.");
  }

  async function resetTerminal() {
    const terminalID = state.terminalID;
    stopStream();
    state.terminalID = "";
    if (terminalID !== "") {
      await request(terminalPrefix + terminalID + "/close", { method: "POST", body: {} });
    }
    if (state.terminal !== null) {
      state.terminal.reset();
      state.terminal.clear();
    }
    identity.textContent = "not connected";
    if (state.password === "") {
      dialogPassword.value = "";
      dialog.showModal();
      dialogPassword.focus();
      return;
    }
    await openTerminal();
  }

  fontDecrease.addEventListener("click", () => changeFontSize(-1));
  fontIncrease.addEventListener("click", () => changeFontSize(1));
  appearance.addEventListener("change", () => {
    if (!appearanceChoices.includes(appearance.value)) {
      appearance.value = state.appearance;
      return;
    }
    state.appearance = appearance.value;
    writeStored(appearanceStorageKey, state.appearance);
    applyAppearance();
  });
  reset.addEventListener("click", () => {
    void resetTerminal();
  });

  dialogForm.addEventListener("submit", (event) => {
    event.preventDefault();
    if (dialogPassword.value === "") {
      dialogStatus.textContent = "Enter the root password.";
      return;
    }
    state.password = dialogPassword.value;
    dialogPassword.value = "";
    dialogStatus.textContent = "";
    dialog.close();
    void openTerminal();
  });
  dialogCancel.addEventListener("click", () => {
    closePasswordPrompt();
  });
  dialog.addEventListener("cancel", () => {
    closePasswordPrompt();
  });

  function closePasswordPrompt() {
    dialogPassword.value = "";
    dialogStatus.textContent = "";
    dialog.close();
    setStatus("No terminal is open. Choose Reset to enter the password again.");
  }

  const resizeObserver = new ResizeObserver(() => {
    fitTerminal();
  });
  resizeObserver.observe(terminalHost);

  const themeObserver = new MutationObserver(() => {
    if (state.appearance === "theme") {
      applyAppearance();
    }
  });
  themeObserver.observe(document.documentElement, { attributes: true, attributeFilter: ["data-bs-theme"] });

  const removalObserver = new MutationObserver(() => {
    if (container.isConnected) {
      return;
    }
    removalObserver.disconnect();
    resizeObserver.disconnect();
    themeObserver.disconnect();
    const terminalID = state.terminalID;
    state.password = "";
    stopStream();
    state.terminalID = "";
    if (terminalID !== "") {
      void request(terminalPrefix + terminalID + "/close", { method: "POST", body: {} });
    }
    if (state.terminal !== null) {
      state.terminal.dispose();
      state.terminal = null;
    }
  });
  removalObserver.observe(document.body, { childList: true, subtree: true });

  applyFontSize();
  dialogPassword.value = "";
  dialog.showModal();
  dialogPassword.focus();
}

function buildPasswordDialog() {
  const dialog = document.createElement("dialog");
  dialog.id = "terminal-password-dialog";
  const form = document.createElement("form");
  form.className = "card card-md";
  form.id = "terminal-password-form";
  const body = document.createElement("div");
  body.className = "card-body";
  const title = document.createElement("h2");
  title.className = "card-title";
  title.textContent = "Terminal password";
  const help = document.createElement("p");
  help.className = "module-help";
  help.textContent = "Enter the root password again to open a shell as the agent's user.";
  const password = document.createElement("input");
  password.id = "terminal-password";
  password.type = "password";
  password.className = "form-control";
  password.autocomplete = "current-password";
  password.required = true;
  const status = document.createElement("p");
  status.id = "terminal-password-status";
  status.className = "status mt-2";
  status.setAttribute("role", "status");
  const actions = document.createElement("div");
  actions.className = "d-flex gap-2 mt-3";
  const submit = document.createElement("button");
  submit.type = "submit";
  submit.className = "btn btn-primary";
  submit.textContent = "Open terminal";
  const cancel = document.createElement("button");
  cancel.type = "button";
  cancel.className = "btn btn-link";
  cancel.id = "terminal-password-cancel";
  cancel.textContent = "Cancel";
  actions.append(submit, cancel);
  body.append(title, help, password, status, actions);
  form.append(body);
  dialog.append(form);
  return {
    dialog,
    form,
    password,
    status,
    cancel,
  };
}

// The dialog parts are wired by renderPage; this helper keeps them together.
function createButton(label, ariaLabel, className) {
  const button = document.createElement("button");
  button.type = "button";
  button.className = className;
  button.textContent = label;
  button.setAttribute("aria-label", ariaLabel);
  return button;
}

function resolveTheme(choice) {
  if (choice === "light") {
    return lightTheme;
  }
  if (choice === "dark") {
    return darkTheme;
  }
  if (choice === "theme" && document.documentElement.dataset.bsTheme === "light") {
    return lightTheme;
  }
  return blackTheme;
}

function readFontSize() {
  const stored = Number.parseInt(readStored(fontSizeStorageKey, ""), 10);
  if (!Number.isInteger(stored)) {
    return defaultFontSize;
  }
  return Math.min(maximumFontSize, Math.max(minimumFontSize, stored));
}

function readAppearance() {
  const stored = readStored(appearanceStorageKey, "black");
  return appearanceChoices.includes(stored) ? stored : "black";
}

function readStored(key, fallback) {
  try {
    const value = localStorage.getItem(key);
    return value === null ? fallback : value;
  } catch (error) {
    return fallback;
  }
}

function writeStored(key, value) {
  try {
    localStorage.setItem(key, value);
  } catch (error) {
    // A browser that refuses storage keeps the choice for this page only.
  }
}

function encodeBase64(bytes) {
  let binary = "";
  const step = 0x2000;
  for (let index = 0; index < bytes.length; index += step) {
    binary += String.fromCharCode(...bytes.subarray(index, index + step));
  }
  return btoa(binary);
}

function decodeBase64(text) {
  try {
    const binary = atob(text);
    const bytes = new Uint8Array(binary.length);
    for (let index = 0; index < binary.length; index += 1) {
      bytes[index] = binary.charCodeAt(index);
    }
    return bytes;
  } catch (error) {
    return null;
  }
}

function loadScript(source) {
  return new Promise((resolve, reject) => {
    const script = document.createElement("script");
    script.src = source;
    script.addEventListener("load", () => resolve());
    script.addEventListener("error", () => reject(new Error("could not load " + source)));
    document.head.append(script);
  });
}

function loadStyle(source) {
  const existing = document.querySelector('link[data-gxb-xterm="true"]');
  if (existing !== null) {
    return Promise.resolve();
  }
  return new Promise((resolve, reject) => {
    const link = document.createElement("link");
    link.rel = "stylesheet";
    link.href = source;
    link.dataset.gxbXterm = "true";
    link.addEventListener("load", () => resolve());
    link.addEventListener("error", () => reject(new Error("could not load " + source)));
    document.head.append(link);
  });
}

function delay(milliseconds) {
  return new Promise((resolve) => {
    setTimeout(resolve, milliseconds);
  });
}
