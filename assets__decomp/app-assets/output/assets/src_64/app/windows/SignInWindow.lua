local var_0_0 = class("SignInWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("framework.scheduler")
local var_0_3 = import("app.model.Hero")
local var_0_4 = "skeletons/ui_effect/function_show/"
local var_0_5 = 5
local var_0_6 = 18
local var_0_7 = 39

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.callback = arg_1_2.callback
	arg_1_0.signResponse = arg_1_2.signResponse
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	arg_2_0.effects = {}
	arg_2_0.setPosX = 0
	arg_2_0.setPosY = 0
	arg_2_0.showAward = false
	arg_2_0.refresh = false

	arg_2_0:initEffect()

	local var_2_0 = arg_2_0:nodeByName("award_list")
	local var_2_1 = var_2_0:getContentSize().width
	local var_2_2 = var_2_0:getContentSize().height

	arg_2_0.awardList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_2_1, var_2_2),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_2_0):onScroll(handler(arg_2_0, arg_2_0.scrollListener))

	arg_2_0.awardList_:setDelegate(handler(arg_2_0, arg_2_0.awardDelegate))
	arg_2_0:layout()
	arg_2_0.awardList_:reload()
	arg_2_0:setListPos(response)
	arg_2_0:checkItemTouch(arg_2_0.signResponse)
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = arg_3_0.selfPlayer.signPartnerID
	local var_3_1 = var_0_3.new()

	var_3_1:initUnCollected(var_3_0)

	if arg_3_0.selfPlayer.signPartnerIsSkin == 1 then
		local var_3_2 = xyd.tables.hero:skinItem(var_3_0)
		local var_3_3 = xyd.tables.item:skinModel(var_3_2[1])

		var_3_1:setSkinInfo(var_3_3)
	end

	arg_3_0:nodeByName("name_txt"):setString(var_3_1:getName())
	arg_3_0:nodeByName("name_txt"):enableOutline(cc.c4b(232, 109, 9, 255), 2)

	local var_3_4 = xyd.split(var_0_1:translation("SIGN_IN_DIALOG_TEXTS"), ":")

	for iter_3_0 = 1, 9 do
		arg_3_0:nodeByName("dialog_text" .. iter_3_0):setString(var_3_4[iter_3_0])
	end

	local var_3_5 = xyd.split(var_0_1:translation("MONTH_TRANSPOSE"), ":")

	arg_3_0:nodeByName("dialog_text1"):enableOutline(cc.c4b(232, 109, 9, 255), 2)
	arg_3_0:nodeByName("dialog_text1"):setString(var_3_5[arg_3_0.selfPlayer.signMonth])

	local var_3_6 = xyd.split(var_0_1:translation("SIGN_IN_TIP_TEXTS"), ":")

	for iter_3_1 = 1, 5 do
		arg_3_0:nodeByName("tip_text" .. iter_3_1):enableOutline(cc.c4b(193, 95, 36, 255), 3)
		arg_3_0:nodeByName("tip_text" .. iter_3_1):setString(var_3_6[iter_3_1])
	end

	local var_3_7 = xyd.tables.signInPartner:isSkin(var_3_0)

	arg_3_0:nodeByName("dialog_text3"):setString(arg_3_0.selfPlayer.signTimes)

	if var_3_7 > 0 then
		arg_3_0:nodeByName("dialog_text7"):setString(7)
		arg_3_0:nodeByName("tip_text2"):setString(7)
		arg_3_0:nodeByName("tip_text4"):setString(var_0_1:translation("SIGN_IN_GET_TEXT2"))
	else
		arg_3_0:nodeByName("dialog_text7"):setString(2)
		arg_3_0:nodeByName("tip_text2"):setString(2)
		arg_3_0:nodeByName("tip_text4"):setString(var_0_1:translation("SIGN_IN_GET_TEXT1"))
	end

	for iter_3_2 = 4, 1, -1 do
		local var_3_8 = arg_3_0:nodeByName("tip_text" .. iter_3_2)
		local var_3_9 = arg_3_0:nodeByName("tip_text" .. iter_3_2 + 1)
		local var_3_10 = var_3_9:getPositionX() - var_3_9:getContentSize().width / 2 - 15 - var_3_8:getContentSize().width / 2

		var_3_8:setPositionX(var_3_10)
	end

	local var_3_11 = xyd.tables.signInPartner:icon(var_3_0)
	local var_3_12 = xyd.tables.signInPartner:x(var_3_0)
	local var_3_13 = xyd.tables.signInPartner:y(var_3_0)

	if var_3_11 and var_3_11 ~= "" then
		local var_3_14 = xyd.SpriteLoader.new(var_3_11, nil, nil, xyd.DefaultImageType.HOME_CARD)

		if not var_3_14 then
			return
		end

		arg_3_0:nodeByName("panel_partner"):addChild(var_3_14)

		local var_3_15 = arg_3_0:nodeByName("panel_partner"):getContentSize()

		var_3_14:setAnchorPoint(cc.p(0.5, 0))
		var_3_14:setPosition(cc.p(var_3_15.width / 2 + var_3_12, var_3_13))
	end
end

function var_0_0.scrollListener(arg_4_0, arg_4_1)
	if arg_4_1.name == "began" then
		arg_4_0.scrollViewMoved_ = false
		arg_4_0.prevY_ = arg_4_1.y
	elseif arg_4_1.name == "moved" and 1 <= math.abs(arg_4_1.y - arg_4_0.prevY_) then
		arg_4_0.scrollViewMoved_ = true
	end
end

function var_0_0.createScheduler(arg_5_0)
	if arg_5_0.handle then
		var_0_2.unscheduleGlobal(arg_5_0.handle)

		arg_5_0.handle = nil
	end

	arg_5_0.totalCount = 0
	arg_5_0.playFirst = false
	arg_5_0.playSecond = false
	arg_5_0.playThird = false

	local var_5_0 = {}

	var_5_0.crystal = 80
	var_5_0.item_num = 80
	var_5_0.table_id = -1

	if not arg_5_0.response then
		arg_5_0.response = {}
		arg_5_0.response.award = var_5_0
		arg_5_0.response.is_signed = 2
		arg_5_0.response.sign_times = arg_5_0.selfPlayer.signTimes + 1
	end

	arg_5_0.handle = var_0_2.scheduleUpdateGlobal(handler(arg_5_0, arg_5_0.loop))
end

function var_0_0.loop(arg_6_0)
	if arg_6_0.totalCount <= var_0_6 then
		if not arg_6_0.playFirst then
			arg_6_0.awardList_:setViewCanNotScroll(true)
			arg_6_0.effects.seal:setVisible(true)
			arg_6_0.effects.seal:play(nil, false, nil, "texiao01")

			arg_6_0.playFirst = true
		end
	elseif arg_6_0.totalCount <= var_0_7 then
		if not arg_6_0.playSecond then
			local var_6_0 = cc.Spawn:create(cc.MoveTo:create(0.12, cc.p(arg_6_0.setPosX, arg_6_0.setPosY)))

			arg_6_0:nodeByName("texiao_pos"):runActionOnce(var_6_0, false, callback)

			arg_6_0.playSecond = true
		end
	elseif not arg_6_0.playThird then
		if arg_6_0.response and not arg_6_0.showAward then
			arg_6_0:showSignInRes(arg_6_0.response)

			arg_6_0.showAward = true
		end

		arg_6_0.effects.seal:setVisible(false)
		arg_6_0.awardList_:setViewCanNotScroll(false)

		arg_6_0.playThird = true
	end

	arg_6_0.totalCount = arg_6_0.totalCount + 1
end

function var_0_0.initEffect(arg_7_0)
	if not arg_7_0.effects.seal then
		local var_7_0 = arg_7_0:getEffect("yinzhang")

		var_7_0:addTo(arg_7_0:nodeByName("texiao_pos"))
		var_7_0:setPosition(cc.p(0, 0))
		var_7_0:setVisible(false)
		var_7_0:setScale(0.82)

		arg_7_0.effects.seal = var_7_0
	end
end

function var_0_0.getEffect(arg_8_0, arg_8_1)
	local var_8_0 = var_0_4 .. arg_8_1
	local var_8_1 = xyd.createEffect(var_8_0)

	var_8_1:setAnchorPoint(cc.p(0.5, 0.5))

	return var_8_1
end

function var_0_0.awardDelegate(arg_9_0, arg_9_1, arg_9_2, arg_9_3)
	if cc.ui.UIListView.COUNT_TAG == arg_9_2 then
		return (math.ceil(#arg_9_0.selfPlayer.signAwards / var_0_5))
	elseif cc.ui.UIListView.CELL_TAG == arg_9_2 then
		local var_9_0 = arg_9_0.awardList_:dequeueItem()

		if not var_9_0 then
			var_9_0 = arg_9_0.awardList_:newItem()
		else
			var_9_0:removeAllChildren(true)
		end

		local var_9_1 = 650
		local var_9_2 = 150

		var_9_0:setItemSize(var_9_1, 150)

		local var_9_3 = display.newNode()

		var_9_3:setContentSize(var_9_1, 150)

		for iter_9_0 = 1, var_0_5 do
			local var_9_4 = (arg_9_3 - 1) * var_0_5 + iter_9_0

			if var_9_4 > #arg_9_0.selfPlayer.signAwards then
				break
			end

			local var_9_5 = import("app.windows.SignInItem").new()

			var_9_3:addChild(var_9_5)
			var_9_5:setPosition(133 * (iter_9_0 - 1), 0)
			var_9_5:setTouchEnabled(true)
			var_9_5:setTouchSwallowEnabled(false)

			local var_9_6 = arg_9_0.selfPlayer.signAwards[var_9_4]

			var_9_6.dayIdx = var_9_4

			var_9_5:setParams(var_9_6)

			var_9_5.item = var_9_6

			local var_9_7 = var_9_5:contentView():nodeByName("arrow")

			var_9_7:setVisible(false)

			if var_9_4 < arg_9_0.selfPlayer.signTimes then
				var_9_5:setBg(2)
			elseif arg_9_0.selfPlayer.signTimes == var_9_4 then
				var_9_7:setVisible(false)
				var_9_7:stopAllActions()

				if arg_9_0.selfPlayer.isSigned == 1 then
					var_9_5:setBg(1)
				else
					var_9_5:setBg(2)
				end
			elseif var_9_4 == arg_9_0.selfPlayer.signTimes + 1 and arg_9_0.selfPlayer.isSigned == 0 then
				var_9_7:setGlobalZOrder(100)

				local var_9_8, var_9_9 = var_9_7:getPosition()
				local var_9_10 = transition.sequence({
					cc.MoveTo:create(1, cc.p(var_9_8, var_9_9 - 10)),
					cc.MoveTo:create(1, cc.p(var_9_8, var_9_9))
				})
				local var_9_11 = cc.RepeatForever:create(var_9_10)

				var_9_7:runAction(var_9_11)
			else
				local var_9_12 = xyd.tables.item:type(var_9_6.award_item_id)
				local var_9_13 = var_9_5:contentView():nodeByName("item"):getContentSize()

				if var_9_12 == -1 then
					local var_9_14 = xyd.getItemEffect(5, 0.5)

					if var_9_14 then
						var_9_5:contentView():nodeByName("item"):addChild(var_9_14)
						var_9_14:setLocalZOrder(-100)
						var_9_14:setPosition(var_9_13.width / 2, var_9_13.height / 2)
						var_9_14:play(nil, true)
					end
				end
			end

			var_9_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
				if arg_10_0.name == "began" then
					var_9_5:contentView():nodeByName("container"):setScale(0.9)

					return true
				elseif arg_10_0.name == "ended" then
					var_9_5:contentView():nodeByName("container"):setScale(1)

					local var_10_0 = {}

					if var_9_4 == arg_9_0.selfPlayer.signTimes + 1 and arg_9_0.selfPlayer.isSigned == 0 then
						xyd.Backend.get():request(xyd.mid.SIGN, var_10_0, function(arg_11_0, arg_11_1)
							if arg_11_0 == xyd.error.OK then
								arg_9_0:showSignInRes(arg_11_1)
							end
						end)
					elseif var_9_4 == arg_9_0.selfPlayer.signTimes and arg_9_0.selfPlayer.isSigned == 1 then
						if arg_9_0.selfPlayer.vip >= var_9_5.item.double_vip_lv then
							xyd.Backend.get():request(xyd.mid.SIGN, var_10_0, function(arg_12_0, arg_12_1)
								if arg_12_0 == xyd.error.OK then
									arg_9_0:showSignInRes(arg_12_1)
								end
							end)
						else
							xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, {
								var_0_1:translation("SIGN_IN_GOT"),
								string.format(var_0_1:translation("SIGN_IN_VIP"), var_9_5.item.double_vip_lv)
							}, function()
								xyd.WindowManager.get():openWindow(xyd.WindowName.vipRecharge, {
									windowState = true
								})
							end, nil, nil, arg_9_0.colorMode)
						end
					elseif not arg_9_0.scrollViewMoved_ then
						local var_10_1 = {
							id = var_9_6.award_item_id
						}
						local var_10_2 = var_9_5:contentView():nodeByName("container")

						if not xyd.WindowManager.get():getWindow("new_item_tips") then
							local var_10_3 = xyd.WindowManager.get():openWindow("new_item_tips", var_10_1)

							xyd.adaptToWorldPosition(var_10_2, var_10_3)
						end
					end
				end
			end)
		end

		var_9_0:addContent(var_9_3)

		return var_9_0
	elseif cc.ui.UIListView.UNLOAD_CELL_TAG == arg_9_2 then
		-- block empty
	end
end

function var_0_0.didOpen(arg_14_0)
	arg_14_0:nodeByName("rule_btn"):addTouchEventListener(function(arg_15_0, arg_15_1)
		xyd.buttonScaleAnim(arg_14_0:nodeByName("rule_btn"), arg_15_1)

		if arg_15_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("sign_in_desc")
		end
	end)
	arg_14_0:addBlockLayer(cc.c4b(0, 0, 0, 125))
end

function var_0_0.checkItemTouch(arg_16_0, arg_16_1)
	if arg_16_1 then
		arg_16_0.response = arg_16_1

		arg_16_0:createScheduler()
	end
end

function var_0_0.setListPos(arg_17_0, arg_17_1)
	local var_17_0 = arg_17_0.selfPlayer.signTimes + 1

	if arg_17_1 then
		var_17_0 = arg_17_1.sign_times
	end

	local var_17_1 = arg_17_0.awardList_:getScrollNode()
	local var_17_2 = math.ceil(#arg_17_0.selfPlayer.signAwards / var_0_5)
	local var_17_3 = var_17_1:getPositionY()
	local var_17_4 = 1

	if var_17_2 == 7 then
		if var_17_0 <= 5 then
			var_17_4 = 1
		elseif var_17_0 <= 10 then
			var_17_4 = 2
		elseif var_17_0 <= 15 then
			var_17_3 = var_17_3 + 150
			var_17_4 = 2
		elseif var_17_0 <= 20 then
			var_17_3 = var_17_3 + 300
			var_17_4 = 2
		elseif var_17_0 <= 25 then
			var_17_3 = var_17_3 + 450
			var_17_4 = 2
		elseif var_17_0 <= 30 then
			var_17_3 = var_17_3 + 600
			var_17_4 = 2
		elseif var_17_0 <= 32 then
			var_17_3 = var_17_3 + 665
			var_17_4 = 2.566666666666667
		end
	elseif var_17_0 <= 5 then
		var_17_4 = 1
	elseif var_17_0 <= 10 then
		var_17_4 = 2
	elseif var_17_0 <= 15 then
		var_17_3 = var_17_3 + 150
		var_17_4 = 2
	elseif var_17_0 <= 20 then
		var_17_3 = var_17_3 + 300
		var_17_4 = 2
	elseif var_17_0 <= 25 then
		var_17_3 = var_17_3 + 450
		var_17_4 = 2
	elseif var_17_0 <= 31 then
		var_17_3 = var_17_3 + 515
		var_17_4 = 2.566666666666667
	end

	if not arg_17_0.refresh then
		var_17_1:setPositionY(var_17_3)
	else
		arg_17_0.refresh = false
	end

	arg_17_0.setPosX = 427.5 + (arg_17_0.selfPlayer.signTimes + 1 - math.floor(arg_17_0.selfPlayer.signTimes / 5) * 5) * 133
	arg_17_0.setPosY = 617.5 - var_17_4 * 150
end

function var_0_0.showSignInRes(arg_18_0, arg_18_1)
	arg_18_0.selfPlayer:setSignIn(arg_18_1.is_signed)

	arg_18_0.selfPlayer.signTimes = arg_18_1.sign_times

	arg_18_0:layout()

	arg_18_0.refresh = true

	arg_18_0:setListPos(arg_18_1)

	if arg_18_0.awardList_ then
		arg_18_0.awardList_:refreshList()
	end

	local var_18_0 = arg_18_1.award

	if var_18_0.is_partner == true then
		local var_18_1 = var_0_3.new()

		var_18_1:populate(var_18_0)
		arg_18_0.selfPlayer:addHero(var_18_1)

		local var_18_2 = {
			toStone = false,
			partnerID = var_18_0.table_id
		}
		local var_18_3 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_18_2)
	else
		if var_18_0.table_id > 0 then
			arg_18_0.selfPlayer:getBackpack():addItemsByID(tonumber(var_18_0.table_id), tonumber(var_18_0.item_num))

			if var_18_0.to_stone == true then
				local var_18_4 = {
					partnerID = xyd.tables.item:heroID(var_18_0.table_id),
					toStone = tonumber(var_18_0.item_num)
				}
				local var_18_5 = xyd.WindowManager.get():openWindow(xyd.WindowName.summonHeroWnd, var_18_4)

				cc.EventProxy.new(var_18_5, var_18_5):addEventListener(xyd.event.SUMMON_HERO_CLOSE, function()
					xyd.WindowManager.get():openWindow("alert_award", {
						awards = {
							var_18_0
						}
					})
				end)
			end
		end

		if var_18_0.to_stone == false or var_18_0.table_id < 0 then
			xyd.WindowManager.get():openWindow("alert_award", {
				awards = {
					var_18_0
				}
			})
		end
	end
end

function var_0_0.willClose(arg_20_0, arg_20_1)
	var_0_0.super.willClose(arg_20_0, arg_20_1)

	if arg_20_0.response and not arg_20_0.showAward then
		arg_20_0:showSignInRes(arg_20_0.response)
	end

	if arg_20_0.handle then
		var_0_2.unscheduleGlobal(arg_20_0.handle)

		arg_20_0.handle = nil
	end

	if arg_20_0.callback then
		arg_20_0.callback()
	end
end

return var_0_0
