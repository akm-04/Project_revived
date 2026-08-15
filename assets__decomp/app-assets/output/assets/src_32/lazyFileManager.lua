local var_0_0 = require("cjson")

return {
	init = function(arg_1_0)
		arg_1_0.fileUtilsIns = cc.FileUtils:getInstance()

		if arg_1_0.fileUtilsIns:isFileExist(xyd.versionUpdatePath .. "lazyFile.json") then
			arg_1_0.maps = arg_1_0:readFromFile(xyd.versionUpdatePath .. "lazyFile.json") or {}
		else
			arg_1_0.maps = {}
		end

		arg_1_0.changeCount = 0
	end,
	setStringForKey = function(arg_2_0, arg_2_1, arg_2_2)
		arg_2_0.maps[arg_2_1] = arg_2_2

		arg_2_0:flush()
	end,
	setStringForKeyNoFlush = function(arg_3_0, arg_3_1, arg_3_2)
		arg_3_0.maps[arg_3_1] = arg_3_2
	end,
	flush = function(arg_4_0)
		arg_4_0:makeDirByFileName(xyd.versionUpdatePath)
		arg_4_0:write2File(var_0_0.encode(arg_4_0.maps), xyd.versionUpdatePath .. "lazyFile.json.tmp")
		arg_4_0.fileUtilsIns:renameFile(xyd.versionUpdatePath, "lazyFile.json.tmp", "lazyFile.json")
	end,
	getStringForKey = function(arg_5_0, arg_5_1)
		return arg_5_0.maps[arg_5_1]
	end,
	deleteValueForKey = function(arg_6_0, arg_6_1)
		arg_6_0.maps[arg_6_1] = nil

		arg_6_0:flush()
	end,
	deleteValueForKeyNoFlush = function(arg_7_0, arg_7_1)
		arg_7_0.maps[arg_7_1] = nil
		arg_7_0.changeCount = arg_7_0.changeCount + 1

		if arg_7_0.changeCount > 30 then
			arg_7_0.changeCount = 0

			arg_7_0:flush()
		end
	end,
	tryFlush = function(arg_8_0)
		if arg_8_0.changeCount < 1 then
			return
		end

		arg_8_0.changeCount = 0

		arg_8_0:flush()
	end,
	makeDirByFileName = function(arg_9_0, arg_9_1)
		if not arg_9_0.fileUtilsIns:isDirectoryExist(arg_9_1) then
			arg_9_0.fileUtilsIns:createDirectory(arg_9_1)
		end
	end,
	readFromFile = function(arg_10_0, arg_10_1)
		return var_0_0.decode(arg_10_0.fileUtilsIns:getStringFromFile(arg_10_1))
	end,
	write2File = function(arg_11_0, arg_11_1, arg_11_2)
		local var_11_0 = io.open(arg_11_2, "w")

		var_11_0:write(arg_11_1)
		var_11_0:close()
	end
}
