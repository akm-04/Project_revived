local var_0_0 = {}

var_0_0.ERROR_INVALID_FILE_CONTENTS = -1
var_0_0.ERROR_HASH_MISS_MATCH = -2
var_0_0.ERROR_STATE_FILE_NOT_FOUND = -3

local var_0_1 = require(cc.PACKAGE_NAME .. ".crypto")
local var_0_2 = require(cc.PACKAGE_NAME .. ".json")
local var_0_3 = "=QP="
local var_0_4 = "state.txt"
local var_0_5
local var_0_6

local function var_0_7(arg_1_0)
	return string.sub(arg_1_0, 1, string.len(var_0_3)) == var_0_3
end

local function var_0_8(arg_2_0)
	local var_2_0 = var_0_2.encode(arg_2_0)
	local var_2_1 = var_0_1.md5(var_2_0 .. var_0_6)
	local var_2_2 = var_0_2.encode({
		h = var_2_1,
		s = var_2_0
	})

	return var_0_3 .. var_2_2
end

local function var_0_9(arg_3_0)
	local var_3_0 = string.sub(arg_3_0, string.len(var_0_3) + 1)
	local var_3_1 = var_0_2.decode(var_3_0)

	if type(var_3_1) ~= "table" then
		printError("GameState.decode_() - invalid contents")

		return {
			errorCode = var_0_0.ERROR_INVALID_FILE_CONTENTS
		}
	end

	local var_3_2 = var_3_1.h
	local var_3_3 = var_3_1.s

	if var_0_1.md5(var_3_3 .. var_0_6) ~= var_3_2 then
		printError("GameState.decode_() - hash miss match")

		return {
			errorCode = var_0_0.ERROR_HASH_MISS_MATCH
		}
	end

	local var_3_4 = var_0_2.decode(var_3_3)

	if type(var_3_4) ~= "table" then
		printError("GameState.decode_() - invalid state data")

		return {
			errorCode = var_0_0.ERROR_INVALID_FILE_CONTENTS
		}
	end

	return {
		values = var_3_4
	}
end

function var_0_0.init(arg_4_0, arg_4_1, arg_4_2)
	if type(arg_4_0) ~= "function" then
		printError("GameState.init() - invalid eventListener")

		return false
	end

	var_0_5 = arg_4_0

	if type(arg_4_1) == "string" then
		var_0_4 = arg_4_1
	end

	if type(arg_4_2) == "string" then
		var_0_6 = arg_4_2
	end

	var_0_5({
		name = "init",
		filename = var_0_0.getGameStatePath(),
		encode = type(var_0_6) == "string"
	})

	return true
end

function var_0_0.load()
	local var_5_0 = var_0_0.getGameStatePath()

	if not io.exists(var_5_0) then
		printInfo("GameState.load() - file \"%s\" not found", var_5_0)

		return var_0_5({
			name = "load",
			errorCode = var_0_0.ERROR_STATE_FILE_NOT_FOUND
		})
	end

	local var_5_1 = io.readfile(var_5_0)

	printInfo("GameState.load() - get values from \"%s\"", var_5_0)

	local var_5_2
	local var_5_3 = false

	if var_0_6 and var_0_7(var_5_1) then
		local var_5_4 = var_0_9(var_5_1)

		if var_5_4.errorCode then
			return var_0_5({
				name = "load",
				errorCode = var_5_4.errorCode
			})
		end

		var_5_2 = var_5_4.values
		var_5_3 = true
	else
		var_5_2 = var_0_2.decode(var_5_1)

		if type(var_5_2) ~= "table" then
			printError("GameState.load() - invalid data")

			return var_0_5({
				name = "load",
				errorCode = var_0_0.ERROR_INVALID_FILE_CONTENTS
			})
		end
	end

	return var_0_5({
		name = "load",
		values = var_5_2,
		encode = var_5_3,
		time = os.time()
	})
end

function var_0_0.save(arg_6_0)
	local var_6_0 = var_0_5({
		name = "save",
		values = arg_6_0,
		encode = type(var_0_6) == "string"
	})

	if type(var_6_0) ~= "table" then
		printError("GameState.save() - listener return invalid data")

		return false
	end

	local var_6_1 = var_0_0.getGameStatePath()
	local var_6_2 = false

	if var_0_6 then
		var_6_2 = io.writefile(var_6_1, var_0_8(var_6_0))
	else
		local var_6_3 = var_0_2.encode(var_6_0)

		if type(var_6_3) == "string" then
			var_6_2 = io.writefile(var_6_1, var_6_3)
		end
	end

	printInfo("GameState.save() - update file \"%s\"", var_6_1)

	return var_6_2
end

function var_0_0.getGameStatePath()
	return string.gsub(device.writablePath, "[\\\\/]+$", "") .. device.directorySeparator .. var_0_4
end

cc = cc or {}
cc.utils = cc.utils or {}
cc.utils.State = var_0_0

return var_0_0
