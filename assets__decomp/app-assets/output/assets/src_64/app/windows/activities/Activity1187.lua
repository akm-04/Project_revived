local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = import("app.common.ui.SpineEffect")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.misc
local var_0_4 = 10
local var_0_5 = {
	TEN = 2,
	ONE = 1
}

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.is_open = arg_1_0.activity.is_open or 0
	arg_1_0.details = arg_1_0.activity.details
	arg_1_0.serverTime = arg_1_0.details.server_time
	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.animaIsPlay = false
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))
	var_2_0:setPosition(0, 0)

	arg_2_0.container = var_2_0:getChildByName("container")
	arg_2_0.btnGift = arg_2_0.container:getChildByName("btn_gift")
	arg_2_0.coinTxt = arg_2_0.container:getChildByName("coin_txt")

	arg_2_0.coinTxt:enableOutline(cc.c4b(73, 52, 92, 255), 2)
	arg_2_0:initGacha()
	arg_2_0:initExtra()
	arg_2_0:initBtn()
	arg_2_0:update()
end

function var_0_0.initGacha(arg_3_0)
	local var_3_0 = arg_3_0.container:getChildByName("btn_gacha_1")
	local var_3_1 = arg_3_0.container:getChildByName("btn_gacha_10")
	local var_3_2, var_3_3 = var_3_0:getPosition()

	var_3_0:addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.began then
			var_3_0:setScale(0.9)
			var_3_0:setPosition(var_3_2, var_3_3 - 20)
		elseif arg_4_1 == ccui.TouchEventType.ended then
			var_3_0:setScale(1)
			var_3_0:setPosition(var_3_2, var_3_3)
			xyd.playButtonSound()

			if not arg_3_0:checkTime() then
				return
			end

			if arg_3_0.details.times < 1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("NUMBER_HAS_FINISH")
				})

				return
			end

			if arg_3_0.animaIsPlay then
				return
			end

			arg_3_0.activitiesModel:getActivityReward2(xyd.Activities.GaCha2, nil, var_0_5.ONE, function(arg_5_0, arg_5_1)
				if arg_5_0 == xyd.error.OK then
					arg_3_0:getReward(arg_5_1, var_0_5.ONE)
				end
			end)
		end
	end)

	local var_3_4, var_3_5 = var_3_1:getPosition()

	var_3_1:addTouchEventListener(function(arg_6_0, arg_6_1)
		if arg_6_1 == ccui.TouchEventType.began then
			var_3_1:setScale(0.9)
			var_3_1:setPosition(var_3_4, var_3_5 - 20)
		elseif arg_6_1 == ccui.TouchEventType.ended then
			var_3_1:setScale(1)
			var_3_1:setPosition(var_3_4, var_3_5)
			xyd.playButtonSound()

			if not arg_3_0:checkTime() then
				return
			end

			if arg_3_0.details.times < 1 then
				xyd.WindowManager.get():openWindow("toast", {
					message = var_0_2:translation("NUMBER_HAS_FINISH")
				})

				return
			end

			if arg_3_0.animaIsPlay then
				return
			end

			arg_3_0.activitiesModel:getActivityReward2(xyd.Activities.GaCha2, nil, var_0_5.TEN, function(arg_7_0, arg_7_1)
				if arg_7_0 == xyd.error.OK then
					arg_3_0:getReward(arg_7_1, var_0_5.TEN)
				end
			end)
		end
	end)
end

function var_0_0.getReward(arg_8_0, arg_8_1, arg_8_2)
	local var_8_0 = 10

	if arg_8_2 == var_0_5.ONE then
		var_8_0 = 1
	elseif arg_8_2 == var_0_5.TEN and arg_8_0.details.times < 10 then
		var_8_0 = arg_8_0.details.times
	end

	arg_8_0.details.times = arg_8_0.details.times - var_8_0
	arg_8_0.details.record_info = arg_8_1.record_info

	arg_8_0:update()

	arg_8_0.awards = arg_8_1.awards
	arg_8_0.animaIsPlay = true

	arg_8_0:runPreAction()
end

function var_0_0.runPreAction(arg_9_0)
	arg_9_0.container:getChildByName("bg_egg"):setVisible(false)

	local var_9_0, var_9_1 = arg_9_0.container:getChildByName("bg_egg"):getPosition()
	local var_9_2 = "windows/activities/1068/texiao/niudanji"
	local var_9_3 = var_9_2 .. ".json"
	local var_9_4 = var_9_2 .. ".atlas"

	arg_9_0.effect = var_0_1.new(var_9_3, var_9_4, 1)

	arg_9_0.effect:setAnchorPoint(cc.p(0.5, 0.5))
	arg_9_0.effect:setPosition(cc.p(var_9_0 + 10, var_9_1 - 250))
	arg_9_0.effect:addTo(arg_9_0.container:getChildByName("pos_egg_spine"), -1)
	arg_9_0.effect:play(function()
		arg_9_0:endAction()

		arg_9_0.animaIsPlay = false
	end, true, nil, "zhuan")
end

function var_0_0.endAction(arg_11_0)
	if arg_11_0.effect then
		arg_11_0.effect:hide()
		arg_11_0.effect:stop()
	end

	arg_11_0.container:getChildByName("bg_egg"):setVisible(true)
	arg_11_0.player:handleRewards(arg_11_0.awards)
end

function var_0_0.initBtn(arg_12_0)
	local var_12_0 = arg_12_0.container:getChildByName("rule_btn")

	var_12_0:setTouchEnabled(true)
	var_12_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_13_0)
		if arg_13_0.name == "began" then
			var_12_0:setScale(0.9)

			return true
		elseif arg_13_0.name == "ended" then
			var_12_0:setScale(1)
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("new_text_rule", {
				title_name = "ANNIVERSARY_GACHA2_RULE_TITLE",
				rule = "ANNIVERSARY_GACHA2_RULE_TEXT"
			})
		end
	end)

	local var_12_1 = arg_12_0.container:getChildByName("collection_btn")

	var_12_1:setTouchEnabled(true)
	var_12_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_14_0)
		if arg_14_0.name == "began" then
			var_12_1:setScale(0.9)

			return true
		elseif arg_14_0.name == "ended" then
			var_12_1:setScale(1)
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("activity_gacha2_collection")
		end
	end)
end

function var_0_0.initExtra(arg_15_0)
	arg_15_0.btnGift:addTouchEventListener(function(arg_16_0, arg_16_1)
		if arg_16_1 == ccui.TouchEventType.began then
			arg_15_0.btnGift:setScale(0.9)
		elseif arg_16_1 == ccui.TouchEventType.ended or arg_16_1 == ccui.TouchEventType.canceled then
			arg_15_0.btnGift:setScale(1)

			local var_16_0 = {
				activity_id = arg_15_0.activity.table_id
			}

			var_16_0.award_id = 1

			xyd.Backend.get():request(xyd.mid.ACTIVITY_1187_AWARD, var_16_0, function(arg_17_0, arg_17_1)
				if arg_17_0 == xyd.error.OK then
					arg_15_0.details.record_info = arg_17_1.record_info

					arg_15_0.player:handleRewards(arg_17_1.awards)
					arg_15_0:update()
				end
			end)
		end
	end)
end

function var_0_0.update(arg_18_0)
	arg_18_0.coinTxt:setString(string.format(var_0_2:translation("ACTIVITY_GACHA_COIN"), arg_18_0.details.times))
	arg_18_0.container:getChildByName("word_can_get"):setVisible(false)
	arg_18_0.container:getChildByName("pos_word"):setVisible(true)
	arg_18_0.container:getChildByName("word_open"):setVisible(true)
	arg_18_0.container:getChildByName("txt_coin_1"):setString(1)

	if arg_18_0.details.times >= 10 then
		arg_18_0.container:getChildByName("txt_coin_10"):setString(10)
	else
		arg_18_0.container:getChildByName("txt_coin_10"):setString(arg_18_0.details.times)
	end

	if arg_18_0.details.times < var_0_4 then
		arg_18_0.container:getChildByName("bg_gacha_10"):setVisible(false)
		arg_18_0.container:getChildByName("bg_gacha_all"):setVisible(true)
	else
		arg_18_0.container:getChildByName("bg_gacha_10"):setVisible(true)
		arg_18_0.container:getChildByName("bg_gacha_all"):setVisible(false)
	end

	local var_18_0 = var_0_3:getValue("gacha2_max_gift_time") - arg_18_0.details.record_info.cur_num

	arg_18_0.container:getChildByName("pos_word"):removeAllChildren()

	local function var_18_1(arg_19_0)
		local var_19_0 = "windows/activities/1068/" .. arg_19_0 .. ".png"

		return xyd.AssetLoader.get():loadSprite(var_19_0)
	end

	local var_18_2 = display.newNode()
	local var_18_3 = var_18_0
	local var_18_4 = {}
	local var_18_5 = 1
	local var_18_6 = 0
	local var_18_7 = 0

	while var_18_3 ~= 0 do
		var_18_4[var_18_5] = var_18_3 % 10
		var_18_3 = math.floor(var_18_3 / 10)
		var_18_5 = var_18_5 + 1
	end

	for iter_18_0 = var_18_5 - 1, 1, -1 do
		local var_18_8 = var_18_1(var_18_4[iter_18_0])
		local var_18_9 = var_18_8:getWidth()

		var_18_7 = var_18_8:getHeight()

		var_18_8:addTo(var_18_2, 10)
		var_18_8:setPosition(var_18_6 + var_18_9 / 2, var_18_7 / 2)

		var_18_6 = var_18_6 + var_18_9
	end

	var_18_2:setContentSize(var_18_6, var_18_7)
	var_18_2:setAnchorPoint(1, 0)
	var_18_2:addTo(arg_18_0.container:getChildByName("pos_word"))

	if (arg_18_0.details.record_info.record or 0) <= 0 then
		arg_18_0.btnGift:setBright(false)
		arg_18_0.btnGift:setTouchEnabled(false)

		return
	end

	arg_18_0.container:getChildByName("word_can_get"):setVisible(true)
	arg_18_0.container:getChildByName("pos_word"):setVisible(false)
	arg_18_0.container:getChildByName("word_open"):setVisible(false)
	arg_18_0.btnGift:setBright(true)
	arg_18_0.btnGift:setTouchEnabled(true)
end

function var_0_0.checkTime(arg_20_0)
	if arg_20_0.is_open == 0 then
		local var_20_0 = ""

		if arg_20_0.activity.start_time > arg_20_0.serverTime then
			var_20_0 = var_0_2:translation("ACTIVITY_NO_OPEN")
		elseif arg_20_0.activity.end_time < arg_20_0.serverTime then
			var_20_0 = var_0_2:translation("ACTIVITY_FINISHED")
		end

		xyd.WindowManager.get():openWindow("toast", {
			message = var_20_0
		})

		return false
	end

	return true
end

return var_0_0
