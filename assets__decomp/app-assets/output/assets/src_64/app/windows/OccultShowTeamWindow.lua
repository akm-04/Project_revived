local var_0_0 = class("OccultShowTeamWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("app.model.Pet")
local var_0_2 = import("app.model.Hero")
local var_0_3 = xyd.tables.translation
local var_0_4 = import("app.common.ui.SpineEffect")
local var_0_5 = 3
local var_0_6 = 160

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.occult = xyd.ModelManager.get():loadModel(xyd.ModelType.OCCULT)
	arg_1_0.teamInviteInfos = arg_1_0.occult.teamInviteInfos
	arg_1_0.campaignId = arg_1_0.teamInviteInfos.campaign_id
	arg_1_0.subId = arg_1_0.teamInviteInfos.sub_id
	arg_1_0.battleID = xyd.tables.creatsCampaign:getFightId(arg_1_0.campaignId, arg_1_0.subId)
	arg_1_0.heroItems_ = {}
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)
	arg_2_0:addTopSidebar()
	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:setButtonClick()
	arg_3_0:updateHeros()
	arg_3_0:showChatWin()
	arg_3_0:nodeByName("word_prepare"):setString(var_0_3:translation("PARADISE_TEXT_1"))
	arg_3_0:nodeByName("word_cancel"):setString(var_0_3:translation("CANCEL"))

	local var_3_0 = xyd.tables.creatsChapterSelect:cooperateMap(arg_3_0.occult.baseInfo.chapter_id)
	local var_3_1 = xyd.SpriteLoader.new(var_3_0, nil, nil, xyd.DefaultImageType.MAP)

	var_3_1:setAnchorPoint(cc.p(0.5, 0.5))
	var_3_1:addTo(arg_3_0:nodeByName("background"), -1)

	local var_3_2 = arg_3_0:nodeByName("background"):getContentSize()

	var_3_1:setPosition(cc.p(var_3_2.width / 2, var_3_2.height / 2))
	arg_3_0:updateRedMark(false)
end

function var_0_0.setButtonClick(arg_4_0)
	local function var_4_0()
		if arg_4_0.occult.teamFightInfos[tostring(arg_4_0.selfPlayer.playerID)].is_prepare == 1 then
			arg_4_0:nodeByName("btn_prepare"):getChildByName("word_cancel"):setVisible(true)
			arg_4_0:nodeByName("btn_prepare"):getChildByName("word_prepare"):setVisible(false)

			arg_4_0.isPrepare = true
		else
			arg_4_0.isPrepare = false

			arg_4_0:nodeByName("btn_prepare"):getChildByName("word_cancel"):setVisible(false)
			arg_4_0:nodeByName("btn_prepare"):getChildByName("word_prepare"):setVisible(true)
		end
	end

	var_4_0()
	arg_4_0:nodeByName("word_prepare"):setString(var_0_3:translation("PARADISE_TEXT_1"))
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_prepare"), nil, function()
		xyd.playButtonSound()

		local var_6_0 = arg_4_0.occult.teamFightInfos[tostring(arg_4_0.selfPlayer.playerID)]

		if var_6_0.is_prepare == 0 then
			if arg_4_0:checkCanPrepareFight() then
				local var_6_1 = {
					campaign_id = arg_4_0.campaignId,
					sub_id = arg_4_0.subId
				}

				arg_4_0.occult:prepareTeamFight(var_6_1, function(arg_7_0, arg_7_1)
					if arg_7_0 == xyd.error.OK then
						var_6_0.is_prepare = 1

						var_4_0()
					end
				end)
			else
				local var_6_2 = var_0_3:translation("CREATS_TIPS_19")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_6_2
				})
			end
		else
			local var_6_3 = {
				campaign_id = arg_4_0.campaignId,
				sub_id = arg_4_0.subId
			}

			arg_4_0.occult:prepareTeamFight(var_6_3, function(arg_8_0, arg_8_1)
				if arg_8_0 == xyd.error.OK then
					var_6_0.is_prepare = 0

					var_4_0()
				end
			end)
		end
	end)
	xyd.nodeEventSample(arg_4_0:nodeByName("btn_fight"), nil, function()
		xyd.playButtonSound()

		if arg_4_0:checkIsMaster() and arg_4_0:checkCanFight() then
			local var_9_0 = {
				campaign_id = arg_4_0.campaignId,
				sub_id = arg_4_0.subId
			}

			arg_4_0.occult:teamFight(var_9_0, function(arg_10_0, arg_10_1)
				if arg_10_0 == xyd.error.OK then
					arg_4_0:playReport(arg_10_1)
				end
			end)
		else
			local var_9_1 = var_0_3:translation("ILLUSION_TEAM_TIPS_16")

			xyd.WindowManager.get():openWindow("toast", {
				message = var_9_1
			})
		end
	end)

	for iter_4_0 = 1, 3 do
		arg_4_0:nodeByName("bottom_item_" .. iter_4_0):setTouchEnabled(true)
		arg_4_0:nodeByName("bottom_item_" .. iter_4_0):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_11_0)
			if arg_11_0.name == "began" then
				arg_4_0:nodeByName("bottom_item_" .. iter_4_0):getChildByName("img_add_" .. iter_4_0):setScale(0.9)

				return true
			elseif arg_11_0.name == "ended" and not arg_4_0.isPrepare then
				xyd.playButtonSound()
				arg_4_0:nodeByName("bottom_item_" .. iter_4_0):getChildByName("img_add_" .. iter_4_0):setScale(1)

				local var_11_0 = {
					index = iter_4_0,
					isPet = iter_4_0 == 3 and true or false
				}

				xyd.WindowManager.get():openWindow("occult_select_hero", var_11_0)
			end
		end)
	end

	if arg_4_0:checkIsMaster() then
		arg_4_0:nodeByName("bottom_item_2"):setVisible(false)
	else
		arg_4_0:nodeByName("bottom_item_3"):setVisible(false)
		arg_4_0:nodeByName("btn_fight"):setVisible(false)
		arg_4_0:nodeByName("btn_prepare"):runAction(cc.MoveBy:create(0, cc.p(-35, 0)))
	end

	arg_4_0:nodeByName("img_chat"):setTouchEnabled(true)
	arg_4_0:nodeByName("img_chat"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
		if arg_12_0.name == "began" then
			arg_4_0:nodeByName("img_chat"):setScale(0.9)

			return true
		elseif arg_12_0.name == "ended" then
			arg_4_0:nodeByName("img_chat"):setScale(1)
			arg_4_0:showChatWin()
			arg_4_0:updateRedMark(false)
		end
	end)
	arg_4_0:nodeByName("top_sidebar"):nodeByName("return_btn"):addTouchEvent(function(arg_13_0)
		if arg_13_0.name == "ended" then
			xyd.playButtonSound()
			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_0_3:translation("OCCULT_QUIT_COMPANION_TIP"), function()
				local var_14_0 = {
					campaign_id = arg_4_0.campaignId,
					sub_id = arg_4_0.subId
				}

				arg_4_0.occult:quitTeamFight(var_14_0, function(arg_15_0, arg_15_1)
					xyd.WindowManager.get():closeWindow(arg_4_0)
				end)
			end, nil, nil, arg_4_0.colorMode)
		end
	end)
end

function var_0_0.updateHeros(arg_16_0)
	local var_16_0 = arg_16_0.occult.teamFightInfos[tostring(arg_16_0.selfPlayer.playerID)]

	for iter_16_0 = 1, #(var_16_0.formation or {}) do
		local var_16_1 = var_16_0.formation[iter_16_0]

		if var_16_1 and var_16_1.table_id and var_16_1.table_id ~= 0 then
			local var_16_2 = var_0_2.new()

			var_16_2:populate(var_16_1)
			arg_16_0:updateHeroSelect(iter_16_0, var_16_2)
		end
	end

	if arg_16_0:checkIsMaster() then
		petInfo = var_16_0.pet

		if petInfo and petInfo.table_id and petInfo.table_id ~= 0 then
			local var_16_3 = var_0_1.new()

			var_16_3:populate(petInfo)
			arg_16_0:updateHeroSelect(3, var_16_3)
		end
	end

	arg_16_0:updateHeroList()
end

function var_0_0.updateHeroSelect(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = arg_17_0:nodeByName("bottom_item_" .. arg_17_1)

	if arg_17_2 then
		var_17_0:getChildByName("img_add_" .. arg_17_1):setVisible(false)
	end

	var_17_0:getChildByName("hero_" .. arg_17_1):removeAllChildren(true)

	if arg_17_1 == 3 then
		xyd.setPetAvatar(var_17_0:getChildByName("hero_" .. arg_17_1), arg_17_2, nil, true)
	else
		xyd.setAvatarBorderNewUI(arg_17_2, var_17_0:getChildByName("hero_" .. arg_17_1))
	end
end

function var_0_0.checkIsMaster(arg_18_0)
	return arg_18_0.occult:checkIsFightStarter(arg_18_0.selfPlayer.playerID)
end

function var_0_0.updateHeroList(arg_19_0)
	arg_19_0.members = {}

	local var_19_0 = arg_19_0.occult.roomInfo.members

	for iter_19_0 = 1, #var_19_0 do
		if arg_19_0.occult:checkIsFightStarter(var_19_0[iter_19_0]) then
			table.insert(arg_19_0.members, 1, var_19_0[iter_19_0])
		else
			table.insert(arg_19_0.members, var_19_0[iter_19_0])
		end
	end

	for iter_19_1 = 1, 6 do
		if iter_19_1 == 1 then
			arg_19_0:createPet(iter_19_1)
		else
			arg_19_0:createHero(iter_19_1)
		end
	end
end

function var_0_0.createPet(arg_20_0, arg_20_1)
	local var_20_0 = arg_20_0.members[math.ceil(arg_20_1 / 2)]
	local var_20_1 = arg_20_0.occult.teamFightInfos[tostring(var_20_0)]
	local var_20_2 = var_20_1.pet or {}
	local var_20_3 = arg_20_0.heroItems_[arg_20_1]

	if not var_20_3 or tolua.isnull(var_20_3) then
		var_20_3 = display.newNode()

		var_20_3:setContentSize(var_0_6, var_0_6)
		var_20_3:setAnchorPoint(cc.p(0, 0))
		var_20_3:addTo(arg_20_0:nodeByName("hero_list"))
		var_20_3:setPosition(cc.p(0, 0))

		arg_20_0.heroItems_[arg_20_1] = var_20_3
	end

	if var_20_3.data and next(var_20_2) and var_20_3.data:getTableID() == var_20_2.table_id then
		if var_20_1.is_prepare ~= var_20_3.status then
			var_20_3.status = var_20_1.is_prepare

			arg_20_0:updateHeroItemPrepare(var_20_3)
		end

		return
	elseif not var_20_2 or not next(var_20_2) then
		arg_20_0.havePet = false

		return
	end

	local var_20_4 = var_0_1.new()

	var_20_4:populate(var_20_2)

	var_20_3.data = var_20_4
	var_20_3.status = var_20_1.is_prepare
	var_20_3.playerInfo = arg_20_0.occult:getPlayerInfoByID(var_20_0)

	local var_20_5 = (var_20_3.count or 0) + 1

	var_20_3.count = var_20_5

	local var_20_6 = var_20_4:getHeroModel()

	var_20_6:setScale(0.75)
	var_20_6:addTo(var_20_3)
	var_20_6:setName("count_" .. var_20_5)
	var_20_6:setPosition(cc.p(var_0_6 / 2, 0))
	var_20_6:setVisible(false)

	arg_20_0.havePet = true

	arg_20_0:updateHeroItemPrepare(var_20_3)
	arg_20_0:addClickEvent(var_20_3)

	if var_20_5 ~= 1 then
		var_20_3:removeChildByName("count_" .. var_20_5 - 1)

		if var_20_3:getChildByName("effect") then
			var_20_3:removeChildByName("effect")
		end
	end

	arg_20_0:showSummonEffcet(var_20_3, function()
		if arg_20_0 and not tolua.isnull(arg_20_0) then
			var_20_6:setVisible(true)
		end
	end)
end

function var_0_0.teamFight(arg_22_0, arg_22_1)
	local var_22_0 = {
		campaign_id = arg_22_0.campaignId,
		sub_id = arg_22_0.subId,
		report_key = arg_22_1
	}

	arg_22_0.occult:getTeamFightReport(var_22_0, function(arg_23_0, arg_23_1)
		if arg_23_0 == xyd.error.OK then
			arg_22_0:playReport(arg_23_1, true)
			xyd.WindowManager.get():closeWindow(arg_22_0)
		end
	end)
end

function var_0_0.createHero(arg_24_0, arg_24_1)
	local var_24_0 = arg_24_0.members[math.ceil(arg_24_1 / 2)]
	local var_24_1 = arg_24_0.occult.teamFightInfos[tostring(var_24_0)]
	local var_24_2

	if not var_24_1.formation then
		var_24_2 = nil
	elseif arg_24_1 == 2 or arg_24_1 == 3 or arg_24_1 == 5 then
		var_24_2 = var_24_1.formation[1]
	elseif arg_24_1 == 4 or arg_24_1 == 6 then
		var_24_2 = var_24_1.formation[2]
	end

	local var_24_3 = arg_24_0.heroItems_[arg_24_1]

	if not var_24_3 or tolua.isnull(var_24_3) then
		var_24_3 = display.newNode()

		var_24_3:setContentSize(var_0_6, var_0_6)
		var_24_3:setAnchorPoint(cc.p(0, 0))
		var_24_3:addTo(arg_24_0:nodeByName("hero_list"))
		var_24_3:setPosition(cc.p((var_0_6 + 20) * (arg_24_1 - 1), 0))

		arg_24_0.heroItems_[arg_24_1] = var_24_3
	end

	if var_24_3.data and var_24_2 and next(var_24_2) and var_24_3.data:getTableID() == var_24_2.table_id then
		if var_24_3.status ~= var_24_1.is_prepare then
			var_24_3.status = var_24_1.is_prepare

			arg_24_0:updateHeroItemPrepare(var_24_3)
		end

		return
	elseif not var_24_2 or not next(var_24_2) or var_24_2.table_id == 0 then
		return
	end

	local var_24_4 = var_0_2.new()

	var_24_4:populate(var_24_2)

	var_24_3.data = var_24_4
	var_24_3.playerInfo = arg_24_0.occult:getPlayerInfoByID(var_24_0)
	var_24_3.status = var_24_1.is_prepare

	local var_24_5 = (var_24_3.count or 0) + 1

	var_24_3.count = var_24_5

	local var_24_6 = var_24_4:getHeroModel()

	var_24_6:setScale(0.75)
	var_24_6:addTo(var_24_3)
	var_24_6:setPosition(cc.p(var_0_6 / 2, 0))
	var_24_6:setName("count_" .. var_24_5)
	var_24_6:setVisible(false)
	arg_24_0:updateHeroItemPrepare(var_24_3)
	arg_24_0:addClickEvent(var_24_3)

	if var_24_5 ~= 1 then
		var_24_3:removeChildByName("count_" .. var_24_5 - 1)

		if var_24_3:getChildByName("effect") then
			var_24_3:removeChildByName("effect")
		end
	end

	arg_24_0:showSummonEffcet(var_24_3, function()
		if arg_24_0 and not tolua.isnull(arg_24_0) then
			var_24_6:setVisible(true)
		end
	end)
end

function var_0_0.showSummonEffcet(arg_26_0, arg_26_1, arg_26_2)
	local var_26_0 = "skeletons/ui_effect/effect_summon/effect_summon"
	local var_26_1 = arg_26_1:getContentSize()
	local var_26_2 = var_0_4.new(var_26_0 .. ".json", var_26_0 .. ".atlas", 1)

	var_26_2:addTo(arg_26_1)
	var_26_2:setPosition(cc.p(var_26_1.width / 2, 0))
	var_26_2:setName("effect")
	var_26_2:play(function()
		if arg_26_2 then
			arg_26_2()
		end
	end, false)
end

function var_0_0.updateHeroItemPrepare(arg_28_0, arg_28_1)
	local var_28_0 = arg_28_1.status == 1 and true or false

	if not arg_28_1:getChildByName("hero_prepare") then
		local var_28_1 = {
			size = 24,
			color = cc.c3b(255, 233, 50)
		}
		local var_28_2 = xyd.AssetLoader.get():loadLabel(var_28_1)

		var_28_2:setString(var_0_3:translation("PARADISE_TEXT_2"))
		var_28_2:setAnchorPoint(cc.p(0.5, 0.5))
		var_28_2:enableOutline(cc.c4b(65, 74, 84, 255), 2)
		var_28_2:addTo(arg_28_1)
		var_28_2:setPosition(cc.p(var_0_6 / 2, var_0_6 + 100))
		var_28_2:setName("hero_prepare")
		var_28_2:setLocalZOrder(100)
	end

	arg_28_1:getChildByName("hero_prepare"):setVisible(var_28_0)
end

function var_0_0.checkCanFight(arg_29_0)
	local var_29_0 = arg_29_0.occult.roomInfo.members

	for iter_29_0 = 1, #var_29_0 do
		if arg_29_0.occult.teamFightInfos[tostring(var_29_0[iter_29_0])].is_prepare == 0 then
			return false
		end
	end

	return true
end

function var_0_0.checkCanPrepareFight(arg_30_0)
	local var_30_0 = arg_30_0.occult.teamFightInfos[tostring(arg_30_0.selfPlayer.playerID)]
	local var_30_1 = #(var_30_0.formation or {})

	if (var_30_1 + (var_30_0.pet and 1 or 0) >= 2 or arg_30_0.occult:checkIsDispatchFull()) and var_30_1 >= 1 then
		return true
	end

	return false
end

function var_0_0.showChatWin(arg_31_0)
	if arg_31_0.chatWinIsShow then
		arg_31_0.chatWinIsShow = false

		arg_31_0:playChatWinMove(arg_31_0.chatWinIsShow)

		return
	elseif arg_31_0.chatIsInit then
		arg_31_0.chatWinIsShow = true

		arg_31_0:playChatWinMove(arg_31_0.chatWinIsShow)

		return
	end

	local var_31_0 = arg_31_0:nodeByName("chat_container")

	var_31_0:setTouchSwallowEnabled(true)
	var_31_0:removeAllChildren()

	local var_31_1 = arg_31_0.occult:getChatWindow("occult_show_team")

	var_31_1:addTo(var_31_0)
	var_31_1:setPosition(cc.p(0, 0))
	var_31_1:setName("chat_wnd")
	var_31_0:setVisible(false)

	arg_31_0.chatIsInit = true
	arg_31_0.chatWinIsShow = false

	var_31_1:updateList()
end

function var_0_0.updateRedMark(arg_32_0, arg_32_1)
	if arg_32_0.chatWinIsShow then
		arg_32_0:nodeByName("red_p"):setVisible(false)
	else
		arg_32_0:nodeByName("red_p"):setVisible(arg_32_1)
	end
end

function var_0_0.playChatWinMove(arg_33_0, arg_33_1)
	local var_33_0 = arg_33_0:nodeByName("chat_container")
	local var_33_1 = var_33_0:getContentSize()
	local var_33_2 = cc.p(arg_33_0:nodeByName("img_chat"):getPosition())

	if arg_33_1 then
		var_33_0:setPosition(cc.p(-var_33_1.width, 0))
		var_33_0:setVisible(true)
		transition.moveTo(var_33_0, {
			time = 0.3,
			x = 0,
			y = 0
		})
		transition.moveTo(arg_33_0:nodeByName("img_chat"), {
			time = 0.3,
			x = var_33_2.x + var_33_1.width,
			y = var_33_2.y
		})
	else
		transition.moveTo(var_33_0, {
			time = 0.3,
			y = 0,
			x = -var_33_1.width
		})
		transition.moveTo(arg_33_0:nodeByName("img_chat"), {
			time = 0.3,
			x = var_33_2.x - var_33_1.width,
			y = var_33_2.y
		})
	end
end

function var_0_0.addClickEvent(arg_34_0, arg_34_1)
	arg_34_1:setTouchEnabled(true)
	arg_34_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_35_0)
		if arg_35_0.name == "began" then
			arg_34_0:showHeroDetail(arg_34_1, true)

			arg_34_0.preX_ = arg_35_0.x
			arg_34_0.preY_ = arg_35_0.y
			arg_34_0.isScrollMove = false

			return true
		elseif arg_35_0.name == "moved" then
			if math.abs(arg_34_0.preX_ - arg_35_0.x) >= 20 or math.abs(arg_34_0.preY_ - arg_35_0.y) >= 20 then
				arg_34_0.isScrollMove = true

				arg_34_0:showHeroDetail(arg_34_1, false)
			end

			return true
		elseif arg_35_0.name == "ended" and not arg_34_0.isScrollMove then
			arg_34_0:showHeroDetail(arg_34_1, false)
		end
	end)
end

function var_0_0.showHeroDetail(arg_36_0, arg_36_1, arg_36_2)
	if not arg_36_2 and arg_36_0.heroDetailWnd and not tolua.isnull(arg_36_0.heroDetailWnd) then
		arg_36_0.heroDetailWnd:setVisible(false)

		return
	end

	if not arg_36_1.data then
		return
	end

	if not arg_36_0.heroDetailWnd or tolua.isnull(arg_36_0.heroDetailWnd) then
		local var_36_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/illusion/cooperation_new/hero_detail.csb")

		var_36_0:addTo(arg_36_0:nodeByName("hero_list"))

		arg_36_0.heroDetailWnd = var_36_0
	end

	local var_36_1 = cc.p(arg_36_1:getPosition())

	arg_36_0.heroDetailWnd:setPosition(cc.p(var_36_1.x - var_0_6 / 2, var_0_6 + 100))

	local var_36_2 = arg_36_0.heroDetailWnd:getChildByName("container")
	local var_36_3 = arg_36_1.data
	local var_36_4 = arg_36_1.playerInfo

	var_36_2:getChildByName("hero"):removeAllChildren()
	xyd.setAvatarBorderNewUI(var_36_3, var_36_2:getChildByName("hero"))
	var_36_2:getChildByName("text_name"):setString(var_36_3:getName())
	var_36_2:getChildByName("text_zhandouli"):setString(var_0_3:translation("HERO_INFO_ZHANDOULI") .. var_36_3:getZhandouli())
	var_36_2:getChildByName("text_player_name"):setString(var_0_3:translation("ILLUSION_TEAM_TIPS_15") .. var_36_4.player_name)
	var_36_2:getChildByName("text_hero_tips"):setString(var_36_3:getDes())
	arg_36_0.heroDetailWnd:setVisible(true)
end

function var_0_0.playReport(arg_37_0, arg_37_1, arg_37_2)
	if arg_37_1 == nil then
		return
	end

	if not arg_37_0 or tolua.isnull(arg_37_0) then
		return
	end

	local var_37_0 = clone(arg_37_0.occult.dispatchInfo)

	if arg_37_1 then
		arg_37_0.occult:handleResponse(arg_37_1)
	end

	local var_37_1 = {}
	local var_37_2

	if arg_37_2 then
		var_37_2 = json.decode(arg_37_1.battle_report[1].report)
	else
		var_37_2 = json.decode(arg_37_1.battle_report)
	end

	var_37_1.herosA = {}
	var_37_1.herosB = {}
	var_37_1.summonMonsters = {}
	var_37_1.campaignType = xyd.CampaignType.OCCULT_COOPERATION
	var_37_1.battleID = arg_37_0.battleID
	var_37_1.battleType = xyd.BattleType.ReplayReport
	ngx.ctx.battle.reportData = var_37_2

	local var_37_3 = {}
	local var_37_4 = {}

	for iter_37_0, iter_37_1 in pairs(ngx.ctx.battle.reportData.fighter) do
		local var_37_5 = string.sub(iter_37_0, 1, 1)
		local var_37_6 = tonumber(string.sub(iter_37_0, 3, 3))

		if var_37_5 == "A" and tonumber(iter_37_1.summon_type) == xyd.summonMonsterType.None then
			local var_37_7 = var_0_2.new()

			var_37_7:populate(iter_37_1.hero)
			var_37_7:setReportData(iter_37_1)

			var_37_7.healthStatus = arg_37_0:getHeroStatus(var_37_7)

			if isOnlyData then
				var_37_7.harms = iter_37_1.harms
				var_37_7.willDie = (iter_37_1.die_count or 0) ~= -1
			end

			var_37_1.herosA[var_37_6] = var_37_7
		elseif var_37_5 == "A" and tonumber(iter_37_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_37_8 = var_0_1.new()

			var_37_8:populate(iter_37_1.hero)
			var_37_8:setReportData(iter_37_1)

			if isOnlyData then
				var_37_8.harms = iter_37_1.harms
				var_37_8.willDie = (iter_37_1.die_count or 0) ~= -1
				var_37_1.petA = {
					var_37_8
				}
			else
				var_37_1.petsA = {
					var_37_8
				}
			end
		elseif var_37_5 == "B" and tonumber(iter_37_1.summon_type) == xyd.summonMonsterType.None then
			local var_37_9 = var_0_2.new()

			var_37_9:populate(iter_37_1.hero)
			var_37_9:setReportData(iter_37_1)

			if isOnlyData then
				var_37_9.harms = iter_37_1.harms
				var_37_9.willDie = (iter_37_1.die_count or 0) ~= -1
				var_37_9.healthStatus = var_37_9.health_status
				var_37_1.herosB[var_37_6] = var_37_9
			else
				var_37_3[var_37_6] = var_37_9
			end
		elseif var_37_5 == "B" and tonumber(iter_37_1.summon_type) == xyd.summonMonsterType.Pet then
			local var_37_10 = var_0_1.new()

			var_37_10:populate(iter_37_1.hero)
			var_37_10:setReportData(iter_37_1)

			if isOnlyData then
				var_37_10.harms = iter_37_1.harms
				var_37_10.willDie = (iter_37_1.die_count or 0) ~= -1
				var_37_1.petB = {
					var_37_10
				}
			else
				var_37_1.petsB = {
					var_37_10
				}
			end
		elseif var_37_5 == "C" then
			local var_37_11 = var_0_2.new()

			var_37_11:populate(iter_37_1.hero)
			var_37_11:setReportData(iter_37_1)

			if not isOnlyData then
				sceneFighter = var_37_11
			end
		elseif tonumber(iter_37_1.summon_type) ~= xyd.summonMonsterType.None and tonumber(iter_37_1.summon_type) ~= xyd.summonMonsterType.Pet then
			local var_37_12 = var_0_2.new()

			var_37_12:populate(iter_37_1.hero)
			var_37_12:setReportData(iter_37_1)

			var_37_4[iter_37_0] = var_37_12
		end
	end

	var_37_1.herosB = {
		var_37_3
	}
	var_37_1.sceneFighter = sceneFighter
	var_37_1.summonMonsters = var_37_4
	var_37_1.reportStar = tonumber(var_37_2.star)

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_RESTORE_WINDOW,
		params = {
			window = "occult_sub_map"
		}
	})
	xyd.WindowManager.get():retainHistory()
	xyd.pushBattleScene(var_37_1)
end

function var_0_0.getHeroStatus(arg_38_0, arg_38_1)
	local var_38_0 = arg_38_1:getTableID()
	local var_38_1 = arg_38_0.occult.roomInfo.members

	for iter_38_0 = 1, #var_38_1 do
		local var_38_2 = arg_38_0.occult.teamFightInfos[tostring(var_38_1[iter_38_0])].formation

		for iter_38_1 = 1, #(var_38_2 or {}) do
			if var_38_2[iter_38_1].table_id == var_38_0 and var_38_2[iter_38_1].hero_detail and var_38_2[iter_38_1].hero_detail.hp then
				return var_38_2[iter_38_1].hero_detail
			end
		end
	end
end

return var_0_0
