local var_0_0 = class("GlobalTimer", import(".BaseModel"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.hero
local var_0_3 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
end

function var_0_0.checkIsMakingChild(arg_3_0)
	if arg_3_0.handle == nil then
		arg_3_0.handle = var_0_1.scheduleGlobal(handler(arg_3_0, arg_3_0.onTimer), 1)
	end
end

function var_0_0.onTimer(arg_4_0)
	local var_4_0 = tonumber(xyd.ServerTime.get():getServerTime())

	if not var_4_0 then
		var_0_1.unscheduleGlobal(arg_4_0.handle)

		arg_4_0.handle = nil

		return
	end

	local var_4_1 = 0
	local var_4_2 = 0

	if arg_4_0.selfPlayer == nil then
		arg_4_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	end

	for iter_4_0, iter_4_1 in pairs(arg_4_0.selfPlayer.collectedPets) do
		if iter_4_1.is_show_ == 0 then
			if var_4_0 < iter_4_1.birthday_ + var_0_2:getHatchTime(iter_4_1:getTableID()) + var_4_1 then
				if iter_4_1.time_ == nil then
					iter_4_1.time_ = iter_4_1.birthday_ + var_0_2:getHatchTime(iter_4_1:getTableID()) + var_4_1 - var_4_0
				end

				iter_4_1.time_ = iter_4_1.time_ - 1
				var_4_2 = var_4_2 + 1
			else
				if xyd.WindowManager.get():getWindow("pet_collect") then
					xyd.EventDispatcher.get():dispatchEvent({
						xyd.event.PETS_UPDATE
					})
				end

				local var_4_3 = xyd.WindowManager.get():getWindow("main_scene_bottom")
				local var_4_4 = xyd.WindowManager.get():getWindow("guide")
				local var_4_5 = xyd.WindowManager.get():getWindow("battle_select_team")

				if var_4_3 and var_4_4 == nil and var_4_5 == nil then
					iter_4_1.is_show_ = 1

					iter_4_1:setShow(function(arg_5_0, arg_5_1)
						return
					end, iter_4_1:getPetID())
					xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, string.format(var_0_3:translation("PET_HAS_MADE_ALERT"), iter_4_1:getName()), function()
						local var_6_0 = 0

						for iter_6_0, iter_6_1 in pairs(arg_4_0.selfPlayer.collectedPets) do
							var_6_0 = var_6_0 + 1

							if iter_6_1:getTableID() == iter_4_1:getTableID() then
								break
							end

							if arg_4_0.selfPlayer.fbShareOpen > 0 then
								xyd.WindowManager.get():openWindow("fb_share", {
									type = xyd.FBShareType.PET,
									heroID = iter_4_1:getTableID()
								})
							end
						end

						xyd.WindowManager.get():openWindow("pet_main", {
							heros = arg_4_0.selfPlayer.collectedPets,
							current = var_6_0,
							scrollx = arg_4_0.scrollx
						})
					end)
				else
					var_4_2 = var_4_2 + 1
				end
			end
		end
	end

	if xyd.WindowManager.get():getWindow("pet_collect") then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.PET_UPDATE_HATCH
		})
	end

	if var_4_2 == 0 and arg_4_0.handle then
		var_0_1.unscheduleGlobal(arg_4_0.handle)

		arg_4_0.handle = nil
	end
end

return var_0_0
