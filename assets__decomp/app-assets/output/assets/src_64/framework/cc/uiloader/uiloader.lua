local var_0_0 = import(".UILoaderUtilitys")
local var_0_1 = class("uiloader")
local var_0_2 = import(".CCSUILoader")
local var_0_3 = import(".CCSSceneLoader")

function var_0_1.ctor(arg_1_0)
	return
end

function var_0_1.load(arg_2_0, arg_2_1, arg_2_2)
	local var_2_0

	if not arg_2_2 or not arg_2_2.bJsonStruct then
		if io.pathinfo(arg_2_1).extname == ".csb" then
			return cc.CSLoader:getInstance():createNodeWithFlatBuffersFile(arg_2_1)
		else
			var_2_0 = arg_2_0:loadFile_(arg_2_1)
		end
	else
		var_2_0 = arg_2_1
	end

	if not var_2_0 then
		print("uiloader - load file fail:" .. arg_2_1)

		return
	end

	local var_2_1

	if arg_2_0:isScene_(var_2_0) then
		var_2_1, w, h = var_0_3:load(var_2_0, arg_2_2)
	else
		var_2_1, w, h = var_0_2:load(var_2_0, arg_2_2)
	end

	var_0_0.clearPath()

	return var_2_1, w, h
end

function var_0_1.seekNodeByTag(arg_3_0, arg_3_1, arg_3_2)
	if not arg_3_1 then
		return
	end

	if arg_3_2 == arg_3_1:getTag() then
		return arg_3_1
	end

	local var_3_0
	local var_3_1 = arg_3_1:getChildren()
	local var_3_2 = arg_3_1:getChildrenCount()

	if var_3_2 < 1 then
		return
	end

	for iter_3_0 = 1, var_3_2 do
		if type(var_3_1) == "table" then
			arg_3_1 = var_3_1[iter_3_0]
		elseif type(var_3_1) == "userdata" then
			arg_3_1 = var_3_1:objectAtIndex(iter_3_0 - 1)
		end

		if arg_3_1 then
			local var_3_3 = arg_3_0:seekNodeByTag(arg_3_1, arg_3_2)

			if var_3_3 then
				return var_3_3
			end
		end
	end
end

function var_0_1.seekNodeByName(arg_4_0, arg_4_1, arg_4_2)
	if not arg_4_1 then
		return
	end

	if arg_4_2 == arg_4_1.name then
		return arg_4_1
	end

	local var_4_0
	local var_4_1 = arg_4_1:getChildren()
	local var_4_2 = arg_4_1:getChildrenCount()

	if var_4_2 < 1 then
		return
	end

	for iter_4_0 = 1, var_4_2 do
		if type(var_4_1) == "table" then
			arg_4_1 = var_4_1[iter_4_0]
		elseif type(var_4_1) == "userdata" then
			arg_4_1 = var_4_1:objectAtIndex(iter_4_0 - 1)
		end

		if arg_4_1 and arg_4_2 == arg_4_1.name then
			return arg_4_1
		end
	end

	for iter_4_1 = 1, var_4_2 do
		if type(var_4_1) == "table" then
			arg_4_1 = var_4_1[iter_4_1]
		elseif type(var_4_1) == "userdata" then
			arg_4_1 = var_4_1:objectAtIndex(iter_4_1 - 1)
		end

		if arg_4_1 then
			local var_4_3 = arg_4_0:seekNodeByName(arg_4_1, arg_4_2)

			if var_4_3 then
				return var_4_3
			end
		end
	end
end

function var_0_1.seekNodeByNameFast(arg_5_0, arg_5_1, arg_5_2)
	if not arg_5_1 then
		return
	end

	if not arg_5_1.subChildren then
		return
	end

	if arg_5_2 == arg_5_1.name then
		return arg_5_1
	end

	local var_5_0 = arg_5_1.subChildren[arg_5_2]

	if var_5_0 then
		return var_5_0
	end

	for iter_5_0, iter_5_1 in ipairs(arg_5_1.subChildren) do
		local var_5_1 = arg_5_0:seekNodeByName(iter_5_1, arg_5_2)

		if var_5_1 then
			return var_5_1
		end
	end
end

function var_0_1.seekNodeByPath(arg_6_0, arg_6_1, arg_6_2)
	if not arg_6_1 then
		return
	end

	local var_6_0 = string.split(arg_6_2, "/")

	for iter_6_0, iter_6_1 in ipairs(var_6_0) do
		arg_6_1 = arg_6_0:seekNodeByNameFast(arg_6_1, iter_6_1)

		if not arg_6_1 then
			return
		end
	end

	return arg_6_1
end

function var_0_1.seekComponents(arg_7_0, arg_7_1, arg_7_2, arg_7_3)
	local var_7_0 = arg_7_0:seekNodeByName(arg_7_1, arg_7_2)

	if not var_7_0 then
		return
	end

	return (arg_7_0:seekNodeByName(var_7_0, "Component" .. arg_7_3))
end

function var_0_1.loadFile_(arg_8_0, arg_8_1)
	local var_8_0 = cc.FileUtils:getInstance()
	local var_8_1 = var_8_0:fullPathForFilename(arg_8_1)
	local var_8_2 = io.pathinfo(var_8_1)

	var_0_0.addSearchPathIf(var_8_2.dirname)

	local var_8_3 = var_8_0:getStringFromFile(var_8_1)

	return (json.decode(var_8_3))
end

function var_0_1.isScene_(arg_9_0, arg_9_1)
	if arg_9_1.components then
		return true
	else
		return false
	end
end

return var_0_1
