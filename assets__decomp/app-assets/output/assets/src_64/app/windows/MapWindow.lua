local var_0_0 = class("MapWindow", import("app.common.ui.BaseWindow"))

var_0_0.MAP_PANEL = "map_panel"
var_0_0.LEFT = "left"
var_0_0.RIGHT = "right"
var_0_0.NORMAL = "normal"
var_0_0.SUPER = "super"
var_0_0.IMG_NAME = "chapter_name_pos"
var_0_0.BONUS_BUTTON = "bonus_button"

local var_0_1 = "skeletons/ui_effect/campaign_map/reward_disappear"
local var_0_2 = "skeletons/ui_effect/campaign_map/reward_hint"
local var_0_3 = "skeletons/ui_effect/chapter_event/guide_small_egg"
local var_0_4 = "skeletons/ui_effect/chapter_event/hide_boss01"
local var_0_5 = 1
local var_0_6 = 1
local var_0_7 = 2
local var_0_8 = 3
local var_0_9 = 24111
local var_0_10 = require("framework.scheduler")
local var_0_11 = xyd.tables.translation
local var_0_12 = {
	Boss = 2,
	Gacha = 1
}
local var_0_13 = {
	CHALLENGE = 4,
	GUILD = 3,
	NORMAL = 1,
	SUPER = 2
}
local var_0_14 = {
	[xyd.CampaignType.NORMAL] = var_0_13.NORMAL,
	[xyd.CampaignType.SUPER] = var_0_13.SUPER,
	[xyd.CampaignType.GUILD] = var_0_13.GUILD,
	[xyd.CampaignType.CHALLENGE] = var_0_13.CHALLENGE
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_2 = arg_1_2 or {}

	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.params = arg_1_2
	arg_1_0.chapterType = arg_1_2.chapter_type or xyd.CampaignType.NORMAL
	arg_1_0.newFuncIDs = arg_1_2.newFuncIDs
	arg_1_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.teamCampaigns = arg_1_2.teamCampaigns or arg_1_0.guild:getGuildCampaigns()
	arg_1_0.teamCampaignList = arg_1_2.teamCampaignList or arg_1_0.guild:getGuildCampaignList()
	arg_1_0.guildChapter = arg_1_2.guildChapter
	arg_1_0.delay1 = 1
	arg_1_0.btn_can_push = true
	arg_1_0.canClickCampaign = true

	if arg_1_2.isStoneCampaign then
		arg_1_0.isStoneCampaign = true
		arg_1_0.stoneChapter = arg_1_2.chapter
		arg_1_0.stoneCampaignID = arg_1_2.campaignID
		arg_1_0.chapterType = arg_1_2.campaignType
		arg_1_0.itemComposeID = arg_1_2.itemComposeID
		arg_1_0.needItemComposeNum = arg_1_2.needItemComposeNum
		arg_1_2.isStoneCampaign = false
	else
		arg_1_0.isStoneCampaign = false
	end

	arg_1_0.teamChapterList = arg_1_0.guild:getGuildChapterList()
	arg_1_0.canClick = true

	if arg_1_0.chapterType == xyd.CampaignType.GUILD then
		var_0_5 = arg_1_0.guild:getMinchapterID()
	else
		var_0_5 = 1
	end
end

function var_0_0.onGuildFightNotice_(arg_2_0, arg_2_1)
	if not arg_2_1.params.chapter_id == arg_2_0.currentTeamChapter then
		return
	end

	xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD):loadGuildMap(function(arg_3_0)
		if arg_3_0 == xyd.error.OK then
			local var_3_0 = xyd.WindowManager.get():getWindow("map_window")

			if var_3_0 then
				var_3_0:updateGuildMap()
			end
		end
	end)
end

function var_0_0.updateGuildMap(arg_4_0)
	arg_4_0.teamCampaigns = arg_4_0.guild:getGuildCampaigns()
	arg_4_0.teamCampaignList = arg_4_0.guild:getGuildCampaignList()
	arg_4_0.teamChapterList = arg_4_0.guild:getGuildChapterList()

	arg_4_0:updateChapter()
end

function var_0_0.initComponents(arg_5_0)
	arg_5_0.mapPanel = arg_5_0:nodeByName(var_0_0.MAP_PANEL)
	arg_5_0.imgName = arg_5_0:nodeByName(var_0_0.IMG_NAME)
	arg_5_0.normalButton = arg_5_0:nodeByName(var_0_0.NORMAL)
	arg_5_0.superButton = arg_5_0:nodeByName(var_0_0.SUPER)
	arg_5_0.teamButton = arg_5_0:nodeByName("guild")
	arg_5_0.challengeButton = arg_5_0:nodeByName("challenge")
	arg_5_0.bonusButton = arg_5_0:nodeByName(var_0_0.BONUS_BUTTON)
	arg_5_0.arrow = xyd.AssetLoader.get():loadSprite("windows/map_window/new/down_arrow.png")

	arg_5_0.arrow:setTouchEnabled(false)
	arg_5_0:addChild(arg_5_0.arrow)

	arg_5_0.left = arg_5_0:nodeByName(var_0_0.LEFT)
	arg_5_0.right = arg_5_0:nodeByName(var_0_0.RIGHT)

	arg_5_0:nodeByName("bonus_txt"):enableShadow(cc.c4b(11, 11, 11, 150), cc.size(1, -1), 1)
	arg_5_0:nodeByName("bonus"):setVisible(false)

	arg_5_0.clippingNode = display.newClippingRegionNode()

	arg_5_0.clippingNode:setClippingRegion(cc.rect(0, 0, arg_5_0.mapPanel:getContentSize().width, arg_5_0.mapPanel:getContentSize().height))
	arg_5_0.mapPanel:addChild(arg_5_0.clippingNode)
	arg_5_0.mapPanel:setTouchSwallowEnabled(true)

	arg_5_0.mapPanelWidth = arg_5_0.mapPanel:getContentSize().width
end

function var_0_0.createLeftAndRightArrowAction(arg_6_0)
	local var_6_0, var_6_1 = arg_6_0.left:getPosition()
	local var_6_2 = transition.sequence({
		cc.MoveTo:create(1, cc.p(var_6_0 + 10, var_6_1)),
		cc.MoveTo:create(1, cc.p(var_6_0, var_6_1))
	})
	local var_6_3 = cc.RepeatForever:create(var_6_2)

	arg_6_0.left:runAction(var_6_3)

	local var_6_4, var_6_5 = arg_6_0.right:getPosition()
	local var_6_6 = transition.sequence({
		cc.MoveTo:create(1, cc.p(var_6_4 - 10, var_6_5)),
		cc.MoveTo:create(1, cc.p(var_6_4, var_6_5))
	})
	local var_6_7 = cc.RepeatForever:create(var_6_6)

	arg_6_0.right:runAction(var_6_7)
end

function var_0_0.willOpen(arg_7_0, arg_7_1)
	arg_7_0:nodeByName("guild_campaign_info"):setVisible(false)
	arg_7_0:nodeByName("jia"):setVisible(false)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_7_0):addEventListener(xyd.event.FIGHT_RESULT, handler(arg_7_0, arg_7_0.onFightResult))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_7_0):addEventListener(xyd.event.GUILD_FIGHT_NOTICE, handler(arg_7_0, arg_7_0.onGuildFightNotice_))
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_7_0):addEventListener(xyd.event.BACKEND_REDMARK, handler(arg_7_0, arg_7_0.updateTaskRedPoint))

	arg_7_0.currentNormalChapter = arg_7_0.selfPlayer.normal_chapter_id
	arg_7_0.maxNormalChapter = arg_7_0.selfPlayer.normal_chapter_id
	arg_7_0.currentSuperChapter = arg_7_0.selfPlayer.super_chapter_id
	arg_7_0.currentTeamChapter = arg_7_0.guildChapter or arg_7_0.guild.team_chapter_id
	arg_7_0.currentChallengeChapter = 1
	arg_7_0.maxChallengeChapter = xyd.tables.misc.maxChallengeChapter

	arg_7_0.selfPlayer:loadWorldMap(function()
		arg_7_0:initComponents()
		arg_7_0:createLeftAndRightArrowAction()
		arg_7_0:layout()
	end)
end

function var_0_0.updateChapterTypeBtnShowInfo(arg_9_0)
	arg_9_0.campaignOpenState = {}
	arg_9_0.campaignOpenState[var_0_13.NORMAL] = true
	arg_9_0.campaignOpenState[var_0_13.SUPER] = arg_9_0.maxSuperChapter > 0
	arg_9_0.campaignOpenState[var_0_13.GUILD] = arg_9_0:checkGuildBtnShow()
	arg_9_0.campaignOpenState[var_0_13.CHALLENGE] = arg_9_0.selfPlayer.lev >= 80

	if not arg_9_0:checkGuildBtnShow() then
		if arg_9_0.chapterType == xyd.CampaignType.GUILD then
			arg_9_0.chapterType = xyd.CampaignType.NORMAL
		end

		arg_9_0.teamCampaignList = nil
		arg_9_0.teamCampaigns = nil
	end
end

function var_0_0.checkGuildBtnShow(arg_10_0)
	if arg_10_0.guild.guild_id and arg_10_0.guild.guild_id > 0 and arg_10_0.teamCampaignList and arg_10_0.teamCampaigns and next(arg_10_0.teamCampaignList) and next(arg_10_0.teamCampaigns) and arg_10_0.selfPlayer.normal_chapter_id >= arg_10_0.guild:getMinchapterID() and arg_10_0.selfPlayer.lev >= xyd.tables.teamCampaign:openLevByChapter(arg_10_0.guild:getMinchapterID()) then
		return true
	else
		return false
	end
end

function var_0_0.layout(arg_11_0)
	arg_11_0:addTopSidebar()

	if arg_11_0.isStoneCampaign then
		if arg_11_0.chapterType == xyd.CampaignType.NORMAL then
			arg_11_0.currentNormalChapter = arg_11_0.stoneChapter
		elseif arg_11_0.chapterType == xyd.CampaignType.SUPER then
			arg_11_0.currentSuperChapter = arg_11_0.stoneChapter
		end
	end

	if arg_11_0.params.chapter then
		if arg_11_0.chapterType == xyd.CampaignType.NORMAL then
			arg_11_0.currentNormalChapter = arg_11_0.params.chapter
		elseif arg_11_0.chapterType == xyd.CampaignType.SUPER then
			arg_11_0.currentSuperChapter = arg_11_0.params.chapter
		elseif arg_11_0.chapterType == xyd.CampaignType.GUILD then
			arg_11_0.currentTeamChapter = arg_11_0.params.chapter
		elseif arg_11_0.chapterType == xyd.CampaignType.CHALLENGE then
			arg_11_0.currentChallengeChapter = arg_11_0.params.chapter
		end
	end

	if arg_11_0.chapterType == xyd.CampaignType.NORMAL and arg_11_0.selfPlayer.lev < xyd.tables.campaign:openLevByChapter(arg_11_0.currentNormalChapter) then
		arg_11_0.currentNormalChapter = arg_11_0.currentNormalChapter - 1
	elseif arg_11_0.chapterType == xyd.CampaignType.SUPER and arg_11_0.selfPlayer.lev < xyd.tables.campaign:openLevByChapter(arg_11_0.currentSuperChapter) then
		arg_11_0.currentSuperChapter = arg_11_0.currentSuperChapter - 1
	elseif arg_11_0.chapterType == xyd.CampaignType.GUILD and arg_11_0.selfPlayer.lev < xyd.tables.teamCampaign:openLevByChapter(arg_11_0.currentTeamChapter) then
		arg_11_0.currentTeamChapter = arg_11_0.currentTeamChapter - 1
	end

	arg_11_0.maxSuperChapter = arg_11_0.selfPlayer.super_chapter_id
	arg_11_0.campaigns = arg_11_0.selfPlayer.worldMaps_

	arg_11_0:updateChapter(true)
	arg_11_0:updateBonus()
	arg_11_0:registerBtn()
	arg_11_0:updateChapterTypeBtnShowInfo()
	arg_11_0:updateTypeBtnState(arg_11_0.chapterType)
	arg_11_0:playGuide()
	arg_11_0:checkGuide()
	arg_11_0:nodeByName("jia"):setTouchEnabled(true)
	arg_11_0:nodeByName("jia"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_12_0)
		if arg_12_0.name == "began" then
			return true
		elseif arg_12_0.name == "ended" and not arg_11_0.isGuildInfoOnMove then
			xyd.playButtonSound()
			arg_11_0:showBottom(true)
		end
	end)
	arg_11_0:nodeByName("jian"):setTouchEnabled(true)
	arg_11_0:nodeByName("jian"):addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
		if arg_13_0.name == "began" then
			return true
		elseif arg_13_0.name == "ended" and not arg_11_0.isGuildInfoOnMove then
			xyd.playButtonSound()
			arg_11_0:showBottom(false)
		end
	end)

	arg_11_0.isMenuExtended = false

	arg_11_0:nodeByName("menu_plus"):setTouchSwallowEnabled(true)
	arg_11_0:nodeByName("menu_plus"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended and not arg_11_0.isMenuOnMove then
			xyd.playButtonSound()

			arg_11_0.isMenuOnMove = true

			arg_11_0:playMenuAction(not arg_11_0.isMenuExtended)
		end
	end)
	arg_11_0:nodeByName("txt_task"):setString(var_0_11:translation("MISSION"))
	arg_11_0:nodeByName("task_btn"):setTouchSwallowEnabled(true)
	arg_11_0:nodeByName("task_btn"):addTouchEventListener(function(arg_15_0, arg_15_1)
		xyd.buttonScaleAnim(arg_15_0, arg_15_1)

		if arg_15_1 == ccui.TouchEventType.ended and not arg_11_0.isMenuOnMove then
			xyd.playButtonSound()
			xyd.ModelManager.get():loadModel(xyd.ModelType.TASK):loadTaskByType(xyd.TaskType.STORY, function(arg_16_0)
				if arg_16_0 == xyd.error.OK then
					xyd.WindowManager.get():openWindow("map_task")
				end
			end, true)
		end
	end)
	arg_11_0:updateTaskRedPoint()
	arg_11_0:addTouchSwallow()
end

function var_0_0.updateTaskRedPoint(arg_17_0)
	if xyd.ModelManager.get():loadModel(xyd.ModelType.REDMARK):isRedmark(xyd.FunctionID.ID_MISSION, xyd.redmark.STORY_TASK) then
		arg_17_0:nodeByName("task_btn"):getChildByName("red_point"):setVisible(true)
	else
		arg_17_0:nodeByName("task_btn"):getChildByName("red_point"):setVisible(false)
	end
end

function var_0_0.playMenuAction(arg_18_0, arg_18_1, arg_18_2)
	if arg_18_1 then
		arg_18_0:nodeByName("plus"):setVisible(false)
		arg_18_0:nodeByName("sub"):setVisible(true)
	else
		arg_18_0:nodeByName("plus"):setVisible(true)
		arg_18_0:nodeByName("sub"):setVisible(false)
	end

	arg_18_0.isMenuExtended = arg_18_1

	for iter_18_0 = 1, 3 do
		arg_18_0:nodeByName("menu_" .. iter_18_0):setVisible(arg_18_0.isMenuExtended)
	end

	arg_18_0.isMenuOnMove = false
end

function var_0_0.showBottom(arg_19_0, arg_19_1)
	local var_19_0 = arg_19_0:nodeByName("guild_campaign_info"):getContentSize().height
	local var_19_1 = 15

	if arg_19_0.chapterType == xyd.CampaignType.GUILD then
		arg_19_0.isGuildInfoOnMove = true

		if arg_19_1 then
			arg_19_0:nodeByName("jia"):setVisible(false)
			arg_19_0:nodeByName("jian"):setVisible(true)

			local var_19_2 = cc.p(arg_19_0:nodeByName("guild_campaign_info"):getPositionX(), var_19_1)

			arg_19_0:nodeByName("guild_campaign_info"):runActionOnce(cc.MoveTo:create(0.5, var_19_2), false, function()
				if arg_19_0 and not tolua.isnull(arg_19_0) then
					arg_19_0.isGuildInfoOnMove = false
				end
			end)
		else
			arg_19_0:nodeByName("jia"):setVisible(true)
			arg_19_0:nodeByName("jian"):setVisible(false)

			local var_19_3 = cc.p(arg_19_0:nodeByName("guild_campaign_info"):getPositionX(), -var_19_0)

			arg_19_0:nodeByName("guild_campaign_info"):runActionOnce(cc.MoveTo:create(0.5, var_19_3), false, function()
				if arg_19_0 and not tolua.isnull(arg_19_0) then
					arg_19_0.isGuildInfoOnMove = false
				end
			end)
		end
	end
end

function var_0_0.registerBtn(arg_22_0)
	arg_22_0.left:addTouchEventListener(function(arg_23_0, arg_23_1)
		if arg_23_1 == ccui.TouchEventType.began then
			arg_22_0.canClick = false
		elseif arg_23_1 == ccui.TouchEventType.ended then
			local var_23_0

			if arg_22_0.chapterType == xyd.CampaignType.NORMAL then
				arg_22_0.currentNormalChapter = math.max(arg_22_0.currentNormalChapter - 1, var_0_5)
				var_23_0 = arg_22_0:createContainer(arg_22_0.currentNormalChapter)
			end

			if arg_22_0.chapterType == xyd.CampaignType.SUPER then
				arg_22_0.currentSuperChapter = math.max(arg_22_0.currentSuperChapter - 1, var_0_5)
				var_23_0 = arg_22_0:createContainer(arg_22_0.currentSuperChapter)
			end

			if arg_22_0.chapterType == xyd.CampaignType.GUILD then
				arg_22_0.currentTeamChapter = math.max(arg_22_0.currentTeamChapter - 1, var_0_5)
				var_23_0 = arg_22_0:createContainer(arg_22_0.currentTeamChapter)
			end

			if arg_22_0.chapterType == xyd.CampaignType.CHALLENGE then
				arg_22_0.currentChallengeChapter = math.max(arg_22_0.currentChallengeChapter - 1, var_0_5)
				var_23_0 = arg_22_0:createContainer(arg_22_0.currentChallengeChapter)
			end

			if var_23_0 == nil then
				return
			end

			arg_22_0.clippingNode:addChild(var_23_0)
			var_23_0:setPosition(-arg_22_0.mapPanelWidth, 0)
			transition.moveBy(var_23_0, {
				time = 0.5,
				y = 0,
				x = arg_22_0.mapPanelWidth,
				onComplete = function()
					arg_22_0:updateChapter()

					arg_22_0.canClick = true
				end
			})
			transition.moveBy(arg_22_0.oldContainer, {
				time = 0.5,
				y = 0,
				x = arg_22_0.mapPanelWidth
			})
		elseif arg_23_1 == 3 then
			arg_22_0.canClick = true
		end
	end)
	arg_22_0.right:addTouchEventListener(function(arg_25_0, arg_25_1)
		if arg_25_1 == ccui.TouchEventType.began then
			arg_22_0.canClick = false
		elseif arg_25_1 == ccui.TouchEventType.ended then
			local var_25_0
			local var_25_1
			local var_25_2

			if arg_22_0.chapterType == xyd.CampaignType.NORMAL then
				var_25_1 = xyd.tables.campaign:openLevByChapter(arg_22_0.currentNormalChapter + 1)
			elseif arg_22_0.chapterType == xyd.CampaignType.SUPER then
				var_25_1 = xyd.tables.campaign:openLevByChapter(arg_22_0.currentSuperChapter + 1)
			elseif arg_22_0.chapterType == xyd.CampaignType.GUILD then
				var_25_1 = xyd.tables.teamCampaign:openLevByChapter(arg_22_0.currentTeamChapter + 1)
				var_25_2 = xyd.tables.teamDungeonSelect:getLastChapter()
			elseif arg_22_0.chapterType == xyd.CampaignType.CHALLENGE then
				var_25_1 = xyd.tables.teamCampaign:openLevByChapter(arg_22_0.currentChallengeChapter + 1)
			end

			if var_25_1 > arg_22_0.selfPlayer.lev then
				local var_25_3 = string.format(var_0_11:translation("OPENLEV_TIP"), var_25_1)

				xyd.WindowManager.get():openWindow("toast", {
					message = var_25_3
				})

				arg_22_0.canClick = true

				return
			elseif var_25_1 == -1 then
				local var_25_4 = var_0_11:translation("MAP_CHAPTER_NOT_OPEN")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_25_4
				})

				arg_22_0.canClick = true

				return
			elseif var_25_2 and var_25_2 <= arg_22_0.currentTeamChapter then
				local var_25_5 = var_0_11:translation("MAP_CHAPTER_NOT_OPEN")

				xyd.WindowManager.get():openWindow("toast", {
					message = var_25_5
				})

				arg_22_0.canClick = true

				return
			elseif arg_22_0.chapterType == xyd.CampaignType.GUILD then
				arg_22_0.arrow:setVisible(false)
			end

			if arg_22_0.chapterType == xyd.CampaignType.NORMAL then
				arg_22_0.currentNormalChapter = math.min(arg_22_0.currentNormalChapter + 1, arg_22_0.maxNormalChapter)
				var_25_0 = arg_22_0:createContainer(arg_22_0.currentNormalChapter)
			elseif arg_22_0.chapterType == xyd.CampaignType.SUPER then
				arg_22_0.currentSuperChapter = math.min(arg_22_0.currentSuperChapter + 1, arg_22_0.maxSuperChapter)
				var_25_0 = arg_22_0:createContainer(arg_22_0.currentSuperChapter)
			elseif arg_22_0.chapterType == xyd.CampaignType.GUILD then
				arg_22_0.currentTeamChapter = math.min(arg_22_0.currentTeamChapter + 1, arg_22_0.maxNormalChapter)
				var_25_0 = arg_22_0:createContainer(arg_22_0.currentTeamChapter)
			elseif arg_22_0.chapterType == xyd.CampaignType.CHALLENGE then
				arg_22_0.currentChallengeChapter = math.min(arg_22_0.currentChallengeChapter + 1, arg_22_0.maxChallengeChapter)
				var_25_0 = arg_22_0:createContainer(arg_22_0.currentChallengeChapter)
			end

			if var_25_0 == nil then
				return
			end

			arg_22_0.clippingNode:addChild(var_25_0)
			var_25_0:setPosition(arg_22_0.mapPanelWidth, 0)

			arg_22_0.canClick = false

			transition.moveBy(var_25_0, {
				time = 0.5,
				y = 0,
				x = -arg_22_0.mapPanelWidth,
				onComplete = function()
					arg_22_0:updateChapter()

					arg_22_0.canClick = true

					arg_22_0:playGuide()
				end
			})
			transition.moveBy(arg_22_0.oldContainer, {
				time = 0.5,
				y = 0,
				x = -arg_22_0.mapPanelWidth
			})
		elseif arg_25_1 == 3 then
			arg_22_0.canClick = true
		end
	end)

	if arg_22_0.chapterType == xyd.CampaignType.NORMAL or arg_22_0.chapterType == xyd.CampaignType.SUPER or arg_22_0.chapterType == xyd.CampaignType.GUILD then
		if arg_22_0.starNum == nil or arg_22_0.starNum == 0 then
			arg_22_0:nodeByName("bonus"):setVisible(false)
		else
			arg_22_0:nodeByName("bonus"):setVisible(true)
		end

		arg_22_0.bonusButton:addTouchEventListener(function(arg_27_0, arg_27_1)
			if arg_27_1 == ccui.TouchEventType.began then
				return true
			elseif arg_27_1 == ccui.TouchEventType.ended then
				if arg_22_0.bonusStar < arg_22_0.starNum then
					local var_27_0 = {
						bonusID = arg_22_0.bonusID
					}

					xyd.WindowManager.get():openWindow("star_bonus", var_27_0):setPosition(0, 140)
				else
					xyd.Backend.get():request(xyd.mid.GET_BONUS_AWARD, {
						bonus_type = arg_22_0.bonusType
					}, function(arg_28_0, arg_28_1, arg_28_2)
						if arg_28_0 == xyd.error.OK then
							if arg_28_1.chapter_info ~= nil then
								arg_22_0.selfPlayer.super_bonus_id = arg_28_1.chapter_info.super_bonus_id
								arg_22_0.selfPlayer.normal_bonus_id = arg_28_1.chapter_info.normal_bonus_id

								arg_22_0:updateBonus()
							end

							if arg_28_1.awards ~= nil then
								xyd.WindowManager.get():openWindow("alert_award", {
									awards = arg_28_1.awards
								})

								local var_28_0 = arg_28_1.awards

								for iter_28_0 = 1, #var_28_0 do
									if var_28_0[iter_28_0].table_id > 0 then
										local var_28_1 = {
											itemID = var_28_0[iter_28_0].table_id,
											itemNum = var_28_0[iter_28_0].item_num
										}

										arg_22_0.selfPlayer:getBackpack():addItem(var_28_1)
									end
								end
							end

							if arg_22_0.effect1_ then
								arg_22_0.effect1_:stop()
								arg_22_0.effect1_:hide()
								arg_22_0:nodeByName("img_star"):show()
							end
						end
					end)
				end
			end
		end)
	else
		arg_22_0:nodeByName("bonus"):setVisible(false)
	end
end

function var_0_0.onFightResult(arg_29_0, arg_29_1)
	xyd.WindowManager.get():closeWindow("new_map_detail_window")

	local var_29_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	local var_29_1 = arg_29_1.params.chapter_info

	if var_29_1 ~= nil then
		var_29_0.normal_chapter_id = var_29_1.normal_chapter_id
		var_29_0.normal_campaign_id = var_29_1.normal_campaign_id
		var_29_0.super_chapter_id = var_29_1.super_chapter_id
		var_29_0.super_campaign_id = var_29_1.super_campaign_id
	end

	if arg_29_1.params.campaigns ~= nil then
		for iter_29_0, iter_29_1 in pairs(arg_29_1.params.campaigns) do
			local var_29_2 = tonumber(iter_29_1.campaign_id)

			if var_29_2 then
				var_29_0.worldMaps_[var_29_2] = {}
				var_29_0.worldMaps_[var_29_2].star = tonumber(iter_29_1.star)
				var_29_0.worldMaps_[var_29_2].dailyLimit = tonumber(iter_29_1.daily_limit)
				var_29_0.worldMaps_[var_29_2].resetCount = tonumber(iter_29_1.reset_count)
			end
		end
	end

	arg_29_0.maxNormalChapter = arg_29_0.selfPlayer.normal_chapter_id
	arg_29_0.maxSuperChapter = arg_29_0.selfPlayer.super_chapter_id

	arg_29_0:updateChapter()
end

function var_0_0.updateChapter(arg_30_0, arg_30_1)
	arg_30_0:playMenuAction(false, arg_30_1)
	arg_30_0:setButtonVisible()
	arg_30_0.clippingNode:removeAllChildren()
	arg_30_0.imgName:removeAllChildren()

	if arg_30_0.chapterType == xyd.CampaignType.NORMAL and arg_30_0.selfPlayer.lev < xyd.tables.campaign:openLevByChapter(arg_30_0.currentNormalChapter) then
		arg_30_0.currentNormalChapter = arg_30_0.currentNormalChapter - 1
	elseif arg_30_0.chapterType == xyd.CampaignType.SUPER and arg_30_0.selfPlayer.lev < xyd.tables.campaign:openLevByChapter(arg_30_0.currentSuperChapter) then
		arg_30_0.currentSuperChapter = arg_30_0.currentSuperChapter - 1
	elseif arg_30_0.chapterType == xyd.CampaignType.GUILD and arg_30_0.selfPlayer.lev < xyd.tables.teamCampaign:openLevByChapter(arg_30_0.currentTeamChapter) then
		arg_30_0.currentTeamChapter = arg_30_0.currentTeamChapter - 1
	end

	local var_30_0 = 1

	if arg_30_0.chapterType == xyd.CampaignType.NORMAL then
		var_30_0 = arg_30_0.currentNormalChapter
	elseif arg_30_0.chapterType == xyd.CampaignType.SUPER then
		var_30_0 = arg_30_0.currentSuperChapter
	elseif arg_30_0.chapterType == xyd.CampaignType.GUILD then
		var_30_0 = arg_30_0.currentTeamChapter
	elseif arg_30_0.chapterType == xyd.CampaignType.CHALLENGE then
		var_30_0 = arg_30_0.currentChallengeChapter
	end

	local var_30_1 = xyd.AssetLoader.get():loadLabel({
		size = 24,
		text = var_0_11:translation("MAP_WINDOW_CHAPTER_" .. var_30_0)
	})

	var_30_1:addTo(arg_30_0.imgName)
	var_30_1:setAnchorPoint(cc.p(0, 0.5))
	var_30_1:setPosition(cc.p(0, arg_30_0.imgName:getContentSize().height / 2))
	var_30_1:enableOutline(cc.c4b(0, 0, 0, 255), 2)

	local var_30_2 = arg_30_0:createContainer(var_30_0)

	arg_30_0.oldContainer = var_30_2

	arg_30_0.clippingNode:addChild(var_30_2)
	arg_30_0.arrow:setVisible(false)
	arg_30_0.arrow:stopAllActions()

	if arg_30_0.lastNode ~= nil and arg_30_0.lastExist then
		local var_30_3 = arg_30_0.lastNode:getPositionX()
		local var_30_4 = arg_30_0.lastNode:getPositionY()
		local var_30_5 = arg_30_0:convertToNodeSpace(arg_30_0.lastNode:getParent():convertToWorldSpace(cc.p(var_30_3, var_30_4)))

		if arg_30_0.lastNode.campaignType ~= var_0_6 then
			var_30_5.y = var_30_5.y + 80
		end

		arg_30_0.arrow:setPosition(var_30_5.x, var_30_5.y + 70)
		arg_30_0.arrow:setVisible(true)

		local var_30_6 = transition.sequence({
			cc.MoveTo:create(1, cc.p(var_30_5.x, var_30_5.y + 50)),
			cc.MoveTo:create(1, cc.p(var_30_5.x, var_30_5.y + 70))
		})
		local var_30_7 = cc.RepeatForever:create(var_30_6)

		arg_30_0.arrow:runAction(var_30_7)
	end
end

function var_0_0.playeTitleAction(arg_31_0)
	local var_31_0 = arg_31_0:nodeByName("chapter_name_container")

	if var_31_0.action and not tolua.isnull(var_31_0.action) then
		transition.removeAction(var_31_0.action)

		var_31_0.action = nil
	end

	local var_31_1 = var_31_0:getContentSize().width
	local var_31_2 = cc.p(1280, 570)

	var_31_0:setPosition(var_31_2)

	local var_31_3 = cc.MoveTo:create(0.3, cc.p(var_31_2.x - var_31_1 + 30, var_31_2.y))
	local var_31_4 = cc.MoveTo:create(0.2, var_31_2)
	local var_31_5 = cc.Sequence:create(var_31_3, cc.DelayTime:create(1.5), var_31_4)

	var_31_0.action = var_31_5

	var_31_0:runAction(var_31_5)
end

function var_0_0.updateBonus(arg_32_0)
	if arg_32_0.chapterType == xyd.CampaignType.GUILD or arg_32_0.chapterType == xyd.CampaignType.CHALLENGE then
		arg_32_0:nodeByName("bonus"):setVisible(false)

		return
	end

	arg_32_0:nodeByName("bonus"):setVisible(true)

	if arg_32_0.chapterType == xyd.CampaignType.NORMAL then
		arg_32_0.bonusID = arg_32_0.selfPlayer.normal_bonus_id
		arg_32_0.bonusStar = arg_32_0.selfPlayer.normal_stars
	end

	if arg_32_0.chapterType == xyd.CampaignType.SUPER then
		arg_32_0.bonusID = arg_32_0.selfPlayer.super_bonus_id
		arg_32_0.bonusStar = arg_32_0.selfPlayer.super_stars
	end

	arg_32_0.starNum = xyd.tables.campaignBonus:starNum(arg_32_0.bonusID)

	if arg_32_0.starNum == nil or arg_32_0.starNum == 0 then
		arg_32_0:nodeByName("bonus"):setVisible(false)
	else
		arg_32_0:nodeByName("bonus"):setVisible(true)

		arg_32_0.bonusType = xyd.tables.campaignBonus:bonusType(arg_32_0.bonusID)

		arg_32_0:nodeByName("bonus_txt"):setString(arg_32_0.bonusStar .. "/" .. arg_32_0.starNum)
		arg_32_0:nodeByName("bonus_txt"):enableOutline(cc.c4b(0, 0, 0, 255), 1)

		local var_32_0 = math.min(arg_32_0.bonusStar / arg_32_0.starNum * 100, 100)

		arg_32_0:nodeByName("bonus_bar"):setPercent(var_32_0)
	end

	if arg_32_0.bonusStar and arg_32_0.starNum and arg_32_0.bonusStar >= arg_32_0.starNum then
		if arg_32_0.effect1_ then
			arg_32_0.effect1_:play(nil, true)
			arg_32_0.effect1_:show()
		else
			local var_32_1 = xyd.createEffect(var_0_2)

			var_32_1:addTo(arg_32_0:nodeByName("bonus"))
			var_32_1:setPosition(arg_32_0:nodeByName("img_star"):getPosition())
			var_32_1:setTouchSwallowEnabled(false)
			var_32_1:setVisible(true)
			var_32_1:play(nil, true)

			arg_32_0.effect1_ = var_32_1
		end

		arg_32_0:nodeByName("img_star"):hide()
	else
		if arg_32_0.effect1_ then
			arg_32_0.effect1_:stop()
			arg_32_0.effect1_:hide()
		end

		arg_32_0:nodeByName("img_star"):show()
	end
end

function var_0_0.initChapterInfo(arg_33_0, arg_33_1, arg_33_2)
	if not arg_33_2 then
		return
	end

	local var_33_0 = arg_33_1:getChildByName("chapter_info")
	local var_33_1 = arg_33_1:getChildByName("chapter_not_open")

	var_33_1:getChildByName("has_done"):setString(xyd.tables.translation:translation("CHAPTER_NOT_OPEN"))
	var_33_0:getChildByName("has_done"):setString(xyd.tables.translation:translation("GUILD_CAMPAIGN_IS_OVER"))
	var_33_0:getChildByName("try_times_left_txt"):setString(xyd.tables.translation:translation("MAP_LEFT_TIMES"))
	var_33_0:getChildByName("extra_reward_txt"):setString(xyd.tables.translation:translation("EXTRA_REWARD_SURPLUS"))

	local var_33_2 = var_33_0:getChildByName("etra_left_time")
	local var_33_3 = var_33_0:getChildByName("dps_rank_btn")
	local var_33_4 = var_33_0:getChildByName("reward_btn")
	local var_33_5 = arg_33_2.chapter_id
	local var_33_6 = xyd.tables.teamDungeonSelect:plotNum(var_33_5)

	if arg_33_2.is_open == 0 then
		var_33_0:setVisible(false)
		var_33_1:setVisible(true)
	else
		var_33_0:setVisible(true)
		var_33_1:setVisible(false)

		if arg_33_2.is_win == 1 then
			arg_33_0:nodeByName("extra_reward_num"):setVisible(false)
			var_33_0:getChildByName("has_done"):setVisible(true)
			var_33_2:setVisible(false)
			var_33_0:getChildByName("try_times_left_txt"):setVisible(false)
			var_33_0:getChildByName("extra_reward_txt"):setVisible(false)
			var_33_0:getChildByName("try_times"):setVisible(false)
		else
			arg_33_0:nodeByName("extra_reward_num"):setVisible(true)
			var_33_0:getChildByName("has_done"):setVisible(false)
			var_33_2:setVisible(true)
			var_33_0:getChildByName("try_times_left_txt"):setVisible(true)
			var_33_0:getChildByName("extra_reward_txt"):setVisible(true)
			var_33_0:getChildByName("try_times"):setVisible(true)
			var_33_0:getChildByName("try_times"):setString(var_33_6 - arg_33_2.challenge_times .. "/" .. var_33_6)

			local var_33_7 = 604800 - (xyd.ServerTime.get():getServerTime() - arg_33_2.start_time)

			if var_33_7 <= 0 then
				arg_33_0:nodeByName("extra_reward_num"):setString(var_0_11:translation("TEAM_TIMEREWARD_TIP") .. "0%")
				arg_33_0:nodeByName("extra_reward_num"):setColor(cc.c3b(82, 82, 82))
				var_33_2:setColor(cc.c3b(82, 82, 82))
				var_33_2:setString("0" .. var_0_11:translation("UNIT_DAY") .. "0" .. var_0_11:translation("UNIT_HOUR"))
			else
				local var_33_8 = math.floor(var_33_7 / 86400)
				local var_33_9 = math.floor(var_33_7 % 86400 / 3600)

				arg_33_0:nodeByName("extra_reward_num"):setString(var_0_11:translation("TEAM_TIMEREWARD_TIP") .. "20%")
				arg_33_0:nodeByName("extra_reward_num"):setColor(xyd.color.RED)
				var_33_2:setColor(xyd.color.RED)
				var_33_2:setString(var_33_8 .. var_0_11:translation("UNIT_DAY") .. var_33_9 .. var_0_11:translation("UNIT_HOUR"))
			end
		end

		var_33_3:setTouchSwallowEnabled(true)
		var_33_3:addTouchEventListener(function(arg_34_0, arg_34_1)
			xyd.buttonScaleAnim(arg_34_0, arg_34_1)

			local var_34_0 = {
				chapter_id = arg_33_2.chapter_id
			}

			if arg_34_1 == ccui.TouchEventType.ended then
				arg_33_0.guild:loadChapterDamageRank(var_34_0, function(arg_35_0)
					if arg_35_0 == xyd.error.OK then
						local var_35_0 = {
							rankList = arg_33_0.guild:getChapterDamageRankList(),
							chapter_id = arg_33_2.chapter_id
						}

						xyd.WindowManager.get():openWindow("damage_rank", var_35_0)
					end
				end)

				arg_33_0.btn_can_push = true
			elseif arg_34_1 == ccui.TouchEventType.began then
				arg_33_0.btn_can_push = false
			end
		end)
		var_33_4:setTouchSwallowEnabled(true)
		var_33_4:addTouchEventListener(function(arg_36_0, arg_36_1)
			xyd.buttonScaleAnim(arg_36_0, arg_36_1)

			if arg_36_1 == ccui.TouchEventType.ended then
				local var_36_0 = {
					chapter_id = arg_33_2.chapter_id
				}

				if arg_33_2.chapter_version == 1 then
					arg_33_0.guild:loadGuildRewards(var_36_0, function(arg_37_0, arg_37_1)
						if arg_37_0 == xyd.error.OK then
							local var_37_0 = {
								chapter_id = arg_33_2.chapter_id,
								rewardList = arg_37_1
							}

							xyd.WindowManager.get():openWindow("apply_reward", var_37_0)
						end
					end)
				end

				if arg_33_2.chapter_version == 2 then
					local var_36_1 = xyd.tables.shop:teamDungeonHomologousIds()
					local var_36_2

					for iter_36_0, iter_36_1 in ipairs(var_36_1) do
						if iter_36_1 == arg_33_2.chapter_id then
							var_36_2 = iter_36_0
						end
					end

					local var_36_3 = xyd.ModelManager.get():loadModel(xyd.ModelType.SHOP)

					var_36_3:loadShopList({}, function()
						if #var_36_3:getGuildOpenList() == 0 then
							xyd.WindowManager.get():openWindow("toast", {
								message = var_0_11:translation("NO_GUILD_SHOP")
							})
						else
							xyd.WindowManager.get():openWindow("guild_shop", {
								shop_type = var_36_2
							})
						end
					end)

					arg_33_0.btn_can_push = true
				end
			elseif arg_36_1 == ccui.TouchEventType.began then
				arg_33_0.btn_can_push = false
			end
		end)
	end
end

function var_0_0.createContainer(arg_39_0, arg_39_1)
	local var_39_0 = cc.Node:create()
	local var_39_1 = xyd.SpriteLoader.new("images/maps/chapter_bg" .. arg_39_1 .. ".png", nil, nil, xyd.DefaultImageType.CHAPTER_MAP)

	var_39_0:setContentSize(arg_39_0.mapPanel:getContentSize())
	xyd.displaySpriteOnContainer(var_39_1, var_39_0, true)

	arg_39_0.lastExist = false

	local var_39_2

	if arg_39_0.teamChapterList then
		var_39_2 = arg_39_0.teamChapterList[arg_39_1]
	end

	if arg_39_0.chapterType == xyd.CampaignType.GUILD then
		arg_39_0:nodeByName("guild_campaign_info"):setVisible(true)
		arg_39_0:initChapterInfo(arg_39_0:nodeByName("guild_campaign_info"), var_39_2)
		arg_39_0:showBottom(true)

		if not var_39_2 then
			return
		end
	else
		arg_39_0:nodeByName("guild_campaign_info"):setVisible(false)
	end

	local var_39_3 = xyd.tables.chapter:normal(arg_39_1)
	local var_39_4 = xyd.tables.chapter:challenge(arg_39_1)

	arg_39_0.plotCampaignIds = {}

	local var_39_5 = 0

	for iter_39_0 = 1, #var_39_3 do
		local var_39_6 = var_39_3[iter_39_0]
		local var_39_7 = xyd.tables.campaign:campaignType(var_39_6)

		if xyd.tables.campaign:isBoss(var_39_6) == 1 then
			var_39_7 = var_0_8
		end

		local var_39_8 = xyd.tables.campaign:x(var_39_6)
		local var_39_9 = xyd.tables.campaign:y(var_39_6)

		if var_39_7 ~= var_0_6 then
			var_39_5 = var_39_5 + 1
		end

		arg_39_0.daguanCount = var_39_5

		local var_39_10
		local var_39_11
		local var_39_12

		if var_39_7 ~= var_0_6 or var_39_7 == xyd.CampaignType.NORMAL then
			var_39_11, var_39_12, rewardIcon = arg_39_0:getTrueCampaignInfo(var_39_6, arg_39_0.chapterType, var_39_5, var_39_4)
		end

		if var_39_7 ~= var_0_6 and (arg_39_0.chapterType ~= xyd.CampaignType.NORMAL or arg_39_0.campaigns[var_39_11] or var_39_7 == var_0_8) then
			local var_39_13 = arg_39_0:getCampaignBossId(arg_39_0.chapterType, var_39_11)

			var_39_10 = arg_39_0:getCampaignResource(var_39_7, var_39_12, var_39_13, rewardIcon)

			if rewardIcon and rewardIcon ~= "" and var_39_12 and var_39_12 > 0 and var_39_11 == arg_39_0.selfPlayer.oldCampaignId then
				arg_39_0.selfPlayer.oldCampaignId = nil

				local var_39_14 = var_39_10:getChildByName("container"):getChildByName("reward_container")
				local var_39_15 = xyd.createEffect(var_0_1)

				var_39_15:addTo(var_39_14)
				var_39_15:setPosition(var_39_14:getChildByName("item_icon"):getPosition())
				var_0_10.performWithDelayGlobal(function()
					if var_39_14 and not tolua.isnull(var_39_14) then
						var_39_14:getChildByName("item_icon"):setVisible(false)
					end
				end, 0.4)
				var_0_10.performWithDelayGlobal(function()
					if var_39_14 and not tolua.isnull(var_39_14) then
						var_39_14:getChildByName("reward_icon"):setVisible(false)
					end
				end, 0.7)
				var_0_10.performWithDelayGlobal(function()
					if var_39_15 and not tolua.isnull(var_39_15) then
						var_39_15:play(nil, false)
					end
				end, 0.2)
			end

			if not arg_39_0.campaigns[var_39_11] and arg_39_0.chapterType ~= xyd.CampaignType.GUILD then
				xyd.GrayNode(var_39_10)
			elseif arg_39_0.chapterType == xyd.CampaignType.GUILD and arg_39_0:checkTeamCampaignGray(tostring(var_39_11), arg_39_1) then
				xyd.GrayNode(var_39_10)
			end
		elseif var_39_7 == var_0_6 then
			if arg_39_0.chapterType ~= xyd.CampaignType.NORMAL then
				var_39_10 = arg_39_0:getCampaignResource(var_39_7, 3)
			elseif var_39_11 and arg_39_0.campaigns[var_39_11] then
				var_39_10 = arg_39_0:getCampaignResource(var_39_7, var_39_12)
			end
		end

		if var_39_7 ~= var_0_6 and arg_39_0.chapterType == xyd.CampaignType.GUILD and arg_39_0.teamCampaigns and arg_39_0.teamCampaigns[tostring(var_39_11)] then
			local var_39_16 = arg_39_0.teamCampaigns[tostring(var_39_11)].percent or 0

			if var_39_16 < 1 then
				local var_39_17 = var_39_10:getChildByName("progress_container")

				var_39_17:setVisible(true)
				var_39_17:getChildByName("progress_bar"):setPercent(var_39_16 * 100)
			end
		end

		local var_39_18 = xyd.tables.chapter:challenge(arg_39_1)
		local var_39_19 = -2 + 3 * var_39_5

		if var_39_10 and arg_39_0.isStoneCampaign and (arg_39_0.stoneCampaignID == var_39_18[var_39_19] or arg_39_0.stoneCampaignID == var_39_18[var_39_19 + 1] or arg_39_0.stoneCampaignID == var_39_18[var_39_19 + 2]) then
			local var_39_20 = import("app.windows.GuideHand").new()

			var_39_20:addTo(var_39_0)

			if var_39_7 ~= var_0_6 then
				var_39_20:setPosition(var_39_8, var_39_9 + 70)
			else
				var_39_20:setPosition(var_39_8, var_39_9 + 40)
			end

			var_39_20:setLocalZOrder(100)
		end

		if var_39_10 and arg_39_0.isStoneCampaign and arg_39_0.stoneCampaignID == var_39_11 then
			local var_39_21 = import("app.windows.GuideHand").new()

			var_39_21:addTo(var_39_0)

			if var_39_7 ~= var_0_6 then
				var_39_21:setPosition(var_39_8, var_39_9 + 70)
			else
				var_39_21:setPosition(var_39_8, var_39_9 + 40)
			end

			var_39_21:setLocalZOrder(100)
		end

		if var_39_10 then
			var_39_10:setTouchEnabled(true)
		end

		if (arg_39_0.chapterType == xyd.CampaignType.NORMAL or arg_39_0.chapterType == xyd.CampaignType.SUPER or arg_39_0.chapterType == xyd.CampaignType.CHALLENGE) and var_39_11 and arg_39_0.campaigns[var_39_11] and (var_39_12 == 0 or var_39_7 ~= var_0_6) then
			local var_39_22 = arg_39_0.campaigns[var_39_11].dailyLimit
			local var_39_23 = arg_39_0.campaigns[var_39_11].resetCount

			var_39_10:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_43_0)
				if arg_43_0.name == "began" then
					return true
				elseif arg_43_0.name == "ended" then
					if not arg_39_0.canClick or not arg_39_0.canClickCampaign or arg_39_0:isOnBtn(arg_43_0.x, arg_43_0.y) then
						return false
					elseif arg_39_0.chapterType == xyd.CampaignType.NORMAL and arg_39_0:checkGuideCampaign() and arg_39_0.lastNode ~= var_39_10 then
						return false
					end

					xyd.playButtonSound()

					if xyd.WindowManager.get():isWindowOpen("guide") and var_39_7 ~= var_0_6 then
						arg_39_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_CAMPAIGN_NODE)
						xyd.WindowManager.get():closeWindow("guide")
					end

					if arg_39_0.chapterType ~= xyd.CampaignType.NORMAL and not arg_39_0:checkNomalCampaignThrough(arg_39_1, var_39_6) then
						return
					end

					local var_43_0 = {
						campaignID = var_39_11,
						campaignType = arg_39_0.chapterType,
						star = var_39_12,
						dailyLimit = var_39_22,
						resetCount = var_39_23,
						itemComposeID = arg_39_0.itemComposeID,
						needItemComposeNum = arg_39_0.needItemComposeNum
					}

					if arg_39_0.chapterType == xyd.CampaignType.CHALLENGE and var_39_12 == 3 then
						var_43_0.maxOK = true
					end

					arg_39_0:openMapDetailWindow(var_43_0)
				end
			end)
		end

		if arg_39_0.chapterType == xyd.CampaignType.GUILD and var_39_7 ~= var_0_6 and var_39_2.is_open == 1 then
			var_39_10:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_44_0)
				if arg_44_0.name == "began" then
					return true
				elseif arg_44_0.name == "ended" then
					if not arg_39_0.canClick or not arg_39_0.canClickCampaign or arg_39_0:isOnBtn(arg_44_0.x, arg_44_0.y) then
						return
					elseif not arg_39_0.btn_can_push then
						arg_39_0.btn_can_push = true

						return
					end

					xyd.playButtonSound()

					if not arg_39_0:checkNomalCampaignThrough(arg_39_1, var_39_6) then
						return
					end

					local var_44_0 = {
						copy_id = var_39_11
					}

					arg_39_0.guild:loadGuildMapDetail(var_44_0, function(arg_45_0, arg_45_1)
						if arg_45_0 == xyd.error.OK then
							local var_45_0 = arg_45_1
							local var_45_1 = arg_45_1.fight_info

							if var_39_2.chapter_version == 2 and arg_39_0.guild:getJoinTime() > var_39_2.start_time then
								xyd.WindowManager.get():openWindow("toast", {
									message = var_0_11:translation("TEAM_DUNGEON_CHALLENGE_LIMIT")
								})

								return
							end

							local var_45_2 = {
								waveIndex = var_45_0.current_index,
								campaignID = var_39_11,
								campaignType = arg_39_0.chapterType,
								monster_status = var_45_0.monster_status,
								isOpen = var_45_0.is_open,
								isWin = var_45_0.is_win,
								chapter = var_39_2.chapter_id,
								challengeTimes = var_39_2.challenge_times
							}

							if var_45_0.current_fight_player > 0 and var_45_0.last_fight_time > 0 then
								local var_45_3 = 60 - (xyd.ServerTime.get():getServerTime() - var_45_0.last_fight_time)

								arg_39_0.guild:setPrepareTime(var_45_3, var_39_11, var_45_0.stage)

								var_45_2.fightPlayerID = var_45_0.current_fight_player
								var_45_2.fightPlayerName = var_45_1.player_name
								var_45_2.fightPlayerLev = var_45_1.lev
								var_45_2.fightPlayerAvatar = var_45_1.avatar_id
								var_45_2.conquer_lev = var_45_1.conquer_lev
								var_45_2.fightStage = var_45_0.stage
							else
								arg_39_0.guild:setPrepareTime(0, var_39_11, var_45_0.stage)

								var_45_2.conquer_lev = arg_39_0.selfPlayer.conquerLev
							end

							xyd.WindowManager.get():openWindow("guild_map_detail_window", var_45_2)
						end
					end)
				end
			end)
		end

		if var_39_10 ~= nil then
			var_39_0:addChild(var_39_10)
			var_39_10:setPosition(var_39_8, var_39_9)
			var_39_10:setLocalZOrder(20)

			if arg_39_0:checkIsLastCampaign(arg_39_0.chapterType, var_39_11, var_39_2) then
				arg_39_0.lastExist = true
				arg_39_0.lastNode = var_39_10

				arg_39_0.lastNode:setLocalZOrder(21)

				arg_39_0.lastNode.campaignType = var_39_7
				arg_39_0.lastCampaignID = var_39_11
			end

			if var_39_7 == var_0_8 then
				arg_39_0.bossNode = var_39_10
			end

			if arg_39_0.chapterType ~= xyd.CampaignType.NORMAL or var_39_7 ~= var_0_8 or not not arg_39_0.campaigns[var_39_11] then
				table.insert(arg_39_0.plotCampaignIds, var_39_6)
			end
		end
	end

	arg_39_0:plotRoad(var_39_0)
	arg_39_0:updateEventsShow(var_39_0, arg_39_1)

	return var_39_0
end

function var_0_0.updateEventsShow(arg_46_0, arg_46_1, arg_46_2)
	local var_46_0 = xyd.tables.chapter:x(arg_46_2)
	local var_46_1 = xyd.tables.chapter:y(arg_46_2)
	local var_46_2 = arg_46_0.selfPlayer.chapterEvents[arg_46_2]
	local var_46_3 = xyd.tables.chapter:eventOpenTimes(arg_46_2)
	local var_46_4 = xyd.tables.chapter:eventType(arg_46_2)

	if var_46_2 and (arg_46_0.chapterType == xyd.CampaignType.NORMAL or arg_46_0.chapterType == xyd.CampaignType.SUPER) and var_46_2.is_open == 1 and var_46_3 > var_46_2.open_times then
		if var_46_4 == var_0_12.Gacha then
			local var_46_5 = xyd.AssetLoader.get():loadSprite("windows/map_window/gacha_icon.png")

			var_46_5:addTo(arg_46_1, 50)
			var_46_5:setPosition(cc.p(var_46_0, var_46_1))
			var_46_5:setTouchEnabled(true)
			var_46_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_47_0)
				if arg_47_0.name == "began" then
					return true
				elseif arg_47_0.name == "ended" and not arg_46_0.isMenuOnMove then
					xyd.playButtonSound()

					local var_47_0 = {
						chapter = arg_46_2
					}

					xyd.WindowManager.get():openWindow("chapter_gacha", var_47_0)
				end
			end)

			if var_46_2.left_times > 0 then
				var_46_5:setOpacity(0)

				local var_46_6 = xyd.createEffect(var_0_3)

				var_46_6:addTo(arg_46_1, 50)
				var_46_6:setPosition(cc.p(var_46_0 - 5, var_46_1 + 10))
				var_46_6:play(nil, true)
			end
		elseif var_46_4 == var_0_12.Boss and var_46_2.val > 0 then
			local var_46_7 = xyd.tables.chapter:eventBossId(arg_46_2)
			local var_46_8 = xyd.tables.chapter:eventBattleId(arg_46_2)
			local var_46_9 = xyd.tables.hero:modelID(var_46_7)
			local var_46_10 = xyd.tables.model:avatar2(var_46_9)
			local var_46_11 = xyd.AssetLoader.get():loadSprite(var_46_10)
			local var_46_12 = xyd.AssetLoader.get():loadSprite("windows/map_window/event_boss_bg.png")

			var_46_12:addTo(arg_46_1, 50)
			var_46_12:setPosition(cc.p(var_46_0, var_46_1))

			local var_46_13 = xyd.AssetLoader:get():loadSprite(var_46_10)
			local var_46_14 = var_46_12:getContentSize().width
			local var_46_15 = var_46_12:getContentSize().height
			local var_46_16 = xyd.AssetLoader:get():loadSprite("windows/map_window/event_boss_clip.png")

			var_46_16:setPosition(var_46_14 / 2, var_46_15 / 2)
			var_46_16:setAnchorPoint(cc.p(0.5, 0.5))
			var_46_16:setScale(var_46_15 / var_46_16:getHeight())

			local var_46_17 = var_46_15 / var_46_16:getHeight()
			local var_46_18 = cc.ClippingNode:create()

			var_46_18:setStencil(var_46_16)
			var_46_18:setInverted(true)
			var_46_18:setAlphaThreshold(0)
			var_46_12:addChild(var_46_18)
			var_46_18:addChild(var_46_13)
			var_46_13:setPosition(var_46_14 / 2, var_46_15 / 2)
			var_46_13:setAnchorPoint(cc.p(0.5, 0.5))

			local var_46_19 = var_46_15 / var_46_13:getHeight()

			var_46_13:setScale(var_46_19 * 0.7)
			var_46_18:setLocalZOrder(1)
			var_46_12:setTouchEnabled(true)
			var_46_12:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_48_0)
				if arg_48_0.name == "began" then
					var_46_12:setScale(0.9)

					return true
				elseif arg_48_0.name == "ended" then
					var_46_12:setScale(1)
					xyd.playButtonSound()

					if xyd.WindowManager.get():getWindow("guide") then
						xyd.WindowManager.get():closeWindow("guide")
					end

					local var_48_0 = {
						chapter = arg_46_2,
						chapter_type = arg_46_0.chapterType
					}

					xyd.WindowManager.get():openWindow("boss_map_detail", var_48_0)
				end
			end)

			if var_46_2.is_new then
				var_46_2.is_new = false

				var_46_12:setVisible(false)

				local var_46_20 = xyd.createEffect(var_0_4)

				var_46_20:addTo(arg_46_1, 60)
				var_46_20:setPosition(cc.p(var_46_0 - 5, var_46_1 + 10))
				var_46_20:play(function()
					var_46_12:setVisible(true)
				end, false, 1.5)

				if arg_46_2 == 7 then
					xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CHAPTER_BOSS_START, true)

					arg_46_0.chapterBossNode = var_46_12

					arg_46_0:playGuide()
				end
			end
		end
	end
end

function var_0_0.isOnBtn(arg_50_0, arg_50_1, arg_50_2)
	return
end

function var_0_0.getCampaignBossId(arg_51_0, arg_51_1, arg_51_2)
	local var_51_0 = {}

	if arg_51_1 == xyd.CampaignType.GUILD then
		var_51_0 = xyd.tables.teamCampaign:monsterDisplay1(tonumber(arg_51_2))
	else
		var_51_0 = xyd.tables.campaign:monsterDisplay(arg_51_2)
	end

	return var_51_0[#var_51_0]
end

function var_0_0.checkIsLastCampaign(arg_52_0, arg_52_1, arg_52_2, arg_52_3)
	if arg_52_1 == xyd.CampaignType.NORMAL or arg_52_1 == xyd.CampaignType.SUPER then
		if arg_52_0.campaigns[arg_52_2] and arg_52_0.campaigns[arg_52_2].star == 0 then
			return true
		end
	elseif arg_52_1 == xyd.CampaignType.GUILD then
		arg_52_2 = tostring(arg_52_2)

		if arg_52_3.is_open == 1 and arg_52_3.is_win == 0 and arg_52_0.teamCampaigns[arg_52_2] and arg_52_0.teamCampaigns[arg_52_2].is_open == 1 and arg_52_0.teamCampaigns[arg_52_2].percent < 1 then
			return true
		end
	end

	return false
end

function var_0_0.openMapDetailWindow(arg_53_0, arg_53_1)
	if xyd.WindowManager.get():isWindowOpen("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	if not arg_53_0.selfPlayer:getBackpack() then
		arg_53_0.selfPlayer:loadBackpack(function(arg_54_0)
			if arg_54_0 == xyd.error.OK then
				xyd.WindowManager.get():openWindow("new_map_detail_window", arg_53_1)
			end
		end)
	else
		xyd.WindowManager.get():openWindow("new_map_detail_window", arg_53_1)
	end
end

function var_0_0.checkNomalCampaignThrough(arg_55_0, arg_55_1, arg_55_2)
	if arg_55_1 > arg_55_0.maxNormalChapter or arg_55_2 > arg_55_0.selfPlayer.normal_campaign_id or arg_55_2 == arg_55_0.selfPlayer.normal_campaign_id and arg_55_0.selfPlayer.worldMaps_[arg_55_2].star <= 0 then
		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_11:translation("NORMAL_MAP_ALERT")
		})

		if xyd.WindowManager.get():isWindowOpen("guide") then
			xyd.WindowManager.get():closeWindow("guide")
		end

		return false
	end

	return true
end

function var_0_0.getCampaignResource(arg_56_0, arg_56_1, arg_56_2, arg_56_3, arg_56_4)
	arg_56_2 = arg_56_2 or 0

	local var_56_0

	if arg_56_1 == var_0_7 then
		var_56_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/map_window/new/campaign_item_normal.csb")
	elseif arg_56_1 == var_0_8 then
		var_56_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/map_window/new/campaign_item_boss.csb")
	elseif arg_56_1 == var_0_6 then
		var_56_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/map_window/new/campaign_item_small.csb")
	end

	local var_56_1 = var_56_0:getChildByName("container")

	if arg_56_1 == var_0_7 or arg_56_1 == var_0_8 then
		local var_56_2 = var_56_1:getChildByName("star_pos")

		for iter_56_0 = 1, 3 do
			if arg_56_2 < iter_56_0 then
				var_56_2:getChildByName("star" .. tostring(iter_56_0)):setVisible(false)
			end
		end

		local var_56_3 = 0

		if arg_56_2 == 2 then
			var_56_3 = 1
		elseif arg_56_2 == 1 then
			var_56_3 = 2
		end

		var_56_2:setPosition(cc.p(var_56_2:getPositionX() + var_56_3 * 16, var_56_2:getPositionY() + var_56_3 * 5 - 5))

		if arg_56_3 then
			local var_56_4 = xyd.tables.hero:modelID(arg_56_3)
			local var_56_5 = xyd.tables.model:campaignCard(var_56_4)
			local var_56_6 = xyd.SpriteLoader.new(var_56_5, nil, nil, xyd.DefaultImageType.CAMPAIGN_CARD)

			var_56_6:setAnchorPoint(cc.p(0.5, 0))
			var_56_6:addTo(var_56_1:getChildByName("icon_pos"))
		end
	elseif arg_56_1 == var_0_6 then
		if arg_56_2 > 0 then
			var_56_1:getChildByName("small_icon"):setVisible(false)
			var_56_1:getChildByName("root"):setVisible(false)
		else
			var_56_1:getChildByName("gray_star"):setVisible(false)
		end
	end

	if arg_56_4 and arg_56_4 ~= "" then
		local var_56_7 = var_56_0:getChildByName("container"):getChildByName("reward_container")

		var_56_7:setVisible(true)

		local var_56_8 = xyd.AssetLoader:get():loadSprite(arg_56_4)

		xyd.displaySpriteOnContainer(var_56_8, var_56_7, true)
		var_56_8:setScale(var_56_8:getScaleX() * 0.8)
		var_56_8:setLocalZOrder(20)
		var_56_8:setName("reward_icon")
	end

	return var_56_0
end

function var_0_0.getTrueCampaignInfo(arg_57_0, arg_57_1, arg_57_2, arg_57_3, arg_57_4)
	local var_57_0 = arg_57_1
	local var_57_1
	local var_57_2

	if arg_57_2 == xyd.CampaignType.SUPER then
		var_57_0 = xyd.tables.campaign:relateCampaign(arg_57_1)
	elseif arg_57_2 == xyd.CampaignType.GUILD then
		var_57_0 = xyd.tables.campaign:teamRelateCampaign(arg_57_1)
	elseif arg_57_2 == xyd.CampaignType.CHALLENGE then
		local var_57_3 = -2 + 3 * arg_57_3

		if not arg_57_4[var_57_3] or not arg_57_0.campaigns[arg_57_4[var_57_3]] then
			return arg_57_4[var_57_3], nil
		end

		if arg_57_0.campaigns[arg_57_4[var_57_3]].star == 0 then
			var_57_0 = arg_57_4[var_57_3]
			var_57_1 = 0
		elseif arg_57_0.campaigns[arg_57_4[var_57_3 + 1]].star == 0 then
			var_57_0 = arg_57_4[var_57_3 + 1]
			var_57_1 = 1
		elseif arg_57_0.campaigns[arg_57_4[var_57_3 + 2]].star == 0 then
			var_57_0 = arg_57_4[var_57_3 + 2]
			var_57_1 = 2
		else
			var_57_0 = arg_57_4[var_57_3 + 2]
			var_57_1 = 3
		end
	end

	if not var_57_1 and arg_57_0.campaigns[var_57_0] then
		var_57_1 = arg_57_0.campaigns[var_57_0].star
	end

	if arg_57_2 ~= xyd.CampaignType.GUILD and var_57_0 and var_57_0 > 0 then
		var_57_2 = xyd.tables.campaign:rewardIcon(var_57_0)
	end

	if var_57_1 and var_57_1 > 0 and var_57_0 ~= arg_57_0.selfPlayer.oldCampaignId then
		var_57_2 = nil
	end

	return var_57_0, var_57_1, var_57_2
end

function var_0_0.createProgressBar(arg_58_0, arg_58_1)
	local var_58_0 = cc.ProgressTimer:create(cc.Sprite:create("windows/map_window/new/line.png"))

	var_58_0:setAnchorPoint(cc.p(0, 0.5))
	var_58_0:setMidpoint(cc.p(0, 0))
	var_58_0:setBarChangeRate(cc.p(1, 0))
	var_58_0:setType(display.PROGRESS_TIMER_BAR)

	var_58_0.maxPercentage = arg_58_1 / var_58_0:getContentSize().width

	return var_58_0
end

function var_0_0.plotRoad(arg_59_0, arg_59_1)
	for iter_59_0, iter_59_1 in pairs(arg_59_0.plotCampaignIds) do
		local var_59_0 = xyd.tables.campaign:x(iter_59_1)
		local var_59_1 = xyd.tables.campaign:y(iter_59_1)
		local var_59_2 = xyd.tables.campaign:lastCampaignID(iter_59_1)

		if var_59_2 > 0 and xyd.isInTable(arg_59_0.plotCampaignIds, var_59_2) then
			local var_59_3 = xyd.tables.campaign:x(var_59_2)
			local var_59_4 = xyd.tables.campaign:y(var_59_2)
			local var_59_5 = math.sqrt(math.pow(var_59_3 - var_59_0, 2) + math.pow(var_59_4 - var_59_1, 2))
			local var_59_6 = arg_59_0:createProgressBar(var_59_5)

			var_59_6:addTo(arg_59_1)
			var_59_6:setPosition(cc.p(var_59_3, var_59_4))

			if arg_59_0.lastExist and iter_59_1 == arg_59_0.lastCampaignID and iter_59_1 == arg_59_0.selfPlayer.newOpenCampaignId and arg_59_0.chapterType == xyd.CampaignType.NORMAL then
				arg_59_0.selfPlayer.newOpenCampaignId = nil

				local var_59_7 = cc.ProgressTo:create(1, var_59_6.maxPercentage * 100)

				arg_59_0.lastNode:setVisible(false)
				arg_59_0.arrow:setOpacity(0)
				var_59_6:runActionOnce(var_59_7, false, function()
					if arg_59_0 and not tolua.isnull(arg_59_0) then
						arg_59_0.lastNode:setVisible(true)

						if arg_59_0.lastNode.campaignType ~= var_0_6 then
							arg_59_0:playCampaigntItemOutAction(arg_59_0.lastNode:getChildByName("container"))
						end

						arg_59_0.arrow:setOpacity(255)
					end
				end)
			else
				var_59_6:setPercentage(var_59_6.maxPercentage * 100)
			end

			local var_59_8 = math.atan2(var_59_1 - var_59_4, var_59_0 - var_59_3) / math.pi * -180

			var_59_6:setRotation(var_59_8)
			var_59_6:setLocalZOrder(10)
		end
	end
end

function var_0_0.playCampaigntItemOutAction(arg_61_0, arg_61_1)
	arg_61_1:setScale(0)
	arg_61_1:setOpacity(0)
	arg_61_1:setRotation(0)

	local var_61_0 = 0.03333333333333333
	local var_61_1 = transition.sequence({
		cc.ScaleTo:create(var_61_0, 0.21),
		cc.ScaleTo:create(var_61_0 * 3, 1.155),
		cc.DelayTime:create(var_61_0 * 3),
		cc.ScaleTo:create(var_61_0 * 2, 1),
		cc.RotateTo:create(var_61_0 * 2, -18),
		cc.RotateTo:create(var_61_0 * 3, 9),
		cc.RotateTo:create(var_61_0 * 3, 0),
		cc.RotateTo:create(var_61_0 * 2, -14),
		cc.RotateTo:create(var_61_0 * 5, 9),
		cc.RotateTo:create(var_61_0 * 3, 0)
	})

	arg_61_1:runAction(var_61_1)
	arg_61_1:runAction(cc.FadeIn:create(var_61_0 * 2))
end

function var_0_0.checkTeamCampaignGray(arg_62_0, arg_62_1, arg_62_2)
	local var_62_0 = arg_62_0.teamChapterList[arg_62_2]

	if var_62_0.is_open ~= 1 or var_62_0.is_win == 1 then
		return true
	end

	if var_62_0.is_open == 1 and (arg_62_0.teamCampaigns[arg_62_1].percent == 0 and arg_62_0.teamCampaigns[arg_62_1].is_open == 0 or arg_62_0.teamCampaigns[arg_62_1].percent == 1 and arg_62_0.teamCampaigns[arg_62_1].is_open == 1) then
		return true
	end

	return false
end

function var_0_0.setButtonVisible(arg_63_0)
	local var_63_0 = 1
	local var_63_1 = 1

	if arg_63_0.chapterType == xyd.CampaignType.NORMAL then
		var_63_0 = arg_63_0.maxNormalChapter
		var_63_1 = arg_63_0.currentNormalChapter
	elseif arg_63_0.chapterType == xyd.CampaignType.SUPER then
		var_63_0 = arg_63_0.maxSuperChapter
		var_63_1 = arg_63_0.currentSuperChapter
	elseif arg_63_0.chapterType == xyd.CampaignType.GUILD then
		var_63_0 = arg_63_0.maxNormalChapter
		var_63_1 = arg_63_0.currentTeamChapter
	elseif arg_63_0.chapterType == xyd.CampaignType.CHALLENGE then
		var_63_0 = arg_63_0.maxChallengeChapter
		var_63_1 = arg_63_0.currentChallengeChapter
	end

	local var_63_2

	var_63_2 = tonumber(var_63_0) or 0

	if var_63_1 > var_0_5 then
		arg_63_0.left:setVisible(true)
	else
		arg_63_0.left:setVisible(false)
	end

	if var_63_1 < var_63_2 then
		arg_63_0.right:setVisible(true)
	else
		arg_63_0.right:setVisible(false)
	end
end

function var_0_0.hide(arg_64_0)
	arg_64_0.left:setVisible(false)
	arg_64_0.right:setVisible(false)
end

function var_0_0.checkGuideCampaign(arg_65_0)
	local var_65_0 = xyd.StoryData.get():getGuideID()

	if var_65_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_MAP or var_65_0 == xyd.GuideStoryType.GUIDE_FIGHT_2_ONE or var_65_0 == xyd.GuideStoryType.GUIDE_FIGHT_3_START or var_65_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_ONE or var_65_0 == xyd.GuideStoryType.GUIDE_FIGHT_5_TWO then
		return true
	end

	return false
end

function var_0_0.setIDBeforeGuideWnd(arg_66_0)
	local var_66_0 = xyd.StoryData.get():getGuideID()

	if var_66_0 < xyd.GuideStoryType.GUIDE_CAMPAIGN_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_CAMPAIGN_MAP, true)
	elseif var_66_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_START then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_4_ONE, true)
	elseif var_66_0 == xyd.GuideStoryType.GUIDE_FIGHT_5_START then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_5_ONE, true)
	elseif var_66_0 == xyd.GuideStoryType.GUIDE_FIGHT_2_START then
		arg_66_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_2_1)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_2_ONE, true)
	elseif var_66_0 == xyd.GuideStoryType.GUIDE_FIGHT_2_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_3_START, true)
		arg_66_0.selfPlayer:sendOperationLog(xyd.StatID.ID_FIGHT_3_1)
	elseif var_66_0 == xyd.GuideStoryType.ACTIVITY_FOUR then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.ACTIVITY_TWO, true)
	elseif var_66_0 == xyd.GuideStoryType.GUIDE_FIGHT_6_ONE or var_66_0 == xyd.GuideStoryType.GUIDE_FIGHT_6_START then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_6_TWO)
	elseif var_66_0 == xyd.GuideStoryType.GUIDE_FIGHT_6_TWO then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_6_END)
		xyd.StoryData.get():persist()
	elseif var_66_0 == xyd.GuideStoryType.GUIDE_FIGHT_7_START then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_7_END)
	elseif var_66_0 > xyd.GuideStoryType.GUIDE_FIGHT_3_END and var_66_0 <= xyd.GuideStoryType.GUIDE_MISSION_TWO then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_MISSION_ONE)
	elseif var_66_0 > xyd.GuideStoryType.GUIDE_MISSION_TWO and var_66_0 < xyd.GuideStoryType.GUIDE_MISSION_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_MISSION_END)
	end
end

function var_0_0.setIDAfterGuideWnd(arg_67_0)
	local var_67_0 = xyd.StoryData.get():getGuideID()

	if var_67_0 == xyd.GuideStoryType.GUIDE_FIGHT_5_ONE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_5_TWO, true)
	elseif var_67_0 == xyd.GuideStoryType.ACTIVITY_TWO then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.ACTIVITY_THREE, true)
	elseif var_67_0 == xyd.GuideStoryType.GUIDE_MISSION_ONE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_MISSION_TWO, true)
	elseif var_67_0 == xyd.GuideStoryType.GUIDE_MISSION_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_STONE_START, true)
	end
end

function var_0_0.checkIntoDetailWnd(arg_68_0)
	local var_68_0 = xyd.StoryData.get():getGuideID()

	if var_68_0 < xyd.GuideStoryType.GUIDE_CAMPAIGN_END or var_68_0 == xyd.GuideStoryType.GUIDE_FIGHT_2_START or var_68_0 == xyd.GuideStoryType.GUIDE_FIGHT_2_END or var_68_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_START or var_68_0 == xyd.GuideStoryType.GUIDE_FIGHT_5_START or var_68_0 == xyd.GuideStoryType.GUIDE_FIGHT_3_START or var_68_0 == xyd.GuideStoryType.GUIDE_CHAPTER_BOSS_START or var_68_0 == xyd.GuideStoryType.GUIDE_FIGHT_6_TWO or var_68_0 == xyd.GuideStoryType.GUIDE_FIGHT_7_START then
		return true
	end
end

function var_0_0.checkGuide(arg_69_0)
	if xyd.StoryData.get():getGuideID() >= xyd.GuideStoryType.GUIDE_FIGHT_6_END and xyd.WindowManager.get():getWindow("guide_new") then
		xyd.WindowManager.get():closeWindow("guide_new")
	end
end

function var_0_0.playGuide(arg_70_0)
	local var_70_0 = xyd.StoryData.get():getGuideID()

	if xyd.WindowManager.get():getWindow("guide") then
		xyd.WindowManager.get():closeWindow("guide")
	end

	if arg_70_0:checkIntoDetailWnd() then
		arg_70_0:setIDBeforeGuideWnd()

		var_70_0 = xyd.StoryData.get():getGuideID()

		local var_70_1 = arg_70_0.lastNode

		if var_70_0 == xyd.GuideStoryType.GUIDE_CHAPTER_BOSS_START then
			var_70_1 = arg_70_0.chapterBossNode
		end

		if var_70_1 then
			local var_70_2 = {
				250,
				350
			}

			if var_70_0 == xyd.GuideStoryType.GUIDE_FIGHT_3_START or var_70_0 == xyd.GuideStoryType.GUIDE_FIGHT_4_ONE or var_70_0 == xyd.GuideStoryType.GUIDE_FIGHT_5_ONE then
				var_70_2 = {
					650,
					350
				}
			end

			local var_70_3 = {
				width = 100,
				height = 100
			}
			local var_70_4 = cc.p(var_70_1:getPosition())
			local var_70_5 = arg_70_0:convertToNodeSpace(var_70_1:getParent():convertToWorldSpace(cc.p(var_70_4)))

			if var_70_0 == xyd.GuideStoryType.GUIDE_CHAPTER_BOSS_START then
				var_70_5.y = var_70_5.y
			elseif arg_70_0.lastNode and arg_70_0.lastNode.campaignType == var_0_6 then
				var_70_5.y = var_70_5.y + 20
			else
				var_70_5.y = var_70_5.y + 50
			end

			local var_70_6 = 2

			if var_70_0 == xyd.GuideStoryType.GUIDE_CAMPAIGN_MAP or var_70_0 == xyd.GuideStoryType.GUIDE_FIGHT_7_END then
				var_70_6 = 3
			end

			xyd.showGuideWnd(var_70_1, var_70_5, var_70_3, var_70_6, var_70_2, true)
		end

		arg_70_0:setIDAfterGuideWnd()
	elseif var_70_0 >= xyd.GuideStoryType.GUIDE_FIGHT_6_START and var_70_0 < xyd.GuideStoryType.GUIDE_FIGHT_6_TWO then
		arg_70_0:setIDBeforeGuideWnd()

		if arg_70_0.bossNode then
			local var_70_7 = arg_70_0.bossNode
			local var_70_8 = {
				650,
				350
			}
			local var_70_9 = {
				width = 100,
				height = 100
			}
			local var_70_10 = cc.p(var_70_7:getPosition())
			local var_70_11 = arg_70_0:convertToNodeSpace(var_70_7:getParent():convertToWorldSpace(cc.p(var_70_10)))

			var_70_11.y = var_70_11.y + 50

			local var_70_12 = 2

			xyd.showGuideWnd(var_70_7, var_70_11, var_70_9, var_70_12, var_70_8, true, true)
			arg_70_0.bossNode:setTouchEnabled(true)
			arg_70_0.bossNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_71_0)
				if arg_71_0.name == "began" then
					return true
				elseif arg_71_0.name == "ended" then
					if xyd.WindowManager.get():getWindow("guide") then
						xyd.WindowManager.get():closeWindow("guide")
					end

					arg_70_0:playGuide()
				end
			end)
		end
	elseif var_70_0 == xyd.GuideStoryType.GUIDE_MISSION_START then
		arg_70_0:setIDBeforeGuideWnd()

		local var_70_13 = arg_70_0:nodeByName("task_btn")
		local var_70_14 = cc.p(var_70_13:getPosition())
		local var_70_15 = {
			250,
			450
		}
		local var_70_16 = arg_70_0:convertToNodeSpace(var_70_13:getParent():convertToWorldSpace(cc.p(var_70_14)))

		xyd.showGuideWnd(var_70_13, var_70_16, nil, 2, var_70_15, true)
		arg_70_0:setIDAfterGuideWnd()
	elseif var_70_0 == xyd.GuideStoryType.GUIDE_MISSION_FOUR then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_MISSION_END)

		local var_70_17 = arg_70_0:nodeByName("top_sidebar"):nodeByName("return_btn")
		local var_70_18 = cc.p(var_70_17:getPosition())
		local var_70_19 = {
			250,
			450
		}
		local var_70_20 = arg_70_0:convertToNodeSpace(var_70_17:getParent():convertToWorldSpace(cc.p(var_70_18)))

		xyd.showGuideWnd(var_70_17, var_70_20, nil, 3, var_70_19, true)
		arg_70_0:setIDAfterGuideWnd()
	else
		local var_70_21 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
		local var_70_22 = xyd.db.stateVariable:getState(var_70_21.playerID, xyd.state.IS_SECOND_CHAPTER_GUIDE)

		if tonumber(var_70_22) == 0 and var_70_21.normal_chapter_id == 2 and var_70_21.normal_campaign_id == 200001 and arg_70_0.currentNormalChapter == 1 then
			xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_FIGHT_7_START, true)

			local var_70_23 = arg_70_0.right
			local var_70_24 = {
				800,
				150
			}
			local var_70_25 = {
				width = 100,
				height = 100
			}
			local var_70_26 = cc.p(var_70_23:getPosition())
			local var_70_27 = arg_70_0:convertToNodeSpace(var_70_23:getParent():convertToWorldSpace(cc.p(var_70_26)))
			local var_70_28 = 2

			xyd.showGuideWnd(var_70_23, var_70_27, var_70_25, var_70_28, var_70_24, true, true)

			local var_70_29 = {
				playerID = var_70_21.playerID,
				name = xyd.state.IS_SECOND_CHAPTER_GUIDE,
				state = tostring(1)
			}

			xyd.db.stateVariable:setState(var_70_29)
		end
	end

	if var_70_0 == xyd.GuideStoryType.GUIDE_SUPER_BATTLE_START then
		arg_70_0:playMenuAction(true, true)

		local var_70_30 = arg_70_0:nodeByName("menu_1")
		local var_70_31 = cc.p(var_70_30:getPosition())

		var_70_31.x = var_70_31.x - var_70_30:getContentSize().width / 2
		var_70_31.y = var_70_31.y + var_70_30:getContentSize().height / 2

		local var_70_32 = arg_70_0:convertToNodeSpace(var_70_30:getParent():convertToWorldSpace(cc.p(var_70_31)))

		xyd.showGuideWnd(var_70_30, var_70_32, nil, 2, nil, false)
	end

	if var_70_0 == xyd.GuideStoryType.ACTIVITY_TWO then
		local var_70_33 = arg_70_0:nodeByName("top_sidebar"):nodeByName("return_btn")
		local var_70_34 = cc.p(var_70_33:getPosition())
		local var_70_35 = {
			250,
			450
		}
		local var_70_36 = arg_70_0:convertToNodeSpace(var_70_33:getParent():convertToWorldSpace(cc.p(var_70_34)))

		xyd.showGuideWnd(var_70_33, var_70_36, nil, 3, var_70_35, true)
		arg_70_0:setIDAfterGuideWnd()
	end
end

function var_0_0.updateTypeBtnState(arg_72_0, arg_72_1)
	local var_72_0 = var_0_14[arg_72_1]
	local var_72_1 = 1
	local var_72_2 = arg_72_0:nodeByName("menu_plus")
	local var_72_3 = var_72_2:getChildByName("node_icon")

	var_72_3:removeAllChildren()
	xyd.AssetLoader.get():loadSprite("windows/map_window/new/icon_" .. var_72_0 .. ".png"):addTo(var_72_3)
	var_72_2:getChildByName("txt"):setString(var_0_11:translation("MAP_WINDOW_TYPE_" .. var_72_0))

	for iter_72_0 = 1, 4 do
		if var_72_0 ~= iter_72_0 then
			local var_72_4 = arg_72_0:nodeByName("menu_" .. var_72_1)

			var_72_4:setVisible(false)
			var_72_4:addTouchEventListener(function(arg_73_0, arg_73_1)
				if arg_73_1 == ccui.TouchEventType.ended and not arg_72_0.isMenuOnMove then
					xyd.playButtonSound()

					if iter_72_0 == var_0_13.NORMAL then
						arg_72_0:changeToNormal()
					elseif iter_72_0 == var_0_13.SUPER then
						arg_72_0:changeToSuper()
					elseif iter_72_0 == var_0_13.GUILD then
						arg_72_0:changeToTeam()
					elseif iter_72_0 == var_0_13.CHALLENGE then
						arg_72_0:changeToChallenge()
					end
				end
			end)

			local var_72_5 = var_72_4:getChildByName("node_icon")

			var_72_5:removeAllChildren()
			xyd.AssetLoader.get():loadSprite("windows/map_window/new/icon_" .. iter_72_0 .. ".png"):addTo(var_72_5)

			if not arg_72_0.campaignOpenState[iter_72_0] then
				var_72_4:setBright(false)
				var_72_4:setTouchEnabled(false)
			else
				var_72_4:setBright(true)
				var_72_4:setTouchEnabled(true)
			end

			var_72_4:getChildByName("txt"):setString(var_0_11:translation("MAP_WINDOW_TYPE_" .. iter_72_0))

			var_72_1 = var_72_1 + 1
		end
	end

	arg_72_0:nodeByName("plus"):setVisible(true)
	arg_72_0:nodeByName("sub"):setVisible(false)
end

function var_0_0.openCampaignTip(arg_74_0, arg_74_1)
	if xyd.WindowManager.get():isWindowOpen("toast") then
		xyd.WindowManager.get():closeWindow("toast")
	end

	local var_74_0 = 0

	if arg_74_1 == xyd.CampaignType.NORMAL then
		var_74_0 = 1
	elseif arg_74_1 == xyd.CampaignType.SUPER then
		var_74_0 = 2
	elseif arg_74_1 == xyd.CampaignType.GUILD then
		var_74_0 = 3
	elseif arg_74_1 == xyd.CampaignType.CHALLENGE then
		var_74_0 = 4
	end

	local var_74_1 = var_0_11:translation("CAMPAIGN_TYPE_TIP" .. var_74_0)

	xyd.WindowManager.get():openWindow("toast", {
		message = var_74_1,
		delay = arg_74_0.delay1
	})
end

function var_0_0.didClose(arg_75_0, arg_75_1)
	xyd.checkFirstInGuide("main_scene_bottom")

	local var_75_0 = xyd.StoryData.get():getGuideID()
	local var_75_1

	if var_75_0 == xyd.GuideStoryType.ACTIVITY_THREE then
		xyd.EventDispatcher.get():dispatchEvent({
			name = xyd.event.PLAY_GUIDE,
			params = {
				guide_id = xyd.GuideStoryType.ACTIVITY_THREE
			}
		})

		var_75_1 = true
	end

	if var_75_0 == xyd.GuideStoryType.GUIDE_STONE_START then
		local var_75_2 = xyd.WindowManager.get():getWindow("main_scene_bottom")

		if var_75_2 then
			var_75_2:playGuide()
		end

		var_75_1 = true
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_ACTION_START,
		params = {
			quickAction = var_75_1
		}
	})
	xyd.WindowManager.get():closeWindow("asset_wnd")
end

function var_0_0.functionClickRecord(arg_76_0, arg_76_1)
	arg_76_0.selfPlayer:sendFunctionClick(arg_76_1)
end

function var_0_0.changeToNormal(arg_77_0)
	arg_77_0:updateTypeBtnState(xyd.CampaignType.NORMAL)

	if arg_77_0.chapterType == xyd.CampaignType.NORMAL then
		return
	end

	arg_77_0.chapterType = xyd.CampaignType.NORMAL

	if arg_77_0.chapterType == xyd.CampaignType.GUILD then
		var_0_5 = arg_77_0.guild:getMinchapterID()
	else
		var_0_5 = 1
	end

	xyd.setCascadeOpacityEnabled(arg_77_0.oldContainer, true)
	arg_77_0.oldContainer:runActionOnce(cc.FadeOut:create(2), false, function()
		return
	end)

	arg_77_0.canClickCampaign = false

	var_0_10.performWithDelayGlobal(function()
		if arg_77_0 and not tolua.isnull(arg_77_0) then
			arg_77_0:openCampaignTip(xyd.CampaignType.NORMAL)
			arg_77_0:updateChapter()
			arg_77_0:updateBonus()

			arg_77_0.canClickCampaign = true
		end
	end, 0.5)
end

function var_0_0.changeToSuper(arg_80_0)
	arg_80_0:updateTypeBtnState(xyd.CampaignType.SUPER)

	if arg_80_0.chapterType == xyd.CampaignType.SUPER then
		return
	end

	arg_80_0.chapterType = xyd.CampaignType.SUPER

	if arg_80_0.chapterType == xyd.CampaignType.GUILD then
		var_0_5 = arg_80_0.guild:getMinchapterID()
	else
		var_0_5 = 1
	end

	arg_80_0.newFuncIDs = nil

	if arg_80_0.guideHand then
		arg_80_0:removeChild(arg_80_0.guideHand)

		arg_80_0.guideHand = nil
	end

	xyd.setCascadeOpacityEnabled(arg_80_0.oldContainer, true)
	arg_80_0.oldContainer:runActionOnce(cc.FadeOut:create(2), false, function()
		return
	end)

	arg_80_0.canClickCampaign = false

	var_0_10.performWithDelayGlobal(function()
		if arg_80_0 and not tolua.isnull(arg_80_0) then
			arg_80_0:openCampaignTip(xyd.CampaignType.SUPER)
			arg_80_0:updateChapter()
			arg_80_0:updateBonus()

			arg_80_0.canClickCampaign = true
		end

		if xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_SUPER_BATTLE_START then
			if xyd.WindowManager.get():isWindowOpen("guide") then
				xyd.WindowManager.get():closeWindow("guide")
			end

			xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_SUPER_BATTLE_END)
			xyd.StoryData.get():persist()
		end
	end, 0.5)
end

function var_0_0.changeToTeam(arg_83_0)
	arg_83_0:updateTypeBtnState(xyd.CampaignType.GUILD)

	if arg_83_0.chapterType == xyd.CampaignType.GUILD then
		return
	end

	arg_83_0.chapterType = xyd.CampaignType.GUILD

	if arg_83_0.chapterType == xyd.CampaignType.GUILD then
		var_0_5 = arg_83_0.guild:getMinchapterID()
	else
		var_0_5 = 1
	end

	arg_83_0.newFuncIDs = nil

	if arg_83_0.guideHand then
		arg_83_0:removeChild(arg_83_0.guideHand)

		arg_83_0.guideHand = nil
	end

	xyd.setCascadeOpacityEnabled(arg_83_0.oldContainer, true)
	arg_83_0.oldContainer:runActionOnce(cc.FadeOut:create(2), false)

	arg_83_0.canClickCampaign = false

	var_0_10.performWithDelayGlobal(function()
		if arg_83_0 and not tolua.isnull(arg_83_0) then
			arg_83_0:openCampaignTip(xyd.CampaignType.GUILD)
			arg_83_0:updateChapter()
			arg_83_0:updateBonus()

			arg_83_0.canClickCampaign = true
		end
	end, 0.5)
end

function var_0_0.changeToChallenge(arg_85_0)
	arg_85_0.selfPlayer:sendFunctionClick(xyd.FunctionClick.CHALLENGE)

	if arg_85_0.campaigns[var_0_9] == nil then
		if xyd.WindowManager.get():isWindowOpen("toast") then
			xyd.WindowManager.get():closeWindow("toast")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = var_0_11:translation("CHALLENGE_ISNOT_OPEN")
		})

		return
	end

	arg_85_0:updateTypeBtnState(xyd.CampaignType.CHALLENGE)

	if arg_85_0.chapterType == xyd.CampaignType.CHALLENGE then
		return
	end

	arg_85_0.chapterType = xyd.CampaignType.CHALLENGE
	var_0_5 = 1

	xyd.setCascadeOpacityEnabled(arg_85_0.oldContainer, true)
	arg_85_0.oldContainer:runActionOnce(cc.FadeOut:create(2), false, function()
		return
	end)

	arg_85_0.canClickCampaign = false

	var_0_10.performWithDelayGlobal(function()
		if arg_85_0 and not tolua.isnull(arg_85_0) then
			arg_85_0:openCampaignTip(xyd.CampaignType.CHALLENGE)
			arg_85_0:updateChapter()
			arg_85_0:updateBonus()

			arg_85_0.canClickCampaign = true
		end
	end, 0.5)
end

function var_0_0.addTouchSwallow(arg_88_0)
	for iter_88_0 = 1, 3 do
		local var_88_0 = arg_88_0:nodeByName("menu_" .. iter_88_0)
		local var_88_1 = display.newNode()

		var_88_1:setContentSize(var_88_0:getContentSize())
		var_88_1:setTouchSwallowEnabled(true)
		var_88_1:setTouchEnabled(true)
		var_88_1:addTo(var_88_0)
	end
end

return var_0_0
