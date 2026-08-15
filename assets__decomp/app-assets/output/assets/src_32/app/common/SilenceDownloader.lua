local var_0_0 = class("SilenceDownloader")
local var_0_1 = require("cjson")
local var_0_2 = xyd.lazyFileManager
local var_0_3 = require("framework.scheduler")
local var_0_4 = "version.json"
local var_0_5 = "__lazy__"
local var_0_6 = 0
local var_0_7 = 10
local var_0_8 = 0.05

function var_0_0.get()
	if not var_0_0.INSTANCE then
		var_0_0.INSTANCE = var_0_0.new()
	end

	return var_0_0.INSTANCE
end

function var_0_0.readFromFile(arg_2_0, arg_2_1)
	return var_0_1.decode(cc.FileUtils:getInstance():getStringFromFile(arg_2_1))
end

function var_0_0.ctor(arg_3_0, ...)
	arg_3_0.assetDownload = xyd.AssetDownload.get()
	arg_3_0.priorityTable = import("app.common.tables.SilencePriorityTable").new()
	arg_3_0.pathDirs = {}
	arg_3_0.firstEnterFlag = 0

	if cc.Application:getInstance():getTargetPlatform() == var_0_6 then
		arg_3_0.source = "source"
	else
		arg_3_0.source = "src_64"
	end

	local var_3_0 = {}

	if cc.FileUtils:getInstance():isFileExist(xyd.versionUpdatePath .. var_0_4) then
		var_3_0 = arg_3_0:readFromFile(xyd.versionUpdatePath .. var_0_4)
	elseif cc.FileUtils:getInstance():isFileExist(arg_3_0.source .. "/" .. var_0_4) then
		var_3_0 = arg_3_0:readFromFile(arg_3_0.source .. "/" .. var_0_4)
	end

	arg_3_0.versions_ = var_3_0
	arg_3_0.versionsDict_ = {}

	for iter_3_0, iter_3_1 in pairs(arg_3_0.versions_) do
		local var_3_1 = iter_3_1.path

		arg_3_0.versionsDict_[var_3_1] = iter_3_1
	end
end

function var_0_0.getSilenceVersions(arg_4_0)
	local var_4_0 = {}

	for iter_4_0, iter_4_1 in pairs(arg_4_0.versions_) do
		local var_4_1 = iter_4_1.path

		if iter_4_1.force == 0 then
			local var_4_2 = arg_4_0.priorityTable:priority(var_4_1)

			if var_4_2 > 0 then
				table.insert(var_4_0, {
					priority = var_4_2,
					versionInfo = iter_4_1
				})
			elseif var_4_1:match("web/skeletons") ~= nil then
				table.insert(var_4_0, {
					priority = 1,
					versionInfo = iter_4_1
				})
			elseif var_4_1:match("web/windows") ~= nil then
				table.insert(var_4_0, {
					priority = 2,
					versionInfo = iter_4_1
				})
			elseif var_4_1:match("web/sound/battle") ~= nil then
				table.insert(var_4_0, {
					priority = 6,
					versionInfo = iter_4_1
				})
			elseif var_4_1:match("web/sound") ~= nil then
				table.insert(var_4_0, {
					priority = 4,
					versionInfo = iter_4_1
				})
			elseif var_4_1:match("web/images/maps/map_images") ~= nil then
				table.insert(var_4_0, {
					priority = 5,
					versionInfo = iter_4_1
				})
			elseif var_4_1:match("web/images/activities") ~= nil then
				table.insert(var_4_0, {
					priority = 3,
					versionInfo = iter_4_1
				})
			else
				table.insert(var_4_0, {
					priority = 0,
					versionInfo = iter_4_1
				})
			end
		end
	end

	table.sort(var_4_0, function(arg_5_0, arg_5_1)
		return arg_5_0.priority > arg_5_1.priority
	end)

	return var_4_0
end

function var_0_0.delaySilenceDownload(arg_6_0)
	if arg_6_0.firstEnterFlag == 1 then
		return
	end

	var_0_3.performWithDelayGlobal(function()
		arg_6_0:silenceDownload()
	end, var_0_7)
end

function var_0_0.silenceDownload(arg_8_0)
	if arg_8_0.firstEnterFlag == 1 then
		return
	end

	local var_8_0 = cc.Application:getInstance():getTargetPlatform()

	arg_8_0.downloadInfos_ = {}

	print("================== START SILENCE DOWNLOAD ==================")

	local var_8_1 = arg_8_0:getSilenceVersions()

	arg_8_0.firstEnterFlag = 1

	arg_8_0:downloadFiles(var_8_1, function()
		print("TOTAL DOWNLOAD:" .. #var_8_1)
		print("================== FINISH SILENCE DOWNLOAD ==================")
		var_0_2:tryFlush()
	end)
end

function var_0_0.downloadFiles(arg_10_0, arg_10_1, arg_10_2)
	if #arg_10_1 <= 0 then
		return arg_10_2()
	end

	local function var_10_0()
		if arg_10_2 then
			arg_10_2()
		end
	end

	local var_10_1 = 0

	local function var_10_2(arg_12_0)
		if arg_12_0 > #arg_10_1 then
			return var_10_0()
		end

		local var_12_0 = arg_10_1[arg_12_0].versionInfo
		local var_12_1 = arg_10_0:getDownloadInfo_(var_12_0)

		if arg_10_0:isDownloadFinished_(var_12_1) then
			return var_10_2(arg_12_0 + 1)
		end

		arg_10_0:downloadVersion_(var_12_1, var_12_0, function(arg_13_0, arg_13_1, arg_13_2)
			local function var_13_0()
				local var_14_0 = display.getRunningScene().__cname

				if var_14_0 == "BattleCreate" or var_14_0 == "BattleScene" or var_14_0 == "BattleCreateReport" or arg_10_0.assetDownload:downloadIsBusy() or xyd.WindowManager.get():isWindowOpen("gold_catch") or xyd.WindowManager.get():isWindowOpen("gold_main") or var_14_0 == "FlappyBirdScene" or xyd.WindowManager.get():isWindowOpen("flappy_bird_main") then
					arg_10_0:delayRetry(var_13_0, 0.5)
				else
					var_10_2(arg_12_0 + 1)
				end
			end

			var_10_1 = var_10_1 + 1

			if var_10_1 == 25 then
				var_10_1 = 0

				var_0_2:tryFlush()
				arg_10_0:delayRetry(var_13_0)
			else
				var_13_0()
			end
		end)
	end

	var_10_2(1)
end

function var_0_0.downloadVersion_(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	local var_15_0 = arg_15_1.path

	if arg_15_0:isFileExist(var_15_0) then
		arg_15_3(xyd.FileDownloader.RESULT_SUCCESS)

		return
	end

	arg_15_0:makeDirByFileName(xyd.versionUpdatePath .. var_15_0)

	local function var_15_1()
		local var_16_0 = xyd.split(arg_15_2.path, "/")
		local var_16_1 = var_16_0[#var_16_0]
		local var_16_2 = ""

		for iter_16_0 = 1, #var_16_0 - 1 do
			var_16_2 = var_16_2 .. var_16_0[iter_16_0] .. "/"
		end

		local var_16_3 = xyd.resDownloadUrl .. var_16_1 .. "." .. arg_15_2.md5
		local var_16_4 = xyd.versionUpdatePath .. var_15_0 .. ".sli_tmp"

		xyd.FileDownloader:download(var_16_3, var_16_4, 0, 10, function(arg_17_0, arg_17_1, arg_17_2)
			return
		end, function(arg_18_0, arg_18_1, arg_18_2)
			if arg_18_0 == xyd.FileDownloader.RESULT_SUCCESS and cc.Crypto:MD5File(var_16_4) == arg_15_2.md5 then
				arg_15_1.finishedSize = arg_15_2.size

				cc.FileUtils:getInstance():renameFile(xyd.versionUpdatePath .. var_16_2, var_16_1 .. ".sli_tmp", var_16_1)

				local var_18_0 = ""

				for iter_18_0, iter_18_1 in pairs(var_16_0) do
					if iter_18_0 ~= 1 then
						var_18_0 = var_18_0 .. "___"
					end

					var_18_0 = var_18_0 .. iter_18_1
				end

				var_0_2:deleteValueForKeyNoFlush(var_0_5 .. var_18_0)
				arg_15_3(xyd.FileDownloader.RESULT_SUCCESS, arg_18_1, arg_18_2)
			else
				arg_15_0:delayRetry(var_15_1)
			end
		end)
	end

	var_15_1()
end

function var_0_0.delayRetry(arg_19_0, arg_19_1, arg_19_2)
	arg_19_2 = arg_19_2 or var_0_8

	var_0_3.performWithDelayGlobal(arg_19_1, arg_19_2)
end

function var_0_0.getDownloadInfo_(arg_20_0, arg_20_1)
	local var_20_0 = arg_20_1.path
	local var_20_1 = arg_20_0.downloadInfos_[var_20_0]

	if var_20_1 == nil then
		var_20_1 = {
			version = arg_20_1.version or xyd.res_version,
			size = arg_20_1.size
		}
		var_20_1.finishedSize = 0
		var_20_1.path = arg_20_1.path
	end

	return var_20_1
end

function var_0_0.clearDownloadInfos_(arg_21_0)
	arg_21_0.downloadInfos_ = {}

	xyd.dbc.downloadInfo:commit()
	xyd.dbc.downloadInfo:truncate()
end

function var_0_0.isDownloadFinished_(arg_22_0, arg_22_1)
	return arg_22_1 ~= nil and arg_22_1.finishedSize == arg_22_1.size
end

local var_0_9 = 0

function var_0_0.saveDownloadInfo_(arg_23_0, arg_23_1)
	if var_0_9 % 10 == 0 then
		xyd.dbc.downloadInfo:commit()
		xyd.dbc.downloadInfo:begin()
	end

	var_0_9 = var_0_9 + 1

	xyd.dbc.downloadInfo:add(arg_23_1)
end

function var_0_0.makeDirByFileName(arg_24_0, arg_24_1)
	local var_24_0 = xyd.split(arg_24_1, "/")
	local var_24_1 = ""

	for iter_24_0 = 1, #var_24_0 - 1 do
		var_24_1 = var_24_1 .. var_24_0[iter_24_0] .. "/"

		if not arg_24_0.pathDirs[var_24_1] then
			if not cc.FileUtils:getInstance():isDirectoryExist(var_24_1) then
				cc.FileUtils:getInstance():createDirectory(var_24_1)
			end

			arg_24_0.pathDirs[var_24_1] = 1
		end
	end
end

function var_0_0.parseXmlPath(arg_25_0, arg_25_1)
	local var_25_0 = xyd.split(arg_25_1, "/")
	local var_25_1 = ""

	for iter_25_0, iter_25_1 in pairs(var_25_0) do
		if iter_25_0 ~= 1 then
			var_25_1 = var_25_1 .. "___"
		end

		var_25_1 = var_25_1 .. iter_25_1
	end

	return var_25_1
end

function var_0_0.isFileExist(arg_26_0, arg_26_1)
	local var_26_0 = arg_26_0:parseXmlPath(arg_26_1)
	local var_26_1 = var_0_2:getStringForKey(var_0_5 .. var_26_0)

	if not var_26_1 or #var_26_1 == 0 then
		return true
	end

	return false
end

return var_0_0
