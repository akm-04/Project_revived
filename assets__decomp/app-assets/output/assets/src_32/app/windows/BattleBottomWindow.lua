local var_0_0 = class("BattleBottomWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = 25
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = {
	{
		50,
		10
	},
	{
		34,
		16,
		66,
		16
	},
	{
		50,
		10,
		18,
		24,
		82,
		24
	},
	{
		38,
		12,
		62,
		12,
		18,
		24,
		82,
		24
	},
	{
		50,
		10,
		34,
		16,
		66,
		16,
		18,
		24,
		82,
		24
	}
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.heros = arg_1_2.heros
	arg_1_0.pets = arg_1_2.pets or {}
	arg_1_0.optionHeros = arg_1_2.optionHeros or {}
	arg_1_0.isUnlimit = arg_1_2.isUnlimit or false
	arg_1_0.isAwakeSecond = arg_1_2.isAwakeSecond or false
	arg_1_0.heroCs_ = {}
end

function var_0_0.didOpen(arg_2_0, arg_2_1)
	arg_2_0.super.didOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:updateAvatar()
	arg_2_0:setUIEffect()
	arg_2_0:setTouchSwallowEnabled(false)
end

function var_0_0.willClose(arg_3_0, arg_3_1)
	for iter_3_0, iter_3_1 in pairs(arg_3_0.guideHands_ or {}) do
		if iter_3_1 then
			transition.stopTarget(iter_3_1)
		end
	end

	for iter_3_2, iter_3_3 in pairs(arg_3_0.guideManuals_ or {}) do
		if iter_3_3 then
			transition.stopTarget(iter_3_3)
		end
	end

	if arg_3_0.guideTalk_ then
		transition.stopTarget(arg_3_0.guideTalk_)
	end

	audio.setSoundsVolume(xyd.db.settings:getSoundEffect())
end

function var_0_0.layout(arg_4_0)
	arg_4_0:getUnlimitContainer():hide()
	arg_4_0:nextBattleBtn():hide()
	arg_4_0:nodeByName("medicine"):hide()

	local var_4_0 = #arg_4_0.heros
	local var_4_1 = var_4_0 == 5 and 142 or 182
	local var_4_2 = arg_4_0:nodeByName("hero_pos"):getX()
	local var_4_3 = arg_4_0:nodeByName("hero_pos"):getY()

	if arg_4_0.isUnlimit then
		var_4_2 = var_4_2 + 150
		var_4_1 = 142
	end

	arg_4_0.batchNode = display.newBatchNode("images/battle/battle_sheet1.png")

	arg_4_0.batchNode:size(arg_4_0:getContentSize())
	arg_4_0.batchNode:align(display.LEFT_BOTTOM, 0, 0)
	arg_4_0.batchNode:addTo(arg_4_0, 0)

	arg_4_0.spBarBacks1_ = {}
	arg_4_0.spBarBacks2_ = {}
	arg_4_0.avatars_ = {}
	arg_4_0.avatarBacks_ = {}
	arg_4_0.avatarBuffIcons_ = {}
	arg_4_0.positions_ = {}
	arg_4_0.batchNodeTop = display.newBatchNode("images/battle/battle_sheet1.png")

	arg_4_0.batchNodeTop:size(arg_4_0:getContentSize())
	arg_4_0.batchNodeTop:align(display.LEFT_BOTTOM, 0, 0)
	arg_4_0.batchNodeTop:addTo(arg_4_0, 3)

	arg_4_0.spRedBars_ = {}
	arg_4_0.spHpIcons_ = {}
	arg_4_0.spMpIcons_ = {}
	arg_4_0.iconNode_ = display.newNode()

	arg_4_0.iconNode_:size(arg_4_0:getContentSize())
	arg_4_0.iconNode_:align(display.LEFT_BOTTOM, 0, 0)
	arg_4_0.iconNode_:addTo(arg_4_0, 2)

	local var_4_4 = (1 + var_4_0) / 2

	for iter_4_0 = 1, var_4_0 do
		arg_4_0.positions_[iter_4_0] = {
			x = var_4_2 + (var_4_4 - iter_4_0) * var_4_1,
			y = var_4_3
		}
		arg_4_0.spBarBacks1_[iter_4_0] = xyd.AssetLoader.get():loadSprite("images/battle/bar_bg.png")

		arg_4_0.spBarBacks1_[iter_4_0]:width(112)
		arg_4_0.spBarBacks1_[iter_4_0]:align(display.CENTER, arg_4_0.positions_[iter_4_0].x, arg_4_0.positions_[iter_4_0].y + 8)
		arg_4_0.batchNode:addChild(arg_4_0.spBarBacks1_[iter_4_0])

		arg_4_0.spBarBacks2_[iter_4_0] = xyd.AssetLoader.get():loadSprite("images/battle/bar_bg.png")

		arg_4_0.spBarBacks2_[iter_4_0]:width(112)
		arg_4_0.spBarBacks2_[iter_4_0]:align(display.CENTER, arg_4_0.positions_[iter_4_0].x, arg_4_0.positions_[iter_4_0].y + 30)
		arg_4_0.batchNode:addChild(arg_4_0.spBarBacks2_[iter_4_0])

		arg_4_0.spRedBars_[iter_4_0] = xyd.AssetLoader.get():loadSprite("images/battle/sp_full_bar.png")

		arg_4_0.spRedBars_[iter_4_0]:align(display.CENTER, arg_4_0.positions_[iter_4_0].x, arg_4_0.positions_[iter_4_0].y + 8)
		arg_4_0.batchNodeTop:addChild(arg_4_0.spRedBars_[iter_4_0])

		arg_4_0.spHpIcons_[iter_4_0] = xyd.AssetLoader.get():loadSprite("images/battle/img_hp.png")

		arg_4_0.spHpIcons_[iter_4_0]:align(display.CENTER, arg_4_0.positions_[iter_4_0].x - 32, arg_4_0.positions_[iter_4_0].y + 36)
		arg_4_0.batchNodeTop:addChild(arg_4_0.spHpIcons_[iter_4_0])

		arg_4_0.spMpIcons_[iter_4_0] = xyd.AssetLoader.get():loadSprite("images/battle/img_sp.png")

		arg_4_0.spMpIcons_[iter_4_0]:align(display.CENTER, arg_4_0.positions_[iter_4_0].x - 32, arg_4_0.positions_[iter_4_0].y + 13)
		arg_4_0.batchNodeTop:addChild(arg_4_0.spMpIcons_[iter_4_0])

		arg_4_0.avatarBuffIcons_[iter_4_0] = {}

		arg_4_0:loadAvatarBuffIcons(iter_4_0)
	end

	for iter_4_1, iter_4_2 in ipairs(arg_4_0.pets) do
		arg_4_0.petPos_ = {
			x = arg_4_0:nodeByName("pet_pos"):getX(),
			y = arg_4_0:nodeByName("pet_pos"):getY()
		}
		arg_4_0.petBack_ = xyd.AssetLoader.get():loadSprite("images/battle/pet_back.png")

		arg_4_0.petBack_:align(display.LEFT_BOTTOM, arg_4_0.petPos_.x, arg_4_0.petPos_.y)
		arg_4_0.batchNode:addChild(arg_4_0.petBack_)
	end

	if xyd.db.settings:getBackgroudMusicOn() == 1 then
		if xyd.db.settings:getBattleMusicOn() == 1 then
			audio.resumeMusic()
		else
			audio.pauseMusic()
		end
	end

	if xyd.db.settings:getSoundEffect() == 1 then
		audio.setSoundsVolume(xyd.db.settings:getBattleSoundOn())
	end

	arg_4_0:nodeByName("txt_auto"):setString(xyd.tables.translation:translation("AUTO_TXT"))
end

function var_0_0.loadAvatarBuffIcons(arg_5_0, arg_5_1)
	local var_5_0 = 32

	for iter_5_0 = 1, var_5_0 do
		arg_5_0.avatarBuffIcons_[arg_5_1][iter_5_0] = xyd.AssetLoader.get():loadSprite("images/battle/buff_icon_" .. iter_5_0 .. ".png")

		arg_5_0.avatarBuffIcons_[arg_5_1][iter_5_0]:width(24)

		if iter_5_0 % 4 == 1 then
			arg_5_0.avatarBuffIcons_[arg_5_1][iter_5_0]:align(display.CENTER, arg_5_0.positions_[arg_5_1].x - 42, arg_5_0.positions_[arg_5_1].y + 172)
		elseif iter_5_0 % 4 == 2 then
			arg_5_0.avatarBuffIcons_[arg_5_1][iter_5_0]:align(display.CENTER, arg_5_0.positions_[arg_5_1].x - 14, arg_5_0.positions_[arg_5_1].y + 172)
		elseif iter_5_0 % 4 == 3 then
			arg_5_0.avatarBuffIcons_[arg_5_1][iter_5_0]:align(display.CENTER, arg_5_0.positions_[arg_5_1].x + 14, arg_5_0.positions_[arg_5_1].y + 172)
		elseif iter_5_0 % 4 == 0 then
			arg_5_0.avatarBuffIcons_[arg_5_1][iter_5_0]:align(display.CENTER, arg_5_0.positions_[arg_5_1].x + 42, arg_5_0.positions_[arg_5_1].y + 172)
		end

		arg_5_0.batchNode:addChild(arg_5_0.avatarBuffIcons_[arg_5_1][iter_5_0])
		arg_5_0.avatarBuffIcons_[arg_5_1][iter_5_0]:hide()
	end
end

function var_0_0.getContainerByIndex(arg_6_0, arg_6_1)
	return arg_6_0:nodeByName("click_node" .. arg_6_1)
end

function var_0_0.getButtonByIndex(arg_7_0, arg_7_1)
	return (arg_7_0:getContainerByIndex(arg_7_1))
end

function var_0_0.getMpBarByIndex(arg_8_0, arg_8_1)
	return arg_8_0.mpProgress_[arg_8_1]
end

function var_0_0.getHpBarByIndex(arg_9_0, arg_9_1)
	return arg_9_0.hpProgress_[arg_9_1]
end

function var_0_0.getLockIcon(arg_10_0)
	return arg_10_0:nodeByName("lock")
end

function var_0_0.getAvatarBorderByIndex(arg_11_0, arg_11_1)
	return
end

function var_0_0.getPetMPBar(arg_12_0)
	return arg_12_0.petMPProgress_
end

function var_0_0.getPetAvatar(arg_13_0)
	return arg_13_0:nodeByName("click_node_pet")
end

function var_0_0.setSpTouchSwalled(arg_14_0, arg_14_1)
	for iter_14_0, iter_14_1 in pairs(arg_14_0.heros) do
		arg_14_0:getContainerByIndex(iter_14_0):setSwallowTouches(arg_14_1)
	end
end

function var_0_0.updateAvatar(arg_15_0)
	if not arg_15_0.isUnlimit then
		for iter_15_0 = 1, #arg_15_0.heros do
			local var_15_0 = arg_15_0.heros[iter_15_0]
			local var_15_1 = arg_15_0.positions_[iter_15_0].x
			local var_15_2 = arg_15_0.positions_[iter_15_0].y

			arg_15_0:setAvatarBorder(var_15_0, var_15_1, var_15_2, iter_15_0)
			arg_15_0:setHPProgress(0, iter_15_0, false)
			arg_15_0:setMPProgress(0, iter_15_0, false)
		end

		for iter_15_1 = 1, #arg_15_0.pets do
			local var_15_3 = arg_15_0.pets[iter_15_1]
			local var_15_4 = arg_15_0.petPos_.x + 23
			local var_15_5 = arg_15_0.petPos_.y + 23

			arg_15_0:setPetAvatarBorder(var_15_3, var_15_4, var_15_5)
			arg_15_0:setPetMPProgress(0, false)
		end
	elseif not arg_15_0.isAwakeSecond then
		local var_15_6, var_15_7 = arg_15_0:nodeByName("left_hero_node"):getPosition()
		local var_15_8, var_15_9 = arg_15_0:nodeByName("right_hero_node"):getPosition()
		local var_15_10 = (var_15_8 - var_15_6) / 4

		for iter_15_2 = 1, #arg_15_0.heros do
			local var_15_11 = arg_15_0.heros[iter_15_2]
			local var_15_12 = var_15_6 + var_15_10 * (#arg_15_0.heros - iter_15_2)
			local var_15_13 = var_15_7

			arg_15_0:setUnlimitAvatar(var_15_11, var_15_12, var_15_13, iter_15_2)
		end

		for iter_15_3 = 1, 2 do
			if arg_15_0.optionHeros[iter_15_3] then
				local var_15_14 = cc.Node:create()
				local var_15_15 = arg_15_0.optionHeros[iter_15_3]
				local var_15_16 = var_15_15:getTableID()
				local var_15_17 = var_15_15:getColor()
				local var_15_18 = var_15_15:getStar()
				local var_15_19, var_15_20 = arg_15_0:nodeByName("option_hero" .. iter_15_3):getPosition()

				var_15_14:setContentSize(90, 90)
				xyd.setAvatarBorder(var_15_16, var_15_14, var_15_17, var_15_18)
				arg_15_0:addChild(var_15_14)
				var_15_14:align(display.LEFT_BOTTOM, var_15_19, var_15_20)
				var_15_14:setName("option_icon" .. iter_15_3)
			end
		end
	end
end

function var_0_0.setAvatarBorder(arg_16_0, arg_16_1, arg_16_2, arg_16_3, arg_16_4, arg_16_5)
	local var_16_0 = display.newNode()

	var_16_0:size(108, 108)
	var_16_0:setAnchorPoint(0.5, 0.5)
	var_16_0:pos(arg_16_2, arg_16_3 + 100)
	xyd.setAvatarBorderNewUI(arg_16_1, var_16_0)
	arg_16_0.iconNode_:addChild(var_16_0)
	var_16_0:setName("click_node" .. arg_16_4)

	arg_16_0.children_["click_node" .. arg_16_4] = var_16_0
end

function var_0_0.removeIcon(arg_17_0, arg_17_1)
	arg_17_0:nodeByName("defence_bottom_bg2"):removeChildByName("click_node" .. arg_17_1)
end

function var_0_0.hideBar(arg_18_0, arg_18_1)
	arg_18_0.spBarBacks1_[arg_18_1]:hide()
	arg_18_0.spBarBacks2_[arg_18_1]:hide()
	arg_18_0.spRedBars_[arg_18_1]:hide()
	arg_18_0.spHpIcons_[arg_18_1]:hide()
	arg_18_0.spMpIcons_[arg_18_1]:hide()

	for iter_18_0 = 1, 32 do
		arg_18_0.avatarBuffIcons_[arg_18_1][iter_18_0]:hide()
	end
end

function var_0_0.setPetAvatarBorder(arg_19_0, arg_19_1, arg_19_2, arg_19_3)
	local function var_19_0()
		local var_20_0 = "images/battle/star_small2.png"

		return xyd.AssetLoader.get():loadSprite(var_20_0)
	end

	local var_19_1 = arg_19_1:getAvatar(2)
	local var_19_2 = arg_19_1:getColor()
	local var_19_3 = arg_19_1:getStar()
	local var_19_4

	if arg_19_1:isAwaken() then
		var_19_4 = xyd.AssetLoader.get():loadSprite("images/battle/b_pet_awake_avatar_border_" .. var_19_2 .. ".png")
	else
		var_19_4 = xyd.AssetLoader.get():loadSprite("images/battle/b_pet_avatar_border_" .. var_19_2 .. ".png")
	end

	arg_19_0.batchNode:addChild(var_19_4)
	var_19_4:align(display.LEFT_BOTTOM, arg_19_2, arg_19_3)

	arg_19_0.petSpRedBar_ = xyd.AssetLoader.get():loadSprite("images/battle/pet_sp_full.png")

	arg_19_0.petSpRedBar_:addTo(arg_19_0.iconNode_, -1)
	arg_19_0.petSpRedBar_:align(display.CENTER, arg_19_2 + 50, arg_19_3 + 50)

	local var_19_5 = xyd.AssetLoader.get():loadSprite("images/battle/pet_top.png")

	arg_19_0.batchNode:addChild(var_19_5)
	var_19_5:align(display.CENTER, arg_19_2 + 50, arg_19_3 + 50)

	local var_19_6 = xyd.AssetLoader.get():loadSprite("images/battle/img_sp.png")

	arg_19_0.batchNodeTop:addChild(var_19_6)
	var_19_6:align(display.CENTER, arg_19_2 + 50, arg_19_3 + 105)

	local var_19_7 = xyd.AssetLoader.get():loadSprite(var_19_1)

	arg_19_0.iconNode_:addChild(var_19_7)
	var_19_7:align(display.CENTER_BOTTOM, arg_19_2 + 50, arg_19_3)

	if var_19_3 and var_19_3 > 0 then
		local var_19_8 = var_19_0():getWidth()
		local var_19_9 = var_0_3[var_19_3]

		for iter_19_0 = 1, var_19_3 do
			local var_19_10 = var_19_0()

			arg_19_0.batchNodeTop:addChild(var_19_10)
			var_19_10:align(display.CENTER, var_19_9[2 * iter_19_0 - 1] + arg_19_2, var_19_9[2 * iter_19_0] + arg_19_3)
		end
	end

	var_19_7:setName("click_node_pet")

	arg_19_0.children_.click_node_pet = var_19_7
end

function var_0_0.getAvatarByIndex(arg_21_0, arg_21_1)
	return (arg_21_0:getContainerByIndex(arg_21_1))
end

function var_0_0.getAutoBtn(arg_22_0)
	if not arg_22_0.autoBtn_ then
		arg_22_0.autoBtn_ = arg_22_0:nodeByName("btn_auto")
	end

	return arg_22_0.autoBtn_
end

function var_0_0.getSpeedBtn(arg_23_0)
	if not arg_23_0.speedBtn_ then
		arg_23_0.speedBtn_ = arg_23_0:nodeByName("btn_speed")
	end

	return arg_23_0.speedBtn_
end

function var_0_0.setUIEffect(arg_24_0)
	if arg_24_0.isUnlimit then
		return
	end

	arg_24_0.avatarUIEffects3_ = {}

	local var_24_0 = "skeletons/ui_effect/common_effect_battle/common_effect_battle6"
	local var_24_1 = var_24_0 .. ".json"
	local var_24_2 = var_24_0 .. ".atlas"

	for iter_24_0, iter_24_1 in ipairs(arg_24_0.heros) do
		local var_24_3 = arg_24_0.spBarBacks2_[iter_24_0]
		local var_24_4 = var_0_2.new(var_24_1, var_24_2, 1)

		var_24_4:addTo(arg_24_0)
		var_24_4:align(display.CENTER, var_24_3:getX(), var_24_3:getY())
		var_24_4:setTouchSwallowEnabled(false)
		var_24_4:setVisible(false)
		table.insert(arg_24_0.avatarUIEffects3_, var_24_4)
	end

	arg_24_0.avatarUIEffects1_ = {}

	local var_24_5 = "skeletons/ui_effect/common_effect_battle/common_effect_battle7"
	local var_24_6 = var_24_5 .. ".json"
	local var_24_7 = var_24_5 .. ".atlas"

	for iter_24_2, iter_24_3 in ipairs(arg_24_0.heros) do
		local var_24_8 = arg_24_0:nodeByName("click_node" .. iter_24_2)
		local var_24_9 = var_0_2.new(var_24_6, var_24_7, 1)

		var_24_9:addTo(arg_24_0, 3)
		var_24_9:align(display.CENTER, var_24_8:getX(), var_24_8:getY())
		var_24_9:setTouchSwallowEnabled(false)
		var_24_9:setVisible(false)
		table.insert(arg_24_0.avatarUIEffects1_, var_24_9)
	end

	arg_24_0.avatarUIEffects2_ = {}

	local var_24_10 = "skeletons/ui_effect/common_effect_battle/common_effect_battle5"
	local var_24_11 = var_24_10 .. ".json"
	local var_24_12 = var_24_10 .. ".atlas"

	for iter_24_4, iter_24_5 in ipairs(arg_24_0.heros) do
		local var_24_13 = arg_24_0:nodeByName("click_node" .. iter_24_4)
		local var_24_14 = var_0_2.new(var_24_11, var_24_12, 1)

		var_24_14:addTo(arg_24_0)
		var_24_14:align(display.CENTER, var_24_13:getX(), var_24_13:getY())
		var_24_14:setTouchSwallowEnabled(false)
		var_24_14:setVisible(false)
		table.insert(arg_24_0.avatarUIEffects2_, var_24_14)
	end

	arg_24_0.avatarUIEffects4_ = {}

	local var_24_15 = "skeletons/ui_effect/effect_pet_battle/effect_pet_battle1"
	local var_24_16 = var_24_15 .. ".json"
	local var_24_17 = var_24_15 .. ".atlas"

	for iter_24_6, iter_24_7 in ipairs(arg_24_0.pets) do
		local var_24_18 = arg_24_0.petSpRedBar_
		local var_24_19 = var_0_2.new(var_24_16, var_24_17, 1)

		var_24_19:addTo(arg_24_0)
		var_24_19:align(display.CENTER, var_24_18:getX(), var_24_18:getY())
		var_24_19:setTouchSwallowEnabled(false)
		var_24_19:setVisible(false)
		table.insert(arg_24_0.avatarUIEffects4_, var_24_19)
	end

	arg_24_0.avatarUIEffects5_ = {}

	local var_24_20 = "skeletons/ui_effect/effect_pet_battle/effect_pet_battle2"
	local var_24_21 = var_24_20 .. ".json"
	local var_24_22 = var_24_20 .. ".atlas"

	for iter_24_8, iter_24_9 in ipairs(arg_24_0.pets) do
		local var_24_23 = arg_24_0.petSpRedBar_
		local var_24_24 = var_0_2.new(var_24_21, var_24_22, 1)

		var_24_24:addTo(arg_24_0)
		var_24_24:align(display.CENTER, var_24_23:getX(), var_24_23:getY())
		var_24_24:setTouchSwallowEnabled(false)
		var_24_24:setVisible(false)
		table.insert(arg_24_0.avatarUIEffects5_, var_24_24)
	end
end

function var_0_0.getUnlimitBorder(arg_25_0)
	local var_25_0 = arg_25_0:nodeByName("left_limit"):getX()
	local var_25_1 = arg_25_0:nodeByName("right_limit"):getX()
	local var_25_2 = arg_25_0:nodeByName("left_limit"):getY()
	local var_25_3 = arg_25_0:nodeByName("up_limit"):getY()

	return var_25_0, var_25_1, var_25_2, var_25_3
end

function var_0_0.updateUIEffect(arg_26_0, arg_26_1, arg_26_2, arg_26_3)
	if not arg_26_1 or arg_26_0.isUnlimit then
		return
	end

	local var_26_0 = table.keyof(arg_26_2, arg_26_1)

	if not var_26_0 then
		return
	end

	local var_26_1

	if arg_26_0.pets[1] and arg_26_1.hero_ == arg_26_0.pets[1] then
		var_26_1 = arg_26_0.avatarUIEffects4_[1]
	elseif var_26_0 <= #arg_26_0.heros then
		var_26_1 = arg_26_0.avatarUIEffects1_[var_26_0]
	else
		return
	end

	if arg_26_3 and not var_26_1:isVisible() then
		var_26_1:play(nil, true)
	end

	if not arg_26_3 and var_26_1:isVisible() then
		var_26_1:stop()
	end

	var_26_1:setVisible(arg_26_3)
end

function var_0_0.setXuliSkillEffect(arg_27_0, arg_27_1, arg_27_2, arg_27_3)
	if not arg_27_1 or arg_27_0.isUnlimit then
		return
	end

	local var_27_0 = table.keyof(arg_27_2, arg_27_1)

	if not var_27_0 or var_27_0 > #arg_27_0.heros then
		return
	end

	arg_27_0.xuliUIEffects_ = arg_27_0.xuliUIEffects_ or {}

	local var_27_1 = arg_27_0.xuliUIEffects_[var_27_0]

	if arg_27_3 then
		if var_27_1 then
			var_27_1:show()
			var_27_1:play(nil, true)
		else
			local var_27_2 = "skeletons/ui_effect/common_effect_battle/common_effect_battle9"
			local var_27_3 = var_27_2 .. ".json"
			local var_27_4 = var_27_2 .. ".atlas"
			local var_27_5 = arg_27_0:nodeByName("click_node" .. var_27_0)
			local var_27_6 = var_0_2.new(var_27_3, var_27_4, 1)

			var_27_6:addTo(arg_27_0)
			var_27_6:align(display.CENTER, var_27_5:getX(), var_27_5:getY())
			var_27_6:setTouchSwallowEnabled(false)
			var_27_6:show()
			var_27_6:play(nil, true)

			arg_27_0.xuliUIEffects_[var_27_0] = var_27_6
		end
	elseif var_27_1 then
		var_27_1:hide()
		var_27_1:stop()
	end
end

function var_0_0.energySkillEffect(arg_28_0, arg_28_1, arg_28_2)
	if not arg_28_1 or arg_28_0.isUnlimit then
		return
	end

	local var_28_0 = table.keyof(arg_28_2, arg_28_1)

	if not var_28_0 then
		return
	end

	local var_28_1

	if arg_28_0.pets[1] and arg_28_1.hero_ == arg_28_0.pets[1] then
		var_28_1 = arg_28_0.avatarUIEffects5_[1]
	elseif var_28_0 <= #arg_28_0.heros then
		var_28_1 = arg_28_0.avatarUIEffects2_[var_28_0]
	else
		return
	end

	var_28_1:show()
	var_28_1:play(function()
		var_28_1:hide()
	end, false)
end

function var_0_0.hpRedEffect(arg_30_0, arg_30_1, arg_30_2)
	local var_30_0 = arg_30_0.avatarUIEffects3_[arg_30_1]

	if arg_30_2 and not var_30_0:isVisible() then
		var_30_0:play(nil, true)
	end

	if not arg_30_2 and var_30_0:isVisible() then
		var_30_0:stop()
	end

	var_30_0:setVisible(arg_30_2)
end

function var_0_0.nextBattleBtn(arg_31_0)
	if not arg_31_0.nextBattleBtn_ then
		arg_31_0.nextBattleBtn_ = arg_31_0:nodeByName("button_next_battle")
	end

	return arg_31_0.nextBattleBtn_
end

function var_0_0.playNextBattle(arg_32_0)
	arg_32_0:nextBattleBtn():show()

	if not arg_32_0.action_ then
		local var_32_0 = cc.MoveBy:create(1, cc.p(30, 0))
		local var_32_1 = cc.Sequence:create(var_32_0, var_32_0:reverse())

		arg_32_0.action_ = cc.RepeatForever:create(var_32_1)

		arg_32_0:nextBattleBtn():runAction(arg_32_0.action_)
	end

	transition.resumeTarget(arg_32_0:nextBattleBtn())
end

function var_0_0.stopNextBattle(arg_33_0)
	arg_33_0:nextBattleBtn():hide()
	transition.pauseTarget(arg_33_0:nextBattleBtn())
end

function var_0_0.getGuideHand(arg_34_0, arg_34_1)
	if not arg_34_0.guideHands_ then
		arg_34_0.guideHands_ = {}
	end

	if arg_34_0.guideHands_[arg_34_1] then
		return arg_34_0.guideHands_[arg_34_1]
	end

	local var_34_0 = "skeletons/ui_effect/common_effect_guide1/common_effect_guide1"
	local var_34_1 = arg_34_0:getContainerByIndex(arg_34_1):getX()
	local var_34_2 = arg_34_0:getContainerByIndex(arg_34_1):getY()

	arg_34_0.guideHands_[arg_34_1] = var_0_2.new(var_34_0 .. ".json", var_34_0 .. ".atlas")

	arg_34_0.guideHands_[arg_34_1]:play(nil, true)
	arg_34_0.guideHands_[arg_34_1]:addTo(arg_34_0, 5)
	arg_34_0.guideHands_[arg_34_1]:pos(var_34_1, var_34_2)

	arg_34_0.guideHands_[arg_34_1].initPos = {
		var_34_1,
		var_34_2
	}

	return arg_34_0.guideHands_[arg_34_1]
end

function var_0_0.showGuideNext(arg_35_0, arg_35_1)
	if not arg_35_0.guideNext_ and arg_35_1 then
		arg_35_0.guideNext_ = import("app.windows.GuideHand").new()

		arg_35_0.guideNext_:addTo(arg_35_0, 100)
		arg_35_0.guideNext_:pos(arg_35_0:nextBattleBtn():getPosition())
	end

	if arg_35_0.guideNext_ and arg_35_1 then
		arg_35_0.guideNext_:show()
	elseif arg_35_0.guideNext_ then
		arg_35_0.guideNext_:hide()
	end

	arg_35_0:showNextTalk(arg_35_1)
end

function var_0_0.showNextTalk(arg_36_0, arg_36_1)
	if not arg_36_0.nextTalk_ and arg_36_1 then
		arg_36_0.nextTalk_ = import("app.windows.GuideTalk").new(true)

		arg_36_0.nextTalk_:setString(xyd.tables.translation:translation("PLAY_NEXT_BATTLE_GUIDE"))
		arg_36_0.nextTalk_:addTo(arg_36_0, -1)
		arg_36_0.nextTalk_:pos(0, 0)
	end

	if arg_36_0.nextTalk_ and arg_36_1 then
		arg_36_0.nextTalk_:show()
	elseif arg_36_0.nextTalk_ then
		arg_36_0.nextTalk_:hide()
	end
end

function var_0_0.showGuideTalk(arg_37_0, arg_37_1, arg_37_2)
	if not arg_37_0.talkStack_ then
		arg_37_0.talkStack_ = {}
	end

	arg_37_0.talkStack_[arg_37_2] = arg_37_1

	local var_37_0 = false

	for iter_37_0 = 1, #arg_37_0.heros do
		var_37_0 = var_37_0 or arg_37_0.talkStack_[iter_37_0]
	end

	if arg_37_0.guideTalk_ then
		arg_37_0.guideTalk_:setVisible(var_37_0)
	elseif not arg_37_0.guideTalk_ and var_37_0 then
		arg_37_0.guideTalk_ = import("app.windows.GuideTalk").new(true)

		arg_37_0.guideTalk_:addTo(arg_37_0, -1)
		arg_37_0.guideTalk_:pos(0, 0)
		arg_37_0.guideTalk_:setString(xyd.tables.translation:translation("USE_SKILL_GUIDE"))
	end
end

function var_0_0.storyGuideTalk(arg_38_0, arg_38_1, arg_38_2, arg_38_3)
	if not arg_38_1 and arg_38_0.guideTalk_ then
		arg_38_0.guideTalk_:hide()

		return
	end

	if arg_38_0.guideTalk_ then
		arg_38_0.guideTalk_:show()

		if arg_38_3 == 1 then
			arg_38_0.guideTalk_:setString(xyd.tables.translation:translation("USE_SKILL_GUIDE"))
		else
			arg_38_0.guideTalk_:setString(xyd.tables.translation:translation("USE_SKILL_GUIDE2"))
		end

		return
	end

	arg_38_0.guideTalk_ = import("app.windows.GuideTalk").new(true)

	arg_38_0.guideTalk_:addTo(arg_38_0, -1)
	arg_38_0.guideTalk_:pos(0, 0)

	if arg_38_3 == 1 then
		arg_38_0.guideTalk_:setString(xyd.tables.translation:translation("USE_SKILL_GUIDE"))
	else
		arg_38_0.guideTalk_:setString(xyd.tables.translation:translation("USE_SKILL_GUIDE2"))
	end
end

function var_0_0.storyGuideHandk(arg_39_0, arg_39_1, arg_39_2)
	if not arg_39_0.storyHands_ then
		arg_39_0.storyHands_ = {}
	end

	if not arg_39_1 then
		for iter_39_0, iter_39_1 in pairs(arg_39_0.storyHands_) do
			if arg_39_0.storyHands_[iter_39_0] then
				arg_39_0.storyHands_[iter_39_0]:hide()
			end
		end

		return
	end

	if arg_39_0.storyHands_[arg_39_2] then
		arg_39_0.storyHands_[arg_39_2]:show()

		return
	end

	arg_39_0.storyHands_[arg_39_2] = import("app.windows.GuideHand").new()

	arg_39_0.storyHands_[arg_39_2]:addTo(arg_39_0, 100)
	arg_39_0.storyHands_[arg_39_2]:pos(arg_39_0:getContainerByIndex(arg_39_2):getX(), arg_39_0:getContainerByIndex(arg_39_2):getY())
end

function var_0_0.storyManualHand(arg_40_0, arg_40_1, arg_40_2, arg_40_3)
	if not arg_40_0.guideHands_ then
		arg_40_0.guideHands_ = {}
	end

	if not arg_40_2 then
		for iter_40_0, iter_40_1 in pairs(arg_40_0.guideHands_) do
			if arg_40_0.guideHands_[iter_40_0] then
				arg_40_0.guideHands_[iter_40_0]:hide()
				transition.stopTarget(arg_40_0.guideHands_[iter_40_0])
			end
		end

		return
	end

	if arg_40_0.guideHands_[arg_40_1] then
		arg_40_0.guideHands_[arg_40_1]:show()

		return
	end

	local var_40_0 = "skeletons/ui_effect/common_effect_guide1/common_effect_guide1"
	local var_40_1 = arg_40_0:getContainerByIndex(arg_40_1):getX()
	local var_40_2 = arg_40_0:getContainerByIndex(arg_40_1):getY()

	arg_40_0.guideHands_[arg_40_1] = var_0_2.new(var_40_0 .. ".json", var_40_0 .. ".atlas")

	arg_40_0.guideHands_[arg_40_1]:play(nil, false)
	arg_40_0.guideHands_[arg_40_1]:addTo(arg_40_0, 101)
	arg_40_0.guideHands_[arg_40_1]:pos(var_40_1, var_40_2)

	local var_40_3 = cc.Sequence:create(cc.MoveTo:create(1.5, cc.p(arg_40_3.x, arg_40_3.y)), cc.CallFunc:create(function()
		arg_40_0.guideHands_[arg_40_1]:pos(var_40_1, var_40_2)
	end), cc.MoveTo:create(1.5, cc.p(arg_40_3.x, arg_40_3.y)), cc.CallFunc:create(function()
		arg_40_0.guideHands_[arg_40_1]:pos(var_40_1, var_40_2)
	end))
	local var_40_4 = cc.RepeatForever:create(var_40_3)

	arg_40_0.guideHands_[arg_40_1]:runAction(var_40_4)
end

function var_0_0.storyGuideManual(arg_43_0, arg_43_1, arg_43_2, arg_43_3, arg_43_4)
	if not arg_43_0.guideManuals_ then
		arg_43_0.guideManuals_ = {}
		arg_43_0.guideTargets_ = {}
	end

	if arg_43_0.guideManuals_[arg_43_1] and tolua.isnull(arg_43_0.guideManuals_[arg_43_1]) then
		arg_43_0.guideManuals_[arg_43_1] = nil
	end

	if not arg_43_2 then
		for iter_43_0, iter_43_1 in pairs(arg_43_0.guideManuals_) do
			if arg_43_0.guideManuals_[iter_43_0] then
				arg_43_0.guideManuals_[iter_43_0]:hide()
				arg_43_0.guideTargets_[iter_43_0]:removeTargetCircle(iter_43_0)
			end
		end

		return
	end

	if arg_43_0.guideManuals_[arg_43_1] then
		arg_43_0.guideManuals_[arg_43_1]:show()
		arg_43_0.guideTargets_[arg_43_1]:playTargetCircle(arg_43_1)

		return
	end

	arg_43_3:playTargetCircle(arg_43_1)

	arg_43_0.guideTargets_[arg_43_1] = arg_43_3
	arg_43_0.guideManuals_[arg_43_1] = xyd.AssetLoader.get():loadSprite("images/battle_manual_1_1.png")

	arg_43_0.guideManuals_[arg_43_1]:opacity(180)

	local var_43_0 = arg_43_0:getContainerByIndex(arg_43_1):getX()
	local var_43_1 = arg_43_0:getContainerByIndex(arg_43_1):getY()
	local var_43_2 = math.atan2(arg_43_3:getY() - var_43_1, arg_43_3:getX() - var_43_0) / math.pi * -180
	local var_43_3 = math.sqrt((arg_43_3:getY() - var_43_1) * (arg_43_3:getY() - var_43_1) + (arg_43_3:getX() - var_43_0) * (arg_43_3:getX() - var_43_0))
	local var_43_4 = math.max(var_43_3, 0)

	arg_43_0.guideManuals_[arg_43_1]:addTo(arg_43_4, -1)
	arg_43_0.guideManuals_[arg_43_1]:setAnchorPoint(cc.p(0.5, 0.5))
	arg_43_0.guideManuals_[arg_43_1]:setScaleX(var_43_4 / arg_43_0.guideManuals_[arg_43_1]:getWidth())
	arg_43_0.guideManuals_[arg_43_1]:pos(arg_43_3:getX() / 2 + var_43_0 / 2, arg_43_3:getY() / 2 + var_43_1 / 2)
	arg_43_0.guideManuals_[arg_43_1]:setRotation(var_43_2)
end

function var_0_0.setHPProgress(arg_44_0, arg_44_1, arg_44_2, arg_44_3, arg_44_4)
	if arg_44_0.hpProgress_ == nil then
		arg_44_0.hpProgress_ = {}
		arg_44_0.easeProgress_ = {}
	end

	if not arg_44_0.hpProgress_[arg_44_2] then
		local var_44_0, var_44_1 = arg_44_0.spBarBacks1_[arg_44_2]:getPosition()
		local var_44_2, var_44_3 = arg_44_0.spBarBacks2_[arg_44_2]:getPosition()
		local var_44_4 = xyd.AssetLoader.get():loadSprite("images/battle/hp_del.png")
		local var_44_5 = xyd.AssetLoader.get():loadSprite("images/battle/hp_bar.png")

		arg_44_0.hpProgress_[arg_44_2] = display.newProgressTimer(var_44_5, display.PROGRESS_TIMER_BAR):align(display.CENTER, var_44_2, var_44_3):addTo(arg_44_0, 1)

		arg_44_0.hpProgress_[arg_44_2]:setMidpoint(cc.p(0, 0))
		arg_44_0.hpProgress_[arg_44_2]:setBarChangeRate(cc.p(1, 0))
		arg_44_0.hpProgress_[arg_44_2]:setPercentage(0)

		arg_44_0.easeProgress_[arg_44_2] = display.newProgressTimer(var_44_4, display.PROGRESS_TIMER_BAR):align(display.CENTER, var_44_2, var_44_3):addTo(arg_44_0, 0)

		arg_44_0.easeProgress_[arg_44_2]:setMidpoint(cc.p(0, 0))
		arg_44_0.easeProgress_[arg_44_2]:setBarChangeRate(cc.p(1, 0))
		arg_44_0.easeProgress_[arg_44_2]:setPercentage(0)
	end

	arg_44_0:setBarProgress_(arg_44_0.hpProgress_[arg_44_2], arg_44_1, false)
	arg_44_0:setBarProgress_(arg_44_0.easeProgress_[arg_44_2], arg_44_1, arg_44_3, function()
		if arg_44_1 < xyd.tables.battleConfig.redHpRate and arg_44_1 > 0 then
			if arg_44_0.avatarUIEffects3_ then
				arg_44_0:hpRedEffect(arg_44_2, true)
			end
		elseif arg_44_0.avatarUIEffects3_ then
			arg_44_0:hpRedEffect(arg_44_2, false)
		end

		if arg_44_4 ~= nil then
			arg_44_4()
		end
	end)
end

function var_0_0.setMPProgress(arg_46_0, arg_46_1, arg_46_2, arg_46_3, arg_46_4)
	if arg_46_0.mpProgress_ == nil then
		arg_46_0.mpProgress_ = {}
	end

	if not arg_46_0.mpProgress_[arg_46_2] then
		local var_46_0, var_46_1 = arg_46_0.spBarBacks1_[arg_46_2]:getPosition()
		local var_46_2, var_46_3 = arg_46_0.spBarBacks2_[arg_46_2]:getPosition()
		local var_46_4 = xyd.AssetLoader.get():loadSprite("images/battle/sp_bar.png")

		arg_46_0.mpProgress_[arg_46_2] = display.newProgressTimer(var_46_4, display.PROGRESS_TIMER_BAR):align(display.CENTER, var_46_0, var_46_1):addTo(arg_46_0, 1)

		arg_46_0.mpProgress_[arg_46_2]:setMidpoint(cc.p(0, 0))
		arg_46_0.mpProgress_[arg_46_2]:setBarChangeRate(cc.p(1, 0))
		arg_46_0.mpProgress_[arg_46_2]:setPercentage(0)
	end

	if arg_46_1 < 1 then
		arg_46_0.spRedBars_[arg_46_2]:hide()
	end

	arg_46_0:setBarProgress_(arg_46_0.mpProgress_[arg_46_2], arg_46_1, arg_46_3, function()
		if arg_46_1 >= 1 then
			arg_46_0.spRedBars_[arg_46_2]:show()
		end

		if arg_46_4 then
			arg_46_4()
		end
	end)
end

function var_0_0.updateBuffIconShow(arg_48_0, arg_48_1, arg_48_2, arg_48_3, arg_48_4, arg_48_5)
	if not arg_48_0.buffIconCounts then
		arg_48_0.buffIconCounts = {}
	end

	if not arg_48_0.nowRound then
		arg_48_0.nowRound = {}
	end

	if not arg_48_0.buffIconNums then
		arg_48_0.buffIconNums = {}
	end

	if not arg_48_0.nowRound[arg_48_3] then
		arg_48_0.nowRound[arg_48_3] = 1
	end

	if not arg_48_0.buffIconCounts[arg_48_3] then
		arg_48_0.buffIconCounts[arg_48_3] = {}

		for iter_48_0 = 1, 32 do
			arg_48_0.buffIconCounts[arg_48_3][iter_48_0] = 0
			arg_48_0.buffIconNums[arg_48_3] = 0
		end
	end

	if arg_48_0.buffIconCounts[arg_48_3] and arg_48_5 then
		for iter_48_1 = 1, 32 do
			arg_48_0.buffIconCounts[arg_48_3][iter_48_1] = 0
			arg_48_0.buffIconNums[arg_48_3] = 0
		end
	end

	if arg_48_1 and next(arg_48_1) then
		for iter_48_2 = 1, #arg_48_1 do
			local var_48_0 = math.max(arg_48_0.buffIconCounts[arg_48_3][arg_48_1[iter_48_2]] + arg_48_2[iter_48_2], 0)

			if arg_48_0.buffIconCounts[arg_48_3][arg_48_1[iter_48_2]] == 0 and var_48_0 > 0 then
				arg_48_0.buffIconNums[arg_48_3] = arg_48_0.buffIconNums[arg_48_3] + 1
			elseif arg_48_0.buffIconCounts[arg_48_3][arg_48_1[iter_48_2]] > 0 and var_48_0 == 0 then
				arg_48_0.buffIconNums[arg_48_3] = arg_48_0.buffIconNums[arg_48_3] - 1
			end

			arg_48_0.buffIconCounts[arg_48_3][arg_48_1[iter_48_2]] = var_48_0
		end
	end

	local var_48_1 = math.max(math.ceil(arg_48_0.buffIconNums[arg_48_3] / 4), 1)

	if arg_48_4 then
		if var_48_1 > arg_48_0.nowRound[arg_48_3] then
			arg_48_0.nowRound[arg_48_3] = arg_48_0.nowRound[arg_48_3] + 1
		else
			arg_48_0.nowRound[arg_48_3] = 1
		end
	end

	local var_48_2 = 1 + 4 * (arg_48_0.nowRound[arg_48_3] - 1)
	local var_48_3 = 4 + 4 * (arg_48_0.nowRound[arg_48_3] - 1)
	local var_48_4 = 0

	if arg_48_0.avatarBuffIcons_[arg_48_3] then
		for iter_48_3 = 1, 32 do
			if arg_48_0.buffIconCounts[arg_48_3][iter_48_3] > 0 then
				var_48_4 = var_48_4 + 1

				if var_48_2 <= var_48_4 and var_48_4 <= var_48_3 then
					arg_48_0.avatarBuffIcons_[arg_48_3][iter_48_3]:show()

					local var_48_5 = (var_48_4 - 1) % 4 * 28

					arg_48_0.avatarBuffIcons_[arg_48_3][iter_48_3]:setPositionX(arg_48_0.positions_[arg_48_3].x - 42 + var_48_5)
				else
					arg_48_0.avatarBuffIcons_[arg_48_3][iter_48_3]:hide()
				end
			else
				arg_48_0.avatarBuffIcons_[arg_48_3][iter_48_3]:hide()
			end
		end
	end
end

function var_0_0.setPetMPProgress(arg_49_0, arg_49_1, arg_49_2, arg_49_3)
	if not arg_49_0.petMPProgress_ then
		local var_49_0 = arg_49_0.petPos_.x
		local var_49_1 = arg_49_0.petPos_.y
		local var_49_2 = xyd.AssetLoader.get():loadSprite("images/battle/pet_sp_bar.png")

		arg_49_0.petMPProgress_ = display.newProgressTimer(var_49_2, display.PROGRESS_TIMER_RADIAL):align(display.LEFT_BOTTOM, var_49_0, var_49_1):addTo(arg_49_0, 1)

		arg_49_0.petMPProgress_:setMidpoint(cc.p(0.5, 0.5))
		arg_49_0.petMPProgress_:setBarChangeRate(cc.p(1, 0))
		arg_49_0.petMPProgress_:setPercentage(0)
	end

	if arg_49_1 < 1 then
		arg_49_0.petSpRedBar_:hide()
	end

	arg_49_0:setBarProgress_(arg_49_0.petMPProgress_, arg_49_1, arg_49_2, function()
		if arg_49_1 >= 1 then
			arg_49_0.petSpRedBar_:show()
		end

		if arg_49_3 then
			arg_49_3()
		end
	end)
end

function var_0_0.setBarProgress_(arg_51_0, arg_51_1, arg_51_2, arg_51_3, arg_51_4)
	arg_51_1:stopAllActions()

	arg_51_2 = arg_51_2 * 100

	local var_51_0 = arg_51_1:getPercentage()

	if tonumber(arg_51_3) then
		arg_51_1:runActionOnce(cc.ProgressTo:create(tonumber(arg_51_3), arg_51_2), false, arg_51_4)
	elseif arg_51_3 or var_51_0 < arg_51_2 then
		local var_51_1 = arg_51_2 - var_51_0
		local var_51_2 = xyd.tables.battleConfig.hpProgressMoveBase + xyd.tables.battleConfig.hpProgressMoveStep * math.abs(var_51_1)
		local var_51_3 = xyd.tables.battleConfig.hpProgressBrakeBase
		local var_51_4 = var_51_0 + var_51_1 * (1 - xyd.tables.battleConfig.hpProgressBrakePercent)
		local var_51_5 = arg_51_2
		local var_51_6 = cc.Sequence:create(cc.ProgressTo:create(var_51_2, var_51_4), cc.ProgressTo:create(var_51_3, var_51_5))

		arg_51_1:runActionOnce(var_51_6, false, arg_51_4)
	else
		arg_51_1:setPercentage(arg_51_2)

		if arg_51_4 ~= nil then
			arg_51_4()
		end
	end
end

function var_0_0.getUnlimitContainer(arg_52_0)
	return arg_52_0:nodeByName("unlimit_container")
end

function var_0_0.showUnlimitContainer(arg_53_0)
	arg_53_0:getUnlimitContainer():show()
	arg_53_0:nodeByName("battle_bottom"):hide()
	arg_53_0:nodeByName("lock"):hide()
	arg_53_0:nodeByName("btn_auto"):hide()
	arg_53_0.batchNode:setVisible(false)
	arg_53_0.batchNodeTop:setVisible(false)
end

function var_0_0.getSummonArea(arg_54_0)
	return arg_54_0:nodeByName("summon_area")
end

function var_0_0.getMedicine(arg_55_0)
	return arg_55_0:nodeByName("medicine")
end

function var_0_0.getMedicineNum(arg_56_0)
	return arg_56_0:nodeByName("medicine_num")
end

function var_0_0.resetUnlimitAvatar(arg_57_0, arg_57_1, arg_57_2, arg_57_3)
	local var_57_0, var_57_1 = arg_57_0:nodeByName("defence_bottom_bg2"):getChildByName("click_node" .. arg_57_1):getPosition()

	arg_57_0:removeIcon(arg_57_1)
	arg_57_0:setUnlimitAvatar(arg_57_3, var_57_0, var_57_1, arg_57_1)

	local var_57_2 = arg_57_0:getChildByName("option_icon1")
	local var_57_3

	if arg_57_0.optionHeros[arg_57_2 + 1] then
		var_57_3 = arg_57_0:getChildByName("option_icon2")
	end

	local var_57_4, var_57_5 = var_57_2:getPosition()
	local var_57_6 = cc.CallFunc:create(function()
		arg_57_0:removeChildByName("option_icon1")
	end)

	xyd.setCascadeOpacityEnabled(var_57_2, true)

	local var_57_7 = cc.Sequence:create(cc.FadeOut:create(0.5), var_57_6)

	var_57_2:runAction(var_57_7)

	if var_57_3 then
		local var_57_8 = cc.CallFunc:create(function()
			var_57_3:setName("option_icon1")

			local var_59_0

			if arg_57_0.optionHeros[arg_57_2 + 2] then
				local var_59_1 = arg_57_0.optionHeros[arg_57_2 + 2]
				local var_59_2 = var_59_1:getTableID()
				local var_59_3 = var_59_1:getColor()
				local var_59_4 = var_59_1:getStar()
				local var_59_5 = cc.Node:create()
				local var_59_6, var_59_7 = arg_57_0:nodeByName("option_hero2"):getPosition()

				var_59_5:setContentSize(90, 90)
				xyd.setAvatarBorder(var_59_2, var_59_5, var_59_3, var_59_4)
				arg_57_0:addChild(var_59_5)
				var_59_5:align(display.LEFT_BOTTOM, var_59_6, var_59_7)
				var_59_5:setName("option_icon2")
			end
		end)
		local var_57_9 = cc.Sequence:create(cc.MoveTo:create(0.8, cc.p(var_57_4, var_57_5)), var_57_8)

		var_57_3:runAction(var_57_9)
	end
end

function var_0_0.setUnlimitAvatar(arg_60_0, arg_60_1, arg_60_2, arg_60_3, arg_60_4)
	local var_60_0 = cc.Node:create()
	local var_60_1 = arg_60_1
	local var_60_2 = var_60_1:getTableID()
	local var_60_3 = var_60_1:getColor()
	local var_60_4 = var_60_1:getStar()
	local var_60_5 = xyd.AssetLoader.get():loadNodeFromJson("windows/common/hero_avatar4.csb")

	var_60_5:setContentSize(120, 120)
	xyd.setAvatarBorder(var_60_1, var_60_5:getChildByName("avatar"))

	local var_60_6 = var_60_5:getChildByName("mask")

	var_60_6:setLocalZOrder(2)
	var_60_6:setVisible(false)
	var_60_5:getChildByName("hp_di"):hide()
	var_60_5:getChildByName("hp"):hide()
	var_60_5:getChildByName("dead_txt"):hide()
	var_60_5:getChildByName("percent"):hide()
	var_60_5:setName("layout")
	var_60_0:addChild(var_60_5)
	var_60_0:setContentSize(120, 120)
	arg_60_0:nodeByName("defence_bottom_bg2"):addChild(var_60_0)
	var_60_0:align(display.LEFT_BOTTOM, arg_60_2, arg_60_3)
	var_60_0:setAnchorPoint(0.5, 0.5)
	var_60_0:setName("click_node" .. arg_60_4)
end

function var_0_0.getUnlimitAvatarMask(arg_61_0, arg_61_1)
	local var_61_0 = arg_61_0:nodeByName("defence_bottom_bg2"):getChildByName("click_node" .. arg_61_1)
	local var_61_1

	if var_61_0 then
		var_61_1 = var_61_0:getChildByName("layout"):getChildByName("mask")
	end

	return var_61_1
end

function var_0_0.getUnlimitContainerByIndex(arg_62_0, arg_62_1)
	return arg_62_0:nodeByName("defence_bottom_bg2"):getChildByName("click_node" .. arg_62_1)
end

function var_0_0.getUnlimitEnergyProcess(arg_63_0)
	return arg_63_0:nodeByName("defence_process")
end

function var_0_0.getUnlimitEnergyScale(arg_64_0)
	return arg_64_0:nodeByName("process_scale")
end

return var_0_0
