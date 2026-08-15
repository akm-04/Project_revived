local var_0_0 = class("HeroSettingWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = "hero_setting"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.heroID_ = arg_1_2.partner_id
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
end

function var_0_0.didOpen(arg_3_0, arg_3_1)
	var_0_0.super:didOpen(arg_3_1)
	arg_3_0:loadDefenceHeros()
end

function var_0_0.layout(arg_4_0)
	local var_4_0 = arg_4_0:nodeByName("background")

	var_4_0:setContentSize(cc.size(xyd.STAGE_WIDTH, var_4_0:getContentSize().height))

	local var_4_1 = xyd.tables.translation

	arg_4_0:nodeByName("title"):setString(var_4_1:translation("HERO_SETTING"))
	arg_4_0:nodeByName("Label_rep"):setString(var_4_1:translation("SET_REP_HERO"))
	arg_4_0:nodeByName("Label_lock"):setString(var_4_1:translation("SET_LOCK_HERO"))
	arg_4_0:nodeByName("Label_update"):setString(var_4_1:translation("UPDATE"))

	arg_4_0.repCheckBox_ = arg_4_0:nodeByName("CheckBox_rep")
	arg_4_0.lockCheckBox_ = arg_4_0:nodeByName("CheckBox_lock")
	arg_4_0.updateButton_ = arg_4_0:nodeByName("Button_update")

	arg_4_0.updateButton_:setTouchEnabled(false)
end

function var_0_0.loadDefenceHeros(arg_5_0)
	xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):loadBattleFormation(xyd.FormationType.DEFENSE, 4, function(arg_6_0)
		arg_5_0:loadHero()
	end)
end

function var_0_0.loadHero(arg_7_0)
	local var_7_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getHeroByID(arg_7_0.heroID_)

	if var_7_0 == nil then
		return
	end

	arg_7_0:refresh(var_7_0)
end

function var_0_0.refresh(arg_8_0, arg_8_1)
	local var_8_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

	arg_8_0.isRep_ = arg_8_1:isRep()
	arg_8_0.isLock_ = arg_8_1:isLock()

	arg_8_0.repCheckBox_:setSelected(arg_8_0.isRep_ == 1)
	arg_8_0.repCheckBox_:addEventListener(function(arg_9_0, arg_9_1)
		if arg_9_1 == ccui.CheckBoxEventType.selected then
			xyd.playButtonSound()

			arg_8_0.isRep_ = 1
		elseif arg_9_1 == ccui.CheckBoxEventType.unselected then
			arg_8_0.repCheckBox_:setSelected(true)
		end
	end)
	arg_8_0.lockCheckBox_:setSelected(arg_8_0.isLock_ == 1)
	arg_8_0.lockCheckBox_:addEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.CheckBoxEventType.selected then
			xyd.playButtonSound()

			arg_8_0.isLock_ = 1
		elseif arg_10_1 == ccui.CheckBoxEventType.unselected then
			xyd.playButtonSound()

			arg_8_0.isLock_ = 0
		end
	end)
	arg_8_0.updateButton_:setTouchEnabled(true)
	arg_8_0.updateButton_:addTouchEventListener(function(arg_11_0, arg_11_1)
		if arg_11_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_8_0.isRep_ == 1 then
				arg_8_0:setRepHero()
			else
				arg_8_0:setLockHero()
			end
		end
	end)
end

function var_0_0.canDismissHero(arg_12_0)
	local var_12_0
	local var_12_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_12_2 = var_12_1:getHeroByID(arg_12_0.heroID_)

	if var_12_2:isRep() == 1 then
		arg_12_0.alertInfo_ = xyd.AlertInfo.DISMISS_REP_HERO
	elseif var_12_2:isLock() == 1 then
		arg_12_0.alertInfo_ = xyd.AlertInfo.DISMISS_LOCK_HERO
	elseif var_12_1:isDefenceHero(arg_12_0.heroID_) then
		arg_12_0.alertInfo_ = xyd.AlertInfo.DISMISS_DEFENCE_HERO
	else
		var_12_0 = true
	end

	return var_12_0
end

function var_0_0.dismissHero(arg_13_0)
	local var_13_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_13_1 = {
		partner_id = arg_13_0.heroID_
	}

	var_13_0:dismissHero(var_13_1, xyd.backendCallbackWrapper(var_0_1, function(arg_14_0, arg_14_1)
		if arg_14_0 == xyd.error.OK then
			xyd.WindowManager.get():closeWindow(arg_13_0)
		else
			xyd.errorAlert(arg_14_1)
		end
	end))
end

function var_0_0.setRepHero(arg_15_0)
	local var_15_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_15_1 = {
		partner_id = arg_15_0.heroID_
	}

	var_15_0:setRepHero(var_15_1, xyd.backendCallbackWrapper(var_0_1, function(arg_16_0, arg_16_1)
		if arg_16_0 == xyd.error.OK then
			arg_15_0:setLockHero()
		else
			xyd.errorAlert(arg_16_1)
		end
	end))
end

function var_0_0.setLockHero(arg_17_0)
	local var_17_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_17_1 = {
		partner_id = arg_17_0.heroID_,
		is_lock = arg_17_0.isLock_
	}

	var_17_0:setLockHero(var_17_1, xyd.backendCallbackWrapper(var_0_1, function(arg_18_0, arg_18_1)
		if arg_18_0 == xyd.error.OK then
			xyd.WindowManager.get():closeWindow(arg_17_0)
		else
			xyd.errorAlert(arg_18_1)
		end
	end))
end

return var_0_0
