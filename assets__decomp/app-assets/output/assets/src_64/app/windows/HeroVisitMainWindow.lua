local var_0_0 = class("HeroVisitMainWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = 1000

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.hero = arg_1_2.hero
	arg_1_0.library = xyd.ModelManager.get():loadModel(xyd.ModelType.LIBRARY)
	arg_1_0.libraryInfos = arg_1_0.library.libraryInfos
	arg_1_0.dialog = arg_1_0.libraryInfos[arg_1_0.hero:getHeroID()].partner_dialogs
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super.willOpen(arg_2_0, arg_2_1)

	arg_2_0.cardContainer = arg_2_0:nodeByName("card_container")

	local var_2_0 = arg_2_0.hero:getTableID()

	if arg_2_0.hero:isAwaken() then
		var_2_0 = xyd.tables.hero:beforeAwaken(var_2_0)
	end

	arg_2_0.dialogTable = import("app.common.tables.DialogueTable").new(var_2_0)

	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_2_0):addEventListener(xyd.event.REFRESH_HERO_VISIT_REDPOINT, function(arg_3_0)
		if arg_2_0 and not tolua.isnull(arg_2_0) then
			arg_2_0:updateRedPoint()
			arg_2_0:updateFeedFunction()
		end
	end)

	arg_2_0.bg = arg_2_0:nodeByName("bg")

	arg_2_0:setBG()
	arg_2_0:layout()
end

function var_0_0.setBG(arg_4_0)
	if arg_4_0.bg then
		arg_4_0.bg:removeSelf()
	end

	arg_4_0.bg = xyd.SpriteLoader.new(xyd.tables.libraryBG:getBG(arg_4_0.library.bgRoom), nil, nil, xyd.DefaultImageType.BG_ROOM)

	arg_4_0.bg:setAnchorPoint(0, 0)
	arg_4_0.bg:addTo(arg_4_0, -1)
end

function var_0_0.layout(arg_5_0)
	arg_5_0:nodeByName("label_name"):setString(arg_5_0.hero:getName())
	arg_5_0:updateCardContainer()
	arg_5_0:setButtonClick()
	arg_5_0:playTalk()
end

function var_0_0.setButtonClick(arg_6_0)
	arg_6_0:nodeByName("send_gift_btn"):addTouchEventListener(function(arg_7_0, arg_7_1)
		if arg_7_1 == ccui.TouchEventType.ended then
			local var_7_0 = {
				hero = arg_6_0.hero
			}

			xyd.WindowManager.get():openWindow("hero_gift_box", var_7_0)
		end
	end)
	arg_6_0:nodeByName("entrust_btn"):addTouchEventListener(function(arg_8_0, arg_8_1)
		if arg_8_1 == ccui.TouchEventType.ended then
			local var_8_0 = arg_6_0.hero
			local var_8_1 = {
				partner_id = var_8_0:getHeroID()
			}

			arg_6_0.library:getPartnerMission(var_8_1, function(arg_9_0, arg_9_1)
				if arg_9_0 == xyd.error.OK then
					if not arg_6_0 or tolua.isnull(arg_6_0) then
						return
					end

					arg_6_0.libraryInfos[var_8_0:getHeroID()].partner_missions = arg_9_1.mission_list

					local var_9_0 = {
						hero = var_8_0,
						partner_missions = arg_6_0.libraryInfos[var_8_0:getHeroID()].partner_missions
					}

					xyd.WindowManager.get():openWindow("hero_task_main", var_9_0)
				end
			end)
		end
	end)
	arg_6_0:nodeByName("interact_btn"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			local var_10_0 = arg_6_0.hero
			local var_10_1 = {
				partner_id = var_10_0:getHeroID()
			}

			arg_6_0.library:getPartnerAct(var_10_1, function(arg_11_0, arg_11_1)
				if arg_11_0 == xyd.error.OK then
					if not arg_6_0 or tolua.isnull(arg_6_0) then
						return
					end

					arg_6_0.libraryInfos[var_10_0:getHeroID()].partner_acts = arg_11_1.partner_acts

					local var_11_0 = {
						hero = var_10_0
					}

					xyd.WindowManager.get():openWindow("hero_touch_game", var_11_0)
				end
			end)
		end
	end)
	arg_6_0:nodeByName("dialog_btn"):addTouchEventListener(function(arg_12_0, arg_12_1)
		if arg_12_1 == ccui.TouchEventType.ended then
			local var_12_0 = arg_6_0.hero
			local var_12_1 = {
				partner_id = var_12_0:getHeroID()
			}

			arg_6_0.library:getHeroDialog(var_12_1, function(arg_13_0, arg_13_1)
				if arg_13_0 == xyd.error.OK then
					if not arg_6_0 or tolua.isnull(arg_6_0) then
						return
					end

					arg_6_0.libraryInfos[var_12_0:getHeroID()].partner_dialogs = arg_13_1.partner_dialogs

					local var_13_0 = {
						hero = var_12_0
					}

					xyd.WindowManager.get():openWindow("hero_dialog", var_13_0)
				end
			end)
		end
	end)
	arg_6_0:nodeByName("feed_btn"):addTouchEventListener(function(arg_14_0, arg_14_1)
		if arg_14_1 == ccui.TouchEventType.ended then
			local var_14_0 = arg_6_0.hero
			local var_14_1 = {
				partner_id = var_14_0:getHeroID()
			}

			xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):sendFunctionClick(xyd.FunctionClick.FEED)
			arg_6_0.library:getFeedInfo(var_14_1, function(arg_15_0, arg_15_1)
				if arg_15_0 == xyd.error.OK then
					if not arg_6_0 or tolua.isnull(arg_6_0) then
						return
					end

					local var_15_0 = {
						feedAddInfo = arg_15_1.feed_add,
						hero = var_14_0
					}

					xyd.WindowManager.get():openWindow("library_feed", var_15_0)
				end
			end)
		end
	end)
	arg_6_0:updateFeedFunction()
	arg_6_0:updateRedPoint()
end

function var_0_0.updateRedPoint(arg_16_0)
	if arg_16_0.library:isDialogRedPointShow(arg_16_0.hero) then
		arg_16_0:nodeByName("dialog_btn"):getChildByName("red_point"):setVisible(true)
	else
		arg_16_0:nodeByName("dialog_btn"):getChildByName("red_point"):setVisible(false)
	end

	if arg_16_0.library:isMissionRedPointShow(arg_16_0.hero) then
		arg_16_0:nodeByName("entrust_btn"):getChildByName("red_point"):setVisible(true)
	else
		arg_16_0:nodeByName("entrust_btn"):getChildByName("red_point"):setVisible(false)
	end
end

function var_0_0.updateFeedFunction(arg_17_0)
	if arg_17_0.hero:isHeroMarried() then
		arg_17_0:nodeByName("entrust_btn"):setVisible(false)
		arg_17_0:nodeByName("feed_btn"):setVisible(true)
		arg_17_0:nodeByName("feed_btn"):getChildByName("red_point"):setVisible(false)
	else
		arg_17_0:nodeByName("entrust_btn"):setVisible(true)
		arg_17_0:nodeByName("feed_btn"):setVisible(false)
	end
end

function var_0_0.playTalk(arg_18_0)
	arg_18_0:nodeByName("text"):setString("")
	arg_18_0:speak(arg_18_0.dialogTable:getDialog(0), arg_18_0:nodeByName("text"), xyd.tables.misc.dialogSpeed)
end

function var_0_0.speak(arg_19_0, arg_19_1, arg_19_2, arg_19_3)
	local var_19_0 = xyd.utf8len(arg_19_1)

	arg_19_0.showInOneTime = false
	arg_19_0.isOnSpeaking = true

	local var_19_1 = 0

	if arg_19_0.handler then
		var_0_1.unscheduleGlobal(arg_19_0.handler)

		arg_19_0.handler = nil
	end

	arg_19_0.handler = var_0_1.scheduleGlobal(function()
		var_19_1 = var_19_1 + 1

		if var_19_1 > var_19_0 and arg_19_0.handler or arg_19_0.showInOneTime == true then
			if not tolua.isnull(arg_19_2) then
				arg_19_2:setString(arg_19_1)
			end

			var_0_1.unscheduleGlobal(arg_19_0.handler)

			arg_19_0.isOnSpeaking = false

			return
		end

		local var_20_0 = xyd.getSplitUtf8Str(arg_19_1, 0, var_19_1 * 3)

		if not tolua.isnull(arg_19_2) then
			arg_19_2:setString(var_20_0)
		end
	end, arg_19_3)
end

function var_0_0.updateCardContainer(arg_21_0)
	arg_21_0.library:updateCardContainer(arg_21_0.hero, arg_21_0.cardContainer, arg_21_0.library.cardState)
end

return var_0_0
