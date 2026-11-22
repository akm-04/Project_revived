"use strict";

import {
  clearToken,
  describeReply,
  getToken,
  request,
  setToken,
  setUnauthorizedHandler,
} from "./transport.js";
import { renderAdvanced, renderModuleForms } from "./advanced.js";

const pages = [
  { id: "dashboard", label: "Dashboard", modules: [] },
  { id: "ota", label: "OTA", modules: ["ota"] },
  { id: "events", label: "Events", modules: ["events"] },
  { id: "notices", label: "Notices", modules: ["publication"] },
  { id: "players", label: "Players", modules: ["player", "session"] },
  { id: "mail", label: "Mail", modules: ["mail"] },
  { id: "rewards", label: "Rewards & Redeem", modules: ["grant", "redeem"] },
  { id: "gm", label: "GM", modules: ["gm"] },
  { id: "server", label: "Server", modules: ["server"] },
  { id: "backups", label: "Backups", modules: ["backup"] },
  { id: "logs", label: "Logs", modules: ["logs"] },
  { id: "advanced", label: "Advanced", modules: null },
];

const state = {
  modules: [],
  backendError: "",
  activePage: "dashboard",
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
const logoutButton = document.getElementById("logout-button");

setUnauthorizedHandler(handleExpiredSession);
loginForm.addEventListener("submit", handleLogin);
logoutButton.addEventListener("click", handleLogout);

if (getToken() === "") {
  showLogin();
} else {
  enterApplication();
}

function showLogin() {
  loginView.hidden = false;
  appView.hidden = true;
}

function showApplication() {
  loginView.hidden = true;
  appView.hidden = false;
}

async function handleLogin(event) {
  event.preventDefault();
  loginStatus.textContent = "";
  const reply = await request("/agent/v1/login", { method: "POST", body: { password: passwordInput.value } });
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
  await request("/agent/v1/logout", { method: "POST", body: {} });
  resetSession();
}

function handleExpiredSession() {
  resetApplication();
  showLogin();
  loginStatus.textContent = "Session expired; log in again.";
}

function resetSession() {
  clearToken();
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

async function enterApplication() {
  const reply = await request("/agent/v1/modules");
  if (reply.status === 401) {
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
  state.activePage = "dashboard";
  showApplication();
  await loadBackendState();
  renderNav();
  renderPage();
}

async function loadBackendState() {
  const reply = await request("/agent/v1/backend/status");
  if (reply.status === 401) {
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

function renderPage() {
  pageView.replaceChildren();
  backendError.textContent = state.backendError;
  const page = pages.find((candidate) => candidate.id === state.activePage) || pages[0];
  if (page.id === "advanced") {
    renderAdvanced(pageView, state.modules);
    return;
  }
  pageView.append(placeholderCard(page.label));
  const modules = modulesForPage(page);
  if (modules.length === 0) {
    return;
  }
  const details = document.createElement("details");
  details.className = "card mt-3";
  const summary = document.createElement("summary");
  summary.className = "card-header";
  summary.textContent = "Advanced";
  details.append(summary);
  const body = document.createElement("div");
  body.className = "card-body";
  for (const module of modules) {
    const moduleForms = document.createElement("div");
    renderModuleForms(moduleForms, module);
    body.append(moduleForms);
  }
  details.append(body);
  pageView.append(details);
}

function modulesForPage(page) {
  if (!Array.isArray(page.modules) || page.modules.length === 0) {
    return [];
  }
  return state.modules.filter((module) => page.modules.includes(module.id));
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
