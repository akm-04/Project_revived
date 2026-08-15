local var_0_0 = ngx
local var_0_1 = class("AssetDownload")
local var_0_2 = require("cjson")
local var_0_3 = require("framework.scheduler")
local var_0_4 = xyd.lazyFileManager
local var_0_5 = "version.json"
local var_0_6 = "__lazy__"
local var_0_7 = 1000000000
local var_0_8 = 0
local var_0_9 = 0

function var_0_1.get()
	if var_0_1.INSTANCE == nil then
		var_0_1.INSTANCE = var_0_1.new()
	end

	return var_0_1.INSTANCE
end

function var_0_1.ctor(arg_2_0)
	arg_2_0.pathDirs = {}
	arg_2_0.downloadProgresses_ = {}
	arg_2_0.isDownloadings_ = {}
	arg_2_0.downloadCallbacks_ = {}
	arg_2_0.skeletonIsDownload = {}
	arg_2_0.soundIsDownload = {}
	arg_2_0.windowIsDownload = {}
	arg_2_0.silenceDownloading = false
	arg_2_0.fileIsDownloading = {}
	arg_2_0.callbackCounts = {}
	arg_2_0.callbackInfos = {}
	arg_2_0.downFileCount = 0
	arg_2_0.waitingStack = {}
	arg_2_0.waitingNum = 0
	arg_2_0.busyProcess = 0
	arg_2_0.fileUtilsIns = cc.FileUtils:getInstance()

	if cc.Application:getInstance():getTargetPlatform() == var_0_8 then
		arg_2_0.source = "source"
	else
		arg_2_0.source = "src_64"
	end

	local var_2_0 = {}

	if arg_2_0.fileUtilsIns:isFileExist(xyd.versionUpdatePath .. var_0_5) then
		var_2_0 = arg_2_0:readFromFile(xyd.versionUpdatePath .. var_0_5)
	elseif arg_2_0.fileUtilsIns:isFileExist(arg_2_0.source .. "/" .. var_0_5) then
		var_2_0 = arg_2_0:readFromFile(arg_2_0.source .. "/" .. var_0_5)
	end

	arg_2_0.webSkeletonDict_ = {}

	for iter_2_0, iter_2_1 in pairs(var_2_0) do
		local var_2_1 = iter_2_1.path

		if var_2_1:match("res/web") then
			local var_2_2 = xyd.split(var_2_1, "/")
			local var_2_3 = ""

			for iter_2_2 = 1, #var_2_2 - 1 do
				if iter_2_2 > 1 then
					var_2_3 = var_2_3 .. "/"
				end

				var_2_3 = var_2_3 .. var_2_2[iter_2_2]
			end

			if arg_2_0.webSkeletonDict_[var_2_3] == nil then
				arg_2_0.webSkeletonDict_[var_2_3] = {}
			end

			table.insert(arg_2_0.webSkeletonDict_[var_2_3], iter_2_1)
		end
	end

	var_0_3.scheduleGlobal(function()
		var_0_4:tryFlush()
	end, 15)
end

function var_0_1.preloadCharacters(arg_4_0, arg_4_1, arg_4_2)
	local var_4_0 = {}
	local var_4_1 = {}
	local var_4_2 = {}
	local var_4_3 = {}

	for iter_4_0, iter_4_1 in ipairs(arg_4_1) do
		local var_4_4 = xyd.tables.hero:modelIDs(iter_4_1)

		if var_4_4 ~= nil then
			for iter_4_2, iter_4_3 in ipairs(var_4_4) do
				if arg_4_0.skeletonIsDownload[iter_4_3] == nil then
					local var_4_5 = xyd.tables.model:resource(iter_4_3)

					if var_4_5 and var_4_5 ~= "" then
						local var_4_6 = var_4_5
						local var_4_7 = xyd.split(var_4_6, "/")
						local var_4_8 = "res/web"

						for iter_4_4 = 1, #var_4_7 - 1 do
							var_4_8 = var_4_8 .. "/" .. var_4_7[iter_4_4]
						end

						table.insert(var_4_2, iter_4_3)

						local var_4_9 = arg_4_0.webSkeletonDict_[var_4_8]

						if var_4_9 == nil then
							print("PRELOAD CHARACTER WAR : " .. var_4_8)
						else
							for iter_4_5, iter_4_6 in ipairs(var_4_9) do
								if not arg_4_0:isFileExist(iter_4_6.path) and not var_4_1[iter_4_6.path] then
									var_4_1[iter_4_6.path] = true

									table.insert(var_4_0, iter_4_6)
								end
							end
						end
					end
				end
			end
		else
			print("INVALIED TABLE_ID : " .. iter_4_1)
		end
	end

	for iter_4_7, iter_4_8 in ipairs(arg_4_1) do
		local var_4_10 = xyd.tables.hero:modelIDs(iter_4_8)

		if var_4_10 ~= nil then
			for iter_4_9, iter_4_10 in ipairs(var_4_10) do
				if arg_4_0.soundIsDownload[iter_4_10] == nil then
					local var_4_11 = xyd.tables.model:deathSound(iter_4_10)

					if var_4_11 and var_4_11 ~= "" then
						local var_4_12 = xyd.split(var_4_11, "/")
						local var_4_13 = "res/web"

						for iter_4_11 = 1, #var_4_12 - 1 do
							var_4_13 = var_4_13 .. "/" .. var_4_12[iter_4_11]
						end

						table.insert(var_4_3, iter_4_8)

						local var_4_14 = arg_4_0.webSkeletonDict_[var_4_13]

						if var_4_14 == nil then
							print("PRELOAD CHARACTER WAR : " .. var_4_13)
						else
							for iter_4_12, iter_4_13 in ipairs(var_4_14) do
								if not arg_4_0:isFileExist(iter_4_13.path) and not var_4_1[iter_4_13.path] then
									var_4_1[iter_4_13.path] = true

									table.insert(var_4_0, iter_4_13)
								end
							end
						end
					end
				end
			end
		end
	end

	local function var_4_15()
		for iter_5_0, iter_5_1 in ipairs(var_4_2) do
			arg_4_0.skeletonIsDownload[iter_5_1] = 1
		end
	end

	local function var_4_16()
		for iter_6_0, iter_6_1 in ipairs(var_4_3) do
			arg_4_0.soundIsDownload[iter_6_1] = 1
		end
	end

	if #var_4_0 <= 0 then
		var_4_15()
		var_4_16()

		return arg_4_2()
	end

	xyd.LoadingProxy.get():addNewLoading(1.5)

	local function var_4_17(arg_7_0, arg_7_1)
		xyd.LoadingProxy.get():setNewLoadingPercent(math.ceil(arg_7_0 * 100))

		if arg_7_1 then
			xyd.LoadingProxy.get():removeLoading()
			var_4_15()
			var_4_16()
			arg_4_2()
		end
	end

	arg_4_0:downloadFiles(var_4_0, var_4_17)
end

function var_0_1.preloadBattleInfos(arg_8_0, arg_8_1, arg_8_2, arg_8_3, arg_8_4)
	local var_8_0 = {}
	local var_8_1 = {}
	local var_8_2 = {}
	local var_8_3 = {}

	for iter_8_0, iter_8_1 in ipairs(arg_8_3) do
		if arg_8_0.skeletonIsDownload[iter_8_1] == nil then
			local var_8_4 = xyd.tables.model:resource(iter_8_1)

			if var_8_4 and var_8_4 ~= "" then
				local var_8_5 = var_8_4
				local var_8_6 = xyd.split(var_8_5, "/")
				local var_8_7 = "res/web"
				local var_8_8

				for iter_8_2 = 1, #var_8_6 - 1 do
					var_8_7 = var_8_7 .. "/" .. var_8_6[iter_8_2]

					if iter_8_2 == #var_8_6 - 1 then
						var_8_8 = var_8_6[iter_8_2]
					end
				end

				table.insert(var_8_2, iter_8_1)

				local var_8_9 = arg_8_0.webSkeletonDict_[var_8_7]

				if var_8_9 == nil then
					print("PRELOAD CHARACTER WAR : " .. var_8_7)
				else
					for iter_8_3, iter_8_4 in ipairs(var_8_9) do
						if not arg_8_0:isFileExist(iter_8_4.path) and not var_8_1[iter_8_4.path] then
							var_8_1[iter_8_4.path] = true

							table.insert(var_8_0, iter_8_4)
						end
					end
				end

				if var_8_8 then
					local var_8_10 = xyd.tables.preloadSkeletons:path(var_8_8)

					if var_8_10 and next(var_8_10) then
						for iter_8_5, iter_8_6 in ipairs(var_8_10) do
							local var_8_11 = "res/web/"
							local var_8_12 = iter_8_6 .. ".json"
							local var_8_13 = iter_8_6 .. ".png"
							local var_8_14 = iter_8_6 .. ".atlas"

							if not arg_8_0:isFileExist(var_8_11 .. var_8_12) and not var_8_1[var_8_11 .. var_8_12] then
								var_8_1[var_8_11 .. var_8_12] = true

								local var_8_15 = arg_8_0:getDownloadVersionInfo({
									var_8_12
								})

								for iter_8_7, iter_8_8 in ipairs(var_8_15) do
									table.insert(var_8_0, iter_8_8)
								end
							end

							if not arg_8_0:isFileExist(var_8_11 .. var_8_13) and not var_8_1[var_8_11 .. var_8_13] then
								var_8_1[var_8_11 .. var_8_13] = true

								local var_8_16 = arg_8_0:getDownloadVersionInfo({
									var_8_13
								})

								for iter_8_9, iter_8_10 in ipairs(var_8_16) do
									table.insert(var_8_0, iter_8_10)
								end
							end

							if not arg_8_0:isFileExist(var_8_11 .. var_8_14) and not var_8_1[var_8_11 .. var_8_14] then
								var_8_1[var_8_11 .. var_8_14] = true

								local var_8_17 = arg_8_0:getDownloadVersionInfo({
									var_8_14
								})

								for iter_8_11, iter_8_12 in ipairs(var_8_17) do
									table.insert(var_8_0, iter_8_12)
								end
							end
						end
					end
				end
			end
		end
	end

	for iter_8_13, iter_8_14 in ipairs(arg_8_3) do
		if arg_8_0.soundIsDownload[iter_8_14] == nil then
			local var_8_18 = xyd.tables.model:deathSound(iter_8_14)

			if var_8_18 and var_8_18 ~= "" then
				local var_8_19 = xyd.split(var_8_18, "/")
				local var_8_20 = "res/web"

				for iter_8_15 = 1, #var_8_19 - 1 do
					var_8_20 = var_8_20 .. "/" .. var_8_19[iter_8_15]
				end

				table.insert(var_8_3, id)

				local var_8_21 = arg_8_0.webSkeletonDict_[var_8_20]

				if var_8_21 == nil then
					print("PRELOAD CHARACTER WAR : " .. var_8_20)
				else
					for iter_8_16, iter_8_17 in ipairs(var_8_21) do
						if not arg_8_0:isFileExist(iter_8_17.path) and not var_8_1[iter_8_17.path] then
							var_8_1[iter_8_17.path] = true

							table.insert(var_8_0, iter_8_17)
						end
					end
				end
			end
		end
	end

	local var_8_22 = arg_8_0:getDownloadVersionInfo(arg_8_2)

	for iter_8_18, iter_8_19 in ipairs(var_8_22) do
		table.insert(var_8_0, iter_8_19)
	end

	local var_8_23 = arg_8_0:getDownloadVersionInfo(arg_8_1)

	for iter_8_20, iter_8_21 in ipairs(var_8_23) do
		table.insert(var_8_0, iter_8_21)
	end

	local function var_8_24()
		for iter_9_0, iter_9_1 in ipairs(var_8_2) do
			arg_8_0.skeletonIsDownload[iter_9_1] = 1
		end
	end

	local function var_8_25()
		for iter_10_0, iter_10_1 in ipairs(var_8_3) do
			arg_8_0.soundIsDownload[iter_10_1] = 1
		end
	end

	if #var_8_0 <= 0 then
		var_8_24()
		var_8_25()

		return arg_8_4()
	end

	xyd.LoadingProxy.get():addNewLoading(1.5)

	local function var_8_26(arg_11_0, arg_11_1)
		xyd.LoadingProxy.get():setNewLoadingPercent(math.ceil(arg_11_0 * 100))

		if arg_11_1 then
			xyd.LoadingProxy.get():removeLoading()
			var_8_24()
			var_8_25()
			arg_8_4()
		end
	end

	arg_8_0:downloadFiles(var_8_0, var_8_26)
end

function var_0_1.preloadBattleSpine(arg_12_0, arg_12_1)
	for iter_12_0, iter_12_1 in ipairs(arg_12_1) do
		local var_12_0 = xyd.tables.model:resource(iter_12_1)

		if var_12_0 and var_12_0 ~= "" then
			local var_12_1 = var_12_0
			local var_12_2 = xyd.split(var_12_1, "/")
			local var_12_3 = "res/web"
			local var_12_4

			for iter_12_2 = 1, #var_12_2 - 1 do
				var_12_3 = var_12_3 .. "/" .. var_12_2[iter_12_2]

				if iter_12_2 == #var_12_2 - 1 then
					var_12_4 = var_12_2[iter_12_2]
				end
			end

			local var_12_5 = arg_12_0.webSkeletonDict_[var_12_3]

			if var_12_5 == nil then
				print("PRELOAD CHARACTER WAR : " .. var_12_3)
			else
				for iter_12_3, iter_12_4 in ipairs(var_12_5) do
					if string.match(iter_12_4.path, ".+%.(%w+)$") == "png" and iter_12_4.size < var_0_7 then
						var_0_0.ctx.battle.preloadSpine(iter_12_4.path)
					end
				end
			end

			if var_12_4 then
				local var_12_6 = xyd.tables.preloadSkeletons:path(var_12_4)

				if var_12_6 and next(var_12_6) then
					for iter_12_5, iter_12_6 in ipairs(var_12_6) do
						local var_12_7 = "res/web/"
						local var_12_8 = iter_12_6 .. ".json"
						local var_12_9 = iter_12_6 .. ".png"
						local var_12_10 = iter_12_6 .. ".atlas"

						if not arg_12_0:isFileExist(var_12_7 .. var_12_8) then
							local var_12_11 = arg_12_0:getDownloadVersionInfo({
								var_12_8
							})

							for iter_12_7, iter_12_8 in ipairs(var_12_11) do
								if string.match(iter_12_8.path, ".+%.(%w+)$") == "png" and iter_12_8.size < var_0_7 then
									var_0_0.ctx.battle.preloadSpine(iter_12_8.path)
								end
							end
						end

						if not arg_12_0:isFileExist(var_12_7 .. var_12_9) then
							local var_12_12 = arg_12_0:getDownloadVersionInfo({
								var_12_9
							})

							for iter_12_9, iter_12_10 in ipairs(var_12_12) do
								if string.match(iter_12_10.path, ".+%.(%w+)$") == "png" and iter_12_10.size < var_0_7 then
									var_0_0.ctx.battle.preloadSpine(iter_12_10.path)
								end
							end
						end

						if not arg_12_0:isFileExist(var_12_7 .. var_12_10) then
							local var_12_13 = arg_12_0:getDownloadVersionInfo({
								var_12_10
							})

							for iter_12_11, iter_12_12 in ipairs(var_12_13) do
								if string.match(iter_12_12.path, ".+%.(%w+)$") == "png" and iter_12_12.size < var_0_7 then
									var_0_0.ctx.battle.preloadSpine(iter_12_12.path)
								end
							end
						end
					end
				end
			end
		end
	end
end

function var_0_1.preloadCharacterSound(arg_13_0, arg_13_1, arg_13_2, arg_13_3)
	local var_13_0 = {}
	local var_13_1 = {}
	local var_13_2 = {}

	for iter_13_0, iter_13_1 in ipairs(arg_13_1) do
		local var_13_3 = xyd.tables.hero:modelIDs(iter_13_1)

		if var_13_3 ~= nil then
			for iter_13_2, iter_13_3 in ipairs(var_13_3) do
				if arg_13_0.soundIsDownload[iter_13_3] == nil then
					local var_13_4 = xyd.tables.model:deathSound(iter_13_3)

					if var_13_4 and var_13_4 ~= "" then
						local var_13_5 = xyd.split(var_13_4, "/")
						local var_13_6 = "res/web"

						for iter_13_4 = 1, #var_13_5 - 1 do
							var_13_6 = var_13_6 .. "/" .. var_13_5[iter_13_4]
						end

						table.insert(var_13_1, iter_13_1)

						local var_13_7 = arg_13_0.webSkeletonDict_[var_13_6]

						if var_13_7 == nil then
							print("PRELOAD CHARACTER WAR : " .. var_13_6)
						else
							for iter_13_5, iter_13_6 in ipairs(var_13_7) do
								if not arg_13_0:isFileExist(iter_13_6.path) and not var_13_2[iter_13_6.path] then
									var_13_2[iter_13_6.path] = true

									table.insert(var_13_0, iter_13_6)
								end
							end
						end
					end
				end
			end
		end
	end

	local function var_13_8()
		for iter_14_0, iter_14_1 in ipairs(var_13_1) do
			arg_13_0.soundIsDownload[iter_14_1] = 1
		end
	end

	if #var_13_0 <= 0 then
		var_13_8()

		return arg_13_2()
	end

	if not arg_13_3 then
		xyd.LoadingProxy.get():addNewLoading(1.5)
	end

	local function var_13_9(arg_15_0, arg_15_1)
		if not arg_13_3 then
			xyd.LoadingProxy.get():setNewLoadingPercent(math.ceil(arg_15_0 * 100))
		end

		if arg_15_1 then
			if not arg_13_3 then
				xyd.LoadingProxy.get():removeLoading()
			end

			var_13_8()
			arg_13_2()
		end
	end

	arg_13_0:downloadFiles(var_13_0, var_13_9)
end

function var_0_1.preloadCharacterModelWithPath(arg_16_0, arg_16_1, arg_16_2, arg_16_3)
	local var_16_0 = {}
	local var_16_1 = {}
	local var_16_2 = {}
	local var_16_3 = xyd.tables.model:resource(arg_16_2)

	if var_16_3 and var_16_3 ~= "" then
		local var_16_4 = var_16_3
		local var_16_5 = xyd.split(var_16_4, "/")
		local var_16_6 = "res/web"
		local var_16_7

		for iter_16_0 = 1, #var_16_5 - 1 do
			var_16_6 = var_16_6 .. "/" .. var_16_5[iter_16_0]

			if iter_16_0 == #var_16_5 - 1 then
				var_16_7 = var_16_5[iter_16_0]
			end
		end

		local var_16_8 = arg_16_0.webSkeletonDict_[var_16_6]

		if var_16_8 == nil then
			print("PRELOAD CHARACTER WAR : " .. var_16_6)
		else
			for iter_16_1, iter_16_2 in ipairs(var_16_8) do
				if not arg_16_0:isFileExist(iter_16_2.path) and not var_16_2[iter_16_2.path] then
					var_16_2[iter_16_2.path] = true

					table.insert(var_16_0, iter_16_2)
				end
			end
		end

		if var_16_7 then
			local var_16_9 = xyd.tables.preloadSkeletons:path(var_16_7)

			if var_16_9 and next(var_16_9) then
				for iter_16_3, iter_16_4 in ipairs(var_16_9) do
					local var_16_10 = "res/web/"
					local var_16_11 = iter_16_4 .. ".json"
					local var_16_12 = iter_16_4 .. ".png"
					local var_16_13 = iter_16_4 .. ".atlas"

					if not arg_16_0:isFileExist(var_16_10 .. var_16_11) and not var_16_2[var_16_10 .. var_16_11] then
						var_16_2[var_16_10 .. var_16_11] = true

						local var_16_14 = arg_16_0:getDownloadVersionInfo({
							var_16_11
						})

						for iter_16_5, iter_16_6 in ipairs(var_16_14) do
							table.insert(var_16_0, iter_16_6)
						end
					end

					if not arg_16_0:isFileExist(var_16_10 .. var_16_12) and not var_16_2[var_16_10 .. var_16_12] then
						var_16_2[var_16_10 .. var_16_12] = true

						local var_16_15 = arg_16_0:getDownloadVersionInfo({
							var_16_12
						})

						for iter_16_7, iter_16_8 in ipairs(var_16_15) do
							table.insert(var_16_0, iter_16_8)
						end
					end

					if not arg_16_0:isFileExist(var_16_10 .. var_16_13) and not var_16_2[var_16_10 .. var_16_13] then
						var_16_2[var_16_10 .. var_16_13] = true

						local var_16_16 = arg_16_0:getDownloadVersionInfo({
							var_16_13
						})

						for iter_16_9, iter_16_10 in ipairs(var_16_16) do
							table.insert(var_16_0, iter_16_10)
						end
					end
				end
			end
		end
	end

	if arg_16_2 and arg_16_0.soundIsDownload[arg_16_2] == nil then
		local var_16_17 = xyd.tables.model:deathSound(arg_16_2)

		if var_16_17 and var_16_17 ~= "" then
			local var_16_18 = xyd.split(var_16_17, "/")
			local var_16_19 = "res/web"

			for iter_16_11 = 1, #var_16_18 - 1 do
				var_16_19 = var_16_19 .. "/" .. var_16_18[iter_16_11]
			end

			table.insert(var_16_1, id)

			local var_16_20 = arg_16_0.webSkeletonDict_[var_16_19]

			if var_16_20 == nil then
				print("PRELOAD CHARACTER WAR : " .. var_16_19)
			else
				for iter_16_12, iter_16_13 in ipairs(var_16_20) do
					if not arg_16_0:isFileExist(iter_16_13.path) and not var_16_2[iter_16_13.path] then
						var_16_2[iter_16_13.path] = true

						table.insert(var_16_0, iter_16_13)
					end
				end
			end
		end
	end

	local function var_16_21()
		for iter_17_0, iter_17_1 in ipairs(var_16_1) do
			arg_16_0.soundIsDownload[iter_17_1] = 1
		end
	end

	if #var_16_0 <= 0 then
		var_16_21()

		return arg_16_3()
	end

	local function var_16_22(arg_18_0, arg_18_1)
		if arg_16_1 and not tolua.isnull(arg_16_1) then
			arg_16_1:setPercent(math.ceil(arg_18_0 * 100))
		end

		if arg_18_1 then
			var_16_21()
			arg_16_3()
		end
	end

	arg_16_0:downloadFiles(var_16_0, var_16_22)
end

function var_0_1.preloadWindowsByName(arg_19_0, arg_19_1, arg_19_2)
	if arg_19_1 == "loading" or arg_19_1 == "new_loading" then
		return arg_19_2()
	end

	local var_19_0 = {}
	local var_19_1 = {}
	local var_19_2 = {}
	local var_19_3 = xyd.tables.preloadWindow:path(arg_19_1)
	local var_19_4 = xyd.tables.window:resource(arg_19_1)

	if var_19_3 and next(var_19_3) then
		for iter_19_0, iter_19_1 in ipairs(var_19_3) do
			if arg_19_0.windowIsDownload[iter_19_1] == nil and iter_19_1 and iter_19_1 ~= "" then
				local var_19_5 = "res/web/" .. iter_19_1

				table.insert(var_19_1, var_19_5)

				local var_19_6 = arg_19_0.webSkeletonDict_[var_19_5]

				if var_19_6 == nil then
					print("PRELOAD WINDOW WAR : " .. var_19_5)
				else
					for iter_19_2, iter_19_3 in ipairs(var_19_6) do
						if not arg_19_0:isFileExist(iter_19_3.path) and not var_19_2[iter_19_3.path] then
							var_19_2[iter_19_3.path] = true

							table.insert(var_19_0, iter_19_3)
						end
					end
				end
			end
		end
	end

	if var_19_4 and var_19_4 ~= "" then
		local var_19_7 = xyd.split(var_19_4, "/")
		local var_19_8 = "res/web"

		for iter_19_4 = 1, #var_19_7 - 1 do
			var_19_8 = var_19_8 .. "/" .. var_19_7[iter_19_4]
		end

		table.insert(var_19_1, var_19_8)

		local var_19_9 = arg_19_0.webSkeletonDict_[var_19_8]

		if var_19_9 == nil then
			print("PRELOAD WINDOW WAR : " .. var_19_8)
		else
			for iter_19_5, iter_19_6 in ipairs(var_19_9) do
				if not arg_19_0:isFileExist(iter_19_6.path) and not var_19_2[iter_19_6.path] then
					var_19_2[iter_19_6.path] = true

					table.insert(var_19_0, iter_19_6)
				end
			end
		end
	end

	local function var_19_10()
		for iter_20_0, iter_20_1 in ipairs(var_19_1) do
			arg_19_0.windowIsDownload[iter_20_1] = 1
		end
	end

	if #var_19_0 <= 0 then
		var_19_10()

		return arg_19_2()
	end

	xyd.LoadingProxy.get():addNewLoading(1.5)

	local function var_19_11(arg_21_0, arg_21_1)
		xyd.LoadingProxy.get():setNewLoadingPercent(math.ceil(arg_21_0 * 100))

		if arg_21_1 then
			xyd.LoadingProxy.get():removeLoading()
			var_19_10()
			arg_19_2()
		end
	end

	arg_19_0:downloadFiles(var_19_0, var_19_11)
end

function var_0_1.preloadActivitiesByTableID(arg_22_0, arg_22_1, arg_22_2)
	if name == "loading" or name == "new_loading" then
		return arg_22_2()
	end

	local var_22_0 = {}
	local var_22_1 = {}
	local var_22_2 = {}
	local var_22_3 = xyd.tables.preloadWindow:path(arg_22_1)

	if var_22_3 and next(var_22_3) then
		for iter_22_0, iter_22_1 in ipairs(var_22_3) do
			if arg_22_0.windowIsDownload[iter_22_1] == nil and iter_22_1 and iter_22_1 ~= "" then
				local var_22_4 = "res/web/" .. iter_22_1

				table.insert(var_22_1, var_22_4)

				local var_22_5 = arg_22_0.webSkeletonDict_[var_22_4]

				if var_22_5 == nil then
					print("PRELOAD WINDOW WAR : " .. var_22_4)
				else
					for iter_22_2, iter_22_3 in ipairs(var_22_5) do
						if not arg_22_0:isFileExist(iter_22_3.path) and not var_22_2[iter_22_3.path] then
							var_22_2[iter_22_3.path] = true

							table.insert(var_22_0, iter_22_3)
						end
					end
				end
			end
		end
	end

	local function var_22_6()
		for iter_23_0, iter_23_1 in ipairs(var_22_1) do
			arg_22_0.windowIsDownload[iter_23_1] = 1
		end
	end

	if #var_22_0 <= 0 then
		var_22_6()

		return arg_22_2()
	end

	xyd.LoadingProxy.get():addNewLoading(1.5)

	local function var_22_7(arg_24_0, arg_24_1)
		xyd.LoadingProxy.get():setNewLoadingPercent(math.ceil(arg_24_0 * 100))

		if arg_24_1 then
			xyd.LoadingProxy.get():removeLoading()
			var_22_6()
			arg_22_2()
		end
	end

	arg_22_0:downloadFiles(var_22_0, var_22_7)
end

function var_0_1.getDownloadVersionInfo(arg_25_0, arg_25_1)
	local var_25_0 = {}

	for iter_25_0, iter_25_1 in pairs(arg_25_1) do
		local var_25_1 = "res/web/" .. iter_25_1
		local var_25_2 = arg_25_0:parseXmlPath(var_25_1)
		local var_25_3 = var_0_4:getStringForKey(var_0_6 .. var_25_2)

		if var_25_3 and var_25_3 ~= "" then
			local var_25_4 = var_0_2.decode(var_25_3)

			table.insert(var_25_0, var_25_4)
		end
	end

	return var_25_0
end

function var_0_1.downloadSpriteByPath(arg_26_0, arg_26_1, arg_26_2, arg_26_3)
	local var_26_0 = {}

	table.insert(var_26_0, arg_26_2)

	local var_26_1 = arg_26_0:getDownloadVersionInfo(var_26_0)

	if #var_26_1 <= 0 then
		return arg_26_3()
	end

	local function var_26_2(arg_27_0, arg_27_1)
		if arg_26_1 and not tolua.isnull(arg_26_1) then
			arg_26_1:setPercent(math.ceil(arg_27_0 * 100))
		end

		if arg_27_1 then
			arg_26_3()
		end
	end

	arg_26_0:downloadFiles(var_26_1, var_26_2)
end

function var_0_1.downloadEffectByPath(arg_28_0, arg_28_1, arg_28_2, arg_28_3)
	local var_28_0 = {}

	table.insert(var_28_0, arg_28_2 .. ".json")
	table.insert(var_28_0, arg_28_2 .. ".atlas")
	table.insert(var_28_0, arg_28_2 .. ".png")

	local var_28_1 = arg_28_0:getDownloadVersionInfo(var_28_0)

	if #var_28_1 <= 0 then
		return arg_28_3()
	end

	local function var_28_2(arg_29_0, arg_29_1)
		if arg_28_1 and not tolua.isnull(arg_28_1) then
			arg_28_1:setPercent(math.ceil(arg_29_0 * 100))
		end

		if arg_29_1 then
			arg_28_3()
		end
	end

	arg_28_0:downloadFiles(var_28_1, var_28_2)
end

function var_0_1.downloadResByPath(arg_30_0, arg_30_1, arg_30_2)
	local var_30_0 = {}

	table.insert(var_30_0, arg_30_1)

	local var_30_1 = arg_30_0:getDownloadVersionInfo(var_30_0)

	if #var_30_1 <= 0 then
		return arg_30_2()
	end

	local function var_30_2(arg_31_0, arg_31_1)
		if arg_31_1 then
			arg_30_2()
		end
	end

	arg_30_0:downloadFiles(var_30_1, var_30_2)
end

function var_0_1.downloadResNoBlock(arg_32_0, arg_32_1, arg_32_2, arg_32_3)
	if arg_32_2 == nil or tolua.isnull(arg_32_2) then
		return
	end

	local var_32_0 = arg_32_0:getDownloadVersionInfo(arg_32_1)

	if #var_32_0 <= 0 then
		return arg_32_3()
	end

	local var_32_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/others/loading/loading.csb")
	local var_32_2 = var_32_1:getChildByName("loading_sector")
	local var_32_3 = cc.RotateBy:create(2, 360)

	var_32_2:runAction(cc.RepeatForever:create(var_32_3))
	arg_32_2:addChild(var_32_1)

	local var_32_4 = arg_32_2:getContentSize()

	var_32_1:setPosition(cc.p(var_32_4.width / 2, var_32_4.height / 2))

	local var_32_5 = var_32_1:getChildByName("loading_text")

	var_32_5:setStringByType(0 .. "%", xyd.fontType.TEXT)

	local function var_32_6(arg_33_0, arg_33_1)
		var_32_5:setStringByType(math.ceil(arg_33_0 * 100) .. "%", xyd.fontType.TEXT)

		if arg_33_1 then
			if var_32_1 == nil and tolua.isnull(var_32_1) then
				return
			end

			var_32_1:removeFromParent()
			arg_32_3()
		end
	end

	arg_32_0:downloadFiles(var_32_0, var_32_6)
end

function var_0_1.silenceDownload(arg_34_0, arg_34_1, arg_34_2)
	arg_34_0.silenceDownloadList = arg_34_0.silenceDownloadList or {}
	arg_34_0.isInDownloadList = arg_34_0.isInDownloadList or {}

	local var_34_0 = arg_34_0:getDownloadVersionInfo(arg_34_1)

	if #var_34_0 <= 0 then
		if arg_34_2 then
			return arg_34_2()
		else
			return
		end
	end

	for iter_34_0, iter_34_1 in pairs(var_34_0) do
		if arg_34_0.isInDownloadList[iter_34_1.path] == nil then
			table.insert(arg_34_0.silenceDownloadList, iter_34_1)

			arg_34_0.isInDownloadList[iter_34_1.path] = true
		end
	end

	if arg_34_0.silenceDownloading == true then
		return
	end

	arg_34_0.silenceDownloading = true

	arg_34_0:downloadFiles(arg_34_0.silenceDownloadList, function()
		arg_34_0.silenceDownloading = false
		arg_34_0.silenceDownloadList = {}
		arg_34_0.isInDownloadList = {}

		if arg_34_2 then
			arg_34_2()
		end
	end, true)
end

function var_0_1.downloadFiles(arg_36_0, arg_36_1, arg_36_2)
	if #arg_36_1 < 1 then
		if arg_36_2 then
			arg_36_2(1, true)
		end

		return
	end

	var_0_9 = var_0_9 + 1

	if var_0_9 > 200000000 then
		var_0_9 = 0
	end

	local var_36_0 = var_0_9
	local var_36_1 = {
		totalBytes = 0,
		downloadBytes = 0,
		needFiles = {},
		callback = arg_36_2
	}

	for iter_36_0, iter_36_1 in ipairs(arg_36_1) do
		if not arg_36_0.callbackCounts[iter_36_1.path] then
			arg_36_0.callbackCounts[iter_36_1.path] = {}
		end

		table.insert(arg_36_0.callbackCounts[iter_36_1.path], var_36_0)

		var_36_1.totalBytes = var_36_1.totalBytes + iter_36_1.size

		table.insert(var_36_1.needFiles, {
			bytes = 0,
			path = iter_36_1.path
		})
	end

	arg_36_0.callbackInfos[var_36_0] = var_36_1

	for iter_36_2, iter_36_3 in ipairs(arg_36_1) do
		arg_36_0:insertToStack(iter_36_3)
	end
end

function var_0_1.windowsTest(arg_37_0, arg_37_1)
	local var_37_0 = arg_37_1.path

	if arg_37_0.fileIsDownloading[var_37_0] then
		return
	end

	local var_37_1 = string.gsub(var_37_0, "res/", "/")

	if not arg_37_0.fileUtilsIns:isFileExist("res/" .. string.gsub(var_37_1, "web/", "web_test/")) then
		arg_37_0:dealCallbacks(true, var_37_0)

		return
	end

	arg_37_0.downFileCount = arg_37_0.downFileCount + 1
	arg_37_0.fileIsDownloading[var_37_0] = true

	arg_37_0:makeDirByFileName(var_37_0)
	var_0_3.performWithDelayGlobal(function()
		arg_37_0:dealCallbacks(false, var_37_0, 9000)
		var_0_3.performWithDelayGlobal(function()
			arg_37_0:dealCallbacks(false, var_37_0, 10000)
			var_0_3.performWithDelayGlobal(function()
				arg_37_0:dealCallbacks(false, var_37_0, 11000)
				var_0_3.performWithDelayGlobal(function()
					arg_37_0.downFileCount = arg_37_0.downFileCount - 1
					arg_37_0.fileIsDownloading[var_37_0] = nil

					arg_37_0.fileUtilsIns:renameFile("res/", string.gsub(var_37_1, "web/", "web_test/"), var_37_1)

					local var_41_0 = arg_37_0:parseXmlPath(var_37_0)

					var_0_4:deleteValueForKeyNoFlush(var_0_6 .. var_41_0)
					arg_37_0:dealCallbacks(true, var_37_0)
				end, 1)
			end, 1)
		end, 1)
	end, 1)
end

function var_0_1.insertToStack(arg_42_0, arg_42_1)
	local var_42_0 = arg_42_1.path

	if arg_42_0.fileIsDownloading[var_42_0] then
		for iter_42_0 = 1, arg_42_0.waitingNum do
			if arg_42_0.waitingStack[iter_42_0].path == var_42_0 then
				local var_42_1 = table.remove(arg_42_0.waitingStack, iter_42_0)

				arg_42_0.waitingStack[arg_42_0.waitingNum] = var_42_1

				break
			end
		end

		return
	end

	arg_42_0.downFileCount = arg_42_0.downFileCount + 1
	arg_42_0.fileIsDownloading[var_42_0] = true

	if arg_42_0.busyProcess < 10 then
		arg_42_0.busyProcess = arg_42_0.busyProcess + 1

		arg_42_0:downloadFile(arg_42_1)
	else
		arg_42_0.waitingNum = arg_42_0.waitingNum + 1
		arg_42_0.waitingStack[arg_42_0.waitingNum] = arg_42_1
	end
end

function var_0_1.tryDownload(arg_43_0)
	if arg_43_0.waitingNum < 1 then
		return
	end

	local var_43_0 = arg_43_0.waitingStack[arg_43_0.waitingNum]

	arg_43_0.waitingNum = arg_43_0.waitingNum - 1
	arg_43_0.busyProcess = arg_43_0.busyProcess + 1

	arg_43_0:downloadFile(var_43_0)
end

function var_0_1.downloadFile(arg_44_0, arg_44_1)
	local var_44_0 = arg_44_1.path
	local var_44_1 = arg_44_1.md5
	local var_44_2 = arg_44_0:getDownloadInfo_(arg_44_1)

	arg_44_0:makeDirByFileName(xyd.versionUpdatePath .. var_44_0)

	local var_44_3 = xyd.versionUpdatePath .. var_44_0 .. ".asset_tmp"

	xyd.FileDownloader:download(var_44_2.url, var_44_3, 0, 10, function(arg_45_0, arg_45_1, arg_45_2)
		arg_44_0:dealCallbacks(false, var_44_0, arg_45_0)
	end, function(arg_46_0, arg_46_1, arg_46_2)
		arg_44_0.downFileCount = arg_44_0.downFileCount - 1
		arg_44_0.fileIsDownloading[var_44_0] = nil
		arg_44_0.busyProcess = arg_44_0.busyProcess - 1

		arg_44_0:tryDownload()

		if arg_46_0 == xyd.FileDownloader.RESULT_SUCCESS and cc.Crypto:MD5File(var_44_3) == var_44_1 then
			var_44_2.finishedSize = arg_44_1.size

			arg_44_0.fileUtilsIns:renameFile(xyd.versionUpdatePath .. var_44_2.dir_path, var_44_2.name .. ".asset_tmp", var_44_2.name)

			local var_46_0 = arg_44_0:parseXmlPath(var_44_0)

			var_0_4:deleteValueForKeyNoFlush(var_0_6 .. var_46_0)
			arg_44_0:dealCallbacks(true, var_44_0)
		else
			local var_46_1 = cc.Crypto:MD5File(var_44_3)

			print(var_44_2.name .. "\nFAILED DOWNLOAD ERROR_CODE:" .. arg_46_1 .. "\n" .. var_46_1 .. "\n" .. arg_44_1.md5)

			arg_44_0.downFileCount = arg_44_0.downFileCount + 1
			arg_44_0.fileIsDownloading[var_44_0] = true

			arg_44_0:dealCallbacks(false, var_44_0, 0)
			arg_44_0:insertToStack(arg_44_1)
		end
	end)
end

function var_0_1.dealCallbacks(arg_47_0, arg_47_1, arg_47_2, arg_47_3)
	local var_47_0 = arg_47_0.callbackCounts[arg_47_2]

	if arg_47_1 then
		arg_47_0.callbackCounts[arg_47_2] = nil
	end

	for iter_47_0, iter_47_1 in ipairs(var_47_0 or {}) do
		local var_47_1 = arg_47_0.callbackInfos[iter_47_1]

		if var_47_1 then
			for iter_47_2, iter_47_3 in ipairs(var_47_1.needFiles) do
				if iter_47_3.path == arg_47_2 then
					if arg_47_1 then
						table.remove(var_47_1.needFiles, iter_47_2)
					else
						var_47_1.downloadBytes = var_47_1.downloadBytes + arg_47_3 - iter_47_3.bytes
						iter_47_3.bytes = arg_47_3
					end
				end
			end

			if #var_47_1.needFiles < 1 then
				arg_47_0.callbackInfos[iter_47_1] = nil

				if var_47_1.callback then
					var_47_1.callback(1, true)
				end
			elseif var_47_1.callback then
				var_47_1.callback(var_47_1.downloadBytes / var_47_1.totalBytes, false)
			end
		end
	end
end

function var_0_1.getDownloadInfo_(arg_48_0, arg_48_1)
	local var_48_0 = arg_48_1.path
	local var_48_1 = {}
	local var_48_2 = xyd.split(arg_48_1.path, "/")
	local var_48_3 = var_48_2[#var_48_2]
	local var_48_4 = (xyd.resDownloadUrl or "") .. var_48_3 .. "." .. arg_48_1.md5
	local var_48_5 = ""

	for iter_48_0 = 1, #var_48_2 - 1 do
		var_48_5 = var_48_5 .. var_48_2[iter_48_0] .. "/"
	end

	var_48_1.version = arg_48_1.version
	var_48_1.size = arg_48_1.size
	var_48_1.finishedSize = 0
	var_48_1.path = arg_48_1.path
	var_48_1.url = var_48_4
	var_48_1.name = var_48_3
	var_48_1.dir_path = var_48_5

	return var_48_1
end

function var_0_1.makeDirByFileName(arg_49_0, arg_49_1)
	local var_49_0 = xyd.split(arg_49_1, "/")
	local var_49_1 = ""

	for iter_49_0 = 1, #var_49_0 - 1 do
		var_49_1 = var_49_1 .. var_49_0[iter_49_0] .. "/"

		if not arg_49_0.pathDirs[var_49_1] then
			if not arg_49_0.fileUtilsIns:isDirectoryExist(var_49_1) then
				arg_49_0.fileUtilsIns:createDirectory(var_49_1)
			end

			arg_49_0.pathDirs[var_49_1] = 1
		end
	end
end

function var_0_1.parseXmlPath(arg_50_0, arg_50_1)
	local var_50_0 = xyd.split(arg_50_1, "/")
	local var_50_1 = ""

	for iter_50_0, iter_50_1 in pairs(var_50_0) do
		if iter_50_0 ~= 1 then
			var_50_1 = var_50_1 .. "___"
		end

		var_50_1 = var_50_1 .. iter_50_1
	end

	return var_50_1
end

function var_0_1.readFromFile(arg_51_0, arg_51_1)
	return var_0_2.decode(arg_51_0.fileUtilsIns:getStringFromFile(arg_51_1))
end

function var_0_1.isFileExist(arg_52_0, arg_52_1)
	local var_52_0 = arg_52_0:parseXmlPath(arg_52_1)
	local var_52_1 = var_0_4:getStringForKey(var_0_6 .. var_52_0)

	if not var_52_1 or #var_52_1 == 0 then
		return true
	end

	return false
end

function var_0_1.downloadIsBusy(arg_53_0)
	return arg_53_0.downFileCount > 0
end

return var_0_1
