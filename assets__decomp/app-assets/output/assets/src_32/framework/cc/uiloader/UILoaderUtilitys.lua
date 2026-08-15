local var_0_0 = {}

function var_0_0.loadTexture(arg_1_0, arg_1_1)
	if var_0_0.isNil(arg_1_0) then
		return
	end

	local var_1_0
	local var_1_1 = cc.FileUtils:getInstance()
	local var_1_2 = var_1_1:fullPathForFilename(arg_1_0)
	local var_1_3 = var_1_1:fullPathForFilename(arg_1_1)
	local var_1_4
	local var_1_5 = cc.SpriteFrameCache:getInstance()

	if arg_1_1 then
		var_1_5:addSpriteFrames(var_1_2, var_1_3)
	else
		var_1_5:addSpriteFrames(var_1_2)
	end
end

function var_0_0.isNil(arg_2_0)
	if not arg_2_0 or string.utf8len(arg_2_0) == 0 then
		return true
	else
		return false
	end
end

function var_0_0.addSearchPathIf(arg_3_0, arg_3_1)
	if not var_0_0.searchDirs then
		var_0_0.searchDirs = {}
	end

	if not var_0_0.isSearchExist(arg_3_0) then
		table.insert(var_0_0.searchDirs, arg_3_0)

		arg_3_1 = arg_3_1 or cc.FileUtils:getInstance()

		arg_3_1:addSearchPath(arg_3_0)
	end
end

function var_0_0.isSearchExist(arg_4_0)
	local var_4_0 = false

	for iter_4_0, iter_4_1 in ipairs(var_0_0.searchDirs) do
		if iter_4_1 == arg_4_0 then
			var_4_0 = true

			break
		end
	end

	return var_4_0
end

function var_0_0.clearPath(arg_5_0)
	if not var_0_0.searchDirs then
		return
	end

	arg_5_0 = arg_5_0 or cc.FileUtils:getInstance()

	local var_5_0 = arg_5_0:getSearchPaths()
	local var_5_1

	for iter_5_0 = #var_0_0.searchDirs, 1, -1 do
		for iter_5_1, iter_5_2 in ipairs(var_5_0) do
			if iter_5_2 == var_0_0.searchDirs[iter_5_0] then
				table.remove(var_5_0, iter_5_1)

				break
			end
		end

		table.remove(var_0_0.searchDirs, iter_5_0)
	end

	local var_5_2 = table.unique(var_5_0, true)

	arg_5_0:setSearchPaths(var_5_2)
end

function var_0_0.getFileFullName(arg_6_0)
	return (fileUtil or cc.FileUtils:getInstance()):fullPathForFilename(arg_6_0)
end

return var_0_0
