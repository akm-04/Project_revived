local var_0_0 = class("ActivityFishingBookWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.common.ui.SpriteNodeButton")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.activityFish
local var_0_4 = xyd.tables.misc
local var_0_5 = xyd.tables.gift
local var_0_6 = {
	FISHING = 1,
	BATTLE = 2
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.id = arg_1_2.default_id or 1
	arg_1_0.type_ = arg_1_2.type_

	if arg_1_0.type_ == var_0_6.FISHING then
		arg_1_0.isAward = arg_1_2.is_award
		arg_1_0.selfCollect = arg_1_2.self_collect
		arg_1_0.serverCollect = arg_1_2.server_collect
	end
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("txt_fishing_num"):setString(var_0_2:translation("ACTIVITY_FISHING_TEXT_13"))
	arg_3_0:nodeByName("txt_my_max_mass"):setString(var_0_2:translation("ACTIVITY_FISHING_TEXT_14"))
	arg_3_0:nodeByName("txt_region_max_mass"):setString(var_0_2:translation("ACTIVITY_FISHING_TEXT_15"))
	arg_3_0:nodeByName("txt_player"):setString(var_0_2:translation("ACTIVITY_FISHING_TEXT_16"))
	arg_3_0:nodeByName("txt_skill"):setString(var_0_2:translation("ACTIVITY_FISHING_TEXT_36"))

	arg_3_0.descLabel = xyd.createLabel(20, cc.c3b(76, 69, 87))

	arg_3_0.descLabel:setAnchorPoint(0.5, 0)
	arg_3_0.descLabel:setWidth(280)
	arg_3_0.descLabel:setLineHeight(25)
	arg_3_0:nodeByName("pos_txt"):addChild(arg_3_0.descLabel)
	arg_3_0:nodeByName("txt_name"):enableOutline(cc.c4b(54, 54, 54, 255), 2)

	for iter_3_0 = 1, 16 do
		local var_3_0 = arg_3_0:nodeByName("fish_" .. iter_3_0)
		local var_3_1 = xyd.getItemBg(var_0_3:rarity(iter_3_0))
		local var_3_2 = xyd.AssetLoader.get():loadSprite("windows/activities/1226/fish_icon/" .. iter_3_0 .. ".png")

		var_3_1:setNormalizedPosition(cc.p(0.5, 0.5))
		var_3_2:setNormalizedPosition(cc.p(0.5, 0.5))
		var_3_2:setName("fish")
		var_3_0:addChild(var_3_1)
		var_3_0:addChild(var_3_2)
		arg_3_0:nodeByName("txt_name_" .. iter_3_0):setString(var_0_3:name(iter_3_0))
		var_3_0:addTouchEventListener(function(arg_4_0, arg_4_1)
			if arg_4_1 == ccui.TouchEventType.ended then
				if iter_3_0 == arg_3_0.id then
					return
				end

				arg_3_0:updateSelectIndex(iter_3_0)
			end
		end)
	end

	arg_3_0:updateSelectIndex(arg_3_0.id)

	local var_3_3 = var_0_1.new({
		sprite = "windows/button/btn_return.png",
		isSound = 0,
		colorModes = xyd.tables.systemColor:btnColors(xyd.ColorMode.BLUE)
	})

	var_3_3:addTo(arg_3_0:nodeByName("title"))
	var_3_3:setAnchorPoint(0.5, 0.5)
	var_3_3:setPosition(43, -23)
	var_3_3:addTouchEvent(function(arg_5_0)
		if arg_5_0.name == "ended" then
			arg_3_0:close()
		end
	end)

	if arg_3_0.type_ == var_0_6.FISHING then
		arg_3_0:nodeByName("fishing_book"):setVisible(true)
		arg_3_0:nodeByName("txt_title"):setString(var_0_2:translation("ACTIVITY_FISHING_TEXT_3"))

		local var_3_4 = var_0_4:getValue("activity_fishing_collection_reward")
		local var_3_5 = var_0_5:items(var_3_4)[1]
		local var_3_6 = var_0_5:itemNum(var_3_4)[1]

		xyd.setItemAndAddTips(arg_3_0:nodeByName("item"), var_3_5, var_3_6)

		local var_3_7 = 0

		for iter_3_1 = 1, 16 do
			if arg_3_0.selfCollect[tostring(iter_3_1)].count > 0 then
				var_3_7 = var_3_7 + 1
			else
				xyd.GrayNode(arg_3_0:nodeByName("fish_" .. iter_3_1):getChildByName("fish"))
			end
		end

		arg_3_0:nodeByName("txt_bar"):setString(var_3_7 .. "/16")
		arg_3_0:nodeByName("bar"):setPercent(100 * var_3_7 / 16)

		if var_3_7 < 16 or arg_3_0.isAward == 1 then
			arg_3_0:nodeByName("mask"):setVisible(true)
		else
			arg_3_0:nodeByName("red_point"):setVisible(true)
			arg_3_0:nodeByName("item"):addTouchEventListener(function(arg_6_0, arg_6_1)
				if arg_6_1 == ccui.TouchEventType.ended then
					xyd.Backend.get():request(xyd.mid.ACTIVITY_FISHING_COLLECT_AWARD, nil, function(arg_7_0, arg_7_1)
						if arg_7_0 == xyd.error.OK then
							arg_3_0.selfPlayer:handleRewards(arg_7_1.awards)

							arg_3_0.isAward = 1

							arg_3_0:nodeByName("item"):setTouchEnabled(false)
							arg_3_0:nodeByName("red_point"):setVisible(false)
							arg_3_0:nodeByName("mask"):setVisible(true)
						end
					end)
				end
			end)
		end
	elseif arg_3_0.type_ == var_0_6.BATTLE then
		arg_3_0:nodeByName("battle_book"):setVisible(true)
		arg_3_0:nodeByName("txt_title"):setString(var_0_2:translation("ACTIVITY_FISHING_TEXT_37"))

		local var_3_8 = xyd.AssetLoader.get():loadSprite("windows/activities/1226/skill_icon/border.png")
		local var_3_9 = xyd.AssetLoader.get():loadSprite("windows/activities/1226/skill_icon/" .. arg_3_0.id .. ".png")

		var_3_8:setNormalizedPosition(cc.p(0.5, 0.5))
		var_3_8:setLocalZOrder(1)
		var_3_9:setNormalizedPosition(cc.p(0.5, 0.5))
		var_3_9:setName("icon")
		arg_3_0:nodeByName("skill_container"):addChild(var_3_8)
		arg_3_0:nodeByName("skill_container"):addChild(var_3_9)
		arg_3_0:nodeByName("skill_container"):addTouchEventListener(function(arg_8_0, arg_8_1)
			if arg_8_1 == ccui.TouchEventType.ended then
				xyd.WindowManager.get():openWindow("activity_fishing_skill_tips", {
					id = arg_3_0.id
				}):setPosition(560, 10)
			end
		end)
	end
end

function var_0_0.updateSelectIndex(arg_9_0, arg_9_1)
	arg_9_0.id = arg_9_1

	arg_9_0:addSelectEffect(arg_9_1)

	local var_9_0 = xyd.AssetLoader.get():loadSprite("windows/activities/1226/fish/" .. arg_9_1 .. ".png")
	local var_9_1 = arg_9_0:nodeByName("bubble"):getContentSize().width

	arg_9_0:nodeByName("pos_fish"):removeAllChildren()
	arg_9_0:nodeByName("pos_fish"):addChild(var_9_0)
	arg_9_0:nodeByName("txt_name"):setString(var_0_3:name(arg_9_1))
	arg_9_0.descLabel:setString(var_0_3:desc(arg_9_1))
	arg_9_0:nodeByName("bubble"):setContentSize(var_9_1, arg_9_0.descLabel:getContentSize().height + 50)

	if arg_9_0.type_ == var_0_6.FISHING then
		arg_9_0:nodeByName("fishing_num"):setString(arg_9_0.selfCollect[tostring(arg_9_1)].count)
		arg_9_0:nodeByName("my_max_mass"):setString(arg_9_0.selfCollect[tostring(arg_9_1)].max_weight .. "kg")
		arg_9_0:nodeByName("region_max_mass"):setString(arg_9_0.serverCollect[tostring(arg_9_1)].max_weight .. "kg")
		arg_9_0:nodeByName("player"):setString(arg_9_0.serverCollect[tostring(arg_9_1)].player_name)
	elseif arg_9_0.type_ == var_0_6.BATTLE then
		arg_9_0:nodeByName("txt_hp"):setString(string.format(var_0_2:translation("ACTIVITY_FISHING_TEXT_30"), var_0_3:hp(arg_9_1)))
		arg_9_0:nodeByName("txt_atk"):setString(string.format(var_0_2:translation("ACTIVITY_FISHING_TEXT_31"), var_0_3:atk(arg_9_1)))
		arg_9_0:nodeByName("txt_def"):setString(string.format(var_0_2:translation("ACTIVITY_FISHING_TEXT_32"), var_0_3:def(arg_9_1)))
		arg_9_0:nodeByName("txt_spd"):setString(string.format(var_0_2:translation("ACTIVITY_FISHING_TEXT_33"), var_0_3:spd(arg_9_1)))
		arg_9_0:nodeByName("txt_evd"):setString(string.format(var_0_2:translation("ACTIVITY_FISHING_TEXT_34"), var_0_3:evd(arg_9_1)))
		arg_9_0:nodeByName("txt_crt"):setString(string.format(var_0_2:translation("ACTIVITY_FISHING_TEXT_35"), var_0_3:crt(arg_9_1)))

		local var_9_2 = xyd.AssetLoader.get():loadSprite("windows/activities/1226/skill_icon/" .. arg_9_0.id .. ".png")

		var_9_2:setNormalizedPosition(cc.p(0.5, 0.5))
		var_9_2:setName("icon")
		arg_9_0:nodeByName("skill_container"):removeChildByName("icon")
		arg_9_0:nodeByName("skill_container"):addChild(var_9_2)
	end
end

function var_0_0.addSelectEffect(arg_10_0, arg_10_1)
	if arg_10_0.selectEffect then
		arg_10_0.selectEffect:removeFromParent(false)
	else
		arg_10_0.selectEffect = xyd.AssetLoader.get():loadSprite("windows/activities/1226/fishing/select.png")

		local var_10_0 = cc.ScaleBy:create(0.3, 1.04)
		local var_10_1 = transition.sequence({
			var_10_0,
			var_10_0:reverse()
		})
		local var_10_2 = cc.RepeatForever:create(var_10_1)

		arg_10_0.selectEffect:runAction(var_10_2)
		arg_10_0.selectEffect:setNormalizedPosition(cc.p(0.5, 0.5))
	end

	arg_10_0:nodeByName("fish_" .. arg_10_1):addChild(arg_10_0.selectEffect)
end

return var_0_0
