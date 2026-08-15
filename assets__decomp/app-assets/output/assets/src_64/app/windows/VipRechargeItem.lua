local var_0_0 = class("VipRechargeItem", function()
	return cc.Node:create()
end)

var_0_0.NAME = "gift_type_txt"
var_0_0.CHARGE = "price_txt"
var_0_0.ICON = "gift_type_img"
var_0_0.RECOMMEND_IMG = "tuijian"
var_0_0.DETAIL = "extra_detail_txt"
MONTH_CARD = 1
WEEK_CARD = 2
ENERGY_MONTH_CARD = 3
PRIVILEGE_MONTH_CARD = 4
DISCOUNT_PRIVILEGE_MONTH_CARD = 5

local var_0_1 = import("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.charge
local var_0_4 = {}

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()
end

function var_0_0.setParams(arg_3_0, arg_3_1)
	arg_3_0.params = arg_3_1
	arg_3_0.chargeId = arg_3_0.params.chargeId
	arg_3_0.iconUrl = arg_3_0.params.iconUrl
	arg_3_0.iconNew = arg_3_0.params.iconNew
	arg_3_0.name = arg_3_0.params.chargeName
	arg_3_0.diamond = arg_3_0.params.diamond or 0
	arg_3_0.extraDiamond = arg_3_0.params.extraDiamond or 0
	arg_3_0.monthCard = arg_3_0.params.monthCard
	arg_3_0.recommend = arg_3_0.params.recommend
	arg_3_0.charge = arg_3_0.params.charge
	arg_3_0.onlyOnce = arg_3_0.params.onlyOnce
	arg_3_0.beforeId = arg_3_0.params.beforeId
	arg_3_0.monthCardLeftTimes = arg_3_1.monthCardLeftTimes
	arg_3_0.weekCardLeftTimes = arg_3_1.weekCardLeftTimes
	arg_3_0.energyMonthCardLeftTimes = arg_3_1.energyMonthCardLeftTimes
	arg_3_0.privilegeLeftCardTimes = arg_3_1.privilegeLeftCardTimes
	arg_3_0.time = arg_3_1.time
	arg_3_0.chargeState = arg_3_0.params.chargeState
	arg_3_0.percent = arg_3_1.percent
	arg_3_0.giftData = arg_3_0.params.giftData
	arg_3_0.cardType = arg_3_0.params.cardType

	arg_3_0:layout()
	arg_3_0:setTouchSwallowEnabled(false)
	arg_3_0:setTouchEnabled(true)
end

function var_0_0.layout(arg_4_0)
	arg_4_0.numMonth = xyd.tables.misc.monthCardTime2
	arg_4_0.numSeason = xyd.tables.misc.seasonPrivilegeCard
	arg_4_0.numHalfYear = xyd.tables.misc.halfyearPrivilegeCard
	arg_4_0.monthlyPrivilegeCardDiscount = xyd.tables.misc.monthlyPrivilegeCardDiscount
	arg_4_0.showDiscount = false

	if arg_4_0.monthlyPrivilegeCardDiscount == 1 then
		arg_4_0.showDiscount = true
	end

	dump(arg_4_0.privilegeLeftCardTimes)
	arg_4_0:showBg(arg_4_0.iconUrl)

	if arg_4_0.recommend == 1 then
		arg_4_0.contentView_:nodeByName("txt_persent"):setString(var_0_2:translation("VIP_WINDOW_TEXT_12"))
	end

	if arg_4_0.monthCard == MONTH_CARD and arg_4_0.monthCardLeftTimes == 0 then
		local var_4_0

		if arg_4_0.cardType == 1 then
			var_4_0 = string.format(var_0_2:translation("DIAMOND_CARD_DESC"), arg_4_0.numMonth)
		elseif arg_4_0.cardType == 2 then
			var_4_0 = string.format(var_0_2:translation("DIAMOND_CARD_DESC"), arg_4_0.numSeason)
		elseif arg_4_0.cardType == 3 then
			var_4_0 = string.format(var_0_2:translation("DIAMOND_CARD_DESC"), arg_4_0.numHalfYear)
		end

		arg_4_0.contentView_:nodeByName("desc"):setString(var_4_0)
		arg_4_0.contentView_:nodeByName("container_time"):setVisible(false)
		arg_4_0.contentView_:nodeByName("container_crystal"):setVisible(false)
	elseif arg_4_0.monthCard == MONTH_CARD and arg_4_0.monthCardLeftTimes > 0 then
		local var_4_1 = string.format(var_0_2:translation("MONTHCARD_TAKEEFFECT"), arg_4_0.monthCardLeftTimes)

		arg_4_0.contentView_:nodeByName("desc"):setString(var_4_1)
		arg_4_0.contentView_:nodeByName("container_time"):setVisible(false)
		arg_4_0.contentView_:nodeByName("container_crystal"):setVisible(false)
	elseif arg_4_0.monthCard == WEEK_CARD and arg_4_0.weekCardLeftTimes == 0 then
		local var_4_2 = var_0_2:translation("WEEK_CARD_DESC")

		arg_4_0.contentView_:nodeByName("desc"):setString(var_4_2)
		arg_4_0.contentView_:nodeByName("container_time"):setVisible(false)
		arg_4_0.contentView_:nodeByName("container_crystal"):setVisible(false)
	elseif arg_4_0.monthCard == WEEK_CARD and arg_4_0.weekCardLeftTimes > 0 then
		local var_4_3 = string.format(var_0_2:translation("WEEKCARD_TAKEEFFECT"), arg_4_0.weekCardLeftTimes)

		arg_4_0.contentView_:nodeByName("desc"):setString(var_4_3)
		arg_4_0.contentView_:nodeByName("container_time"):setVisible(false)
		arg_4_0.contentView_:nodeByName("container_crystal"):setVisible(false)
	elseif arg_4_0.monthCard == ENERGY_MONTH_CARD and arg_4_0.energyMonthCardLeftTimes == 0 then
		local var_4_4 = var_0_2:translation("ENERGY_MONTH_CARD_DESC")

		arg_4_0.contentView_:nodeByName("desc"):setString(var_4_4)
		arg_4_0.contentView_:nodeByName("container_time"):setVisible(false)
		arg_4_0.contentView_:nodeByName("container_crystal"):setVisible(false)
	elseif arg_4_0.monthCard == ENERGY_MONTH_CARD and arg_4_0.energyMonthCardLeftTimes > 0 then
		local var_4_5 = string.format(var_0_2:translation("ENERGYMONTHCARD_TAKEEFFECT"), arg_4_0.energyMonthCardLeftTimes)

		arg_4_0.contentView_:nodeByName("desc"):setString(var_4_5)
		arg_4_0.contentView_:nodeByName("container_time"):setVisible(false)
		arg_4_0.contentView_:nodeByName("container_crystal"):setVisible(false)
	elseif arg_4_0.monthCard == PRIVILEGE_MONTH_CARD and arg_4_0.privilegeLeftCardTimes == 0 then
		local var_4_6

		if arg_4_0.cardType == 1 then
			var_4_6 = string.format(var_0_2:translation("PRIVILEGE_CARD_DESC"), arg_4_0.numMonth)
		elseif arg_4_0.cardType == 2 then
			var_4_6 = string.format(var_0_2:translation("PRIVILEGE_CARD_DESC"), arg_4_0.numSeason)
		elseif arg_4_0.cardType == 3 then
			var_4_6 = string.format(var_0_2:translation("PRIVILEGE_CARD_DESC"), arg_4_0.numHalfYear)
		end

		arg_4_0.contentView_:nodeByName("desc"):setString(var_4_6)
		arg_4_0.contentView_:nodeByName("container_time"):setVisible(false)
		arg_4_0.contentView_:nodeByName("container_crystal"):setVisible(false)
	elseif arg_4_0.monthCard == DISCOUNT_PRIVILEGE_MONTH_CARD and arg_4_0.privilegeLeftCardTimes == 0 then
		local var_4_7

		if arg_4_0.cardType == 1 then
			var_4_7 = string.format(var_0_2:translation("PRIVILEGE_CARD_DESC"), arg_4_0.numMonth)
		elseif arg_4_0.cardType == 2 then
			var_4_7 = string.format(var_0_2:translation("PRIVILEGE_CARD_DESC"), arg_4_0.numSeason)
		elseif arg_4_0.cardType == 3 then
			var_4_7 = string.format(var_0_2:translation("PRIVILEGE_CARD_DESC"), arg_4_0.numHalfYear)
		end

		arg_4_0.contentView_:nodeByName("desc"):setString(var_4_7)
		arg_4_0.contentView_:nodeByName("container_time"):setVisible(false)
		arg_4_0.contentView_:nodeByName("container_crystal"):setVisible(false)
		arg_4_0.contentView_:nodeByName("before_pirce"):setVisible(arg_4_0.showDiscount)

		local var_4_8

		dump(arg_4_0.beforeId)

		if arg_4_0.beforeId and arg_4_0.beforeId ~= 0 then
			var_4_8 = var_0_3:charge(arg_4_0.beforeId)
		else
			var_4_8 = arg_4_0.charge
		end

		local var_4_9 = string.format(var_4_8 .. var_0_2:translation("VIP_WINDOW_TEXT_13"))

		arg_4_0.contentView_:nodeByName("before_pirce"):setString(var_0_2:translation("PRIVILEGE_CARD_CHARGE") .. var_4_9)
	elseif arg_4_0.monthCard == PRIVILEGE_MONTH_CARD and arg_4_0.privilegeLeftCardTimes > 0 then
		local var_4_10 = string.format(var_0_2:translation("PRIVILEGEMONTHCARD_TAKEEFFECT"), arg_4_0.privilegeLeftCardTimes)

		arg_4_0.contentView_:nodeByName("desc"):setString(var_4_10)
		arg_4_0.contentView_:nodeByName("container_time"):setVisible(false)
		arg_4_0.contentView_:nodeByName("container_crystal"):setVisible(false)
	elseif arg_4_0.monthCard == DISCOUNT_PRIVILEGE_MONTH_CARD and arg_4_0.privilegeLeftCardTimes > 0 then
		local var_4_11 = string.format(var_0_2:translation("PRIVILEGEMONTHCARD_TAKEEFFECT"), arg_4_0.privilegeLeftCardTimes)

		arg_4_0.contentView_:nodeByName("desc"):setString(var_4_11)
		arg_4_0.contentView_:nodeByName("container_time"):setVisible(false)
		arg_4_0.contentView_:nodeByName("container_crystal"):setVisible(false)
		arg_4_0.contentView_:nodeByName("before_pirce"):setVisible(arg_4_0.showDiscount)

		local var_4_12

		if arg_4_0.beforeId and arg_4_0.beforeId ~= 0 then
			var_4_12 = var_0_3:charge(arg_4_0.beforeId)
		else
			var_4_12 = arg_4_0.charge
		end

		local var_4_13 = string.format(var_4_12 .. var_0_2:translation("VIP_WINDOW_TEXT_13"))

		arg_4_0.contentView_:nodeByName("before_pirce"):setString(var_0_2:translation("PRIVILEGE_CARD_CHARGE") .. var_4_13)
	elseif arg_4_0.monthCard ~= MONTH_CARD and arg_4_0.monthCard ~= WEEK_CARD and arg_4_0.monthCard ~= ENERGY_MONTH_CARD and arg_4_0.monthCard ~= PRIVILEGE_MONTH_CARD and arg_4_0.monthCard ~= DISCOUNT_PRIVILEGE_MONTH_CARD and arg_4_0.extraDiamond ~= 0 then
		local var_4_14 = string.format(var_0_2:translation("GIVE_DIAMOND"), arg_4_0.extraDiamond)

		arg_4_0.contentView_:nodeByName("desc"):setString(var_4_14)
		arg_4_0.contentView_:nodeByName("desc"):setFontSize(22)
		arg_4_0.contentView_:nodeByName("desc"):setColor(cc.c4b(224, 0, 121, 255))
		arg_4_0.contentView_:nodeByName("desc"):enableOutline(cc.c4b(255, 255, 255, 255), 2)
		arg_4_0.contentView_:nodeByName("container_time"):setVisible(false)
		arg_4_0.contentView_:nodeByName("container_gift"):setVisible(false)
	else
		arg_4_0.contentView_:nodeByName("desc"):setString("")
	end

	arg_4_0.contentView_:nodeByName("txt_gift_desc"):setString(arg_4_0.name)

	if arg_4_0.monthCard ~= MONTH_CARD and arg_4_0.monthCard ~= WEEK_CARD and arg_4_0.monthCard ~= ENERGY_MONTH_CARD and arg_4_0.monthCard ~= PRIVILEGE_MONTH_CARD and arg_4_0.monthCard ~= DISCOUNT_PRIVILEGE_MONTH_CARD and arg_4_0.diamond > 0 then
		if arg_4_0.onlyOnce == 1 then
			arg_4_0.contentView_:nodeByName("container_gift"):setVisible(false)
			arg_4_0.contentView_:nodeByName("container_crystal"):setVisible(true)
			arg_4_0.contentView_:nodeByName("txt_crystal"):setString(arg_4_0.diamond)
		else
			arg_4_0.contentView_:nodeByName("bg_persent"):setVisible(false)
			arg_4_0.contentView_:nodeByName("container_gift"):setVisible(false)
			arg_4_0.contentView_:nodeByName("container_crystal"):setVisible(true)
			arg_4_0.contentView_:nodeByName("container_time"):setVisible(false)
			arg_4_0.contentView_:nodeByName("txt_crystal"):setString(arg_4_0.diamond)
		end
	end

	if arg_4_0.monthCard ~= MONTH_CARD and arg_4_0.monthCard ~= WEEK_CARD and arg_4_0.monthCard ~= ENERGY_MONTH_CARD and arg_4_0.monthCard ~= PRIVILEGE_MONTH_CARD and arg_4_0.monthCard ~= DISCOUNT_PRIVILEGE_MONTH_CARD and arg_4_0.onlyOnce == 1 then
		arg_4_0.contentView_:nodeByName("txt_tips"):setString(var_0_2:translation("VIP_WINDOW_TEXT_14"))
	end

	if arg_4_0.iconNew ~= "" then
		local var_4_15 = xyd.SpriteLoader.new(arg_4_0.iconNew, nil, nil, xyd.DefaultImageType.CHARGE)

		var_4_15:setAnchorPoint(cc.p(0.5, 0.5))
		arg_4_0.contentView_:nodeByName("img_gift"):addChild(var_4_15)
	else
		local var_4_16 = xyd.AssetLoader.get():loadSprite("images/vip_recharge/default.png")

		var_4_16:setAnchorPoint(cc.p(0.5, 0.5))
		arg_4_0.contentView_:nodeByName("img_gift"):addChild(var_4_16)
	end

	arg_4_0.contentView_:nodeByName("txt_price"):setString(arg_4_0.charge .. var_0_2:translation("VIP_WINDOW_TEXT_13"))

	if arg_4_0.time then
		if xyd.tables.giftbag.isNew[arg_4_0.chargeId] then
			arg_4_0.contentView_:nodeByName("txt_tips"):setString("")
		else
			arg_4_0.contentView_:nodeByName("txt_tips"):setString(var_0_2:translation("VIP_WINDOW_TEXT_15"))
		end

		local var_4_17 = xyd.tables.giftbag:discribe(arg_4_0.chargeId)

		if var_4_17 and var_4_17 ~= "" then
			arg_4_0.contentView_:nodeByName("txt_tips"):setString(var_4_17)
		end

		local var_4_18 = arg_4_0.time

		arg_4_0.contentView_:nodeByName("container_crystal"):setVisible(false)

		if var_4_18 > 0 then
			arg_4_0.contentView_:nodeByName("txt_time"):setString(xyd.secondsToString1(math.floor(var_4_18)))

			local var_4_19 = tostring(arg_4_0)
			local var_4_20 = var_0_1.scheduleGlobal(function()
				var_4_18 = var_4_18 - 1

				if tolua.isnull(arg_4_0) then
					var_0_1.unscheduleGlobal(var_0_4[var_4_19])

					var_0_4[var_4_19] = nil
				else
					arg_4_0.contentView_:nodeByName("txt_time"):setString(xyd.secondsToString1(math.floor(var_4_18)))
				end

				if var_4_18 < 0 then
					var_0_1.unscheduleGlobal(var_0_4[var_4_19])

					var_0_4[var_4_19] = nil

					local var_5_0 = xyd.WindowManager.get():getWindow("vip_recharge")

					if var_5_0 then
						var_5_0:update()
					end
				end
			end, 1)

			var_0_4[var_4_19] = var_4_20
		else
			arg_4_0.contentView_:nodeByName("container_time"):setVisible(false)
			arg_4_0.contentView_:nodeByName("txt_time"):setString(xyd.secondsToString1(0))
		end
	end

	if arg_4_0.percent then
		arg_4_0.contentView_:nodeByName("txt_persent"):setString(arg_4_0.percent .. "%")
	end

	if arg_4_0.chargeState ~= xyd.ChargeState.diamond and arg_4_0.chargeState ~= xyd.ChargeState.monthlyPrivilege then
		arg_4_0.contentView_:nodeByName("btn_buy"):addTouchEventListener(function(arg_6_0, arg_6_1)
			if arg_6_1 == ccui.TouchEventType.began then
				arg_4_0.contentView_:nodeByName("btn_buy"):setScale(0.9, 0.9)
			end

			if arg_6_1 == ccui.TouchEventType.moved then
				arg_4_0.contentView_:nodeByName("btn_buy"):setScale(1, 1)
			end

			if arg_6_1 == ccui.TouchEventType.ended then
				arg_4_0.contentView_:nodeByName("btn_buy"):setScale(1, 1)

				local var_6_0 = xyd.WindowManager.get():getWindow("vip_recharge")

				if var_6_0 and not var_6_0.scrollViewMoved_ then
					xyd.WindowManager.get():openWindow("gift_view", {
						gift_data = arg_4_0.giftData
					})
				end
			end
		end)
	else
		arg_4_0.contentView_:nodeByName("btn_buy"):addTouchEventListener(function(arg_7_0, arg_7_1)
			if arg_7_1 == ccui.TouchEventType.began then
				arg_4_0.contentView_:nodeByName("btn_buy"):setScale(0.9, 0.9)
			end

			if arg_7_1 == ccui.TouchEventType.moved then
				arg_4_0.contentView_:nodeByName("btn_buy"):setScale(1, 1)
			end

			if arg_7_1 == ccui.TouchEventType.ended then
				arg_4_0.contentView_:nodeByName("btn_buy"):setScale(1, 1)

				local var_7_0 = xyd.WindowManager.get():getWindow("vip_recharge")

				if var_7_0 and not var_7_0.scrollViewMoved_ then
					dump(arg_4_0.chargeId)
					var_7_0:purchase(arg_4_0.chargeId)
				end
			end
		end)
	end
end

function var_0_0.contentView(arg_8_0)
	if arg_8_0.contentView_ == nil then
		arg_8_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_8_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/vipwindow/giftbag.csb"))
		arg_8_0.contentView_:addTo(arg_8_0)
		arg_8_0.contentView_:setTouchSwallowEnabled(false)
	end

	return arg_8_0.contentView_
end

function var_0_0.showBg(arg_9_0, arg_9_1)
	xyd.AssetLoader.get():loadSprite(arg_9_1):addTo(arg_9_0.contentView_:nodeByName("bg"))
end

return var_0_0
