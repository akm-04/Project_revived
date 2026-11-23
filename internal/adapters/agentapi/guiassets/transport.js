"use strict";

const agentTokenKey = "gxbOperatorToken";
const loginPath = "/agent/v1/login";

let unauthorizedHandler = () => {};

// sessionStorage is the token's single home: a token removed there is gone on
// the next request, so an expired session needs no page reload (G16).
function currentToken() {
  return sessionStorage.getItem(agentTokenKey) || "";
}

export function getToken() {
  return currentToken();
}

export function setToken(value) {
  sessionStorage.setItem(agentTokenKey, value);
}

export function clearToken() {
  sessionStorage.removeItem(agentTokenKey);
}

export function setUnauthorizedHandler(handler) {
  unauthorizedHandler = handler;
}

// request is the GUI's whole agent transport: one call per action, the same
// routes the CLI uses. A 401 anywhere but login drops the token and hands the
// session back to the shell (G12).
export async function request(targetPath, options) {
  const settings = options || {};
  const headers = {};
  const token = currentToken();
  if (token !== "") {
    headers.Authorization = "Bearer " + token;
  }
  let body;
  if (settings.body !== undefined) {
    headers["Content-Type"] = "application/json";
    body = JSON.stringify(settings.body);
  }
  let response;
  try {
    response = await fetch(targetPath, { method: settings.method || "GET", headers, body });
  } catch (error) {
    // The browser's raw "Failed to fetch" text tells the operator nothing, so
    // the transport reports the one useful fact itself.
    return { ok: false, status: 0, body: { error_code: "AGENT_UNREACHABLE", message: "The operator agent is not reachable. Check that gxb-operator agent is running." } };
  }
  const text = await response.text();
  let parsed = null;
  if (text !== "") {
    try {
      parsed = JSON.parse(text);
    } catch (error) {
      parsed = text;
    }
  }
  const reply = { ok: response.ok, status: response.status, body: parsed, unauthorized: false };
  if (response.status === 401 && targetPath !== loginPath) {
    reply.unauthorized = true;
    clearToken();
    unauthorizedHandler();
  }
  return reply;
}

// loadPicture fetches one image through the same session and answers an object
// URL, or null when the picture is unavailable.
export async function loadPicture(targetPath) {
  const token = currentToken();
  let response;
  try {
    response = await fetch(targetPath, { headers: token === "" ? {} : { Authorization: "Bearer " + token } });
  } catch (error) {
    return null;
  }
  if (!response.ok) {
    return null;
  }
  return URL.createObjectURL(await response.blob());
}

export function describeReply(reply) {
  const body = reply.body;
  if (body && typeof body === "object") {
    const code = body.error_code || body.code || "";
    const message = body.message || body.error || "";
    if (code === "AGENT_BACKEND_UNAVAILABLE" || /backend is not running/i.test(message)) {
      return "Backend not running";
    }
    if (code === "AGENT_UNREACHABLE") {
      return message;
    }
    if (code !== "" || message !== "") {
      return "HTTP " + reply.status + (code !== "" ? " " + code : "") + (message !== "" ? ": " + message : "");
    }
  }
  if (typeof body === "string" && body !== "") {
    return "HTTP " + reply.status + ": " + body;
  }
  return "HTTP " + reply.status;
}
