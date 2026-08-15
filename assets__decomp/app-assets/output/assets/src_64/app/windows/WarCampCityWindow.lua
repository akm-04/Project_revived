local var_0_0 = class("WarCampCityWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.warCamp
local var_0_3 = xyd.tables.warCampCampaign
local var_0_4 = xyd.tables.warCampTimeline
local var_0_5 = import("app.model.Hero")
local var_0_6 = 86400

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.warCamp_ = xyd.ModelManager.get():loadModel(xyd.ModelType.WAR_CAMP)
	arg_1_0.cityID = arg_1_2.city_id
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.bgAnchorPoint = arg_1_2.anchorPoint
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:initDatas()
	arg_2_0:layout()
end

function var_0_0.willClose(arg_3_0, arg_3_1)
	var_0_0.super:willClose(arg_3_1)
end

function var_0_0.initDatas(arg_4_0)
	arg_4_0.warCamp_:loadSingleActivity()

	arg_4_0.bossID = var_0_2:bossId(arg_4_0.cityID)
	arg_4_0.myCamp = arg_4_0.warCamp_:getCampType()
	arg_4_0.curMapInfo = arg_4_0.warCamp_:getMapInfoByMapID(arg_4_0.cityID)
end

function var_0_0.layout(arg_5_0)
	if arg_5_0.cityID ~= arg_5_0.warCamp_:getMaxCityNum() and arg_5_0.cityID ~= 1 then
		arg_5_0:initSkills()
	end

	arg_5_0:initBossModel()
	arg_5_0:setupButton()
	arg_5_0:initHpBar()
	arg_5_0:initBg()
	arg_5_0:nodeByName("my_harm"):enableOutline(cc.c4b(255, 159, 37, 255), 2)
	arg_5_0:nodeByName("my_score"):enableOutline(cc.c4b(255, 159, 37, 255), 2)
	arg_5_0:updateBasicInfo()
	arg_5_0:nodeByName("my_score"):setVisible(false)
	arg_5_0:nodeByName("word_10"):setVisible(false)
end

function var_0_0.updateBasicInfo(arg_6_0)
	local var_6_0 = var_0_3:campaignDes(arg_6_0.bossID)
	local var_6_1 = var_0_2:buffDesc(arg_6_0.cityID)

	arg_6_0:nodeByName("boss_desc_detail"):setString(var_6_0)

	if #var_6_1 == 1 then
		arg_6_0:nodeByName("buff_desc"):setVisible(true)
		arg_6_0:nodeByName("buff_desc2"):setVisible(false)
		arg_6_0:nodeByName("buff_type"):setString(var_0_1:translation("WAR_CAMP_BUFF_TIPS"))
		arg_6_0:nodeByName("buff_desc_txt"):setString(var_6_1[1])
	else
		arg_6_0:nodeByName("buff_desc"):setVisible(false)
		arg_6_0:nodeByName("buff_desc2"):setVisible(true)
		arg_6_0:nodeByName("buff_type2"):setString(var_0_1:translation("WAR_CAMP_BUFF_TIPS"))
		arg_6_0:nodeByName("buff_desc_txt1"):setString(var_6_1[1])
		arg_6_0:nodeByName("buff_desc_txt2"):setString(var_6_1[2])
	end

	if arg_6_0.curMapInfo.camp == xyd.WarCampSelectType.NONE then
		arg_6_0:nodeByName("layout1"):setVisible(true)
		arg_6_0:nodeByName("layout2"):setVisible(false)
	elseif arg_6_0.curMapInfo.camp == xyd.WarCampSelectType.LEFT then
		arg_6_0:nodeByName("camp_name_bg2"):setVisible(false)
		arg_6_0:nodeByName("camp_2"):setVisible(false)
		arg_6_0:nodeByName("layout1"):setVisible(false)
		arg_6_0:nodeByName("layout2"):setVisible(true)
	elseif arg_6_0.curMapInfo.camp == xyd.WarCampSelectType.RIGHT then
		arg_6_0:nodeByName("camp_name_bg1"):setVisible(false)
		arg_6_0:nodeByName("camp_1"):setVisible(false)
		arg_6_0:nodeByName("layout1"):setVisible(false)
		arg_6_0:nodeByName("layout2"):setVisible(true)
	end

	arg_6_0:nodeByName("btn_harm_rank"):getChildByName("btn_word_gray_3"):setVisible(false)

	local var_6_2 = arg_6_0.warCamp_:getMaxCityNum()

	if arg_6_0.cityID == 1 or arg_6_0.cityID == var_6_2 then
		arg_6_0:nodeByName("word_9"):setVisible(false)
		arg_6_0:nodeByName("word_10"):setVisible(false)
		arg_6_0:nodeByName("my_harm"):setVisible(false)
		arg_6_0:nodeByName("my_score"):setVisible(false)
		arg_6_0:nodeByName("btn_harm_rank"):setBright(false)
		arg_6_0:nodeByName("btn_harm_rank"):setTouchEnabled(false)
		arg_6_0:nodeByName("btn_word_gray_3"):setVisible(true)
		arg_6_0:nodeByName("btn_word_3"):setVisible(false)
		arg_6_0:nodeByName("word_12"):setVisible(false)
	end

	if arg_6_0.curMapInfo.camp ~= xyd.WarCampSelectType.NONE and arg_6_0.myCamp ~= arg_6_0.curMapInfo.first_camp then
		arg_6_0:nodeByName("my_score"):setString(0)
		arg_6_0:nodeByName("my_harm"):setString(0)
	else
		arg_6_0:nodeByName("my_harm"):setString(arg_6_0.curMapInfo.self_hurt or 0)

		local var_6_3 = arg_6_0.curMapInfo.self_hurt * xyd.tables.misc.campWarBossHonorParam / xyd.DECIMAL_BASE
		local var_6_4 = 1

		for iter_6_0, iter_6_1 in pairs(xyd.tables.misc.warCampSkinItems) do
			if arg_6_0.selfPlayer:hasSkin(iter_6_1) then
				var_6_4 = var_6_4 + xyd.tables.misc.warCampSkinItemRate
			end
		end

		local var_6_5 = math.floor(var_6_3 * var_6_4)

		arg_6_0:nodeByName("my_score"):setString(math.floor(var_6_5))
	end

	if arg_6_0.warCamp_.baseInfo.add_times >= xyd.tables.misc:getValue("camp_war_boss_time_limit") then
		arg_6_0:nodeByName("challege_txt_container"):removeAllChildren()
		arg_6_0:nodeByName("challage_desc"):setString(var_0_1:translation("WAR_CAMP_BOSS_TIME_TIPS_4"))
	else
		arg_6_0:nodeByName("challage_times"):setString(var_0_1:translation("WAR_CAMP_BOSS_TIME_TIPS_1"))
		arg_6_0:nodeByName("challage_num"):setString(arg_6_0.warCamp_.baseInfo.challenge_times)
		arg_6_0:nodeByName("challage_desc"):setString("")

		local var_6_6 = cc.p(arg_6_0:nodeByName("challage_desc"):getPosition())
		local var_6_7 = 5
		local var_6_8 = xyd.tables.misc:getValue("camp_war_boss_time_energy")
		local var_6_9 = xyd.tables.misc:getValue("camp_war_boss_time_get")
		local var_6_10 = string.format(var_0_1:translation("WAR_CAMP_BOSS_TIME_TIPS_3"), var_6_8, var_6_9)
		local var_6_11 = xyd.split(var_6_10, "\n")

		for iter_6_2 = 1, #var_6_11 do
			local var_6_12 = var_6_11[iter_6_2]

			arg_6_0:createText(var_6_6.x, var_6_6.y, 24, var_6_12, iter_6_2)

			var_6_6.y = var_6_6.y - 24 - var_6_7
		end
	end
end

function var_0_0.createText(arg_7_0, arg_7_1, arg_7_2, arg_7_3, arg_7_4, arg_7_5)
	local var_7_0 = arg_7_0:nodeByName("challege_txt_container")
	local var_7_1 = {
		size = arg_7_3,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		color = cc.c3b(0, 0, 0)
	}
	local var_7_2 = xyd.createMultiColorTxt(arg_7_4, xyd.color.WHITE, arg_7_3, false)

	var_7_2:addTo(var_7_0)
	var_7_2:setPosition(cc.p(arg_7_1, arg_7_2))
	var_7_2:setAnchorPoint(cc.p(0, 1))
	var_7_2:setName("labelText" .. arg_7_5)
end

function var_0_0.initBg(arg_8_0)
	local var_8_0 = xyd.AssetLoader.get():loadSprite("windows/war_camp/war_map/bg1.png")
	local var_8_1 = var_8_0:getContentSize()
	local var_8_2 = 2

	var_8_0:setScale(var_8_2)
	var_8_0:addTo(arg_8_0:nodeByName("container"), -2)
	var_8_0:setAnchorPoint(cc.p(arg_8_0.bgAnchorPoint.x, arg_8_0.bgAnchorPoint.y))
	var_8_0:setPosition(cc.p(xyd.STAGE_WIDTH / 2, xyd.STAGE_HEIGHT / 2))

	local var_8_3 = display.newColorLayer(cc.c4b(0, 0, 0, 200))
	local var_8_4 = arg_8_0:convertToWorldSpace(cc.p(0, 0))

	var_8_3:pos(-var_8_4.x, -var_8_4.y):addTo(arg_8_0:nodeByName("container"), -1)
end

function var_0_0.initSkills(arg_9_0)
	local var_9_0 = arg_9_0:nodeByName("skill_container")

	var_9_0:removeAllChildren()

	local var_9_1 = var_0_3:skillId(arg_9_0.bossID)
	local var_9_2 = var_9_0:getContentSize().height
	local var_9_3 = 0

	for iter_9_0 = 1, #var_9_1 do
		local var_9_4 = var_9_1[iter_9_0]
		local var_9_5 = display.newNode()

		var_9_5:setContentSize(var_9_2, var_9_2)

		local var_9_6 = xyd.tables.skill:icon(var_9_4)
		local var_9_7 = xyd.SpriteLoader.new(var_9_6, nil, nil, xyd.DefaultImageType.SKILL_ICON, var_9_5)
		local var_9_8 = xyd.AssetLoader.get():loadSprite("windows/hero/skill_icon.png")

		var_9_8:setPosition(var_9_5:getWidth() / 2, var_9_5:getHeight() / 2)
		var_9_8:setAnchorPoint(cc.p(0.5, 0.5))
		var_9_8:scale(var_9_5:getWidth() / var_9_8:getWidth() / 20 * 19)

		stencil = xyd.AssetLoader:get():loadSprite("images/icon_mask2.png")

		stencil:setPosition(var_9_5:getWidth() / 2, var_9_5:getHeight() / 2)
		stencil:setAnchorPoint(cc.p(0.5, 0.5))
		stencil:scale(var_9_5:getWidth() / stencil:getWidth())

		local var_9_9 = cc.ClippingNode:create()

		var_9_9:setStencil(stencil)
		var_9_9:setInverted(true)
		var_9_9:setAlphaThreshold(0)
		var_9_5:addChild(var_9_9)
		var_9_9:addChild(var_9_7)
		var_9_7:align(display.LEFT_BOTTOM, 0, 0)
		var_9_7:scale((var_9_5:getWidth() - 3) / var_9_7:getWidth())
		var_9_5:addTo(var_9_0)
		var_9_8:addTo(var_9_5)
		var_9_5:setPosition((iter_9_0 - 1) * (var_9_2 + 10) + 20, 0)

		local var_9_10 = {
			has_jiantou = false,
			id = var_9_4
		}

		var_9_5:setTouchEnabled(true)
		var_9_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
			if arg_10_0.name == "began" then
				if not xyd.WindowManager.get():getWindow("skill_tips") then
					local var_10_0 = xyd.WindowManager.get():openWindow("skill_tips", var_9_10)

					xyd.adaptToWorldPosition(var_9_5, var_10_0)
				end

				return true
			elseif arg_10_0.name == "ended" then
				xyd.WindowManager.get():closeWindow("skill_tips")
			end
		end)
	end
end

function var_0_0.initBossModel(arg_11_0)
	local var_11_0 = var_0_3:modelId(arg_11_0.bossID)

	if var_11_0 == 0 then
		return
	end

	local var_11_1 = xyd.HeroAnimation.new(nil, var_11_0, xyd.tables.model:uiScale(var_11_0), {})

	if var_11_1 then
		var_11_1:idle()
	end

	var_11_1:addTo(arg_11_0:nodeByName("boss"))

	local var_11_2 = arg_11_0:nodeByName("boss"):getContentSize()

	var_11_1:setPosition(cc.p(var_11_2.width / 2, 0))

	local var_11_3 = var_0_3:name(arg_11_0.bossID)

	arg_11_0:nodeByName("boss_name"):setString(var_0_2:name(arg_11_0.cityID))
end

function var_0_0.checkCanFight(arg_12_0)
	if arg_12_0.curMapInfo.camp == arg_12_0.myCamp then
		return
	end

	if arg_12_0.warCamp_.baseInfo.challenge_times <= 0 and arg_12_0.curMapInfo.camp == 0 then
		local var_12_0 = var_0_1:translation("TRIAL_TIMES_ERROR")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_12_0
		})

		return false
	end

	local var_12_1 = xyd.ServerTime.get():getServerTime()
	local var_12_2 = var_0_2:openTime(arg_12_0.cityID)
	local var_12_3 = arg_12_0.warCamp_.activity.start_time
	local var_12_4 = (var_0_4:getEndWarDay() - 1) * var_0_6 + var_12_3

	if var_12_1 < var_12_2 + var_12_3 then
		local var_12_5 = var_0_1:translation("WAR_CAMP_BOSS_TIPS_6")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_12_5
		})

		return false
	elseif var_12_4 < var_12_1 then
		local var_12_6 = var_0_1:translation("WAR_CAMP_BOSS_TIPS_8")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_12_6
		})

		return false
	end

	local var_12_7 = var_0_2:link(arg_12_0.cityID)
	local var_12_8 = false

	for iter_12_0 = 1, #var_12_7 do
		if arg_12_0.warCamp_:getMapInfoByMapID(var_12_7[iter_12_0]).camp == arg_12_0.myCamp then
			var_12_8 = true

			break
		end
	end

	if not var_12_8 then
		local var_12_9 = var_0_1:translation("WAR_CAMP_BOSS_TIPS_7")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_12_9
		})

		return false
	end

	if arg_12_0.curMapInfo.camp == 0 then
		return true
	end

	local var_12_10 = var_0_2:freeWordTime(arg_12_0.cityID)

	if var_12_1 <= arg_12_0.curMapInfo.time + var_12_10 then
		local var_12_11 = var_0_1:translation("WAR_CAMP_BOSS_TIPS_5")

		xyd.WindowManager.get():openWindow("toast", {
			message = var_12_11
		})

		return false
	end

	return true
end

function var_0_0.setupButton(arg_13_0)
	arg_13_0:nodeByName("btn_fight"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			if not arg_13_0:checkCanFight() then
				return
			end

			local var_14_0 = {
				city_id = arg_13_0.cityID
			}

			if arg_13_0.curMapInfo.camp == 0 then
				var_14_0.window_type = xyd.WarCampTeamWindowType.FIGHT_BOSS
			elseif arg_13_0.curMapInfo.camp ~= arg_13_0.myCamp then
				var_14_0.window_type = xyd.WarCampTeamWindowType.FIGHT_ENEMY
			end

			xyd.WindowManager.get():openWindow("war_camp_team", var_14_0)
		end
	end)
	arg_13_0:nodeByName("btn_my_teams"):addTouchEventListener(function(arg_15_0, arg_15_1)
		if arg_15_1 == ccui.TouchEventType.ended then
			local var_15_0 = {
				city_id = arg_13_0.cityID,
				window_type = xyd.WarCampTeamWindowType.NORMAL,
				click_city = arg_13_0.cityID
			}

			xyd.WindowManager.get():openWindow("war_camp_team", var_15_0)
		end
	end)
	arg_13_0:nodeByName("btn_check_teams"):addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.ended then
			local var_16_0 = {
				map_id = arg_13_0.cityID
			}

			arg_13_0.warCamp_:getMapTeams(var_16_0, function(arg_17_0, arg_17_1)
				if arg_17_0 == xyd.error.OK then
					local var_17_0 = arg_17_1

					var_17_0.cityID = arg_13_0.cityID

					xyd.WindowManager.get():openWindow("war_camp_city_teams", var_17_0)
				end
			end)
		end
	end)
	arg_13_0:nodeByName("btn_harm_rank"):addTouchEventListener(function(arg_18_0, arg_18_1)
		if arg_18_1 == ccui.TouchEventType.ended then
			local var_18_0 = {
				map_id = arg_13_0.cityID
			}

			arg_13_0.warCamp_:getHurtRank(var_18_0, function(arg_19_0, arg_19_1)
				if arg_19_0 == xyd.error.OK then
					arg_19_1.isHarm = true

					xyd.WindowManager.get():openWindow("war_camp_rank", arg_19_1)
				end
			end)
		end
	end)

	if arg_13_0.curMapInfo.camp == 0 or arg_13_0.curMapInfo.camp ~= arg_13_0.myCamp then
		arg_13_0:nodeByName("btn_my_teams"):setTouchEnabled(false)
		arg_13_0:nodeByName("btn_check_teams"):setTouchEnabled(false)
		arg_13_0:nodeByName("btn_my_teams"):setBright(false)
		arg_13_0:nodeByName("btn_check_teams"):setBright(false)
		arg_13_0:nodeByName("btn_check_teams"):getChildByName("btn_word_1"):setVisible(false)
		arg_13_0:nodeByName("btn_my_teams"):getChildByName("btn_word_4"):setVisible(false)
		arg_13_0:nodeByName("btn_fight"):getChildByName("btn_word_gray_2"):setVisible(false)
	elseif arg_13_0.curMapInfo.camp == arg_13_0.myCamp then
		arg_13_0:nodeByName("btn_fight"):setTouchEnabled(false)
		arg_13_0:nodeByName("btn_fight"):setBright(false)
		arg_13_0:nodeByName("btn_check_teams"):getChildByName("btn_word_gray_1"):setVisible(false)
		arg_13_0:nodeByName("btn_my_teams"):getChildByName("btn_word_gray_4"):setVisible(false)
		arg_13_0:nodeByName("btn_fight"):getChildByName("btn_word_2"):setVisible(false)
	end
end

function var_0_0.initHpBar(arg_20_0)
	local var_20_0 = var_0_2:bossHp(arg_20_0.cityID)
	local var_20_1 = arg_20_0.curMapInfo.hurt_1 + arg_20_0.curMapInfo.hurt_2
	local var_20_2 = xyd.BAR_DECIMAL_BASE * (var_20_0 - var_20_1) / var_20_0

	if var_20_2 < 0 then
		var_20_2 = 0
	end

	arg_20_0:nodeByName("hp_bar"):setPercent(math.floor(var_20_2))
	arg_20_0:nodeByName("hp_rate"):setString(string.format("%0.2f", var_20_2) .. "/" .. xyd.BAR_DECIMAL_BASE .. "%")
end

return var_0_0
