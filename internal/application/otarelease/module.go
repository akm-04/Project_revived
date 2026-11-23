package otarelease

import (
	"gxb.local/backend/v2/internal/application/operator"
	domain "gxb.local/backend/v2/internal/domain/otarelease"
)

// Module is the ota module (I11A_ARCHITECTURE_V1 section 2): the three release
// commands, the settings command (its handler is bound by the composition root)
// and the two OTA reads. The settings field list and its defaults come from the
// domain settings, so a bounds change needs no edit here.
func (commands Commands) Module() operator.Module {
	return operator.Module{
		ID:         "ota",
		Title:      "OTA releases",
		Role:       operator.RoleRoot,
		LogChannel: "ota",
		Screen:     operator.Screen{Tab: "OTA", Columns: []string{"version", "lane", "state", "at"}},
		Defaults:   &operator.Defaults{Values: operator.DefaultValues(SettingsFields()), ResetCommand: "ota.settings.set"},
		Commands: []operator.CommandSpec{
			{Name: "ota.register_build", Class: operator.ClassLive, Help: "Register a finished offline build as BUILT; it has no effect on clients.", Fields: registerBuildFields(), Handler: commands.registerBuildHandler},
			{Name: "ota.publish", Class: operator.ClassMaintenance, Help: "Activate a BUILT release; the maintenance window restarts clients on the OTA check.", Fields: []operator.Field{releaseVersionField()}, Handler: commands.publishHandler},
			{Name: "ota.withdraw", Class: operator.ClassMaintenance, Help: "Stop advertising an ACTIVE release; installed clients keep it.", Fields: []operator.Field{releaseVersionField()}, Handler: commands.withdrawHandler},
			{Name: "ota.settings.set", Class: operator.ClassLive, Help: "Replace the operator-tunable OTA settings; the last writer wins.", Fields: SettingsFields()},
		},
		Reads: []operator.Read{
			{Name: "ota.status", Help: "Active lanes, built releases, activations and serving counters."},
			{Name: "ota.release", Help: "Whether a release number exists in any state.", Fields: []operator.Field{releaseVersionField()}},
		},
	}
}

func releaseVersionField() operator.Field {
	return operator.NewField("version", operator.FieldString, true, "release number, for example 1.631.2")
}

func registerBuildFields() []operator.Field {
	return []operator.Field{
		releaseVersionField(),
		operator.NewField("lane", operator.FieldString, true, "artifact lane").WithEnum(string(domain.LaneCode), string(domain.LaneAssets), string(domain.LaneCatalog)),
		operator.NewField("package_files", operator.FieldArray, true, "volumes: name, size, md5, sha256"),
		operator.NewField("total_size", operator.FieldInt, true, "sum of the volume sizes in bytes").Bounded(1, domain.MaxTotalBytes),
		operator.NewField("md5", operator.FieldString, true, "lowercase hex md5 of the whole package"),
		operator.NewField("sha256", operator.FieldString, true, "lowercase hex sha256 of the whole package"),
		operator.NewField("manifest", operator.FieldObject, true, "shipped client paths: {files:[{path,size,md5}]} in sorted order"),
		operator.NewField("rollback", operator.FieldBool, false, "register a number below the lane's active release"),
	}
}

// SettingsFields is the ota.settings.set payload: every tunable, its factory
// default and its domain bounds (L4h item 6).
func SettingsFields() []operator.Field {
	defaults := domain.DefaultSettings()
	return []operator.Field{
		operator.NewField("lazy_fetch", operator.FieldString, false, "auto serves /res/ once an ACTIVE assets release exists").WithEnum(string(domain.LazyFetchAuto), string(domain.LazyFetchOn), string(domain.LazyFetchOff)).WithDefault(string(defaults.LazyFetch)),
		operator.NewField("res_path", operator.FieldString, false, "absolute path of the original client res folder served for assets-lane rows").WithDefault(defaults.ResPath),
		operator.NewField("apk_res_path", operator.FieldString, false, "absolute path of the APK res tree the operator GUI reads icons from after res_path").WithDefault(defaults.ApkResPath),
		operator.NewField("recovered_res_path", operator.FieldString, false, "absolute path of the asset-recovery lane folder served for code-lane rows").WithDefault(defaults.RecoveredResPath),
		operator.NewField("download_base_seconds", operator.FieldInt, false, "base write deadline of one OTA download").Bounded(domain.MinDownloadBaseSeconds, domain.MaxDownloadBaseSeconds).WithDefault(defaults.DownloadBaseSeconds),
		operator.NewField("download_min_kib_per_second", operator.FieldInt, false, "slowest client rate the deadline budget assumes").Bounded(domain.MinDownloadMinKiBPerSecond, domain.MaxDownloadMinKiBPerSecond).WithDefault(defaults.DownloadMinKiBPerSecond),
		operator.NewField("cache_max_age_seconds", operator.FieldInt, false, "Cache-Control max-age of served release files").Bounded(domain.MinCacheMaxAgeSeconds, domain.MaxCacheMaxAgeSeconds).WithDefault(defaults.CacheMaxAgeSeconds),
		operator.NewField("serving_refresh_seconds", operator.FieldInt, false, "how long a servable snapshot stays fresh").Bounded(domain.MinServingRefreshSeconds, domain.MaxServingRefreshSeconds).WithDefault(defaults.ServingRefreshSeconds),
		operator.NewField("volume_mb", operator.FieldInt, false, "per-volume cap of ota build").Bounded(domain.MinVolumeMB, domain.MaxVolumeMB).WithDefault(defaults.VolumeMB),
	}
}
