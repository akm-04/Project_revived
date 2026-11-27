"use strict";

import { clearToken, describeReply, getToken, request, setToken, setUnauthorizedHandler } from "../transport.js";
import { openServerPicker } from "./server_picker.js";
import { openPlayerPicker } from "./player_picker.js";
import { openResourcePicker } from "./resource_picker.js";
import { openDurationPicker } from "./duration_picker.js";
import { confirmAction } from "./confirm_action.js";

const loginView = document.getElementById("login-view");
const componentsView = document.getElementById("components-view");
const loginForm = document.getElementById("login-form");
const passwordInput = document.getElementById("password");
const loginStatus = document.getElementById("login-status");

setUnauthorizedHandler(handleExpiredSession);
loginForm.addEventListener("submit", handleLogin);
if (getToken() === "") {
  showLogin();
} else {
  showComponents();
}

wireComponent("open-server-picker", "server-output", () => openServerPicker());
wireComponent("open-player-picker", "player-output", () => openPlayerPicker());
wireComponent("open-resource-picker", "resource-output", () => openResourcePicker());
wireComponent("open-duration-picker", "duration-output", () => openDurationPicker());
wireComponent("open-confirm-action", "confirm-output", () => confirmAction({
  title: "Test confirm action",
  summary: "This summary is what the action would do.",
}));

function showLogin() {
  loginView.hidden = false;
}

function showComponents() {
  loginView.hidden = true;
  componentsView.hidden = false;
}

function handleExpiredSession() {
  showLogin();
  loginStatus.textContent = "Session expired; log in again.";
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
  showComponents();
}

function wireComponent(buttonID, outputID, open) {
  const button = document.getElementById(buttonID);
  const output = document.getElementById(outputID);
  button.addEventListener("click", async () => {
    const value = await open();
    output.textContent = JSON.stringify(value, null, 2);
  });
}
