local var_0_0 = class("TwoYearsInviteItem", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.translation
local var_0_2 = xyd.tables.model
local var_0_3 = xyd.tables.hero
local var_0_4 = import("app.model.Hero")
local var_0_5 = 460
local var_0_6 = "windows/two_years/concentrate/mask.png"
local var_0_7 = 1
local var_0_8 = 2
local var_0_9 = 1000

function var_0_0.ctor(arg_2_0)
	arg_2_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_2_0.twoYearsModel = xyd.ModelManager.get():loadModel(xyd.ModelType.TWO_YEARS)

	arg_2_0:contentView()
end

function var_0_0.setParams(arg_3_0, arg_3_1, arg_3_2, arg_3_3)
	local var_3_0

	if arg_3_1 then
		var_3_0 = arg_3_1.table_id
		arg_3_0.info = arg_3_1
	end

	arg_3_0.isInvited = arg_3_3
	arg_3_0.itemPos = arg_3_2

	arg_3_0:setClippedCard(var_3_0)

	arg_3_0.heroid = var_3_0

	arg_3_0:setTouchSwallowEnabled(false)
	arg_3_0:setTouchEnabled(true)

	if arg_3_3 == var_0_7 then
		arg_3_0.contentView_:nodeByName("quest_progress"):setVisible(false)
		arg_3_0.contentView_:nodeByName("leaving_time"):setVisible(false)
		arg_3_0.contentView_:nodeByName("hp_bar"):setPercent(arg_3_0.info.hp / arg_3_0.info.total_hp * 100)
		arg_3_0.contentView_:nodeByName("mp_bar"):setPercent(arg_3_0.info.mp / var_0_9 * 100)

		if arg_3_0.info.hp == 0 then
			arg_3_0.contentView_:nodeByName("dead"):setVisible(true)
		else
			arg_3_0.contentView_:nodeByName("dead"):setVisible(false)
		end

		arg_3_0.contentView_:nodeByName("win_times"):setString(string.format(var_0_1:translation("ANNI2_TIPS_TXT3"), arg_3_0.info.total_win_times))
	elseif arg_3_3 == var_0_8 then
		arg_3_0.contentView_:nodeByName("dead"):setVisible(false)

		local var_3_1 = xyd.ServerTime.get():getServerTime()

		arg_3_0.contentView_:nodeByName("quest_progress"):setString(string.format(var_0_1:translation("ANNI2_TIPS_TXT4"), arg_3_0:checkQuestProgress(arg_3_1.mission_info)))

		local var_3_2 = xyd.tables.misc.twoYearsRefreshTime - (var_3_1 - arg_3_0.twoYearsModel.baseInfo.refresh_time)

		arg_3_0.contentView_:nodeByName("leaving_time"):setString(string.format(var_0_1:translation("ANNI2_TIPS_TXT5"), xyd.secondsToString1(var_3_2)))
		arg_3_0.contentView_:nodeByName("invite_concnent_process_bg"):setVisible(false)
		arg_3_0.contentView_:nodeByName("invite_concnent_process_bg2"):setVisible(false)
		arg_3_0.contentView_:nodeByName("invite_concnent_bg_refresh"):setVisible(false)
		arg_3_0.contentView_:nodeByName("win_times"):setVisible(false)
	elseif not arg_3_3 then
		arg_3_0.contentView_:nodeByName("invite_concnent_bg_refresh"):setVisible(true)
	end

	if arg_3_3 then
		arg_3_0.contentView_:nodeByName("partner_name"):setString(var_0_3:name(arg_3_0.info.table_id))
		arg_3_0.contentView_:nodeByName("partner_name"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
	end

	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.TWO_YEARS_ITEM_NOTIFY, function(arg_4_0)
		if not arg_3_0.isInvited and arg_4_0.params.is_refresh then
			local var_4_0 = string.format(var_0_1:translation("ANNI2_TIPS_TXT26"), xyd.tables.misc.twoYearsRefreshCost)

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_4_0, function()
				arg_3_0.twoYearsModel:anniRefreshHeroes()
			end, nil, nil, arg_3_0.colorMode)
		end
	end)
	cc.EventProxy.new(xyd.EventDispatcher.get(), arg_3_0):addEventListener(xyd.event.TWO_YEARS_ITEM_TIME, function(arg_6_0)
		if arg_3_0 and not tolua.isnull(arg_3_0) then
			arg_3_0.contentView_:nodeByName("leaving_time"):setString(string.format(var_0_1:translation("ANNI2_TIPS_TXT5"), xyd.secondsToString1(arg_6_0.params.refresh_rest_time)))
		end
	end)
end

function var_0_0.checkQuestProgress(arg_7_0, arg_7_1)
	local var_7_0 = 0
	local var_7_1 = 0

	for iter_7_0, iter_7_1 in pairs(arg_7_1) do
		var_7_1 = var_7_1 + 1

		if iter_7_1.is_finish == 1 then
			var_7_0 = var_7_0 + 1
		end
	end

	return var_7_0, var_7_1
end

function var_0_0.setClippedCard(arg_8_0, arg_8_1)
	if not arg_8_1 then
		return
	end

	local var_8_0 = display.newSprite(var_0_2:smallCard(arg_8_1))
	local var_8_1 = cc.ClippingNode:create()

	var_8_1:setAlphaThreshold(0)
	var_8_1:setInverted(true)
	var_8_1:addChild(var_8_0)

	local var_8_2 = display.newSprite(var_0_6)

	var_8_2:setPosition(cc.p(0, 0))
	var_8_2:setAnchorPoint(cc.p(0, 0))
	var_8_1:setStencil(var_8_2)
	var_8_0:setAnchorPoint(cc.p(0, 0))

	local var_8_3 = arg_8_0.contentView_:nodeByName("hero_image"):getContentSize().width
	local var_8_4 = arg_8_0.contentView_:nodeByName("hero_image"):getContentSize().height
	local var_8_5 = var_8_3 / var_8_1:getContentSize().width
	local var_8_6 = var_8_4 / var_8_1:getContentSize().height

	var_8_1:addTo(arg_8_0.contentView_:nodeByName("hero_image"))
end

function var_0_0.layout(arg_9_0)
	return
end

function var_0_0.contentView(arg_10_0)
	if arg_10_0.contentView_ == nil then
		arg_10_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_10_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/two_years/invite_item.csb"))
		arg_10_0.contentView_:addTo(arg_10_0)
		arg_10_0:setContentSize(arg_10_0.contentView_:getContentSize().width, arg_10_0.contentView_:getContentSize().height)
		arg_10_0.contentView_:setTouchSwallowEnabled(false)
		arg_10_0.contentView_:setAnchorPoint(0, 0)
	end

	return arg_10_0.contentView_
end

return var_0_0
