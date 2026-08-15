local var_0_0 = class("Registry")

var_0_0.classes_ = {}
var_0_0.objects_ = {}

function var_0_0.add(arg_1_0, arg_1_1)
	assert(type(arg_1_0) == "table" and arg_1_0.__cname ~= nil, "Registry.add() - invalid class")

	arg_1_1 = arg_1_1 or arg_1_0.__cname

	assert(var_0_0.classes_[arg_1_1] == nil, string.format("Registry.add() - class \"%s\" already exists", tostring(arg_1_1)))

	var_0_0.classes_[arg_1_1] = arg_1_0
end

function var_0_0.remove(arg_2_0)
	assert(var_0_0.classes_[arg_2_0] ~= nil, string.format("Registry.remove() - class \"%s\" not found", arg_2_0))

	var_0_0.classes_[arg_2_0] = nil
end

function var_0_0.exists(arg_3_0)
	return var_0_0.classes_[arg_3_0] ~= nil
end

function var_0_0.newObject(arg_4_0, ...)
	local var_4_0 = var_0_0.classes_[arg_4_0]

	if not var_4_0 then
		pcall(function()
			var_4_0 = require(arg_4_0)

			var_0_0.add(var_4_0, arg_4_0)
		end)
	end

	assert(var_4_0 ~= nil, string.format("Registry.newObject() - invalid class \"%s\"", tostring(arg_4_0)))

	return var_4_0.new(...)
end

function var_0_0.setObject(arg_6_0, arg_6_1)
	assert(var_0_0.objects_[arg_6_1] == nil, string.format("Registry.setObject() - object \"%s\" already exists", tostring(arg_6_1)))
	assert(arg_6_0 ~= nil, "Registry.setObject() - object \"%s\" is nil", tostring(arg_6_1))

	var_0_0.objects_[arg_6_1] = arg_6_0
end

function var_0_0.getObject(arg_7_0)
	assert(var_0_0.objects_[arg_7_0] ~= nil, string.format("Registry.getObject() - object \"%s\" not exists", tostring(arg_7_0)))

	return var_0_0.objects_[arg_7_0]
end

function var_0_0.removeObject(arg_8_0)
	assert(var_0_0.objects_[arg_8_0] ~= nil, string.format("Registry.removeObject() - object \"%s\" not exists", tostring(arg_8_0)))

	var_0_0.objects_[arg_8_0] = nil
end

function var_0_0.isObjectExists(arg_9_0)
	return var_0_0.objects_[arg_9_0] ~= nil
end

return var_0_0
