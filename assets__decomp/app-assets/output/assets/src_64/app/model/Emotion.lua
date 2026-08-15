local var_0_0 = class("Emotion", import(".BaseModel"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.emoticon

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.emotionList = {}

	arg_1_0:init()
end

function var_0_0.init(arg_2_0)
	arg_2_0.emotionList = {}

	local var_2_0 = var_0_2:getIds()

	for iter_2_0, iter_2_1 in ipairs(var_2_0) do
		local var_2_1 = {
			id = iter_2_1
		}

		var_2_1.isLock = false

		if var_0_2:itemID(iter_2_1) == 0 then
			table.insert(arg_2_0.emotionList, var_2_1)
		elseif arg_2_0.selfPlayer:getBackpack():getItemNumByID(var_0_2:itemID(iter_2_1)) > 0 then
			table.insert(arg_2_0.emotionList, var_2_1)
		elseif var_0_2:isShow(iter_2_1) > 0 then
			var_2_1.isLock = true

			table.insert(arg_2_0.emotionList, var_2_1)
		end
	end
end

function var_0_0.allCounts(arg_3_0)
	return #arg_3_0.emotionList
end

return var_0_0
