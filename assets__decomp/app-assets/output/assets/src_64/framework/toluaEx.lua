function tolua.cloneTable(arg_1_0)
	if type(arg_1_0) ~= "table" then
		return nil
	end

	local var_1_0 = {}

	for iter_1_0, iter_1_1 in pairs(arg_1_0) do
		var_1_0[iter_1_0] = iter_1_1
	end

	local var_1_1 = getmetatable(arg_1_0)

	if var_1_1 then
		setmetatable(var_1_0, var_1_1)
	end

	return var_1_0
end

if CCPoint then
	tolua.default_gc_classes__ = {
		"ccColor3B",
		"ccColor4B",
		"ccColor4F",
		"CCPoint",
		"CCRect",
		"CCSize"
	}
else
	tolua.default_gc_classes__ = {}
end

function tolua.fullgc(arg_2_0)
	collectgarbage("collect")

	if arg_2_0 == nil then
		arg_2_0 = tolua.default_gc_classes__
	elseif type(arg_2_0) == "string" then
		arg_2_0 = {
			arg_2_0
		}
	elseif type(arg_2_0) ~= "table" then
		arg_2_0 = tolua.default_gc_classes__
	end

	local var_2_0 = tolua.getregval("tolua_gc")
	local var_2_1 = tolua.cloneTable(var_2_0)

	if var_2_1 then
		tolua.setregval("tolua_gc", var_2_1)
	end

	for iter_2_0, iter_2_1 in ipairs(arg_2_0) do
		local var_2_2 = tolua.getubox(iter_2_1)
		local var_2_3 = tolua.cloneTable(var_2_2)

		if var_2_2 then
			tolua.setubox(iter_2_1, var_2_3)
		end
	end

	local var_2_4
	local var_2_5

	collectgarbage("collect")
end
