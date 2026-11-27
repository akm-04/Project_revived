"use strict";

// createModal builds one Tabler modal layer. The backdrop and the full-screen
// modal element are separate fixed layers, so no inline style or CSP change is
// needed; Escape, the close button and a click outside the dialog close it.
export function createModal(options) {
  const settings = options || {};
  const backdrop = document.createElement("div");
  backdrop.className = "modal-backdrop";
  const modal = document.createElement("div");
  modal.className = "modal d-block";
  modal.setAttribute("role", "dialog");
  modal.setAttribute("aria-modal", "true");
  if (settings.modalId) {
    modal.id = settings.modalId;
  }
  const dialog = document.createElement("div");
  dialog.className = "modal-dialog modal-dialog-centered" + (settings.wide ? " modal-lg" : "");
  const content = document.createElement("div");
  content.className = "modal-content";
  const header = document.createElement("div");
  header.className = "modal-header";
  const title = document.createElement("h2");
  title.className = "modal-title";
  title.textContent = settings.title || "";
  const closeButton = document.createElement("button");
  closeButton.type = "button";
  closeButton.className = "btn-close";
  closeButton.setAttribute("aria-label", "Close");
  header.append(title, closeButton);
  const body = document.createElement("div");
  body.className = "modal-body";
  const footer = document.createElement("div");
  footer.className = "modal-footer";
  content.append(header, body, footer);
  dialog.append(content);
  modal.append(dialog);
  document.body.append(backdrop, modal);

  let closed = false;
  function close() {
    if (closed) {
      return;
    }
    closed = true;
    document.removeEventListener("keydown", onKeyDown);
    backdrop.remove();
    modal.remove();
    if (settings.onClose) {
      settings.onClose();
    }
  }
  function onKeyDown(event) {
    if (event.key === "Escape") {
      event.preventDefault();
      close();
    }
  }
  closeButton.addEventListener("click", close);
  modal.addEventListener("click", (event) => {
    if (event.target === modal) {
      close();
    }
  });
  document.addEventListener("keydown", onKeyDown);
  return { modal, body, footer, close };
}

export function errorParagraph() {
  const element = document.createElement("p");
  element.className = "status";
  element.setAttribute("role", "alert");
  return element;
}

export function actionButton(label, primary, identifier) {
  const button = document.createElement("button");
  button.type = "button";
  button.className = "btn " + (primary ? "btn-primary" : "btn-outline-secondary");
  button.textContent = label;
  if (identifier) {
    button.id = identifier;
  }
  return button;
}
