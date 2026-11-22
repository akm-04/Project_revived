package operatoragent

import (
	"context"
	"encoding/json"
	"errors"
	"fmt"
	"net/url"
	"path/filepath"

	"gxb.local/backend/v2/internal/application/operator"
	"gxb.local/backend/v2/internal/application/otabuild"
	apprelease "gxb.local/backend/v2/internal/application/otarelease"
	domain "gxb.local/backend/v2/internal/domain/otarelease"
)

// OTABuildKind is the long operation kind of `ota build`.
const OTABuildKind = "ota.build"

// BuildRequest is the agent API / CLI request of `ota build`.
type BuildRequest struct {
	Lane        string `json:"lane"`
	Version     string `json:"version"`
	Rollback    bool   `json:"rollback"`
	LazyRefresh bool   `json:"lazy_refresh,omitempty"`
	Reason      string `json:"reason,omitempty"`
	SemanticKey string `json:"semantic_key,omitempty"`
}

// OTAOperationStarter starts the build long operation and returns it at once.
type OTAOperationStarter interface {
	Start(context.Context, BuildRequest) (Operation, error)
}

// Build runs `ota build`: read the backend status, build the lane offline, then
// register the finished build. It never publishes (I11A_1_PLAN "L4c
// decisions").
type Build struct {
	Config     Config
	Operator   OperatorClient
	Operations *Operations
}

type buildFingerprint struct {
	Lane        string `json:"lane"`
	Version     string `json:"version"`
	Rollback    bool   `json:"rollback"`
	LazyRefresh bool   `json:"lazy_refresh"`
}

type otaStatusReply struct {
	Revision int64 `json:"revision"`
	Active   struct {
		Assets *string `json:"assets"`
	} `json:"active"`
}

// releaseExists asks the backend's exact-version read. Any failure fails the
// step closed, so a release that the bounded status list omits (WITHDRAWN,
// SUPERSEDED or past its bound) can still not be built twice (L4f fix 2).
func (build Build) releaseExists(ctx context.Context, version string) (bool, error) {
	response, err := build.Operator.Read(ctx, "ota.release", "version="+url.QueryEscape(version))
	if err != nil {
		return false, err
	}
	if response.Status != 200 {
		if response.Status == 409 {
			return false, &BackendRefusal{Status: response.Status, Body: response.Body}
		}
		return false, fmt.Errorf("ota.release answered HTTP %d", response.Status)
	}
	var reply struct {
		Exists bool `json:"exists"`
	}
	if err := json.Unmarshal(response.Body, &reply); err != nil {
		return false, fmt.Errorf("ota.release replied no existence flag: %w", err)
	}
	return reply.Exists, nil
}

// assetsSidecarPath names the active assets release's res sidecar; the build
// wrote it beside the volumes as <version>-<sha256[:12]>.zip.res.json.
func assetsSidecarPath(otaRoot, version string) (string, error) {
	matches, err := filepath.Glob(filepath.Join(otaRoot, "updates", "assets", version+"-*.zip.res.json"))
	if err != nil {
		return "", Refuse(CodeBuildConfig, "the active assets sidecar cannot be found: "+err.Error())
	}
	if len(matches) != 1 {
		return "", Refuse(CodeBuildConfig, fmt.Sprintf("the active assets release %s has no single res sidecar (%d found)", version, len(matches)))
	}
	return matches[0], nil
}

// Start validates the request, mints or reuses the semantic key and starts the
// operation. Invalid input is a permanent refusal the API answers 409.
func (build Build) Start(ctx context.Context, request BuildRequest) (Operation, error) {
	if build.Operations == nil || build.Operator == nil {
		return Operation{}, Refuse(CodeBuildConfig, "the agent build is not configured")
	}
	lane, err := domain.ParseLane(request.Lane)
	if err != nil {
		return Operation{}, Refuse(CodeBuildLaneInvalid, err.Error())
	}
	version, err := domain.ParseVersion(request.Version)
	if err != nil {
		return Operation{}, Refuse(CodeBuildVersionInvalid, err.Error())
	}
	if build.Config.OTARoot == "" {
		return Operation{}, Refuse(CodeBuildConfig, "agent.json has no ota_root")
	}
	if request.LazyRefresh && lane != domain.LaneCode {
		return Operation{}, Refuse(CodeBuildInputInvalid, "lazy refresh is only an input of the code lane")
	}
	fingerprint, err := json.Marshal(buildFingerprint{Lane: string(lane), Version: version.String(), Rollback: request.Rollback, LazyRefresh: request.LazyRefresh})
	if err != nil {
		return Operation{}, err
	}
	semanticKey := request.SemanticKey
	if semanticKey == "" {
		semanticKey = build.Operations.ReusableKey(OTABuildKind, fingerprint)
	}
	if semanticKey == "" {
		semanticKey, err = NewToken()
		if err != nil {
			return Operation{}, err
		}
	}
	reason := request.Reason
	if reason == "" {
		reason = "ota build " + version.String()
	}

	var built otabuild.Result
	assetsVersion := ""
	steps := []Step{
		{Name: "read ota.status", Run: func(ctx context.Context) (any, error) {
			response, err := build.Operator.Read(ctx, "ota.status", "")
			if err != nil {
				return nil, err
			}
			if response.Status != 200 {
				return nil, &BackendRefusal{Status: response.Status, Body: response.Body}
			}
			var status otaStatusReply
			if err := json.Unmarshal(response.Body, &status); err != nil {
				return nil, fmt.Errorf("ota.status replied no release list: %w", err)
			}
			if status.Active.Assets != nil {
				assetsVersion = *status.Active.Assets
			}
			exists, err := build.releaseExists(ctx, version.String())
			if err != nil {
				return nil, err
			}
			if exists {
				return nil, Refuse(CodeVersionExists, "the release number already exists")
			}
			return map[string]any{"revision": status.Revision}, nil
		}},
		{Name: "build", Run: func(ctx context.Context) (any, error) {
			input := otabuild.Input{
				Lane:          string(lane),
				Version:       version.String(),
				Rollback:      request.Rollback,
				StockBaseline: build.Config.StockBaseline,
				StockCatalog:  build.Config.StockCatalog,
				ClientTree:    build.Config.ClientTree,
				Origins:       build.Config.Origins,
				UpdatesDir:    filepath.Join(build.Config.OTARoot, "updates", string(lane)),
				StagingDir:    filepath.Join(build.Config.OTARoot, "staging"),
			}
			if request.LazyRefresh {
				if assetsVersion == "" {
					return nil, Refuse(CodeBuildNoAssetsRelease, "there is no ACTIVE assets release to refresh")
				}
				sidecar, err := assetsSidecarPath(build.Config.OTARoot, assetsVersion)
				if err != nil {
					return nil, err
				}
				input.LazyRefresh = true
				input.AssetsSidecar = sidecar
			}
			settings, err := apprelease.SettingsFile{Root: build.Config.OTARoot}.Load()
			if err != nil {
				return nil, Refuse(CodeBuildConfig, "settings.json is unreadable: "+err.Error())
			}
			input.VolumeByteLimit = settings.VolumeLimitBytes()
			if lane == domain.LaneAssets || request.LazyRefresh {
				input.ResPath = settings.ResPath
			}
			result, err := otabuild.Build(ctx, input)
			if err != nil {
				return nil, buildRefusal(err)
			}
			built = result
			return map[string]any{"report": result.Report}, nil
		}},
		{Name: "register_build", Run: func(ctx context.Context) (any, error) {
			payload, err := json.Marshal(built.Request)
			if err != nil {
				return nil, err
			}
			response, err := build.Operator.Command(ctx, OperatorRequest{
				Name: "ota.register_build",
				Envelope: operator.Envelope{
					Principal:   "root",
					Role:        operator.RoleRoot,
					Scope:       "global",
					Reason:      reason,
					SemanticKey: semanticKey,
				},
				Payload: payload,
			})
			if err != nil {
				return nil, err
			}
			if response.Status < 200 || response.Status >= 300 {
				return nil, &BackendRefusal{Status: response.Status, Body: response.Body}
			}
			return map[string]any{"release": json.RawMessage(response.Body), "report": built.Report}, nil
		}},
	}
	return build.Operations.Start(ctx, OTABuildKind, semanticKey, fingerprint, steps)
}

// buildRefusalCodes maps every otabuild refusal kind to one stable AGENT_* code.
var buildRefusalCodes = []struct {
	kind error
	code string
}{
	{otabuild.ErrInvalidLane, CodeBuildLaneInvalid},
	{otabuild.ErrInvalidVersion, CodeBuildVersionInvalid},
	{otabuild.ErrInvalidInput, CodeBuildInputInvalid},
	{otabuild.ErrEmptyPackage, CodeBuildEmpty},
	{otabuild.ErrDuplicatePath, CodeBuildDuplicatePath},
	{otabuild.ErrUpdateSceneForbidden, CodeBuildForbiddenFile},
	{otabuild.ErrOriginMismatch, CodeBuildOriginMismatch},
	{otabuild.ErrOriginsMissing, CodeBuildOriginsMissing},
	{otabuild.ErrAbiMismatch, CodeBuildAbiMismatch},
	{otabuild.ErrStockHashMismatch, CodeBuildStockMismatch},
	{otabuild.ErrPatchKind, CodeBuildPatchKind},
	{otabuild.ErrInvalidPatch, CodeBuildPatchInvalid},
	{otabuild.ErrPatchAnchor, CodeBuildPatchAnchor},
	{otabuild.ErrVolumeLimit, CodeBuildVolumeLimit},
	{otabuild.ErrTargetExists, CodeBuildTargetExists},
	{otabuild.ErrCatalogInvalid, CodeBuildCatalogInvalid},
	{otabuild.ErrResPathMissing, CodeBuildResPathMissing},
	{otabuild.ErrNoExactAssets, CodeBuildNoExactAssets},
	{otabuild.ErrAssetCollision, CodeBuildAssetCollision},
}

func buildRefusal(err error) error {
	if errors.Is(err, otabuild.ErrBuildIO) {
		return Temporarily(CodeBuildIO, err.Error())
	}
	for _, entry := range buildRefusalCodes {
		if errors.Is(err, entry.kind) {
			return Refuse(entry.code, err.Error())
		}
	}
	return err
}
