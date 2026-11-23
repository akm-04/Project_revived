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
const themeStorageKey = "gxbOperatorTheme";
const themeChoices = ["auto", "light", "dark"];
const defaultThemeChoice = "dark";
const systemDark = window.matchMedia("(prefers-color-scheme: dark)");

const navigationGroups = ["Game", "Server", "Tools"];

const pages = [
  { id: "dashboard", label: "Dashboard", group: "Game" },
  { id: "events", label: "Events", group: "Game" },
  { id: "notices", label: "Notices", group: "Game" },
  { id: "players", label: "Players", group: "Game" },
  { id: "mail", label: "Mail", group: "Game" },
  { id: "rewards", label: "Rewards & Redeem", group: "Game" },
  { id: "gm", label: "GM", group: "Game" },
  { id: "server", label: "Server", group: "Server" },
  { id: "ota", label: "OTA", group: "Server" },
  { id: "backups", label: "Backups", group: "Server" },
  { id: "logs", label: "Logs", group: "Server" },
  { id: "terminal", label: "Terminal", group: "Server" },
  { id: "settings", label: "Settings", group: "Server" },
  { id: "advanced", label: "Advanced", group: "Tools" },
];

const state = {
  modules: [],
  backendError: "",
  activePage: "dashboard",
  entered: false,
  searchQuery: "",
};

const loginView = document.getElementById("login-view");
const appView = document.getElementById("app-view");
const loginForm = document.getElementById("login-form");
const passwordInput = document.getElementById("password");
const passwordVisibility = document.getElementById("password-visibility");
const loginStatus = document.getElementById("login-status");
const loginServer = document.getElementById("login-server");
const operatorHost = document.getElementById("operator-host");
const navView = document.getElementById("nav");
const navSearch = document.getElementById("nav-search");
const sidebarToggle = document.getElementById("sidebar-toggle");
const pageView = document.getElementById("page-view");
const backendState = document.getElementById("backend-state");
const backendError = document.getElementById("backend-error");
const themeMenu = document.getElementById("theme-menu");
const themeButton = document.getElementById("theme-button");
const themeDropdown = document.getElementById("theme-dropdown");
const helpButton = document.getElementById("help-button");
const accountMenu = document.getElementById("account-menu");
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
passwordVisibility.addEventListener("click", togglePasswordVisibility);
navSearch.addEventListener("input", handleSearch);
logoutButton.addEventListener("click", handleLogout);
accountButton.addEventListener("click", toggleAccountMenu);
themeButton.addEventListener("click", toggleThemeMenu);
helpButton.addEventListener("click", openModuleHelp);
changePasswordButton.addEventListener("click", openPasswordModal);
passwordForm.addEventListener("submit", handlePasswordChange);
passwordCancel.addEventListener("click", closePasswordModal);
document.addEventListener("click", closeMenusOutside);
document.addEventListener("keydown", closeMenusOnEscape);
setInterval(pollWhileIdle, statusPollMilliseconds);
startTheme();
showServerName();

if (getToken() === "") {
  showLogin();
} else {
  enterApplication();
}

// showLogin overlays the application page; the page DOM and its form values
// stay intact underneath (G16).
function showLogin() {
  closeAccountMenu();
  closeThemeMenu();
  loginView.hidden = false;
}

function showApplication() {
  loginView.hidden = true;
  appView.hidden = false;
}

// The top-left block reads operator@host, like the reference console. The
// host is the address the browser reached the agent on.
function showServerName() {
  const host = window.location.hostname === "" ? "unknown" : window.location.hostname;
  operatorHost.textContent = host;
  loginServer.textContent = host;
}

function togglePasswordVisibility() {
  const visible = passwordInput.type === "text";
  passwordInput.type = visible ? "password" : "text";
  passwordVisibility.setAttribute("aria-pressed", visible ? "false" : "true");
  passwordVisibility.setAttribute("aria-label", visible ? "Show password" : "Hide password");
}

// G43: dark is the default look; light and auto stay selectable (G24). The
// choice drives Tabler's data-bs-theme on the root element.
function startTheme() {
  const choice = readThemeChoice();
  applyTheme(choice);
  for (const radio of document.querySelectorAll('input[name="theme-choice"]')) {
    radio.checked = radio.value === choice;
    radio.addEventListener("change", () => {
      if (!radio.checked) {
        return;
      }
      saveThemeChoice(radio.value);
      applyTheme(radio.value);
      closeThemeMenu();
    });
  }
  systemDark.addEventListener("change", () => {
    if (readThemeChoice() === "auto") {
      applyTheme("auto");
    }
  });
}

function readThemeChoice() {
  try {
    const stored = localStorage.getItem(themeStorageKey);
    return themeChoices.includes(stored) ? stored : defaultThemeChoice;
  } catch (error) {
    return defaultThemeChoice;
  }
}

function saveThemeChoice(choice) {
  try {
    localStorage.setItem(themeStorageKey, choice);
  } catch (error) {
    return;
  }
}

function applyTheme(choice) {
  const dark = choice === "dark" || (choice === "auto" && systemDark.matches);
  document.documentElement.dataset.bsTheme = dark ? "dark" : "light";
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
  state.searchQuery = "";
  navSearch.value = "";
  navView.replaceChildren();
  pageView.replaceChildren();
  document.title = "GXB Operator";
  backendError.textContent = "";
  backendState.textContent = "";
  backendState.className = "operator-backend-state";
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
    backendState.className = "operator-backend-state text-secondary";
    return;
  }
  const running = status.running === true;
  const processDetail = running && status.pid ? " (pid " + status.pid + ")" : "";
  backendState.textContent = "Backend: " + (running ? "running" + processDetail : "stopped");
  backendState.className = "operator-backend-state " + (running ? "text-success" : "text-danger");
}

function handleSearch(event) {
  state.searchQuery = event.target.value.trim().toLowerCase();
  renderNav();
}

function toggleAccountMenu() {
  const open = accountDropdown.hidden;
  closeThemeMenu();
  accountDropdown.hidden = !open;
  accountButton.setAttribute("aria-expanded", open ? "true" : "false");
}

function closeAccountMenu() {
  accountDropdown.hidden = true;
  accountButton.setAttribute("aria-expanded", "false");
}

function toggleThemeMenu() {
  const open = themeDropdown.hidden;
  closeAccountMenu();
  themeDropdown.hidden = !open;
  themeButton.setAttribute("aria-expanded", open ? "true" : "false");
}

function closeThemeMenu() {
  themeDropdown.hidden = true;
  themeButton.setAttribute("aria-expanded", "false");
}

function closeMenusOutside(event) {
  if (!themeMenu.contains(event.target)) {
    closeThemeMenu();
  }
  if (!accountMenu.contains(event.target)) {
    closeAccountMenu();
  }
}

function closeMenusOnEscape(event) {
  if (event.key !== "Escape") {
    return;
  }
  closeThemeMenu();
  closeAccountMenu();
}

// Help points at the registry-driven module help: every command and read on the
// Advanced page carries the help text the agent reported.
function openModuleHelp() {
  selectPage("advanced");
}

function selectPage(pageId) {
  state.activePage = pageId;
  closeSidebarOnPhone();
  renderNav();
  renderPage();
}

function closeSidebarOnPhone() {
  if (window.matchMedia("(max-width: 767.98px)").matches) {
    document.getElementById("operator-menu").classList.remove("show");
    sidebarToggle.setAttribute("aria-expanded", "false");
  }
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

// The menu groups Game, Server and Tools; the search box filters the entries as
// the operator types and hides a section that has no match.
function renderNav() {
  navView.replaceChildren();
  let matches = 0;
  for (const groupName of navigationGroups) {
    const groupEntries = pages.filter((page) => page.group === groupName && navEntryMatches(page));
    if (groupEntries.length === 0) {
      continue;
    }
    const section = document.createElement("div");
    section.className = "operator-nav-section";
    const heading = document.createElement("div");
    heading.className = "operator-nav-heading";
    heading.textContent = groupName;
    section.append(heading);
    for (const page of groupEntries) {
      section.append(navEntry(page));
      matches += 1;
    }
    navView.append(section);
  }
  if (matches === 0) {
    const empty = document.createElement("p");
    empty.className = "operator-nav-empty";
    empty.textContent = "No matching pages.";
    navView.append(empty);
  }
}

function navEntryMatches(page) {
  return state.searchQuery === "" || page.label.toLowerCase().includes(state.searchQuery);
}

function navEntry(page) {
  const button = document.createElement("button");
  button.type = "button";
  button.className = "nav-link text-start" + (page.id === state.activePage ? " active" : "");
  button.textContent = page.label;
  if (page.id === state.activePage) {
    button.setAttribute("aria-current", "page");
  }
  button.addEventListener("click", () => selectPage(page.id));
  return button;
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
  document.title = page.label + " · GXB Operator";
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
