local var_0_0 = {}
local var_0_1 = require("framework.scheduler")
local var_0_2 = cc.FileUtils:getInstance()
local var_0_3 = 5
local var_0_4 = "version.json"
local var_0_5 = "URes"
local var_0_6 = "UTmp"
local var_0_7 = var_0_2:getWritablePath()
local var_0_8 = var_0_7 .. var_0_5 .. "/"
local var_0_9 = var_0_7 .. var_0_6 .. "/"
local var_0_10 = "32"

if jit.arch == "arm64" then
	var_0_10 = "64"
end

local function var_0_11(arg_1_0, arg_1_1)
	local var_1_0 = io.pathinfo(arg_1_1)

	var_0_2:createDirectory(var_1_0.dirname)

	local var_1_1 = io.readfile(arg_1_0)

	if var_1_1 then
		io.writefile(arg_1_1, var_1_1, "wb")
	end
end

local function var_0_12(arg_2_0, arg_2_1)
	local var_2_0 = io.pathinfo(arg_2_0)

	var_0_2:createDirectory(var_2_0.dirname)
	io.writefile(arg_2_0, arg_2_1, "wb")
end

local function var_0_13(arg_3_0, arg_3_1)
	arg_3_0 = string.split(arg_3_0, ".")
	arg_3_1 = string.split(arg_3_1, ".")

	for iter_3_0 = 1, 3 do
		mVer = tonumber(arg_3_0[iter_3_0])
		mSver = tonumber(arg_3_1[iter_3_0])

		if mVer < mSver then
			return true
		elseif mVer > mSver then
			return false
		end
	end

	return false
end

local function var_0_14(arg_4_0, arg_4_1)
	if string.sub(arg_4_0, #arg_4_0 - 3) == ".zip" and string.sub(arg_4_0, #arg_4_0 - 5, #arg_4_0 - 4) ~= var_0_10 then
		return false
	end

	local var_4_0 = var_0_9 .. arg_4_0

	if var_0_2:isFileExist(var_4_0) and crypto.md5file(var_4_0) == arg_4_1 then
		return false
	end

	return true
end

local function var_0_15(arg_5_0, arg_5_1)
	local var_5_0 = var_0_2:fullPathForFilename(arg_5_0)

	if string.find(var_5_0, var_0_8, 1, true) == 1 then
		if var_0_2:isFileExist(var_5_0) and crypto.md5file(var_5_0) == arg_5_1 then
			var_0_11(var_5_0, var_0_9 .. arg_5_0)

			return true
		end

		return false
	end

	return true
end

local function var_0_16(arg_6_0, arg_6_1)
	local var_6_0 = {}
	local var_6_1 = 0
	local var_6_2 = arg_6_1.asserts

	for iter_6_0, iter_6_1 in pairs(arg_6_0.asserts) do
		local var_6_3 = var_6_2[iter_6_0]

		if var_6_3 then
			if var_6_3[1] ~= iter_6_1[1] then
				if var_0_14(iter_6_0, var_6_3[1]) then
					table.insert(var_6_0, {
						url = iter_6_0,
						total = var_6_3[2]
					})

					var_6_1 = var_6_1 + var_6_3[2]
				end
			elseif not var_0_15(iter_6_0, var_6_3[1]) then
				table.insert(var_6_0, {
					url = iter_6_0,
					total = var_6_3[2]
				})

				var_6_1 = var_6_1 + var_6_3[2]
			end

			var_6_3.checked = true
		end
	end

	for iter_6_2, iter_6_3 in pairs(var_6_2) do
		if iter_6_3.checked then
			iter_6_3.checked = nil
		elseif var_0_14(iter_6_2, iter_6_3[1]) then
			var_6_1 = var_6_1 + iter_6_3[2]

			table.insert(var_6_0, {
				url = iter_6_2,
				total = iter_6_3[2]
			})
		end
	end

	return {
		change = var_6_0,
		size = var_6_1,
		packages = arg_6_1.packages
	}
end

local function var_0_17(arg_7_0, arg_7_1, arg_7_2)
	arg_7_1(2, arg_7_2.size, 0)

	local var_7_0 = 0
	local var_7_1 = 0
	local var_7_2 = 0

	local function var_7_3(arg_8_0)
		var_7_1 = var_7_1 + arg_8_0

		arg_7_1(2, arg_7_2.size, var_7_1)
	end

	local function var_7_4(arg_9_0)
		var_7_0 = var_7_0 - 1
		var_7_2 = var_7_2 + 1

		var_7_3(-arg_9_0.getSize)

		arg_9_0.isReqed = nil
		arg_9_0.getSize = nil
	end

	local function var_7_5(arg_10_0)
		local var_10_0 = arg_7_2.change[arg_10_0]
		local var_10_1 = arg_7_0 .. "/" .. var_10_0.url
		local var_10_2 = network.createHTTPRequest(function(arg_11_0)
			local var_11_0 = arg_11_0.request

			if arg_11_0.name == "completed" then
				if var_11_0:getResponseStatusCode() ~= 200 then
					var_7_4(var_10_0)

					return
				end

				var_7_0 = var_7_0 - 1

				local var_11_1 = var_11_0:getResponseDataLength() - var_10_0.getSize

				var_7_3(var_11_1)
				var_0_12(var_0_9 .. var_10_0.url, var_11_0:getResponseData())

				arg_7_2.change[arg_10_0] = nil

				if var_7_2 > 0 then
					var_7_2 = var_7_2 - 1
				end
			elseif arg_11_0.name == "progress" then
				local var_11_2 = arg_11_0.dltotal - var_10_0.getSize

				var_7_3(var_11_2)

				var_10_0.getSize = arg_11_0.dltotal
			else
				var_7_4(var_10_0)
			end
		end, var_10_1, "GET")

		var_10_0.isReqed = true
		var_10_0.getSize = 0
		var_7_0 = var_7_0 + 1

		var_10_2:setTimeout(math.max(10, var_10_0.total / 10240))
		var_10_2:start()
	end

	var_0_0._scheduler = var_0_1.scheduleUpdateGlobal(function()
		if table.nums(arg_7_2.change) == 0 then
			var_0_1.unscheduleGlobal(var_0_0._scheduler)
			var_0_2:removeDirectory(var_0_8)
			var_0_2:renameFile(var_0_7, var_0_6, var_0_5)
			var_0_2:purgeCachedEntries()

			for iter_12_0, iter_12_1 in ipairs(arg_7_2.packages) do
				cc.LuaLoadChunksFromZIP(iter_12_1 .. var_0_10 .. ".zip")
			end

			cc.Director:getInstance():purgeCachedData()

			__UpdaterInited = nil

			arg_7_1(1)

			return
		end

		if var_7_0 == 0 and var_7_2 >= var_0_3 then
			var_0_1.unscheduleGlobal(var_0_0._scheduler)
			arg_7_1(5, -1)

			return
		end

		if var_7_0 < var_0_3 and table.nums(arg_7_2.change) > var_7_0 then
			for iter_12_2, iter_12_3 in pairs(arg_7_2.change) do
				if iter_12_3.isReqed ~= true then
					var_7_5(iter_12_2)

					break
				end
			end
		end
	end)
end

local function var_0_18(arg_13_0, arg_13_1)
	local var_13_0 = var_0_2:getDataFromFile(var_0_4)

	assert(var_13_0, "Error: fail to get data from config.json")

	local var_13_1 = json.decode(var_13_0)

	assert(var_13_1, "Error: fail to parser config.json")

	local var_13_2 = network.createHTTPRequest(function(arg_14_0)
		local var_14_0 = arg_14_0.request

		if arg_14_0.name == "completed" then
			local var_14_1 = var_14_0:getResponseStatusCode()

			if var_14_1 ~= 200 then
				arg_13_1(4, var_14_1)

				return
			end

			local var_14_2 = var_14_0:getResponseString()
			local var_14_3 = json.decode(var_14_2)

			if var_0_13(var_13_1.EngineVersion, var_14_3.EngineVersion) then
				arg_13_1(6)
			elseif var_0_13(var_13_1.GameVersion, var_14_3.GameVersion) then
				var_0_12(var_0_9 .. var_0_4, var_14_0:getResponseData())

				local var_14_4 = var_0_16(var_13_1, var_14_3)

				if network.isLocalWiFiAvailable() then
					var_0_17(arg_13_0, arg_13_1, var_14_4)
				else
					arg_13_1(7, var_14_4.size, function()
						var_0_17(arg_13_0, arg_13_1, var_14_4)
					end)
				end
			else
				print("== no need update")

				__UpdaterInited = nil

				arg_13_1(1)
			end
		elseif arg_14_0.name == "progress" then
			-- block empty
		else
			arg_13_1(5, var_14_0:getErrorCode())
		end
	end, arg_13_0 .. "/" .. var_0_4, "GET")

	var_13_2:setTimeout(30)
	var_13_2:start()
end

local function var_0_19(arg_16_0, arg_16_1)
	if not network.isInternetConnectionAvailable() then
		arg_16_1(3)

		return
	end

	local var_16_0 = network.createHTTPRequest(function(arg_17_0)
		local var_17_0 = arg_17_0.request

		if arg_17_0.name == "completed" then
			local var_17_1 = var_17_0:getResponseStatusCode()

			if var_17_1 ~= 200 then
				arg_16_1(4, var_17_1)

				return
			end

			local var_17_2 = var_17_0:getResponseString()
			local var_17_3 = string.gsub(var_17_2, "[\n\r]", "")

			var_0_18(var_17_3, arg_16_1)
		elseif arg_17_0.name == "progress" then
			-- block empty
		else
			arg_16_1(5, var_17_0:getErrorCode())
		end
	end, arg_16_0, "GET")

	var_16_0:setTimeout(15)
	var_16_0:start()
end

function var_0_0.init(arg_18_0, arg_18_1, arg_18_2)
	if __UpdaterInited then
		var_0_19(arg_18_1, arg_18_2)

		return
	end

	__UpdaterInited = true

	local var_18_0 = var_0_2:getDataFromFile("res/" .. var_0_4)
	local var_18_1 = json.decode(var_18_0)

	var_0_2:setSearchPaths({
		var_0_8,
		"res/"
	})

	local var_18_2 = var_0_2:getDataFromFile(var_0_4)
	local var_18_3 = json.decode(var_18_2)

	if var_0_13(var_18_3.EngineVersion, var_18_1.EngineVersion) or var_0_13(var_18_3.GameVersion, var_18_1.GameVersion) then
		var_0_2:removeDirectory(var_0_8)
		var_0_2:purgeCachedEntries()

		var_18_3 = var_18_1
	end

	var_0_1.performWithDelayGlobal(function()
		for iter_19_0, iter_19_1 in ipairs(var_18_3.packages) do
			cc.LuaLoadChunksFromZIP(iter_19_1 .. var_0_10 .. ".zip")
		end

		print("== restarting", arg_18_0)
		cc.Director:getInstance():replaceScene(require(arg_18_0).new())
	end, 0)
end

return var_0_0
