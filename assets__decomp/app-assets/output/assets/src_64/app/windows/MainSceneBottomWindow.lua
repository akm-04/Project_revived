local var_0_0 = class("MainSceneBottomWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = "skeletons/ui_effect/skill_full/skill"
local var_0_3 = import("app.common.ui.SpineEffect")
local var_0_4 = xyd.tables.translation
local var_0_5 = 8
local var_0_6 = 177
local var_0_7 = {
	"CHAT_SHIJIE",
	"CHAT_SIREN",
	"CHAT_SHETUAN",
	"CHAT_GM",
	"CHAT_KUAFU",
	"CHAT_ZUDUI"
}
local var_0_8 = {
	{
		nodeName = "hero",
		windowName = "hero_list"
	},
	{
		nodeName = "backpack",
		windowName = "backpack"
	},
	{
		nodeName = "mission",
		windowName = "mission"
	},
	{
		nodeName = "pet",
		windowName = "pet_collect"
	},
	{
		nodeName = "guild",
		windowName = "guild"
	}
}
local var_0_9 = {
	guild = 8,
	backpack = 5,
	chat = 1,
	pet = 7,
	mail = 2,
	hero = 6,
	mission = 4
}

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	arg_1_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.GuideHands = {}
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.activitiesModel = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
	arg_1_0.globalTimer = xyd.ModelManager.get():loadModel(xyd.ModelType.GLOBAL_TIMER)
	arg_1_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_1_0.giftPushModel = xyd.ModelManager.get():loadModel(xyd.ModelType.GIFT_PUSH)
	arg_1_0.task = xyd.ModelManager.get():loadModel(xyd.ModelType.TASK)
	arg_1_0.redmark = xyd.ModelManager.get():loadModel(xyd.ModelType.REDMARK)

	arg_1_0:setTouchSwallowEnabled(false)
	arg_1_0:setTouchEnabled(false)
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	local var_2_0 = arg_2_0:nodeByName("hero")

	var_2_0:getChildByName("label"):setString(var_0_4:translation("HERO_WUJIANG"))
	var_2_0:addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_2_0:removeGuideHand("hero")

			if arg_2_0.selfPlayer.lev < 20 then
				arg_2_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_HERO_LEV_LESS_20)
			end

			arg_2_0.selfPlayer:loadHeros({}, function(arg_4_0)
				if arg_4_0 == xyd.error.OK then
					if xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_EQUIP_END then
						arg_2_0.selfPlayer:sendOperationLog(xyd.StatID.ID_CLICK_HEROWND)
					end

					if not arg_2_0.selfPlayer:getBackpack() then
						arg_2_0.selfPlayer:loadBackpack(function(arg_5_0)
							if arg_5_0 == xyd.error.OK then
								xyd.WindowManager.get():openWindow("hero_list")

								if arg_2_0.selfPlayer:getSkillPoint() == arg_2_0.selfPlayer:getSkillPointLimit() then
									arg_2_0.selfPlayer:setPressHero(true, arg_2_0.selfPlayer.hasChangeSkill)
									arg_2_0:nodeByName("skill_is_full"):setVisible(false)
								end
							end
						end)
					else
						xyd.WindowManager.get():openWindow("hero_list")

						if arg_2_0.selfPlayer:getSkillPoint() == arg_2_0.selfPlayer:getSkillPointLimit() then
							arg_2_0.selfPlayer:setPressHero(true, arg_2_0.selfPlayer.hasChangeSkill)
							arg_2_0:nodeByName("skill_is_full"):setVisible(false)
						end
					end
				end
			end)
		end
	end)

	local var_2_1 = arg_2_0:nodeByName("backpack")

	var_2_1:getChildByName("label"):setString(var_0_4:translation("BACKPACK"))
	var_2_1:addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("backpack")
		end
	end)

	local var_2_2 = arg_2_0:nodeByName("mission")

	var_2_2:getChildByName("label"):setString(var_0_4:translation("MISSION"))
	var_2_2:addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_2_0.task:loadTaskByType(nil, function(arg_8_0)
				if arg_8_0 == xyd.error.OK then
					arg_2_0.selfPlayer:loadWorldMap(function()
						xyd.WindowManager.get():openWindow("task")
						xyd.sendGudieBtnClick("mission")
					end)
				end
			end)
		end
	end)

	local var_2_3 = arg_2_0:nodeByName("pet")

	var_2_3:getChildByName("label"):setString(var_0_4:translation("PET"))
	var_2_3:addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			arg_2_0.giftPushModel:judgePush(2)

			if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_PET) == true then
				arg_2_0.globalTimer:checkIsMakingChild()
				xyd.WindowManager.get():openWindow("pet_collect")
			else
				local var_10_0 = xyd.tables.functionOpen
				local var_10_1 = string.format(var_0_4:translation("FUNCTION_OPEN_TIP_LEVEL"), var_10_0:level(xyd.FunctionID.ID_PET))

				xyd.WindowManager.get():openWindow("toast", {
					message = var_10_1
				})
			end
		end
	end)
	xyd.nodeEventSample(arg_2_0:nodeByName("faq"), nil, function()
		xyd.WindowManager.get():openWindow("faq")
	end)
	arg_2_0:updateFaqBtnShow()

	arg_2_0.notifies = {}
	arg_2_0.notifies[1] = arg_2_0:nodeByName("chat_notif")
	arg_2_0.notifies[4] = arg_2_0:nodeByName("mission_notif")
	arg_2_0.notifies[5] = arg_2_0:nodeByName("backpack_notif")
	arg_2_0.notifies[6] = arg_2_0:nodeByName("hero_notif")
	arg_2_0.notifies[7] = arg_2_0:nodeByName("pet_notif")
	arg_2_0.notifies[8] = arg_2_0:nodeByName("guild_notif")
	arg_2_0.guild = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.DRINK_NOTIF, handler(arg_2_0, arg_2_0.updateGuildNotif))
	arg_2_0:nodeByName("guild_notif"):setVisible(false)

	if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_GUILD) == true then
		arg_2_0.guild:loadSelfGuild(function()
			if arg_2_0.guild and arg_2_0.guild.guild_id ~= nil and arg_2_0.guild.guild_id ~= 0 then
				arg_2_0:updateGuildNotif(nil)
			end
		end)
	end

	local var_2_4 = arg_2_0:nodeByName("chat")

	var_2_4:setTouchEnabled(true)
	var_2_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
		if arg_13_0.name == "began" then
			var_2_4:setScale(0.8)

			return true
		elseif arg_13_0.name == "cancled" then
			var_2_4:setScale(1)
		elseif arg_13_0.name == "ended" then
			xyd.playButtonSound()
			var_2_4:setScale(1)

			if arg_2_0.selfPlayer.lev < var_0_5 and not xyd.isDebug() then
				local var_13_0 = string.format(var_0_4:translation("FUNCTION_OPEN_TIP_LEVEL"), var_0_5)

				xyd.WindowManager.get():openWindow("toast", {
					message = var_13_0
				})

				return true
			end

			xyd.WindowManager.get():openWindow("chat")
		end
	end)

	local var_2_5 = arg_2_0:nodeByName("chat_notif")

	var_2_5:setVisible(false)

	arg_2_0.notifies[var_0_9.chat] = var_2_5

	arg_2_0:nodeByName("guild"):getChildByName("label"):setString(var_0_4:translation("GUILD"))
	arg_2_0:nodeByName("guild"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()

			if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_GUILD) ~= true then
				local var_14_0
				local var_14_1 = xyd.tables.functionOpen
				local var_14_2 = xyd.tables.translation

				if var_14_1:level(xyd.FunctionID.ID_GUILD) > 1 then
					var_14_0 = string.format(var_14_2:translation("FUNCTION_OPEN_TIP_LEVEL"), var_14_1:level(xyd.FunctionID.ID_GUILD))
				elseif var_14_1:stage(xyd.FunctionID.ID_GUILD) > 0 then
					local var_14_3 = xyd.tables.campaign
					local var_14_4 = "NUM_" .. var_14_3:chapter(var_14_1:stage(xyd.FunctionID.ID_GUILD))

					var_14_0 = string.format(var_14_2:translation("FUNCTION_OPEN_TIP_STAGE"), var_14_2:translation(var_14_4))
				else
					var_14_0 = string.format(var_14_2:translation("FUNCTION_OPEN_TIP_OTHER"))
				end

				if xyd.WindowManager.get():getWindow("toast") ~= nil then
					xyd.WindowManager.get():closeWindow("toast")
				end

				xyd.WindowManager.get():openWindow("toast", {
					message = var_14_0
				})

				return true
			end

			arg_2_0:removeGuideHand("guild")
			arg_2_0.guild:loadSelfGuild(function(arg_15_0)
				if arg_15_0 == xyd.error.OK then
					if arg_2_0.guild.guild_id == nil or arg_2_0.guild.guild_id == 0 then
						xyd.WindowManager.get():openWindow("team_main")
					else
						xyd.WindowManager.get():openWindow("team")
					end
				end
			end)
		end
	end)

	if not arg_2_0.skillEffect then
		local var_2_6 = var_0_2 .. ".json"
		local var_2_7 = var_0_2 .. ".atlas"

		arg_2_0.skillEffect = var_0_3.new(var_2_6, var_2_7, 1)

		arg_2_0.skillEffect:setAnchorPoint(cc.p(0.5, 0.5))
		arg_2_0.skillEffect:setPosition(-25, -10)
		arg_2_0.skillEffect:addTo(arg_2_0:nodeByName("skill_is_full"))
	end

	arg_2_0.skillEffect:play(nil, true)

	if arg_2_0.selfPlayer.lev <= xyd.tables.misc.skill_point_full_hide_max_lv then
		arg_2_0:updateSkillFull()
	else
		arg_2_0:nodeByName("skill_is_full"):setVisible(false)
	end

	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.MAIN_SCENE_BOTTOM_NOTIFY, function(arg_16_0)
		if arg_16_0.params then
			local var_16_0 = arg_16_0.params.index
			local var_16_1 = arg_16_0.params.show or false

			arg_2_0:updateNotify(var_16_0, var_16_1)
		end
	end)
	arg_2_0:updateBackendRedmark()
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.BACKEND_REDMARK, function(arg_17_0)
		arg_2_0:updateBackendRedmark()
	end)

	if arg_2_0.selfPlayer:isFuncOpen(xyd.FunctionID.ID_PET) == true and (not arg_2_0.selfPlayer.collectedPets or #arg_2_0.selfPlayer.collectedPets < 1) then
		if xyd.StoryData.get():getGuideID() < xyd.GuideStoryType.GUIDE_PET_ONE then
			if xyd.WindowManager.get():getWindow("levelup") then
				xyd.WindowManager.get():closeWindow("levelup")
			end

			if arg_2_0.firstLoadPet == nil then
				arg_2_0.selfPlayer:loadCollectedPets(function(arg_18_0, arg_18_1)
					if arg_18_0 == xyd.error.OK then
						if arg_2_0.selfPlayer.collectedPets and arg_2_0.selfPlayer.collectedPets[1] and arg_2_0.selfPlayer.collectedPets[1]:isCollected() and arg_2_0.selfPlayer.collectedPets[1].is_show_ == 1 then
							xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_PET_ONE)
							xyd.StoryData.get():persist()
							xyd.EventDispatcher.get():dispatchEvent({
								name = xyd.event.PET_GUIDE_TO_CAMPAIGN
							})
						else
							arg_2_0.selfPlayer:setPetGuideId()
							arg_2_0:playPetGuide()
						end
					end
				end)
			else
				arg_2_0.selfPlayer:setPetGuideId()
				arg_2_0:playPetGuide()
			end

			arg_2_0.firstLoadPet = true
		elseif xyd.StoryData.get():getGuideID() == xyd.GuideStoryType.GUIDE_PET_TWO then
			arg_2_0:playGuide(true)
		end

		arg_2_0.globalTimer:checkIsMakingChild()
	end

	arg_2_0.socialSystem:loadFriends({}, function(arg_19_0, arg_19_1)
		local var_19_0 = xyd.WindowManager.get():getWindow("main_scene_bottom")

		if var_19_0 and not tolua.isnull(var_19_0) then
			var_19_0:refreshNoticeState()
		end

		xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM):handleFriendMessageDB()
	end)
	arg_2_0:initChatShow()

	local var_2_8 = arg_2_0:nodeByName("background")
	local var_2_9 = display.newNode()

	var_2_9:addTo(var_2_8, -1)

	local var_2_10 = var_2_8:getContentSize()

	var_2_9:setContentSize(var_2_10.width, var_2_10.height)
	var_2_9:setTouchEnabled(true)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.MAIN_SCENE_ACTION_START, function(arg_20_0)
		arg_2_0:onEnterAction(arg_20_0.params and arg_20_0.params.quickAction)
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.MAIN_SCENE_ACTION_END, function(arg_21_0)
		arg_2_0:onEnterActionEnd()
	end)
end

function var_0_0.updateFaqBtnShow(arg_22_0)
	arg_22_0:nodeByName("faq"):setVisible(xyd.db.settings:getShowFAQ() == 1)
end

function var_0_0.initChatShow(arg_23_0)
	arg_23_0.chatShowContainer = arg_23_0:nodeByName("bg_chat_show")

	arg_23_0.chatShowContainer:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_24_0)
		if arg_24_0.name == "ended" then
			xyd.WindowManager.get():openWindow("chat")
		end
	end)

	local var_23_0 = arg_23_0:nodeByName("chat_show_list")
	local var_23_1 = var_23_0:getContentSize()
	local var_23_2 = display.newClippingRegionNode(cc.rect(0, 0, var_23_1.width, var_23_1.height))

	var_23_2:addTo(var_23_0)

	arg_23_0.chatShowLabel = xyd.AssetLoader.get():loadNodeFromJson("windows/chat_window/chat_show/chat_show_item.csb")

	arg_23_0.chatShowLabel:addTo(var_23_2)

	arg_23_0.chatContentLabel = xyd.AssetLoader.get():loadLabel({
		size = 24,
		color = cc.c3b(255, 255, 255),
		text = var_0_4:translation("CHAT_WELCOME")
	}):addTo(var_23_0):pos(30, var_23_1.height / 2)

	arg_23_0.chatShowContainer:setVisible(true)

	arg_23_0.chatShowHandle = var_0_1.performWithDelayGlobal(function()
		arg_23_0.chatShowLabel:runAction(cc.Sequence:create({
			cc.DelayTime:create(0.3),
			cc.CallFunc:create(function()
				arg_23_0.chatContentLabel:setVisible(false)
			end)
		}))
		arg_23_0.chatShowContainer:runAction(cc.FadeTo:create(0.7, 37))

		arg_23_0.chatShowS = true
	end, 5)
end

function var_0_0.ChatShowEvent(arg_27_0, arg_27_1, arg_27_2)
	if not arg_27_0.chatShowS then
		return
	end

	arg_27_0.chatShowS = nil

	if arg_27_0.chatContentLabel then
		arg_27_0.chatContentLabel:removeSelf()
	end

	arg_27_0.chatShowContainer:stopAllActions()
	arg_27_0.chatShowLabel:stopAllActions()
	arg_27_0.chatShowLabel:setPosition(0, 5)
	arg_27_0.chatShowLabel:getChildByName("label_channel"):setString("[" .. var_0_4:translation(var_0_7[arg_27_1 + 1]) .. "]")
	arg_27_0.chatShowLabel:getChildByName("label_name"):setString(arg_27_2.player_name)

	local var_27_0 = arg_27_2.message

	if arg_27_2.type == xyd.ChatTextType.REPORT then
		var_27_0 = var_0_4:translation("CHAT_SHARE_TIPS")
	elseif arg_27_2.type == xyd.ChatTextType.ILLUSION then
		var_27_0 = string.format(var_0_4:translation("CHAT_ZUDUI_TIPS"), json.decode(var_27_0).boss_name)
	elseif arg_27_2.type == xyd.ChatTextType.OCCULT then
		local var_27_1 = json.decode(var_27_0).chapter_id
		local var_27_2 = xyd.tables.creatsChapterSelect:chapterName(tonumber(var_27_1))

		var_27_0 = string.format(var_0_4:translation("OCCULT_COMPANION_TIP"), var_27_2)
	elseif arg_27_2.type == xyd.ChatTextType.ADVENTURE_ILLUSION then
		var_27_0 = var_0_4:translation("ADVENTURE_EVENT_PARADISE_TIP")
	elseif arg_27_2.type == xyd.ChatTextType.ADVENTURE_DEFENSE then
		var_27_0 = var_0_4:translation("ADVENTURE_EVENT_MONSTER_TIP")
	elseif arg_27_2.type == xyd.ChatTextType.RAGNAROK then
		var_27_0 = string.format(var_0_4:translation("RAGNAROK_BOSS_TEAM_28"), json.decode(var_27_0).boss_name)
	else
		local var_27_3 = xyd.split(var_27_0, "|")

		if var_27_3 and var_27_3[1] and var_27_3[2] == "[s&i?g&n]" then
			var_27_0 = "[" .. xyd.tables.emoticon:words(tonumber(var_27_3[1])) .. "]"
		end
	end

	arg_27_0.chatContentLabel = xyd.AssetLoader.get():loadLabel({
		size = 21,
		align = cc.ui.TEXT_ALIGN_LEFT,
		valign = cc.ui.TEXT_VALIGN_BOTTOM,
		color = cc.c3b(255, 255, 255),
		dimensions = cc.size(200, 0),
		text = var_27_0
	})

	arg_27_0.chatContentLabel:setLineBreakWithoutSpace(true)
	arg_27_0.chatContentLabel:setAnchorPoint(cc.p(0, 1))
	arg_27_0.chatContentLabel:pos(20, 20):addTo(arg_27_0.chatShowLabel)

	local var_27_4 = arg_27_0.chatContentLabel:getContentSize().height

	arg_27_0.chatShowLabel:runAction(cc.Sequence:create({
		cc.DelayTime:create(0.4),
		cc.CallFunc:create(function()
			arg_27_0.chatShowLabel:setVisible(true)
		end)
	}))
	arg_27_0.chatShowContainer:runAction(cc.Sequence:create({
		cc.FadeTo:create(0.7, 255),
		cc.CallFunc:create(function()
			arg_27_0.chatShowLabel:runAction(cc.Sequence:create({
				cc.DelayTime:create(1),
				cc.MoveTo:create(var_27_4 / 24 - 0.99, cc.p(0, var_27_4 - 24)),
				cc.DelayTime:create(3),
				cc.CallFunc:create(function()
					arg_27_0.chatShowLabel:runAction(cc.Sequence:create({
						cc.DelayTime:create(0.4),
						cc.CallFunc:create(function()
							arg_27_0.chatShowLabel:setVisible(false)
						end)
					}))
					arg_27_0.chatShowContainer:runAction(cc.FadeTo:create(0.7, 37))
				end)
			}))
		end)
	}))

	if arg_27_0.chatShowHandle then
		var_0_1.unscheduleGlobal(arg_27_0.chatShowHandle)
	end

	arg_27_0.chatShowHandle = var_0_1.performWithDelayGlobal(function()
		arg_27_0.chatShowS = true
	end, 1)
end

function var_0_0.functionClickRecord(arg_33_0, arg_33_1)
	local var_33_0

	if arg_33_1 == "chat" then
		var_33_0 = xyd.FunctionClick.CHAT
	elseif arg_33_1 == "friend" then
		var_33_0 = xyd.FunctionClick.FRIEND
	elseif arg_33_1 == "pet" then
		var_33_0 = xyd.FunctionClick.PET
	elseif arg_33_1 == "hero" then
		var_33_0 = xyd.FunctionClick.HERO
	elseif arg_33_1 == "mail" then
		var_33_0 = xyd.FunctionClick.MAILBOX
	end

	if var_33_0 then
		arg_33_0.selfPlayer:sendFunctionClick(var_33_0)
	end
end

function var_0_0.removeGuideHand(arg_34_0, arg_34_1)
	local var_34_0 = arg_34_0.GuideHands[arg_34_1]

	if var_34_0 ~= nil then
		if var_34_0.nodes and next(var_34_0.nodes) then
			for iter_34_0, iter_34_1 in pairs(var_34_0.nodes) do
				arg_34_0:removeChild(iter_34_1)
			end
		end

		newFuncIDs = var_34_0.funcIDs

		if var_34_0.funcIDs and next(var_34_0.funcIDs) then
			for iter_34_2, iter_34_3 in pairs(var_34_0.funcIDs) do
				xyd.StoryData.get():removeFuncID(iter_34_3)
			end
		end

		arg_34_0.GuideHands[arg_34_1] = nil
	end
end

function var_0_0.refreshNoticeState(arg_35_0)
	if tonumber(xyd.db.stateVariable:getState(arg_35_0.selfPlayer.playerID, xyd.state.NOTICE_COUNT)) < #arg_35_0.socialSystem.noticelist then
		arg_35_0.socialSystem:setIsHasNewNoticeState(1)
		arg_35_0.socialSystem:refreshRedMark()
	end
end

function var_0_0.handleFriendMessageDB(arg_36_0)
	for iter_36_0, iter_36_1 in ipairs(arg_36_0.socialSystem.friendlist) do
		xyd.db.friendMessages:deleteRecordsIfOverlimit(arg_36_0.selfPlayer.playerID, iter_36_1.player_id, xyd.tables.misc.offlineMessageNumber)
	end
end

function var_0_0.playPetGuide(arg_37_0, arg_37_1)
	if xyd.WindowManager.get():getWindow("guide") == nil then
		if arg_37_0.selfPlayer.collectedPets and #arg_37_0.selfPlayer.collectedPets > 0 and arg_37_0.selfPlayer.collectedPets[1].is_show_ == 1 then
			arg_37_0.selfPlayer:setPetGuideId()
			arg_37_0:playGuide(true)
		end

		if arg_37_0.selfPlayer.petGuideId == 1 then
			local var_37_0 = {
				egg_id = xyd.tables.misc.firstEgg,
				has_egg = arg_37_1
			}

			xyd.WindowManager.get():openWindow("pet_get_egg", var_37_0)
		end
	end
end

function var_0_0.updateSkillFull(arg_38_0)
	if arg_38_0.skillTimer then
		var_0_1.unscheduleGlobal(arg_38_0.skillTimer)
	end

	arg_38_0.skillPoints = arg_38_0.selfPlayer:getSkillPoint()

	if arg_38_0.selfPlayer.hasPressHero == nil then
		if arg_38_0.skillPoints < arg_38_0.selfPlayer:getSkillPointLimit() then
			arg_38_0:nodeByName("skill_is_full"):setVisible(false)
		else
			arg_38_0:nodeByName("skill_is_full"):setVisible(true)
		end
	elseif arg_38_0.selfPlayer.hasPressHero == true then
		arg_38_0:nodeByName("skill_is_full"):setVisible(false)
	elseif arg_38_0.skillPoints < arg_38_0.selfPlayer:getSkillPointLimit() then
		arg_38_0:nodeByName("skill_is_full"):setVisible(false)
	elseif arg_38_0.selfPlayer.hasChangeSkill == nil then
		arg_38_0:nodeByName("skill_is_full"):setVisible(true)
		arg_38_0.selfPlayer:setPressHero(arg_38_0.selfPlayer.hasPressHero, false)
	elseif arg_38_0.selfPlayer.hasChangeSkill == true then
		arg_38_0:nodeByName("skill_is_full"):setVisible(true)
		arg_38_0.selfPlayer:setPressHero(arg_38_0.selfPlayer.hasPressHero, false)
	end

	if arg_38_0.selfPlayer.lev < xyd.tables.misc.skill_point_full_hide_min_lv then
		arg_38_0:nodeByName("skill_is_full"):setVisible(false)
	end

	if arg_38_0.skillTimer == nil then
		arg_38_0.skillTimer = var_0_1.scheduleGlobal(handler(arg_38_0, arg_38_0.timerUpdate), 1)
	end
end

function var_0_0.timerUpdate(arg_39_0)
	if arg_39_0.time_index == nil then
		arg_39_0.time_index = 0
	else
		arg_39_0.time_index = arg_39_0.time_index + 1
	end

	local var_39_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

	if arg_39_0.selfPlayer.lev <= xyd.tables.misc.skill_point_full_hide_max_lv and arg_39_0.selfPlayer.lev >= xyd.tables.misc.skill_point_full_hide_min_lv then
		if arg_39_0 and tolua.isnull(arg_39_0) ~= true then
			arg_39_0.skillPoints = arg_39_0.selfPlayer:getSkillPoint()

			if arg_39_0.skillPoints < arg_39_0.selfPlayer:getSkillPointLimit() then
				arg_39_0.selfPlayer:setPressHero(arg_39_0.selfPlayer.hasPressHero, true)
			elseif arg_39_0.selfPlayer.hasChangeSkill and arg_39_0.selfPlayer.hasChangeSkill == true then
				arg_39_0.selfPlayer:setPressHero(false, arg_39_0.selfPlayer.hasChangeSkill)
			end

			if arg_39_0.selfPlayer.hasPressHero == nil then
				if arg_39_0.skillPoints < arg_39_0.selfPlayer:getSkillPointLimit() then
					arg_39_0:nodeByName("skill_is_full"):setVisible(false)
				else
					arg_39_0:nodeByName("skill_is_full"):setVisible(true)
				end
			elseif arg_39_0.selfPlayer.hasPressHero == true then
				arg_39_0:nodeByName("skill_is_full"):setVisible(false)
			elseif arg_39_0.skillPoints < arg_39_0.selfPlayer:getSkillPointLimit() then
				arg_39_0:nodeByName("skill_is_full"):setVisible(false)
			elseif arg_39_0.selfPlayer.hasChangeSkill == nil then
				arg_39_0:nodeByName("skill_is_full"):setVisible(true)
				arg_39_0.selfPlayer:setPressHero(arg_39_0.selfPlayer.hasPressHero, false)
			elseif arg_39_0.selfPlayer.hasChangeSkill == true then
				arg_39_0:nodeByName("skill_is_full"):setVisible(true)
				arg_39_0.selfPlayer:setPressHero(arg_39_0.selfPlayer.hasPressHero, false)
			end
		end

		if arg_39_0.time_index and arg_39_0.time_index == 5 then
			arg_39_0.time_index = nil

			arg_39_0.skillEffect:play(nil, true)
		end
	else
		arg_39_0:nodeByName("skill_is_full"):setVisible(false)
	end

	if var_39_0.teaTalkFinish then
		arg_39_0:nodeByName("guild_notif"):setVisible(true)
	else
		arg_39_0:nodeByName("guild_notif"):setVisible(false)
	end

	if arg_39_0.skillTimer and arg_39_0.selfPlayer.lev > xyd.tables.misc.skill_point_full_hide_max_lv then
		arg_39_0:nodeByName("skill_is_full"):setVisible(false)
		var_0_1.unscheduleGlobal(arg_39_0.skillTimer)
	end

	if var_39_0.warStep then
		local var_39_1 = xyd.tables.guildBattleTable
		local var_39_2 = var_39_1:season(var_39_0.warStep) or 0
		local var_39_3 = var_39_1:round(var_39_0.warStep) or 0
		local var_39_4 = var_39_1:step(var_39_0.warStep) or 0
		local var_39_5 = 0

		if var_39_4 == xyd.GuildWarStep.ENROLL then
			var_39_5 = var_39_2 * 100 + var_39_3 * 10 + 1
		elseif var_39_4 == xyd.GuildWarStep.PREPARE and var_39_0.isEnrollWar and var_39_0.isEnrollWar == 1 then
			var_39_5 = var_39_2 * 100 + var_39_3 * 10 + 2
		end

		if var_39_5 >= 111 and var_39_5 > xyd.db.guildWarRedPoint:getGuildWarRedPointData() then
			arg_39_0:nodeByName("guild_notif"):setVisible(true)
		end
	end
end

function var_0_0.updateGuildNotif(arg_40_0, arg_40_1)
	local var_40_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_GUILD)

	arg_40_0:nodeByName("guild_notif"):setVisible(false)

	if var_40_0.guild_id and var_40_0.guild_id ~= 0 then
		local function var_40_1()
			if xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER).lev > xyd.tables.misc.skill_point_full_hide_max_lv then
				arg_40_0:nodeByName("skill_is_full"):setVisible(false)

				if arg_40_0.skillTimer then
					var_0_1.unscheduleGlobal(arg_40_0.skillTimer)
				elseif var_40_0.teaTalkFinish then
					arg_40_0:nodeByName("guild_notif"):setVisible(true)
				else
					arg_40_0:nodeByName("guild_notif"):setVisible(false)
				end

				arg_40_0.skillTimer = var_0_1.scheduleGlobal(handler(arg_40_0, arg_40_0.timerUpdate), 1)
			elseif var_40_0.teaTalkFinish then
				arg_40_0:nodeByName("guild_notif"):setVisible(true)
			else
				arg_40_0:nodeByName("guild_notif"):setVisible(false)
			end
		end

		if arg_40_1 == nil then
			var_40_0:getTeaTalkInfo(function(arg_42_0, arg_42_1)
				if arg_42_0 == xyd.error.OK then
					if not arg_40_0 or tolua.isnull(arg_40_0) then
						return
					end

					var_40_1()
				end
			end, {
				is_self = 1
			})
		else
			var_40_1()
		end

		if var_40_0.warStep then
			local var_40_2 = xyd.tables.guildBattleTable
			local var_40_3 = var_40_2:season(var_40_0.warStep) or 0
			local var_40_4 = var_40_2:round(var_40_0.warStep) or 0
			local var_40_5 = var_40_2:step(var_40_0.warStep) or 0
			local var_40_6 = 0

			if var_40_5 == xyd.GuildWarStep.ENROLL then
				var_40_6 = var_40_3 * 100 + var_40_4 * 10 + 1
			elseif var_40_5 == xyd.GuildWarStep.PREPARE and var_40_0.isEnrollWar and var_40_0.isEnrollWar == 1 then
				var_40_6 = var_40_3 * 100 + var_40_4 * 10 + 2
			end

			if var_40_6 >= 111 and var_40_6 > xyd.db.guildWarRedPoint:getGuildWarRedPointData() then
				arg_40_0:nodeByName("guild_notif"):setVisible(true)
			end
		end
	else
		arg_40_0.drink_time = 0

		if arg_40_0.skillTimer and arg_40_0.selfPlayer.lev > xyd.tables.misc.skill_point_full_hide_max_lv then
			var_0_1.unscheduleGlobal(arg_40_0.skillTimer)
		end

		arg_40_0:nodeByName("guild_notif"):setVisible(false)
	end
end

function var_0_0.willClose(arg_43_0, arg_43_1)
	if arg_43_0.skillTimer then
		var_0_1.unscheduleGlobal(arg_43_0.skillTimer)
	end

	if arg_43_0.chatShowHandle then
		var_0_1.unscheduleGlobal(arg_43_0.chatShowHandle)
	end

	if arg_43_0.chatShowContainer and not tolua.isnull(arg_43_0.chatShowContainer) then
		arg_43_0.chatShowContainer:stopAllActions()

		if arg_43_0.chatShowLabel and not tolua.isnull(arg_43_0.chatShowLabel) then
			arg_43_0.chatShowLabel:stopAllActions()
		end
	end
end

function var_0_0.didOpen(arg_44_0, arg_44_1)
	arg_44_0.selfPlayer:checkEquipableAndSummon()
	xyd.ModelManager.get():loadModel(xyd.ModelType.MAILBOX):checkNewMail()
end

function var_0_0.updateNotify(arg_45_0, arg_45_1, arg_45_2)
	if arg_45_1 > 0 and arg_45_1 <= #arg_45_0.notifies and arg_45_0.notifies[arg_45_1] then
		if arg_45_1 == 3 then
			if arg_45_0.socialSystem:isHasRedMarkShow() then
				arg_45_0.notifies[arg_45_1]:setVisible(true)
			else
				arg_45_0.notifies[arg_45_1]:setVisible(false)
			end

			return
		end

		arg_45_0.notifies[arg_45_1]:setVisible(arg_45_2)
	end
end

function var_0_0.updateBackendRedmark(arg_46_0)
	local var_46_0 = xyd.ModelManager.get():loadModel(xyd.ModelType.BATTLE_PASS)

	if arg_46_0.redmark:isRedmark(xyd.FunctionID.ID_MISSION, xyd.redmark.DAILY_TASK) or arg_46_0.redmark:isRedmark(xyd.FunctionID.ID_MISSION, xyd.redmark.GROW_TASK) or arg_46_0.redmark:isRedmark(xyd.FunctionID.ID_MISSION, xyd.redmark.AWAKE_TASK) or arg_46_0.redmark:isRedmark(xyd.FunctionID.ID_MISSION, xyd.redmark.PARTNER_TASK) or var_46_0:isOpen() and arg_46_0.redmark:isRedmark(xyd.FunctionID.ID_BATTLE_PASS, xyd.redmark.BATTLE_PASS_MISSION_COMPLETE) then
		arg_46_0.notifies[var_0_9.mission]:setVisible(true)
	else
		arg_46_0.notifies[var_0_9.mission]:setVisible(false)
	end
end

function var_0_0.checkGuideIntoHero(arg_47_0)
	local var_47_0 = xyd.StoryData.get():getGuideID()

	if var_47_0 >= xyd.GuideStoryType.GUIDE_EQUIP_START and var_47_0 < xyd.GuideStoryType.GUIDE_EQUIP_END or var_47_0 >= xyd.GuideStoryType.GUIDE_LEVUP_START and var_47_0 < xyd.GuideStoryType.GUIDE_LEVUP_END or var_47_0 >= xyd.GuideStoryType.GUIDE_MISSION_FOUR and var_47_0 <= xyd.GuideStoryType.GUIDE_STONE_END or var_47_0 >= xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_START and var_47_0 < xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_END or var_47_0 >= xyd.GuideStoryType.GUIDE_SKILL_START and var_47_0 < xyd.GuideStoryType.GUIDE_SKILL_END then
		return true
	end

	if var_47_0 >= xyd.GuideStoryType.GUIDE_MISSION_START and var_47_0 <= xyd.GuideStoryType.GUIDE_MISSION_END then
		local var_47_1 = arg_47_0.selfPlayer:getBackpack()

		if var_47_1 == nil then
			return false
		end

		if var_47_1:getItemNumByID(40001004) >= xyd.TotalStarSuipian[1] then
			xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_STONE_START, true)
			xyd.StoryData.get():persist()

			return true
		end
	end

	return false
end

function var_0_0.setIDBeforeGuideWnd(arg_48_0)
	local var_48_0 = xyd.StoryData.get():getGuideID()

	if var_48_0 >= xyd.GuideStoryType.GUIDE_EQUIP_START and var_48_0 < xyd.GuideStoryType.GUIDE_EQUIP_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_START, true)
	end

	if var_48_0 == xyd.GuideStoryType.GUIDE_STONE_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_LEVUP_START, true)
	end

	if var_48_0 >= xyd.GuideStoryType.GUIDE_LEVUP_START and var_48_0 < xyd.GuideStoryType.GUIDE_LEVUP_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_LEVUP_START, true)
	end

	if var_48_0 >= xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_START and var_48_0 < xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_SIX then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_TWO, true)
	end

	if var_48_0 >= xyd.GuideStoryType.GUIDE_SKILL_START and var_48_0 < xyd.GuideStoryType.GUIDE_SKILL_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_SKILL_START, true)
	end

	if var_48_0 >= xyd.GuideStoryType.GUIDE_MISSION_THREE and var_48_0 < xyd.GuideStoryType.GUIDE_STONE_START then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_STONE_START, true)
	end
end

function var_0_0.setIDAfterGuideWnd(arg_49_0)
	local var_49_0 = xyd.StoryData.get():getGuideID()

	if var_49_0 == xyd.GuideStoryType.GUIDE_EQUIP_START then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_ONE)
	elseif var_49_0 == xyd.GuideStoryType.GUIDE_LEVUP_START then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_LEVUP_ONE)
	elseif var_49_0 == xyd.GuideStoryType.GUIDE_STONE_START then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_STONE_ONE)
		arg_49_0.selfPlayer:sendOperationLog(xyd.StatID.ID_STONE_1)
	elseif var_49_0 == xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_TWO then
		arg_49_0.selfPlayer:sendOperationLog(xyd.StatID.ID_JINJIE_3)
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_EQUIP_JINJIE_THREE)
	elseif var_49_0 == xyd.GuideStoryType.GUIDE_FIGHT_3_END then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_MISSION_START, true)
		xyd.StoryData.get():persist()
	elseif var_49_0 == xyd.GuideStoryType.GUIDE_MISSION_ONE then
		xyd.StoryData.get():setGuideID(xyd.GuideStoryType.GUIDE_MISSION_START, true)
	end
end

function var_0_0.playGuide(arg_50_0, arg_50_1)
	local var_50_0 = xyd.StoryData.get():getGuideID()

	if arg_50_0:checkGuideIntoHero() or arg_50_1 == true then
		local var_50_1 = "hero"

		if arg_50_1 then
			var_50_1 = "pet"
		end

		xyd.WindowManager.get():closeAllWindowsForGuide()
		arg_50_0:setIDBeforeGuideWnd()

		local var_50_2 = xyd.StoryData.get():getGuideID()
		local var_50_3 = arg_50_0:nodeByName(var_50_1)
		local var_50_4, var_50_5 = var_50_3:getPosition()
		local var_50_6 = var_50_3:getContentSize()
		local var_50_7 = {
			1000,
			200
		}

		xyd.WindowManager.get():openWindow("guide")

		local var_50_8 = xyd.WindowManager.get():getWindow("guide")

		var_50_8:addNode()
		var_50_8:setStencil(var_50_6.width * 0.9, var_50_6.height, var_50_4, var_50_5 + var_50_6.height / 2, -30, {
			main_scene = true,
			position = var_50_7,
			effect_pos = cc.p(70, 0)
		})
		arg_50_0:setIDAfterGuideWnd()
	end
end

function var_0_0.playFunctionGuide(arg_51_0, arg_51_1)
	local var_51_0
	local var_51_1 = -10
	local var_51_2 = 40
	local var_51_3 = 0
	local var_51_4 = 0
	local var_51_5 = var_0_4:translation("OPEN_FUNCTION")

	if arg_51_1 == xyd.FunctionID.ID_SKILL_UP then
		var_51_0 = "hero"
		var_51_3 = 10
		var_51_4 = 15
		var_51_5 = var_51_5 .. var_0_4:translation("SKILL_UPGRADE_TXT")
	elseif arg_51_1 == xyd.FunctionID.ID_GUILD then
		var_51_0 = "guild"
		var_51_5 = var_51_5 .. var_0_4:translation("GUILD")
	elseif xyd.StoryData.get():getGuideID() >= xyd.GuideStoryType.GUIDE_STONE_END and xyd.tables.hero:hasHero(arg_51_1) and not xyd.isSuperHero(arg_51_1) then
		var_51_0 = "hero"
		var_51_3 = 10
		var_51_4 = 15
		var_51_5 = var_0_4:translation("CAN_SUMMON") .. xyd.tables.hero:name(arg_51_1)
	end

	if var_51_0 then
		print("play function guide for id :" .. arg_51_1)

		local var_51_6 = arg_51_0:nodeByName(var_51_0)
		local var_51_7 = var_51_6:getPositionX()
		local var_51_8 = var_51_6:getPositionY() + 30
		local var_51_9 = display.newNode()

		var_51_9:setPosition(var_51_7, var_51_8)

		local var_51_10 = import("app.windows.GuideHand").new()

		var_51_9:addChild(var_51_10)
		var_51_10:setPosition(0, 0)

		local var_51_11 = xyd.AssetLoader.get():loadNodeFromJson("windows/function/function_open.csb")

		var_51_9:addChild(var_51_11)
		var_51_11:setPosition(var_51_1, var_51_2)
		var_51_11:getChildByName("tip_container"):getChildByName("text_open"):setString(var_51_5)

		local var_51_12 = var_51_11:getChildByName("tip_container"):getChildByName("tip_arrow")

		if var_51_4 ~= 0 then
			local var_51_13 = cc.p(var_51_12:getPosition())

			var_51_12:setPosition(cc.p(var_51_13.x + var_51_4, var_51_13.y))
		end

		if var_51_3 ~= 0 then
			var_51_12:setSkewY(var_51_3)
		end

		if arg_51_0.GuideHands[var_51_0] == nil then
			arg_51_0:addChild(var_51_9)

			arg_51_0.GuideHands[var_51_0] = {
				nodes = {
					var_51_9
				},
				funcIDs = {
					arg_51_1
				}
			}
		else
			table.insert(arg_51_0.GuideHands[var_51_0].nodes, var_51_9)
			table.insert(arg_51_0.GuideHands[var_51_0].funcIDs, arg_51_1)
		end
	end
end

function var_0_0.playWindowMove(arg_52_0, arg_52_1)
	local var_52_0 = arg_52_0:nodeByName("background")

	if arg_52_1 then
		arg_52_0.oldPosition = cc.p(var_52_0:getPosition())

		var_52_0:runAction(cc.MoveTo:create(0.5, cc.p(arg_52_0.oldPosition.x, -xyd.STAGE_HEIGHT)))
	else
		var_52_0:runAction(cc.MoveTo:create(0.5, cc.p(arg_52_0.oldPosition.x, arg_52_0.oldPosition.y)))
	end
end

function var_0_0.onEnterAction(arg_53_0, arg_53_1)
	local var_53_0 = {
		"guild",
		"pet",
		"mission",
		"backpack",
		"hero"
	}

	arg_53_0:nodeByName("up_layer"):runAction(cc.Sequence:create({
		cc.MoveBy:create(0, cc.p(0, -84)),
		cc.DelayTime:create(arg_53_1 and 0 or 0.33),
		cc.MoveBy:create(0.13, cc.p(0, 84))
	}))
	arg_53_0:nodeByName("bg_chat_show"):runAction(cc.Sequence:create({
		cc.MoveBy:create(0, cc.p(-388, 0)),
		cc.DelayTime:create(arg_53_1 and 0.23 or 0.56),
		cc.MoveBy:create(0.13, cc.p(388, 0))
	}))

	for iter_53_0 = 1, #var_53_0 do
		arg_53_0:nodeByName(var_53_0[iter_53_0]):setTouchEnabled(false)
		arg_53_0:nodeByName(var_53_0[iter_53_0]):runAction(cc.Sequence:create({
			cc.MoveBy:create(0, cc.p(0, -93)),
			cc.DelayTime:create((arg_53_1 and 0.06 or 0.4) + (iter_53_0 - 1) * 0.03),
			cc.MoveBy:create(0.13, cc.p(0, 103)),
			cc.MoveBy:create(0.2, cc.p(0, -10))
		}))
	end

	arg_53_0:nodeByName("chat"):setTouchEnabled(false)

	for iter_53_1, iter_53_2 in pairs(arg_53_0.GuideHands) do
		for iter_53_3, iter_53_4 in pairs(iter_53_2.nodes) do
			if iter_53_4 and not tolua.isnull(iter_53_4) then
				iter_53_4:setVisible(false)
			end
		end
	end
end

function var_0_0.onEnterActionEnd(arg_54_0)
	local var_54_0 = {
		"guild",
		"pet",
		"mission",
		"backpack",
		"hero",
		"chat"
	}

	for iter_54_0 = 1, #var_54_0 do
		arg_54_0:nodeByName(var_54_0[iter_54_0]):setTouchEnabled(true)
	end

	for iter_54_1, iter_54_2 in pairs(arg_54_0.GuideHands) do
		for iter_54_3, iter_54_4 in pairs(iter_54_2.nodes) do
			if iter_54_4 and not tolua.isnull(iter_54_4) then
				iter_54_4:setVisible(true)
			end
		end
	end
end

return var_0_0
