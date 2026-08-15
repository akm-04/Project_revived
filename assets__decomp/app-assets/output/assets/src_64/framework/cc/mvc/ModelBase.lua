local var_0_0 = class("ModelBase")

var_0_0.idkey = "id"
var_0_0.schema = {
	id = {
		"string"
	}
}
var_0_0.fields = {
	"id"
}

local function var_0_1(arg_1_0, arg_1_1)
	for iter_1_0, iter_1_1 in ipairs(arg_1_1) do
		arg_1_0[iter_1_1] = nil
	end
end

function var_0_0.ctor(arg_2_0, arg_2_1)
	cc(arg_2_0):addComponent("components.behavior.EventProtocol"):exportMethods()

	arg_2_0.isModelBase_ = true

	if type(arg_2_1) ~= "table" then
		arg_2_1 = {}
	end

	arg_2_0:setProperties(arg_2_1)
end

function var_0_0.getId(arg_3_0)
	local var_3_0 = arg_3_0[arg_3_0.class.idkey .. "_"]

	assert(var_3_0 ~= nil, string.format("%s:getId() - invalid id", arg_3_0.class.__cname))

	return var_3_0
end

function var_0_0.isValidId(arg_4_0)
	local var_4_0 = arg_4_0[arg_4_0.class.idkey .. "_"]

	return type(var_4_0) == "string" and var_4_0 ~= ""
end

function var_0_0.setProperties(arg_5_0, arg_5_1)
	assert(type(arg_5_1) == "table", string.format("%s:setProperties() - invalid properties", arg_5_0.class.__cname))

	for iter_5_0, iter_5_1 in pairs(arg_5_0.class.schema) do
		local var_5_0 = iter_5_1[1]
		local var_5_1 = iter_5_1[2]
		local var_5_2 = iter_5_0 .. "_"
		local var_5_3 = arg_5_1[iter_5_0]

		if var_5_3 ~= nil then
			if var_5_0 == "number" then
				var_5_3 = tonumber(var_5_3)
			end

			assert(type(var_5_3) == var_5_0, string.format("%s:setProperties() - type mismatch, %s expected %s, actual is %s", arg_5_0.class.__cname, iter_5_0, var_5_0, type(var_5_3)))

			arg_5_0[var_5_2] = var_5_3
		elseif arg_5_0[var_5_2] == nil and var_5_1 ~= nil then
			if type(var_5_1) == "table" then
				var_5_3 = clone(var_5_1)
			elseif type(var_5_1) == "function" then
				var_5_3 = var_5_1()
			else
				var_5_3 = var_5_1
			end

			arg_5_0[var_5_2] = var_5_3
		end
	end

	return arg_5_0
end

function var_0_0.getProperties(arg_6_0, arg_6_1, arg_6_2)
	local var_6_0 = arg_6_0.class.schema

	if type(arg_6_1) ~= "table" then
		arg_6_1 = arg_6_0.class.fields
	end

	local var_6_1 = {}

	for iter_6_0, iter_6_1 in ipairs(arg_6_1) do
		local var_6_2 = iter_6_1 .. "_"
		local var_6_3 = var_6_0[iter_6_1][1]
		local var_6_4 = arg_6_0[var_6_2]

		assert(type(var_6_4) == var_6_3, string.format("%s:getProperties() - type mismatch, %s expected %s, actual is %s", arg_6_0.class.__cname, iter_6_1, var_6_3, type(var_6_4)))

		var_6_1[iter_6_1] = var_6_4
	end

	if type(arg_6_2) == "table" then
		var_0_1(var_6_1, arg_6_2)
	end

	return var_6_1
end

return var_0_0
