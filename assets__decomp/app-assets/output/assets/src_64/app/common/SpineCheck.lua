local var_0_0 = class("SpineCheck")
local var_0_1 = xyd.tables.model
local var_0_2 = xyd.tables.skill

function var_0_0.get()
	if var_0_0.INSTANCE == nil then
		var_0_0.INSTANCE = var_0_0.new()
	end

	return var_0_0.INSTANCE
end

function var_0_0.check(arg_2_0, arg_2_1)
	print("start check model resource")

	local var_2_0 = "resources/" .. (arg_2_1 or "zh_tw") .. "/"

	for iter_2_0, iter_2_1 in pairs(var_0_1.resources_) do
		local var_2_1, var_2_2 = unpack(iter_2_1)

		if var_2_1 and var_2_1 ~= "" then
			local var_2_3 = cc.FileUtils:getInstance():fullPathForFilename(var_2_0 .. var_2_1)

			if not io.exists(var_2_3) then
				print("json data doesn't exist: " .. var_2_3 .. "    modelID:" .. iter_2_0)
			end
		end

		if var_2_2 and var_2_2 ~= "" then
			local var_2_4 = cc.FileUtils:getInstance():fullPathForFilename(var_2_0 .. var_2_2)

			if not io.exists(var_2_4) then
				print("atlas data doesn't exist: " .. var_2_4 .. "    modelID:" .. iter_2_0)
			end
		end
	end

	local var_2_5 = {
		selfResource = var_0_2.selfResource_,
		areaResource = var_0_2.areaResource_,
		unitResource = var_0_2.unitResource_,
		hurtResource = var_0_2.hurtResource_
	}

	for iter_2_2, iter_2_3 in pairs(var_2_5) do
		print("start check " .. iter_2_2)

		for iter_2_4, iter_2_5 in pairs(iter_2_3) do
			local var_2_6, var_2_7 = unpack(iter_2_5)

			if var_2_6 and var_2_6 ~= "" then
				local var_2_8 = cc.FileUtils:getInstance():fullPathForFilename(var_2_0 .. var_2_6)

				if not io.exists(var_2_8) then
					print("json data doesn't exist: " .. var_2_8 .. "    skillID:" .. iter_2_4)
				end
			end

			if var_2_7 and var_2_7 ~= "" then
				local var_2_9 = cc.FileUtils:getInstance():fullPathForFilename(var_2_0 .. var_2_7)

				if not io.exists(var_2_9) then
					print("atlas data doesn't exist: " .. var_2_9 .. "    skillID:" .. iter_2_4)
				end
			end
		end
	end

	print("check finished")
end

return var_0_0
