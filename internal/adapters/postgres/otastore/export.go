package otastore

import (
	"context"
	"encoding/json"
	"errors"

	appota "gxb.local/backend/v2/internal/application/otarelease"
	"gxb.local/backend/v2/internal/foundation/tx"
)

var errInvalid = errors.New("otastore: invalid input")

// ExportStateTx dumps every release and activation row once, so the first start
// after this change can move the existing records into the OTA root. Later
// database restores never call it, because the file exists.
const exportReleases = `SELECT COALESCE(jsonb_agg(jsonb_build_object(
	'id',id,'version',version,'lane',lane,'state',state,'package_files',package_files,
	'total_size',total_size,'md5',md5,'sha256',sha256,'manifest',manifest,
	'built_at',built_at,'published_at',published_at
) ORDER BY id),'[]'::jsonb)::text FROM ota_releases`

const exportActivations = `SELECT COALESCE(jsonb_agg(jsonb_build_object(
	'id',id,'release_id',release_id,'version',version,'action',action,'command_key',command_key,'at',at
) ORDER BY id),'[]'::jsonb)::text FROM ota_activations`

func (Store) ExportStateTx(ctx context.Context, query tx.Queryer) (appota.StateDocument, error) {
	if query == nil {
		return appota.StateDocument{}, errInvalid
	}
	var document appota.StateDocument
	var raw string
	if err := query.QueryRow(ctx, exportReleases).Scan(&raw); err != nil {
		return appota.StateDocument{}, err
	}
	if err := json.Unmarshal([]byte(raw), &document.Releases); err != nil {
		return appota.StateDocument{}, err
	}
	if err := query.QueryRow(ctx, exportActivations).Scan(&raw); err != nil {
		return appota.StateDocument{}, err
	}
	if err := json.Unmarshal([]byte(raw), &document.Activations); err != nil {
		return appota.StateDocument{}, err
	}
	return document, nil
}
