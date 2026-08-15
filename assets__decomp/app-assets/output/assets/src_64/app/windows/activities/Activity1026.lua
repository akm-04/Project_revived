local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = import("app.common.ui.SpineEffect")

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/activities/world_boss.csb")

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))
	var_2_0:setPosition(0, 0)

	local var_2_1 = var_2_0:getChildByName("container"):getChildByName("enter_btn")
	local var_2_2 = "skeletons/ui_effect/world_boss_activity/effect_fengyin"
	local var_2_3 = var_2_2 .. ".json"
	local var_2_4 = var_2_2 .. ".atlas"

	arg_2_0.worldBossEffect = var_0_1.new(var_2_3, var_2_4, 1)

	arg_2_0.worldBossEffect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_2_0.worldBossEffect:setPosition(var_2_1:getWidth() / 2 + 0.5, var_2_1:getHeight() / 2 - 0.5)
	arg_2_0.worldBossEffect:addTo(var_2_1)
	arg_2_0.worldBossEffect:play(nil, true)
	var_2_0:getChildByName("container"):getChildByName("fengyin_bg1"):setVisible(false)
	var_2_0:getChildByName("container"):getChildByName("fengyin_bg"):setVisible(false)
	var_2_1:addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.began then
			if arg_2_0.worldBossEffect then
				var_2_0:getChildByName("container"):getChildByName("fengyin_bg1"):setVisible(true)
				var_2_0:getChildByName("container"):getChildByName("fengyin_bg"):setVisible(true)
				arg_2_0.worldBossEffect:setVisible(false)
			end
		elseif arg_3_1 == ccui.TouchEventType.ended then
			if arg_2_0.worldBossEffect then
				arg_2_0.worldBossEffect:setVisible(true)
			end

			xyd.ModelManager.get():loadModel(xyd.ModelType.WORLD_BOSS):loadWorldBoss(function(arg_4_0, arg_4_1)
				if arg_4_0 == xyd.error.OK then
					xyd.playButtonSound()
					var_2_0:getChildByName("container"):getChildByName("fengyin_bg1"):setVisible(false)
					var_2_0:getChildByName("container"):getChildByName("fengyin_bg"):setVisible(false)
					xyd.WindowManager.get():closeWindow(arg_2_0)
					xyd.WindowManager.get():openWindow("world_boss", {
						fromMain = false
					})
				end
			end, true)
		elseif arg_3_1 == 3 then
			var_2_0:getChildByName("container"):getChildByName("fengyin_bg1"):setVisible(false)
			var_2_0:getChildByName("container"):getChildByName("fengyin_bg"):setVisible(false)
			arg_2_0.worldBossEffect:setVisible(true)
		end
	end)
end

return var_0_0
