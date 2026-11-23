"use strict";

import { loadPicture } from "./transport.js";

// pictureElement draws one catalogue picture; a missing or unreadable file
// keeps a marked placeholder instead of a broken image.
export function pictureElement(iconPath) {
  const wrapper = document.createElement("span");
  const placeholder = document.createElement("span");
  placeholder.className = "placeholder";
  placeholder.textContent = "missing";
  const image = document.createElement("img");
  image.className = "picture";
  image.alt = iconPath;
  image.hidden = true;
  wrapper.append(placeholder, image);
  if (iconPath === "") {
    return wrapper;
  }
  const targetPath = "/agent/v1/res/" + iconPath.split("/").map(encodeURIComponent).join("/");
  loadPicture(targetPath).then((objectURL) => {
    if (objectURL === null) {
      return;
    }
    image.src = objectURL;
    image.hidden = false;
    placeholder.hidden = true;
  });
  return wrapper;
}
