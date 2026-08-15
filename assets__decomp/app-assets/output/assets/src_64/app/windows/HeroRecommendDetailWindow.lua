local var_0_0 = class("HeroRecommendDetailWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.model.Hero")
local var_0_3 = import("app.model.Pet")
local var_0_4 = "4"
local var_0_5 = "5"

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.heroRecommend = xyd.ModelManager.get():loadModel(xyd.ModelType.HERO_RECOMMEND)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.info = arg_1_2.info
	arg_1_0.forceInfo = arg_1_0.info.force_info
	arg_1_0.tableId = arg_1_2.table_id

	local var_1_0 = var_0_2.new()

	var_1_0:populateWithTableID(arg_1_0.tableId)

	arg_1_0.hero = var_1_0
	arg_1_0.modelState = 1
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
	arg_2_0.blockLayer_:setPosition(cc.p(-640, -360))
end

function var_0_0.layout(arg_3_0)
	arg_3_0:nodeByName("no_record_tip_txt"):setString(var_0_1:translation("RECOMMEND_NO_RECORD_TEXT"))

	if arg_3_0:getListLen() > 0 then
		arg_3_0:nodeByName("no_record_tip_txt"):setVisible(false)
	end

	arg_3_0:updateHeroModel()
	arg_3_0:updateTopContainer()
	arg_3_0:updateMyHeroInfo()

	arg_3_0.scroll = arg_3_0:nodeByName("scroll")

	local var_3_0 = arg_3_0.scroll:getContentSize()

	arg_3_0.scrollList = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_0.width, var_3_0.height),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_HORIZONTAL
	}):addTo(arg_3_0.scroll):onScroll(handler(arg_3_0, arg_3_0.scrollListener))

	arg_3_0.scrollList:setDelegate(handler(arg_3_0, arg_3_0.scrollListDelegate))
	arg_3_0.scrollList:reload()
	arg_3_0:setButtonClick()
end

function var_0_0.updateHeroModel(arg_4_0)
	local var_4_0 = arg_4_0.hero

	arg_4_0:nodeByName("hero_name_txt"):enableOutline(cc.c4b(255, 255, 255, 155), 2)
	arg_4_0:nodeByName("hero_name_txt"):setString(var_4_0:getName())
	arg_4_0:nodeByName("score_txt"):setString(arg_4_0.info.recommend_score)

	local var_4_1 = arg_4_0:getHeroModel()

	var_4_1:setTouchSwallowEnabled(false)

	arg_4_0.modelState = xyd.ModelState.Walk

	local var_4_2 = arg_4_0:getHeroContainer():getContentSize().width / 2

	var_4_1:setPosition(cc.p(var_4_2, 0))
	arg_4_0:getHeroContainer():removeAllChildren()
	var_4_1:addTo(arg_4_0:getHeroContainer())
	var_4_1:setTouchEnabled(true)
	var_4_1:setScale(0.85)

	arg_4_0.isShow = false

	arg_4_0:getHeroContainer():addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended and not arg_4_0.isShow then
			arg_4_0:resetModelState()
		end
	end)
end

function var_0_0.updateTopContainer(arg_6_0)
	local var_6_0 = arg_6_0.forceInfo.top_player_info

	if var_6_0.guild_id and var_6_0.guild_id > 0 then
		arg_6_0:nodeByName("guild_name"):setString(var_6_0.guild_name)
		arg_6_0:nodeByName("guild_text"):setString(var_0_1:translation("GUILD") .. ":")
	else
		arg_6_0:nodeByName("guild_name"):setVisible(false)
		arg_6_0:nodeByName("guild_text"):setVisible(false)
	end

	local var_6_1 = xyd.AssetLoader.get():loadLabel(nil, "lucky_value")

	var_6_1:setString(math.ceil(arg_6_0.forceInfo.top_hero_info.force))
	var_6_1:setAnchorPoint(cc.p(0, 0.5))
	var_6_1:setScale(1)
	var_6_1:addTo(arg_6_0:nodeByName("top_container"):getChildByName("zhandouli_pos"))
	xyd.setPlayerInfoContainer(arg_6_0:nodeByName("top_container"), var_6_0)

	local var_6_2 = var_6_0
	local var_6_3 = {
		avatar_id = var_6_2.avatar_id,
		avatar_frame_id = var_6_2.avatar_frame_id,
		playerInfo = var_6_2
	}

	arg_6_0:nodeByName("avtar_container"):removeAllChildren()
	xyd.setPlayerAvatar(arg_6_0:nodeByName("avtar_container"), var_6_3)
	arg_6_0:nodeByName("top_container"):getChildByName("region_txt"):setString("S" .. tostring(var_6_2.region))

	local var_6_4 = var_0_2.new()

	var_6_4:populate(arg_6_0.forceInfo.top_hero_info)
	xyd.setAvatarBorderWithLevelAndHp(var_6_4, arg_6_0:nodeByName("icon_container"))

	local var_6_5 = "images/title_system/text/" .. tostring(arg_6_0.tableId) .. ".png"
	local var_6_6 = xyd.AssetLoader.get():loadSprite(var_6_5)

	var_6_6:setAnchorPoint(cc.p(0, 0.5))
	var_6_6:addTo(arg_6_0:nodeByName("title_name_pos"))

	local var_6_7 = -8

	var_6_6:setPosition(cc.p(var_6_7, 0))

	local var_6_8 = (arg_6_0:nodeByName("top_text"):getContentSize().width - var_6_6:getContentSize().width - var_6_7) / 2

	arg_6_0:nodeByName("title_name_pos"):setPositionX(arg_6_0:nodeByName("title_name_pos"):getPositionX() + var_6_8)
end

function var_0_0.addHeroTips(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = {
		id = arg_7_2:getTableID(),
		lev = arg_7_2:getLevel(),
		quality = arg_7_2:getColor(),
		name = arg_7_2:getName(),
		desc = xyd.tables.hero:getDes(arg_7_2:getTableID()),
		hero = arg_7_2
	}

	var_7_0.isHero = true

	local var_7_1, var_7_2 = arg_7_1:getPosition()

	arg_7_1:setTouchEnabled(true)
	arg_7_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_8_0)
		if arg_8_0.name == "began" then
			local var_8_0 = xyd.WindowManager.get():getWindow("new_item_tips")
			local var_8_1 = arg_7_0:convertToWorldSpace(cc.p(0, 0))

			if not var_8_0 then
				local var_8_2 = xyd.WindowManager.get():openWindow("new_item_tips", var_7_0)

				xyd.adaptToWorldPosition(arg_7_1, var_8_2)
			end

			return true
		elseif arg_8_0.name == "ended" and xyd.WindowManager.get():getWindow("new_item_tips") then
			local var_8_3 = xyd.WindowManager.get():closeWindow("new_item_tips")
		end
	end)
end

function var_0_0.updateMyHeroInfo(arg_9_0)
	if arg_9_0.forceInfo.my_hero_info then
		arg_9_0:nodeByName("my_zhandouli_text"):setString(string.format(var_0_1:translation("MY_ZHANDOULI_TEXT"), arg_9_0.hero:getName()))

		local var_9_0 = xyd.AssetLoader.get():loadLabel(nil, "lucky_value")

		var_9_0:setString(math.ceil(arg_9_0.forceInfo.my_hero_info.force))
		var_9_0:setAnchorPoint(cc.p(0, 0.5))
		var_9_0:addTo(arg_9_0:nodeByName("my_own_container"):getChildByName("zhandouli_pos"))
		var_9_0:setScale(0.9)
		var_9_0:setPositionY(5)
		arg_9_0:nodeByName("not_have_btn"):setVisible(false)
		arg_9_0:nodeByName("my_own_container"):getChildByName("zhandouli_pos"):setPositionX(arg_9_0:nodeByName("my_zhandouli_text"):getPositionX() + arg_9_0:nodeByName("my_zhandouli_text"):getContentSize().width + 10)

		local var_9_1 = arg_9_0.forceInfo.exceed_percent * 100
		local var_9_2 = math.floor(var_9_1)
		local var_9_3 = math.floor((var_9_1 - var_9_2) * 100)

		arg_9_0:nodeByName("rank_text1"):setString(var_0_1:translation("PARTNER_RANK_TIP1"))
		arg_9_0:nodeByName("rank_text2"):setString(var_0_1:translation("PARTNER_RANK_TIP2"))

		local var_9_4 = 0
		local var_9_5 = arg_9_0:nodeByName("my_own_container"):getChildByName("rank_pos")
		local var_9_6 = xyd.AssetLoader.get():loadLabel(nil, "bonus")

		var_9_6:setString(var_9_2)
		var_9_6:setPosition(cc.p(var_9_4, 10))
		var_9_6:setAnchorPoint(cc.p(0, 0.5))
		var_9_6:addTo(var_9_5)

		local var_9_7 = var_9_4 + var_9_6:getContentSize().width
		local var_9_8 = "windows/hero_recommend/hero_detail/point.png"

		pointIcon = xyd.AssetLoader.get():loadSprite(var_9_8)

		pointIcon:setAnchorPoint(cc.p(0, 0.5))
		pointIcon:addTo(var_9_5)
		pointIcon:setPosition(cc.p(var_9_7, 10))

		local var_9_9 = var_9_7 + pointIcon:getContentSize().width
		local var_9_10 = xyd.AssetLoader.get():loadLabel(nil, "bonus")

		var_9_10:setString(var_9_3)
		var_9_10:setPosition(cc.p(var_9_9, 10))
		var_9_10:setAnchorPoint(cc.p(0, 0.5))
		var_9_10:addTo(var_9_5)

		local var_9_11 = var_9_9 + var_9_10:getContentSize().width
		local var_9_12 = "windows/hero_recommend/hero_detail/percent.png"
		local var_9_13 = xyd.AssetLoader.get():loadSprite(var_9_12)

		var_9_13:setAnchorPoint(cc.p(0, 0.5))
		var_9_13:addTo(var_9_5)
		var_9_13:setPosition(cc.p(var_9_11, 10))

		local var_9_14 = var_9_11 + var_9_13:getContentSize().width

		arg_9_0:nodeByName("rank_text2"):setPositionX(var_9_5:getPositionX() + var_9_14 + 10)
	else
		arg_9_0:nodeByName("my_own_container"):setVisible(false)
		arg_9_0:nodeByName("not_have_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
			if arg_10_1 == ccui.TouchEventType.ended then
				local var_10_0 = arg_9_0.hero
				local var_10_1 = xyd.tables.hero:stoneID(var_10_0:getTableID())

				xyd.WindowManager.get():openWindow("stone", {
					hero = var_10_0,
					itemComposeID = var_10_1
				})
			end
		end)
	end
end

function var_0_0.setButtonClick(arg_11_0)
	arg_11_0:nodeByName("rank_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			local var_12_0 = {
				table_id = arg_11_0.tableId
			}

			arg_11_0.heroRecommend:getForceRankList(var_12_0, function(arg_13_0, arg_13_1)
				if arg_13_0 == xyd.error.OK then
					local var_13_0 = {
						hero = arg_11_0.hero,
						my_rank = arg_13_1.my_rank,
						rank_list = arg_13_1.rank_list
					}

					xyd.WindowManager.get():openWindow("hero_recommend_player_rank", var_13_0)
				end
			end)
		end
	end)
	arg_11_0:nodeByName("library_btn"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_11_0.heroRecommend:toTujianHeroDetail(arg_11_0.tableId)
		end
	end)
end

function var_0_0.getHeroContainer(arg_15_0)
	if not arg_15_0.heroContainer_ then
		arg_15_0.heroContainer_ = arg_15_0:nodeByName("hero_container")
	end

	return arg_15_0.heroContainer_
end

function var_0_0.setIsShow(arg_16_0)
	arg_16_0.isShow = false

	arg_16_0:getHeroModel():idle()
end

function var_0_0.resetModelState(arg_17_0)
	local var_17_0 = arg_17_0:getHeroModel()

	if arg_17_0.modelState == 8 then
		arg_17_0.modelState = arg_17_0.modelState + 1
	end

	arg_17_0.modelState = arg_17_0.modelState % 8
	arg_17_0.isShow = true

	local var_17_1

	if arg_17_0.modelState == xyd.ModelState.Walk then
		var_17_0:walk(true)

		arg_17_0.isShow = false
		var_17_1 = xyd.tables.model:getMoveSound(arg_17_0.hero:getModelID())
	elseif arg_17_0.modelState == xyd.ModelState.Win then
		var_17_0:win(false, handler(arg_17_0, arg_17_0.setIsShow))

		var_17_1 = xyd.tables.model:getWinSound(arg_17_0.hero:getModelID())
	elseif arg_17_0.modelState == xyd.ModelState.Attack1 then
		var_17_0:attack(1, nil, nil, handler(arg_17_0, arg_17_0.setIsShow))

		var_17_1 = xyd.tables.model:getNormalAttackSound(arg_17_0.hero:getModelID())
	elseif arg_17_0.modelState == xyd.ModelState.Attack2 then
		var_17_0:attack(2, nil, nil, handler(arg_17_0, arg_17_0.setIsShow))

		var_17_1 = xyd.tables.model:getAttack1Sound(arg_17_0.hero:getModelID())
	elseif arg_17_0.modelState == xyd.ModelState.Attack3 then
		var_17_0:attack(3, nil, nil, handler(arg_17_0, arg_17_0.setIsShow))

		var_17_1 = xyd.tables.model:getAttack2Sound(arg_17_0.hero:getModelID())
	elseif arg_17_0.modelState == xyd.ModelState.Attack4 then
		if not var_17_0:hasAnimation("gongji04") then
			arg_17_0.modelState = arg_17_0.modelState + 1

			arg_17_0:resetModelState()

			return
		end

		var_17_0:attack(4, nil, nil, handler(arg_17_0, arg_17_0.setIsShow))

		var_17_1 = xyd.tables.model:getAttack4Sound(arg_17_0.hero:getModelID())
	elseif arg_17_0.modelState == xyd.ModelState.Attack5 then
		if not var_17_0:hasAnimation("gongji05") then
			arg_17_0.modelState = arg_17_0.modelState + 1

			arg_17_0:resetModelState()

			return
		end

		var_17_0:attack(5, nil, nil, handler(arg_17_0, arg_17_0.setIsShow))

		var_17_1 = xyd.tables.model:getAttack4Sound(arg_17_0.hero:getModelID())
	else
		arg_17_0:setIsShow()
	end

	if var_17_1 and var_17_1 ~= "" then
		local var_17_2 = string.sub(var_17_1, #var_17_1 - 4, #var_17_1 - 4)
		local var_17_3 = xyd.tables.hero:getSoundDelayTime(arg_17_0.hero.tableID_, tonumber(var_17_2))

		arg_17_0.selfPlayer:playHeroSound(var_17_1, var_17_3)
	end

	arg_17_0.modelState = arg_17_0.modelState + 1
end

function var_0_0.getHeroModel(arg_18_0)
	if not arg_18_0.heroModel_ then
		arg_18_0.heroModel_ = arg_18_0.hero:getHeroModel()
	end

	return arg_18_0.heroModel_
end

function var_0_0.scrollListDelegate(arg_19_0, arg_19_1, arg_19_2, arg_19_3)
	if cc.ui.UIListView.COUNT_TAG == arg_19_2 then
		return arg_19_0:getListLen()
	elseif cc.ui.UIListView.CELL_TAG == arg_19_2 then
		local var_19_0
		local var_19_1 = arg_19_0.scrollList:dequeueItem()

		if not var_19_1 then
			var_19_1 = arg_19_0.scrollList:newItem()
		else
			var_19_1:removeAllChildren(true)
		end

		local var_19_2 = arg_19_0:createListContent(arg_19_3)
		local var_19_3 = var_19_2:getWidth()
		local var_19_4 = var_19_2:getHeight()

		var_19_1:setItemSize(var_19_3, var_19_4)
		var_19_1:addContent(var_19_2)

		return var_19_1
	end
end

function var_0_0.getListLen(arg_20_0)
	local var_20_0 = arg_20_0.info.recommend_formations[var_0_4]
	local var_20_1 = arg_20_0.info.recommend_formations[var_0_5]
	local var_20_2 = #table.keys(arg_20_0.info.recommend_formations)

	if var_20_0 then
		var_20_2 = var_20_2 + #var_20_0 - 1
	end

	if var_20_1 then
		var_20_2 = var_20_2 + #var_20_1 - 1
	end

	return var_20_2
end

function var_0_0.getKeyAndData(arg_21_0, arg_21_1)
	local var_21_0
	local var_21_1
	local var_21_2 = arg_21_0.info.recommend_formations[var_0_4]
	local var_21_3 = arg_21_0.info.recommend_formations[var_0_5]
	local var_21_4 = table.keys(arg_21_0.info.recommend_formations)
	local var_21_5 = 0

	for iter_21_0 = 1, #var_21_4 do
		if var_21_4[iter_21_0] == var_0_4 then
			for iter_21_1 = 1, #var_21_2 do
				var_21_5 = var_21_5 + 1

				if var_21_5 == arg_21_1 then
					return var_21_4[iter_21_0], var_21_2[iter_21_1]
				end
			end
		elseif var_21_4[iter_21_0] == var_0_5 then
			for iter_21_2 = 1, #var_21_3 do
				var_21_5 = var_21_5 + 1

				if var_21_5 == arg_21_1 then
					return var_21_4[iter_21_0], var_21_3[iter_21_2]
				end
			end
		else
			var_21_5 = var_21_5 + 1

			if var_21_5 == arg_21_1 then
				return var_21_4[iter_21_0], arg_21_0.info.recommend_formations[var_21_4[iter_21_0]]
			end
		end
	end
end

function var_0_0.createListContent(arg_22_0, arg_22_1)
	local var_22_0 = display.newNode()
	local var_22_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/hero_recommend/hero_detail/recommend_formation_item.csb")
	local var_22_2 = var_22_1:getChildByName("container")
	local var_22_3 = var_22_2:getChildByName("building_btn")
	local var_22_4 = var_22_2:getChildByName("formation_container")
	local var_22_5, var_22_6 = arg_22_0:getKeyAndData(arg_22_1)

	if not var_22_6.isUnfold then
		var_22_6.isUnfold = false

		var_22_4:setVisible(false)
		var_22_2:setContentSize(var_22_3:getContentSize().width, var_22_3:getContentSize().height)
	end

	local var_22_7 = var_22_3:getContentSize()
	local var_22_8 = xyd.tables.heroRecommendType:icon(tonumber(var_22_5))

	if var_22_8 ~= "" then
		local var_22_9 = xyd.AssetLoader.get():loadSprite(var_22_8)

		var_22_9:addTo(var_22_3)
		var_22_9:setPosition(cc.p(var_22_7.width / 2, var_22_7.height / 2))
		var_22_9:setScale(0.8)
	end

	local var_22_10 = xyd.tables.heroRecommendType:nameIcon2(tonumber(var_22_5))

	if var_22_10 ~= "" then
		local var_22_11 = xyd.AssetLoader.get():loadSprite(var_22_10)

		var_22_11:addTo(var_22_3)
		var_22_11:setPosition(cc.p(var_22_7.width / 2, var_22_7.height - 30))
	end

	if var_22_5 == var_0_4 or var_22_5 == var_0_5 then
		local var_22_12 = {
			font = "fonts/main_font.ttf",
			size = 24,
			color = cc.c3b(255, 138, 0)
		}
		local var_22_13 = xyd.AssetLoader.get():loadLabel(var_22_12)

		var_22_13:setAnchorPoint(cc.p(0.5, 0.5))

		if var_22_5 == var_0_4 then
			var_22_13:setString(xyd.tables.illusionCampaign:name(var_22_6.paradise_id))
		elseif var_22_5 == var_0_5 then
			var_22_13:setString(string.format(var_0_1:translation("NORMAL_CHAPTER"), tostring(var_22_6.chapter_id)))
		end

		var_22_13:addTo(var_22_3)
		var_22_13:setPosition(cc.p(var_22_3:getContentSize().width / 2, 65))
		var_22_13:enableOutline(cc.c4b(255, 255, 255, 255), 2)
	end

	local var_22_14

	if var_22_6.formation_rank <= 3 then
		var_22_14 = xyd.AssetLoader.get():loadSprite("windows/single_day/rank/" .. var_22_6.formation_rank .. ".png")
	else
		var_22_14 = xyd.AssetLoader.get():loadLabel(nil, "tacit_rank")

		var_22_14:setString(var_22_6.formation_rank)
		var_22_14:setAnchorPoint(cc.p(0.5, 0))
		var_22_14:setLocalZOrder(20)
	end

	var_22_14:setScale(0.7)
	var_22_14:addTo(var_22_3)
	var_22_14:setPosition(cc.p(var_22_3:getContentSize().width / 2, 30))

	local var_22_15 = 0
	local var_22_16 = 0
	local var_22_17 = 80

	for iter_22_0 = 1, #var_22_6.formation do
		local var_22_18 = display.newNode()

		var_22_18:setContentSize(60, 60)
		var_22_18:setAnchorPoint(cc.p(0, 0.5))
		var_22_18:addTo(var_22_4:getChildByName("formation_pos"))
		var_22_18:setPosition(cc.p(var_22_15, var_22_16))

		var_22_15 = var_22_15 + var_22_17

		local var_22_19 = var_0_2.new()

		if var_22_6.formation[iter_22_0] then
			var_22_19:populate(var_22_6.formation[iter_22_0])
			xyd.setAvatarBorderWithLevelAndHp(var_22_19, var_22_18)
			arg_22_0:addHeroTips(var_22_18, var_22_19)
		end
	end

	if var_22_6.pet_info then
		local var_22_20 = display.newNode()

		var_22_20:setContentSize(60, 60)
		var_22_20:setAnchorPoint(cc.p(0, 0.5))
		var_22_20:addTo(var_22_4:getChildByName("formation_pos"))
		var_22_20:setPosition(cc.p(var_22_15, var_22_16))

		local var_22_21 = var_22_15 + var_22_17
		local var_22_22 = var_0_3.new()

		var_22_22:initUnCollected(var_22_6.pet_info.table_id, nil, var_22_6.pet_info)
		xyd.setPetAvatar(var_22_20, var_22_22, 0, true, nil, 0.5)
		arg_22_0:addHeroTips(var_22_20, var_22_22)
	end

	xyd.setPlayerInfoContainer(var_22_4, var_22_6.player_info)

	local var_22_23 = var_22_6.player_info
	local var_22_24 = {
		avatar_id = var_22_23.avatar_id,
		avatar_frame_id = var_22_23.avatar_frame_id,
		playerInfo = var_22_23
	}

	var_22_4:getChildByName("avtar_container"):removeAllChildren()
	xyd.setPlayerAvatar(var_22_4:getChildByName("avtar_container"), var_22_24)
	var_22_4:getChildByName("region_txt"):setString("S" .. tostring(var_22_23.region))

	if var_22_23.guild_id and var_22_23.guild_id > 0 then
		var_22_4:getChildByName("guild_name"):setString(var_22_23.guild_name)
		var_22_4:getChildByName("guild_text"):setString(var_0_1:translation("GUILD") .. ":")
	else
		var_22_4:getChildByName("guild_name"):setVisible(false)
		var_22_4:getChildByName("guild_text"):setVisible(false)
	end

	var_22_3:setTouchEnabled(true)
	var_22_3:setTouchSwallowEnabled(false)
	var_22_3:addTouchEventListener(function(arg_23_0, arg_23_1)
		if arg_23_1 == ccui.TouchEventType.ended and not arg_22_0.scrollViewMoved_ then
			var_22_6.isUnfold = not var_22_6.isUnfold

			arg_22_0:setOrgPositonX()
			arg_22_0.scrollList:reload()
			arg_22_0:scrollToOrgPositonX()
		end
	end)
	var_22_4:getChildByName("fold_btn"):addTouchEventListener(function(arg_24_0, arg_24_1)
		if arg_24_1 == ccui.TouchEventType.ended and not arg_22_0.scrollViewMoved_ then
			var_22_6.isUnfold = false

			arg_22_0:setOrgPositonX()
			arg_22_0.scrollList:reload()
			arg_22_0:scrollToOrgPositonX()
		end
	end)
	var_22_1:addTo(var_22_0)
	var_22_1:setAnchorPoint(cc.p(0, 0))
	var_22_0:setContentSize(var_22_2:getContentSize())
	var_22_1:setName("source")

	return var_22_0
end

function var_0_0.setOrgPositonX(arg_25_0)
	arg_25_0.orgPositonX = arg_25_0.scrollList:getScrollNode():getPositionX()
end

function var_0_0.scrollToOrgPositonX(arg_26_0)
	arg_26_0.scrollList:getScrollNode():setPositionX(arg_26_0.orgPositonX)

	arg_26_0.orgPositonX = nil
end

function var_0_0.scrollListener(arg_27_0, arg_27_1)
	if arg_27_1.name == "began" then
		arg_27_0.scrollViewMoved_ = false
		arg_27_0.prevX_ = arg_27_1.x
	elseif arg_27_1.name == "moved" and 5 <= math.abs(arg_27_1.x - arg_27_0.prevX_) then
		arg_27_0.scrollViewMoved_ = true
	end
end

return var_0_0
