"use strict";

import {
  clearToken,
  describeReply,
  getToken,
  request,
  setToken,
  setUnauthorizedHandler,
} from "./transport.js";
import { renderAdvanced } from "./advanced.js";

const statusPollMilliseconds = 15000;

const pages = [
  { id: "dashboard", label: "Dashboard" },
  { id: "ota", label: "OTA" },
  { id: "events", label: "Events" },
  { id: "notices", label: "Notices" },
  { id: "players", label: "Players" },
  { id: "mail", label: "Mail" },
  { id: "rewards", label: "Rewards & Redeem" },
  { id: "gm", label: "GM" },
  { id: "server", label: "Server" },
  { id: "backups", label: "Backups" },
  { id: "logs", label: "Logs" },
  { id: "settings", label: "Settings" },
  { id: "advanced", label: "Advanced" },
];

const state = {
  modules: [],
  backendError: "",
  activePage: "dashboard",
  entered: false,
};

const loginView = document.getElementById("login-view");
const appView = document.getElementById("app-view");
const loginForm = document.getElementById("login-form");
const passwordInput = document.getElementById("password");
const loginStatus = document.getElementById("login-status");
const navView = document.getElementById("nav");
const pageView = document.getElementById("page-view");
const backendState = document.getElementById("backend-state");
const backendError = document.getElementById("backend-error");
const accountButton = document.getElementById("account-button");
const accountDropdown = document.getElementById("account-dropdown");
const changePasswordButton = document.getElementById("change-password-button");
const logoutButton = document.getElementById("logout-button");
const passwordModal = document.getElementById("password-modal");
const passwordForm = document.getElementById("password-form");
const currentPasswordInput = document.getElementById("current-password");
const newPasswordInput = document.getElementById("new-password");
const repeatPasswordInput = document.getElementById("repeat-password");
const passwordStatus = document.getElementById("password-status");
const passwordCancel = document.getElementById("password-cancel");

setUnauthorizedHandler(handleExpiredSession);
loginForm.addEventListener("submit", handleLogin);
logoutButton.addEventListener("click", handleLogout);
accountButton.addEventListener("click", toggleAccountMenu);
changePasswordButton.addEventListener("click", openPasswordModal);
passwordForm.addEventListener("submit", handlePasswordChange);
passwordCancel.addEventListener("click", closePasswordModal);
setInterval(pollWhileIdle, statusPollMilliseconds);

if (getToken() === "") {
  showLogin();
} else {
  enterApplication();
}

// showLogin overlays the application page; the page DOM and its form values
// stay intact underneath (G16).
function showLogin() {
  closeAccountMenu();
  closePasswordModal();
  loginView.hidden = false;
}

function showApplication() {
  loginView.hidden = true;
  appView.hidden = false;
}

async function handleLogin(event) {
  event.preventDefault();
  loginStatus.textContent = "";
  const reply = await request("/agent/v1/login", { method: "POST", body: { password: passwordInput.value } });
  if (reply.status === 401) {
    clearToken();
    return;
  }
  if (!reply.ok) {
    loginStatus.textContent = describeReply(reply);
    return;
  }
  if (!reply.body || typeof reply.body.token !== "string" || reply.body.token === "") {
    loginStatus.textContent = "The agent login reply carried no token.";
    return;
  }
  setToken(reply.body.token);
  passwordInput.value = "";
  await enterApplication();
}

async function handleLogout() {
  closeAccountMenu();
  await request("/agent/v1/logout", { method: "POST", body: {} });
  resetSession();
}

function handleExpiredSession() {
  showLogin();
  loginStatus.textContent = "Session expired; log in again.";
}

function resetSession() {
  clearToken();
  state.entered = false;
  resetApplication();
  loginStatus.textContent = "";
  showLogin();
}

function resetApplication() {
  state.modules = [];
  state.backendError = "";
  state.activePage = "dashboard";
  navView.replaceChildren();
  pageView.replaceChildren();
  backendError.textContent = "";
  backendState.textContent = "";
  backendState.className = "nav-link";
}

// enterApplication loads the registry. A first entry renders the dashboard; a
// relogin after a 401 only refreshes the registry, so the operator returns to
// the same page with the same form values (G16).
async function enterApplication() {
  const reply = await request("/agent/v1/modules");
  if (reply.unauthorized) {
    return;
  }
  if (!reply.ok) {
    showLogin();
    loginStatus.textContent = describeReply(reply);
    return;
  }
  const body = reply.body && typeof reply.body === "object" ? reply.body : {};
  state.modules = Array.isArray(body.modules) ? body.modules : [];
  state.backendError = body.backend_error || "";
  showApplication();
  if (!state.entered) {
    state.entered = true;
    state.activePage = "dashboard";
    renderNav();
    renderPage();
  } else {
    renderNav();
  }
  await loadBackendState();
}

function pollWhileIdle() {
  if (!state.entered || loginView.hidden === false) {
    return;
  }
  void loadBackendState();
}

async function loadBackendState() {
  const reply = await request("/agent/v1/backend/status");
  if (reply.unauthorized) {
    return;
  }
  const status = reply.body && typeof reply.body === "object" ? reply.body : null;
  if (!reply.ok || status === null) {
    backendState.textContent = "Backend: unknown";
    backendState.className = "nav-link text-secondary";
    return;
  }
  const running = status.running === true;
  const processDetail = running && status.pid ? " (pid " + status.pid + ")" : "";
  backendState.textContent = "Backend: " + (running ? "running" + processDetail : "stopped");
  backendState.className = "nav-link " + (running ? "text-success" : "text-danger");
}

function toggleAccountMenu() {
  const open = accountDropdown.hidden;
  accountDropdown.hidden = !open;
  accountButton.setAttribute("aria-expanded", open ? "true" : "false");
}

function closeAccountMenu() {
  accountDropdown.hidden = true;
  accountButton.setAttribute("aria-expanded", "false");
}

function openPasswordModal() {
  closeAccountMenu();
  passwordModal.hidden = false;
  currentPasswordInput.focus();
}

function closePasswordModal() {
  passwordModal.hidden = true;
  currentPasswordInput.value = "";
  newPasswordInput.value = "";
  repeatPasswordInput.value = "";
  passwordStatus.textContent = "";
}

async function handlePasswordChange(event) {
  event.preventDefault();
  passwordStatus.textContent = "";
  if (newPasswordInput.value !== repeatPasswordInput.value) {
    passwordStatus.textContent = "The new passwords do not match.";
    return;
  }
  const reply = await request("/agent/v1/password", {
    method: "POST",
    body: { current: currentPasswordInput.value, new: newPasswordInput.value },
  });
  if (reply.unauthorized) {
    return;
  }
  if (!reply.ok) {
    passwordStatus.textContent = describeReply(reply);
    return;
  }
  closePasswordModal();
  state.entered = false;
  resetSession();
  loginStatus.textContent = "Password changed; log in again.";
}

function renderNav() {
  navView.replaceChildren();
  for (const page of pages) {
    const button = document.createElement("button");
    button.type = "button";
    button.className = "nav-link text-start" + (page.id === state.activePage ? " active" : "");
    button.textContent = page.label;
    button.addEventListener("click", () => {
      state.activePage = page.id;
      renderNav();
      renderPage();
    });
    navView.append(button);
  }
}

let renderSequence = 0;

// Each page lives in pages/<id>.js and exports renderPage(container, context);
// a page without a file yet keeps the placeholder, so page leaves never edit
// this file.
async function renderPage() {
  renderSequence += 1;
  const sequence = renderSequence;
  pageView.replaceChildren();
  backendError.textContent = state.backendError;
  const page = pages.find((candidate) => candidate.id === state.activePage) || pages[0];
  if (page.id === "advanced") {
    renderAdvanced(pageView, state.modules);
    return;
  }
  const view = await loadPageView(page.id);
  if (sequence !== renderSequence) {
    return;
  }
  const content = document.createElement("div");
  pageView.append(content);
  if (view) {
    view.renderPage(content, { modules: state.modules, page });
  } else {
    content.append(placeholderCard(page.label));
  }
}

async function loadPageView(pageId) {
  try {
    const view = await import(`./pages/${pageId}.js`);
    return typeof view.renderPage === "function" ? view : null;
  } catch (error) {
    return null;
  }
}

function placeholderCard(label) {
  const card = document.createElement("div");
  card.className = "card card-body";
  const heading = document.createElement("h2");
  heading.className = "card-title";
  heading.textContent = label;
  const text = document.createElement("p");
  text.className = "module-help mb-0";
  text.textContent = "page arrives in a later leaf";
  card.append(heading, text);
  return card;
}
