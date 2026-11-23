"use strict";

// formatTime renders one RFC3339 value as local time and keeps the UTC value
// in the title, so hovering shows the wire value (G24). An unparseable value
// stays as it is; a missing one reads "unknown".
export function formatTime(value) {
  const element = document.createElement("time");
  const raw = typeof value === "string" ? value : "";
  const parsed = raw === "" ? NaN : Date.parse(raw);
  element.title = raw === "" ? "unknown" : raw;
  if (Number.isNaN(parsed)) {
    element.textContent = raw === "" ? "unknown" : raw;
    return element;
  }
  element.dateTime = raw;
  element.textContent = new Date(parsed).toLocaleString();
  return element;
}

export function formatTimeText(value) {
  return formatTime(value).textContent;
}

// setStatus paints a status line by tone: neutral for progress and plain facts,
// text-danger for errors, text-success for a completed action.
export function setStatus(element, text, tone) {
  element.textContent = text;
  element.classList.toggle("text-danger", tone === "error");
  element.classList.toggle("text-success", tone === "success");
}

export function emptyState(text) {
  const box = document.createElement("div");
  box.className = "empty";
  const title = document.createElement("p");
  title.className = "empty-title";
  title.textContent = text;
  box.append(title);
  return box;
}

export function pageHeader(text) {
  const header = document.createElement("div");
  header.className = "page-header mb-3";
  const title = document.createElement("h1");
  title.className = "page-title";
  title.textContent = text;
  header.append(title);
  return header;
}
