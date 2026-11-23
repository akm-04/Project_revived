"use strict";

import { actionButton, createModal, errorParagraph } from "./modal.js";

const presets = [
  { days: 1, label: "1 day" },
  { days: 3, label: "3 days" },
  { days: 7, label: "7 days" },
  { days: 15, label: "15 days" },
  { days: 30, label: "30 days" },
];

const millisecondsPerDay = 86400000;

// openDurationPicker returns {start, end} as UTC RFC3339. Presets run from now;
// Custom takes the browser's local datetime-local values and converts them.
export function openDurationPicker(options) {
  const settings = options || {};
  return new Promise((resolve) => {
    let settled = false;
    function settle(value) {
      if (settled) {
        return;
      }
      settled = true;
      resolve(value);
    }
    const dialog = createModal({
      title: settings.title || "Duration",
      modalId: "duration-picker",
      onClose: () => settle(null),
    });
    let mode = "preset";
    let days = 7;

    const presetRow = document.createElement("div");
    presetRow.className = "duration-presets mb-3";
    const presetButtons = [];
    for (const preset of presets) {
      const button = actionButton(preset.label, false, "duration-" + preset.days);
      button.classList.add("duration-preset");
      button.addEventListener("click", () => {
        mode = "preset";
        days = preset.days;
        customFields.hidden = true;
        markActive();
      });
      presetButtons.push(button);
      presetRow.append(button);
    }
    const customButton = actionButton("Custom", false, "duration-custom");
    customButton.classList.add("duration-preset");
    presetRow.append(customButton);

    const customFields = document.createElement("div");
    customFields.hidden = true;
    const startInput = datetimeField(customFields, "duration-start", "Start (local time)");
    const endInput = datetimeField(customFields, "duration-end", "End (local time)");
    endInput.value = localInputValue(new Date(Date.now() + millisecondsPerDay));

    const failure = errorParagraph();
    dialog.body.append(presetRow, customFields, failure);

    customButton.addEventListener("click", () => {
      mode = "custom";
      customFields.hidden = false;
      if (startInput.value === "") {
        startInput.value = localInputValue(new Date());
      }
      if (endInput.value === "") {
        endInput.value = localInputValue(new Date(Date.now() + millisecondsPerDay));
      }
      markActive();
      startInput.focus();
    });

    const cancel = actionButton("Cancel", false, "duration-cancel");
    const confirm = actionButton("Use duration", true, "duration-confirm");
    cancel.addEventListener("click", () => dialog.close());
    confirm.addEventListener("click", () => {
      failure.textContent = "";
      if (mode === "preset") {
        const start = new Date();
        settle({ start: start.toISOString(), end: new Date(start.getTime() + days * millisecondsPerDay).toISOString() });
        dialog.close();
        return;
      }
      const start = parseLocal(startInput.value);
      const end = parseLocal(endInput.value);
      if (start === null || end === null) {
        failure.textContent = "Enter both a start and an end time.";
        return;
      }
      if (end.getTime() <= start.getTime()) {
        failure.textContent = "The end must be after the start.";
        return;
      }
      settle({ start: start.toISOString(), end: end.toISOString() });
      dialog.close();
    });
    dialog.footer.append(cancel, confirm);
    markActive();

    function markActive() {
      for (const button of presetButtons) {
        const active = mode === "preset" && button.id === "duration-" + days;
        button.className = "btn duration-preset " + (active ? "btn-primary" : "btn-outline-secondary");
      }
      customButton.className = "btn duration-preset " + (mode === "custom" ? "btn-primary" : "btn-outline-secondary");
    }
  });
}

function datetimeField(container, identifier, label) {
  const row = document.createElement("div");
  row.className = "mb-3";
  const element = document.createElement("label");
  element.className = "form-label";
  element.htmlFor = identifier;
  element.textContent = label;
  const input = document.createElement("input");
  input.type = "datetime-local";
  input.className = "form-control";
  input.id = identifier;
  row.append(element, input);
  container.append(row);
  return input;
}

function localInputValue(date) {
  const pad = (value) => String(value).padStart(2, "0");
  return date.getFullYear() + "-" + pad(date.getMonth() + 1) + "-" + pad(date.getDate()) +
    "T" + pad(date.getHours()) + ":" + pad(date.getMinutes());
}

function parseLocal(text) {
  if (text === "") {
    return null;
  }
  const parsed = new Date(text);
  if (Number.isNaN(parsed.getTime())) {
    return null;
  }
  return parsed;
}
