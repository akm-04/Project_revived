local var_0_0 = {}
local var_0_1 = {
	["item.lua"] = true,
	["model_points.lua"] = true,
	["battle_config.lua"] = true,
	["skill.lua"] = true,
	["buff.lua"] = true
}
local var_0_2 = {
	["monster.lua"] = true
}
local var_0_3 = {
	["partner.lua"] = true,
	["super_partner.lua"] = true,
	["activity_partner.lua"] = true,
	["pet.lua"] = true
}
local var_0_4 = crypto.decodeBase64
local var_0_5 = string
local var_0_6 = loadstring

function var_0_0.decryptSaveMemoryUnparsed(arg_1_0, arg_1_1)
	local var_1_0 = "data.tables." .. arg_1_0
	local var_1_1 = require(var_1_0)
	local var_1_2 = var_0_6(var_0_4(var_1_1))()

	arg_1_1(var_1_2)
end

function var_0_0.decryptSaveMemoryParsed(arg_2_0, arg_2_1)
	local var_2_0 = "data.tables." .. arg_2_0
	local var_2_1 = require(var_2_0)
	local var_2_2 = var_0_6(var_0_4(var_2_1))()

	for iter_2_0, iter_2_1 in pairs(var_2_2.rows) do
		arg_2_1(iter_2_1, var_2_2.keys)
	end
end

function var_0_0.decryptParse(arg_3_0, arg_3_1)
	local var_3_0 = "data.tables." .. arg_3_0
	local var_3_1 = require(var_3_0)
	local var_3_2 = var_0_4(var_3_1)
	local var_3_3 = 0
	local var_3_4 = {}

	for iter_3_0 in var_0_5.gmatch(var_3_2, "([^\r\n]*)[\r\n]+") do
		var_3_3 = var_3_3 + 1

		if iter_3_0 and #iter_3_0 > 0 then
			iter_3_0 = xyd.trimString(iter_3_0)
		end

		local var_3_5 = "([^\t]*)\t"

		if var_3_3 == 2 then
			for iter_3_1 in var_0_5.gmatch(iter_3_0 .. "\t", var_3_5) do
				table.insert(var_3_4, iter_3_1)
			end
		elseif var_3_3 ~= 1 then
			local var_3_6 = {}
			local var_3_7 = 1

			for iter_3_2 in var_0_5.gmatch(iter_3_0 .. "\t", var_3_5) do
				iter_3_2 = var_0_5.gsub(iter_3_2, "::", "\n")
				var_3_6[var_3_4[var_3_7]] = iter_3_2
				var_3_7 = var_3_7 + 1
			end

			arg_3_1(var_3_6)
		end
	end
end

function var_0_0.parse(arg_4_0, arg_4_1)
	if arg_4_1 == nil then
		return
	end

	if var_0_2[arg_4_0] then
		var_0_0.decryptSaveMemoryUnparsed(arg_4_0, arg_4_1)

		return
	elseif var_0_3[arg_4_0] then
		var_0_0.decryptSaveMemoryParsed(arg_4_0, arg_4_1)

		return
	elseif var_0_1[arg_4_0] then
		var_0_0.decryptParse(arg_4_0, arg_4_1)

		return
	end

	local var_4_0 = "data.tables." .. arg_4_0
	local var_4_1 = require(var_4_0)

	for iter_4_0, iter_4_1 in ipairs(var_4_1.rows) do
		local var_4_2 = {}

		for iter_4_2 = 1, #var_4_1.keys do
			local var_4_3 = iter_4_1[iter_4_2]
			local var_4_4 = var_0_5.gsub(var_4_3, "::", "\n")

			var_4_2[var_4_1.keys[iter_4_2]] = var_4_4
		end

		arg_4_1(var_4_2)
	end

	package.loaded[var_4_0] = nil
end

return var_0_0
