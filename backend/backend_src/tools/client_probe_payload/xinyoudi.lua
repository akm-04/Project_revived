json = require("framework.json")
xyd = xyd or {}

require("app.common.math")
require("app.common.color")
require("app.common.const")
require("app.common.enums")
require("app.common.error")
require("app.common.event")
require("app.common.network.mid")
require("app.common.utils")
require("app.common.WindowConst")
require("app.common.WidgetConst")
require("app.common.TemplateConst")
require("app.common.config")
require("app.common.shader")
require("app.common.state")
require("app.cc.extra")
require("app.common.storage.db")

xyd.list = require("app.common.list")

require("app.common.table")
require("app.common.tables.tables")
require("app.common.localizer")
require("app.common.ui.NodeEx")
require("lib.battle.battleConfig"):new()

xyd.AssetLoader = import("app.common.AssetLoader")
xyd.AssetDownload = import("app.common.AssetDownload")
xyd.SpriteLoader = import("app.common.ui.SpriteLoader")
xyd.EffectLoader = import("app.common.ui.EffectLoader")
xyd.Backend = import("app.common.network.Backend")
xyd.ColoredSprite = import("app.common.ui.ColoredSprite")
xyd.GrayedSprite = import("app.common.ui.GrayedSprite")
xyd.MaskedSprite = import("app.common.ui.MaskedSprite")
xyd.EventDispatcher = import("app.common.EventDispatcher")
xyd.HeroAnimation = import("app.common.ui.HeroAnimation")
xyd.ModelManager = import("app.model.ModelManager")
xyd.ProgressBar = import("app.common.ui.ProgressBar")
xyd.WindowManager = import("app.common.ui.WindowManager")
xyd.ServerTime = import("app.common.ServerTime")
xyd.SpineEffect = import("app.common.ui.SpineEffect")
xyd.StoryData = import("app.common.StoryData")
xyd.BattleCreateReport = import("app.scenes.BattleCreateReport")
xyd.LoadingProxy = import("app.common.ui.LoadingProxy")
xyd.AlertWindow = import("app.windows.AlertWindow")
xyd.CommonAlertWindow = import("app.windows.CommonAlertWindow")
xyd.BattleCreate = import("app.scenes.BattleCreate")
xyd.BattleStoryScene = import("app.scenes.BattleStoryScene")
xyd.LoadingScene = import("app.scenes.LoadingScene")
xyd.MainScene = import("app.scenes.MainScene")
xyd.HeroScene = import("app.scenes.HeroScene")
xyd.SocialScene = import("app.scenes.SocialScene")
xyd.ArenaScene = import("app.scenes.ArenaScene")
xyd.StoryScene = import("app.scenes.StoryScene")
xyd.EditNameScene = import("app.scenes.EditNameScene")
xyd.AdvancedTipWindow = import("app.windows.AdvancedTipWindow")
xyd.OneKeyEquipTipWindow = import("app.windows.OneKeyEquipTipWindow")
xyd.SelfDrinkTipWindow = import("app.windows.SelfDrinkTipWindow")
xyd.PetAddExpTipWindow = import("app.windows.PetAddExpTipWindow")
xyd.ThirdDiglettConfirmWindow = import("app.windows.ThirdDiglettConfirmWindow")
xyd.CvLinkConfirmWindow = import("app.windows.CvLinkConfirmWindow")
xyd.ChocolateFruitsConfirmWindow = import("app.windows.ChocolateFruitsConfirmWindow")
xyd.FourthAnniGoldConfirmWindow = import("app.windows.FourthAnniGoldConfirmWindow")
xyd.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

local var_0_0 = __G__TRACKBACK__

function __G__TRACKBACK__(arg_1_0)
	arg_1_0 = arg_1_0 or ""

	local var_1_0 = debug.traceback("LUA ERROR: " .. arg_1_0, 2)

	xyd.db.errorLog:add(var_1_0)
	var_0_0(arg_1_0)
end

import("app.common.network.ErrorLogPoster"):run()

-- GXB EOL resource-pipeline diagnostic overlay (v0.6.0).
-- This block only adds tracing wrappers; it does not alter resource decisions.
local function __gxb_resource_trace(arg_2_0)
	local var_2_0 = tostring(arg_2_0 or "")

	pcall(function()
		local var_3_0 = xyd.versionUpdatePath .. "resource_pipeline_trace.log"
		local var_3_1 = io.open(var_3_0, "a")

		if var_3_1 then
			var_3_1:write(tostring(os.time()) .. " " .. var_2_0 .. "\n")
			var_3_1:close()
		end
	end)
	print("[GXB-RESOURCE-TRACE] " .. var_2_0)
end

local function __gxb_trace_list(arg_4_0)
	if type(arg_4_0) ~= "table" then
		return tostring(arg_4_0)
	end

	local var_4_0 = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_0) do
		if type(iter_4_1) == "table" then
			table.insert(var_4_0, tostring(iter_4_1.path or iter_4_1[1] or "<table>"))
		else
			table.insert(var_4_0, tostring(iter_4_1))
		end

		if #var_4_0 >= 64 then
			table.insert(var_4_0, "<truncated>")
			break
		end
	end

	return table.concat(var_4_0, "|")
end

xyd.__gxbResourceTrace = __gxb_resource_trace
__gxb_resource_trace("probe_loaded resDownloadUrl=" .. tostring(xyd.resDownloadUrl) .. " updatePath=" .. tostring(xyd.versionUpdatePath))

do
	local var_5_0 = xyd.AssetDownload

	if var_5_0 and not var_5_0.__gxb_resource_probe_wrapped then
		var_5_0.__gxb_resource_probe_wrapped = true

		local var_5_1 = var_5_0.preloadBattleInfos
		local var_5_2 = var_5_0.getDownloadVersionInfo
		local var_5_3 = var_5_0.isFileExist
		local var_5_4 = var_5_0.downloadFiles
		local var_5_5 = var_5_0.insertToStack
		local var_5_6 = var_5_0.downloadFile
		local var_5_7 = var_5_0.dealCallbacks

		function var_5_0.preloadBattleInfos(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4)
			__gxb_resource_trace("preloadBattleInfos enter sounds=" .. __gxb_trace_list(arg_6_1) .. " maps=" .. __gxb_trace_list(arg_6_2) .. " models=" .. __gxb_trace_list(arg_6_3) .. " resDownloadUrl=" .. tostring(xyd.resDownloadUrl))

			local function var_6_0(...)
				__gxb_resource_trace("preloadBattleInfos callback")

				if arg_6_4 then
					return arg_6_4(...)
				end
			end

			return var_5_1(arg_6_0, arg_6_1, arg_6_2, arg_6_3, var_6_0)
		end

		function var_5_0.getDownloadVersionInfo(arg_7_0, arg_7_1)
			local var_7_0 = var_5_2(arg_7_0, arg_7_1)

			__gxb_resource_trace("getDownloadVersionInfo names=" .. __gxb_trace_list(arg_7_1) .. " -> " .. __gxb_trace_list(var_7_0))

			return var_7_0
		end

		function var_5_0.isFileExist(arg_8_0, arg_8_1)
			local var_8_0 = var_5_3(arg_8_0, arg_8_1)
			local var_8_1 = ""
			local var_8_2 = ""

			pcall(function()
				var_8_1 = "__lazy__" .. arg_8_0:parseXmlPath(arg_8_1)
				var_8_2 = xyd.lazyFileManager:getStringForKey(var_8_1) or ""
			end)
			__gxb_resource_trace("isFileExist path=" .. tostring(arg_8_1) .. " result=" .. tostring(var_8_0) .. " lazyKey=" .. tostring(var_8_1) .. " lazyBytes=" .. tostring(#var_8_2))

			return var_8_0
		end

		function var_5_0.downloadFiles(arg_9_0, arg_9_1, arg_9_2)
			__gxb_resource_trace("downloadFiles count=" .. tostring(type(arg_9_1) == "table" and #arg_9_1 or -1) .. " files=" .. __gxb_trace_list(arg_9_1))

			local function var_9_0(arg_10_0, arg_10_1)
				__gxb_resource_trace("downloadFiles progress=" .. tostring(arg_10_0) .. " done=" .. tostring(arg_10_1))

				if arg_9_2 then
					return arg_9_2(arg_10_0, arg_10_1)
				end
			end

			return var_5_4(arg_9_0, arg_9_1, var_9_0)
		end

		function var_5_0.insertToStack(arg_11_0, arg_11_1)
			__gxb_resource_trace("insertToStack path=" .. tostring(arg_11_1 and arg_11_1.path) .. " md5=" .. tostring(arg_11_1 and arg_11_1.md5) .. " busy=" .. tostring(arg_11_0.busyProcess) .. " waiting=" .. tostring(arg_11_0.waitingNum))

			return var_5_5(arg_11_0, arg_11_1)
		end

		function var_5_0.downloadFile(arg_12_0, arg_12_1)
			local var_12_0 = ""
			local var_12_1 = ""

			pcall(function()
				local var_13_0 = arg_12_0:getDownloadInfo_(arg_12_1)
				var_12_0 = tostring(var_13_0.url)
				var_12_1 = tostring(xyd.versionUpdatePath .. tostring(arg_12_1.path) .. ".asset_tmp")
			end)
			__gxb_resource_trace("downloadFile BEFORE_NATIVE path=" .. tostring(arg_12_1 and arg_12_1.path) .. " md5=" .. tostring(arg_12_1 and arg_12_1.md5) .. " size=" .. tostring(arg_12_1 and arg_12_1.size) .. " url=" .. var_12_0 .. " tmp=" .. var_12_1)

			return var_5_6(arg_12_0, arg_12_1)
		end

		function var_5_0.dealCallbacks(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
			__gxb_resource_trace("dealCallbacks success=" .. tostring(arg_14_1) .. " path=" .. tostring(arg_14_2) .. " progressOrCode=" .. tostring(arg_14_3))

			return var_5_7(arg_14_0, arg_14_1, arg_14_2, arg_14_3)
		end
	end
end

do
	local var_15_0 = xyd.LoadingProxy

	if var_15_0 and not var_15_0.__gxb_resource_probe_wrapped then
		var_15_0.__gxb_resource_probe_wrapped = true

		local var_15_1 = var_15_0.addNewLoading
		local var_15_2 = var_15_0.removeLoading
		local var_15_3 = var_15_0.reset

		function var_15_0.addNewLoading(arg_16_0, arg_16_1)
			__gxb_resource_trace("LoadingProxy.addNewLoading beforeCount=" .. tostring(arg_16_0.count_) .. " delay=" .. tostring(arg_16_1) .. " stack=" .. tostring(debug.traceback("", 2)))

			return var_15_1(arg_16_0, arg_16_1)
		end

		function var_15_0.removeLoading(arg_17_0)
			__gxb_resource_trace("LoadingProxy.removeLoading beforeCount=" .. tostring(arg_17_0.count_) .. " stack=" .. tostring(debug.traceback("", 2)))

			return var_15_2(arg_17_0)
		end

		function var_15_0.reset(arg_18_0)
			__gxb_resource_trace("LoadingProxy.reset beforeCount=" .. tostring(arg_18_0.count_) .. " stack=" .. tostring(debug.traceback("", 2)))

			return var_15_3(arg_18_0)
		end
	end
end

-- Trace the Lua-visible native downloader boundary itself.  This wrapper is
-- deliberately installed under pcall because some builds expose bindings as
-- non-writable userdata rather than a mutable Lua table.  Failure to wrap is
-- logged and leaves the original binding untouched.
do
	local var_19_0 = xyd.FileDownloader

	if var_19_0 and not var_19_0.__gxb_resource_probe_wrapped then
		local var_19_1 = var_19_0.download

		if type(var_19_1) == "function" then
			local var_19_2, var_19_3 = pcall(function()
				var_19_0.__gxb_resource_probe_wrapped = true

				function var_19_0.download(arg_20_0, arg_20_1, arg_20_2, arg_20_3, arg_20_4, arg_20_5, arg_20_6)
					__gxb_resource_trace("FileDownloader.download ENTER url=" .. tostring(arg_20_1) .. " dst=" .. tostring(arg_20_2) .. " resume=" .. tostring(arg_20_3) .. " timeout=" .. tostring(arg_20_4))

					local function var_20_0(arg_21_0, arg_21_1, arg_21_2)
						__gxb_resource_trace("FileDownloader.progress a=" .. tostring(arg_21_0) .. " b=" .. tostring(arg_21_1) .. " c=" .. tostring(arg_21_2))

						if arg_20_5 then
							return arg_20_5(arg_21_0, arg_21_1, arg_21_2)
						end
					end

					local function var_20_1(arg_22_0, arg_22_1, arg_22_2)
						__gxb_resource_trace("FileDownloader.finish result=" .. tostring(arg_22_0) .. " code=" .. tostring(arg_22_1) .. " extra=" .. tostring(arg_22_2))

						if arg_20_6 then
							return arg_20_6(arg_22_0, arg_22_1, arg_22_2)
						end
					end

					local var_20_2 = var_19_1(arg_20_0, arg_20_1, arg_20_2, arg_20_3, arg_20_4, var_20_0, var_20_1)

					__gxb_resource_trace("FileDownloader.download RETURN value=" .. tostring(var_20_2))

					return var_20_2
				end
			end)

			if var_19_2 then
				__gxb_resource_trace("FileDownloader wrapper installed RESULT_SUCCESS=" .. tostring(var_19_0.RESULT_SUCCESS) .. " RESULT_FAILED=" .. tostring(var_19_0.RESULT_FAILED))
			else
				__gxb_resource_trace("FileDownloader wrapper install failed error=" .. tostring(var_19_3))
			end
		else
			__gxb_resource_trace("FileDownloader.download unavailable type=" .. tostring(type(var_19_1)))
		end
	else
		__gxb_resource_trace("FileDownloader binding unavailable or already wrapped")
	end
end
