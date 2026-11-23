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
//go:embed guiassets
var guiAssets embed.FS

const guiAssetsRoot = "guiassets/"

const contentSecurityPolicy = "default-src 'self'; script-src 'self'; style-src 'self'; " +
	"img-src 'self' blob: data:; connect-src 'self'; object-src 'none'; base-uri 'none'; " +
	"frame-ancestors 'none'; form-action 'self'"

var guiContentTypes = map[string]string{
	".html": "text/html; charset=utf-8",
	".css":  "text/css; charset=utf-8",
	".js":   "text/javascript; charset=utf-8",
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
// needs the agent session. Only the index and files under /gui/ are served, and
// only with the three asset content types; an unknown file or an escaping path
// is not found.
func (handler Handler) serveGUI(writer http.ResponseWriter, request *http.Request) {
	if request.Method != http.MethodGet {
		writeRefusal(writer, http.StatusNotFound, operatoragent.CodeNotFound, "no such GUI route")
		return
	}
	name, found := guiAssetName(request.URL.Path)
	if !found {
		writeRefusal(writer, http.StatusNotFound, operatoragent.CodeNotFound, "no such GUI route")
		return
	}
	contents, err := guiAssets.ReadFile(name)
	if err != nil {
		writeRefusal(writer, http.StatusNotFound, operatoragent.CodeNotFound, "no such GUI route")
		return
	}
	setGUIHeaders(writer, guiContentTypes[strings.ToLower(path.Ext(name))])
	writer.WriteHeader(http.StatusOK)
	_, _ = writer.Write(contents)
}

// guiAssetName maps one URL path to an embedded file. The index is the only
// path outside /gui/; every other asset must stay under guiassets/ with a
// serveable extension.
func guiAssetName(urlPath string) (string, bool) {
	if urlPath == "/" {
		return guiAssetsRoot + "index.html", true
	}
	relative, found := strings.CutPrefix(urlPath, "/gui/")
	if !found {
		return "", false
	}
	cleaned, valid := cleanAssetPath(relative)
	if !valid {
		return "", false
	}
	name := guiAssetsRoot + cleaned
	if _, serveable := guiContentTypes[strings.ToLower(path.Ext(name))]; !serveable {
		return "", false
	}
	return name, true
}

// cleanAssetPath keeps only a relative slash path whose segments never name
// ".."; an empty, absolute or escaping path is refused.
func cleanAssetPath(raw string) (string, bool) {
	if raw == "" || strings.HasPrefix(raw, "/") || strings.Contains(raw, "\\") {
		return "", false
	}
	for _, segment := range strings.Split(raw, "/") {
		if segment == ".." {
			return "", false
		}
	}
	cleaned := path.Clean(raw)
	if cleaned == "." || cleaned == ".." || strings.HasPrefix(cleaned, "../") {
		return "", false
	}
	return cleaned, true
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
	roots, err := handler.resRoots()
	if err != nil {
		writeRefusal(writer, http.StatusNotFound, operatoragent.CodeNotFound, "the res folder is not configured")
		return
	}
	// The game keeps lazily downloaded files under res/web/<rest>, the same file
	// as res/<rest> (stock writable alias), so each root is tried plain and
	// under web/. Every candidate still has to resolve inside that root.
	var resolved string
	var resolvedInfo os.FileInfo
	for _, root := range roots {
		for _, base := range []string{root, filepath.Join(root, "web")} {
			candidate, resolveErr := filepath.EvalSymlinks(filepath.Join(base, relative))
			if resolveErr != nil || !withinResRoot(candidate, root) {
				continue
			}
			info, statErr := os.Stat(candidate)
			if statErr == nil && info.Mode().IsRegular() {
				resolved, resolvedInfo = candidate, info
				break
			}
		}
		if resolved != "" {
			break
		}
	}
	if resolved == "" {
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
	http.ServeContent(writer, request, resolvedInfo.Name(), resolvedInfo.ModTime(), file)
}

// resRoots resolves the picture roots in lookup order: res_path first, then the
// optional apk_res_path that holds icons living only in the APK res tree. Both
// are read per request so an ota.settings.set change applies without a restart.
func (handler Handler) resRoots() ([]string, error) {
	settings, err := otarelease.SettingsFile{Root: handler.OTARoot}.Load()
	if err != nil {
		return nil, err
	}
	roots := make([]string, 0, 2)
	for _, configured := range []string{settings.ResPath, settings.ApkResPath} {
		if configured == "" {
			continue
		}
		resolved, resolveErr := filepath.EvalSymlinks(configured)
		if resolveErr != nil {
			continue
		}
		roots = append(roots, resolved)
	}
	if len(roots) == 0 {
		return nil, errors.New("settings.json has no res_path")
	}
	return roots, nil
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
