package agentapi

import (
	"embed"
	"errors"
	"net/http"
	"os"
	"path"
	"path/filepath"
	"strings"

	"gxb.local/backend/v2/internal/application/operatoragent"
	"gxb.local/backend/v2/internal/application/otarelease"
)

// The GUI is compiled into the agent: plain HTML, CSS and JavaScript, no build
// step, no CDN and no external font (I11A_2_PLAN "O5 GUI").
//
//go:embed guiassets/index.html guiassets/app.css guiassets/app.js
var guiAssets embed.FS

const contentSecurityPolicy = "default-src 'self'; script-src 'self'; style-src 'self'; " +
	"img-src 'self' blob:; connect-src 'self'; object-src 'none'; base-uri 'none'; " +
	"frame-ancestors 'none'; form-action 'self'"

var guiContentTypes = map[string]string{
	"/":            "text/html; charset=utf-8",
	"/gui/app.css": "text/css; charset=utf-8",
	"/gui/app.js":  "text/javascript; charset=utf-8",
}

var guiAssetsByName = map[string]string{
	"/":            "guiassets/index.html",
	"/gui/app.css": "guiassets/app.css",
	"/gui/app.js":  "guiassets/app.js",
}

var imageContentTypes = map[string]string{
	".png":  "image/png",
	".jpg":  "image/jpeg",
	".jpeg": "image/jpeg",
	".gif":  "image/gif",
	".webp": "image/webp",
	".bmp":  "image/bmp",
}

// serveGUI answers the embedded GUI files. They carry no operator data, so the
// login page itself is readable before a session exists; every data route still
// needs the agent session.
func (handler Handler) serveGUI(writer http.ResponseWriter, request *http.Request) {
	name, found := guiAssetsByName[request.URL.Path]
	if !found || request.Method != http.MethodGet {
		writeRefusal(writer, http.StatusNotFound, operatoragent.CodeNotFound, "no such GUI route")
		return
	}
	contents, err := guiAssets.ReadFile(name)
	if err != nil {
		writeRefusal(writer, http.StatusInternalServerError, operatoragent.CodeFailed, "the GUI asset is unreadable")
		return
	}
	setGUIHeaders(writer, guiContentTypes[request.URL.Path])
	writer.WriteHeader(http.StatusOK)
	_, _ = writer.Write(contents)
}

// serveRes serves one catalogue picture read-only from the OTA settings
// res_path (I11A_OPERATOR_COMMANDS_V1 ruling 9). A path that leaves the root,
// a symlink that leaves it, a missing file and a non-image are all refused.
func (handler Handler) serveRes(writer http.ResponseWriter, request *http.Request) {
	relative, valid := cleanResPath(strings.TrimPrefix(request.URL.Path, resPrefix))
	if !valid {
		writeRefusal(writer, http.StatusBadRequest, operatoragent.CodeBodyInvalid, "the res path is not a relative file path")
		return
	}
	root, err := handler.resRoot()
	if err != nil {
		writeRefusal(writer, http.StatusNotFound, operatoragent.CodeNotFound, "the res folder is not configured")
		return
	}
	resolved, err := filepath.EvalSymlinks(filepath.Join(root, relative))
	if err != nil || !withinResRoot(resolved, root) {
		writeRefusal(writer, http.StatusNotFound, operatoragent.CodeNotFound, "no such picture")
		return
	}
	info, err := os.Stat(resolved)
	if err != nil || !info.Mode().IsRegular() {
		writeRefusal(writer, http.StatusNotFound, operatoragent.CodeNotFound, "no such picture")
		return
	}
	mediaType, image := imageContentTypes[strings.ToLower(filepath.Ext(resolved))]
	if !image {
		writeRefusal(writer, http.StatusBadRequest, operatoragent.CodeBodyInvalid, "only image files are served")
		return
	}
	file, err := os.Open(resolved)
	if err != nil {
		writeRefusal(writer, http.StatusNotFound, operatoragent.CodeNotFound, "no such picture")
		return
	}
	defer file.Close()
	setGUIHeaders(writer, mediaType)
	writer.Header().Set("Cache-Control", "no-store")
	http.ServeContent(writer, request, info.Name(), info.ModTime(), file)
}

// resRoot resolves the res_path of the OTA settings. It is read per request so
// an ota.settings.set change applies without restarting the agent.
func (handler Handler) resRoot() (string, error) {
	settings, err := otarelease.SettingsFile{Root: handler.OTARoot}.Load()
	if err != nil {
		return "", err
	}
	if settings.ResPath == "" {
		return "", errors.New("settings.json has no res_path")
	}
	return filepath.EvalSymlinks(settings.ResPath)
}

// cleanResPath accepts only a relative path whose segments never name ".."; it
// also refuses an absolute path, including one hidden behind an encoded slash.
func cleanResPath(raw string) (string, bool) {
	unixPath := strings.ReplaceAll(raw, "\\", "/")
	if unixPath == "" || strings.HasPrefix(unixPath, "/") {
		return "", false
	}
	for _, segment := range strings.Split(unixPath, "/") {
		if segment == ".." {
			return "", false
		}
	}
	cleaned := path.Clean(unixPath)
	if cleaned == "." || cleaned == ".." || strings.HasPrefix(cleaned, "../") {
		return "", false
	}
	if filepath.IsAbs(filepath.FromSlash(cleaned)) {
		return "", false
	}
	return filepath.FromSlash(cleaned), true
}

func withinResRoot(resolved, root string) bool {
	return resolved == root || strings.HasPrefix(resolved, root+string(os.PathSeparator))
}

func setGUIHeaders(writer http.ResponseWriter, contentType string) {
	writer.Header().Set("Content-Type", contentType)
	writer.Header().Set("Content-Security-Policy", contentSecurityPolicy)
	writer.Header().Set("X-Content-Type-Options", "nosniff")
	writer.Header().Set("Referrer-Policy", "no-referrer")
}
