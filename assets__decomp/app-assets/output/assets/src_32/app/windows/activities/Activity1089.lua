local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = xyd.tables.translation
local var_0_4 = 50005181
local var_0_5 = 6
local var_0_6 = 3

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.yuanxiaoNum = arg_1_0.player:getBackpack():getItemNumByID(var_0_4)
	arg_1_0.count = arg_1_0.activity.details.times
	arg_1_0.cookTime = xyd.splitToNumber(arg_1_0.activity.details.pots, "|")
	arg_1_0.cookNeedTime = xyd.tables.misc.yuanxiaoCookTime
	arg_1_0.yuanxiaoHandle = {}
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

	local var_2_1 = xyd.tables.activities:title(arg_2_0.activity.table_id)
	local var_2_2 = xyd.AssetLoader.get():loadSprite(var_2_1)
	local var_2_3, var_2_4 = var_2_0:getChildByName("title_pos"):getPosition()

	var_2_2:addTo(var_2_0)
	var_2_2:setPosition(var_2_3, var_2_4)

	arg_2_0.container = var_2_0:getChildByName("bg")
	arg_2_0.leftPerson = arg_2_0.container:getChildByName("left_person")
	arg_2_0.rightPerson = arg_2_0.container:getChildByName("right_person")
	arg_2_0.panContainer = arg_2_0.container:getChildByName("bg_bottom")
	arg_2_0.pan = arg_2_0.panContainer:getChildByName("pan")
	arg_2_0.dialogPic = arg_2_0.container:getChildByName("bg_dialog")
	arg_2_0.dialogTxt = arg_2_0.container:getChildByName("dialog")

	arg_2_0.dialogTxt:enableOutline(cc.c4b(115, 7, 71, 255), 2)

	arg_2_0.numTxt = arg_2_0.container:getChildByName("num_tag"):getChildByName("num_txt")
	arg_2_0.yuanxiaoClick = {}

	for iter_2_0 = 1, var_0_5 do
		table.insert(arg_2_0.yuanxiaoClick, arg_2_0.panContainer:getChildByName("yuanxiao" .. iter_2_0))
	end

	arg_2_0.container:getChildByName("rule_btn"):addTouchEventListener(function(arg_3_0, arg_3_1)
		if arg_3_1 == ccui.TouchEventType.ended then
			xyd.playButtonSound()
			xyd.WindowManager.get():openWindow("activity_gacha_rule", {
				rule = "YUANXIAO_COOK_RULE_TEXT",
				title = "YUANXIAO_COOK_RULE_TITLE"
			})
		end
	end)

	if arg_2_0.activity.is_open == 0 then
		arg_2_0.numTxt:setString(arg_2_0.count)

		local var_2_5 = xyd.ServerTime.get():getServerTime()
		local var_2_6 = ""

		if var_2_5 < arg_2_0.activity.start_time then
			var_2_6 = var_0_3:translation("ACTIVITY_NO_OPEN")
		elseif var_2_5 > arg_2_0.activity.end_time then
			var_2_6 = var_0_3:translation("ACTIVITY_FINISHED")
		end

		arg_2_0.dialogTxt:setString(var_2_6)

		return
	end

	arg_2_0:addEffect(arg_2_0.panContainer:getChildByName("pan_effect"), 3)
	arg_2_0:showDialog()
	arg_2_0:initCook()
end

function var_0_0.initCook(arg_4_0)
	arg_4_0.numTxt:setString(arg_4_0.count)

	arg_4_0.numList = {}

	local var_4_0 = xyd.ServerTime.get():getServerTime()

	for iter_4_0, iter_4_1 in ipairs(arg_4_0.cookTime) do
		if iter_4_1 == 0 then
			table.insert(arg_4_0.numList, iter_4_0)
			arg_4_0.yuanxiaoClick[iter_4_0]:setVisible(false)
		else
			arg_4_0.yuanxiaoClick[iter_4_0]:setVisible(true)

			local var_4_1 = arg_4_0.cookTime[iter_4_0] + arg_4_0.cookNeedTime - var_4_0

			if var_4_1 > 0 then
				arg_4_0:addEffect(arg_4_0.panContainer:getChildByName("yuanxiao_effect" .. iter_4_0), 1)
				arg_4_0:cookHandle(iter_4_0, var_4_1)
			else
				arg_4_0:addEffect(arg_4_0.panContainer:getChildByName("yuanxiao_effect" .. iter_4_0), 2)
			end
		end
	end

	arg_4_0.pan:setTouchEnabled(true)
	arg_4_0.pan:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_5_0)
		if arg_5_0.name == "began" then
			return true
		elseif arg_5_0.name == "ended" then
			if arg_4_0.count == 0 then
				arg_4_0:showDialog(var_0_3:translation("YUANXIAO_COOK_NO_COUNT"))

				return
			elseif #arg_4_0.numList == 0 then
				arg_4_0:showDialog(var_0_3:translation("YUANXIAO_COOK_NO_SPACE"))

				return
			end

			local var_5_0 = arg_4_0.numList[math.random(#arg_4_0.numList)]

			xyd.Backend.get():request(xyd.mid.YUANXIAO_START_COOK, {
				index = var_5_0
			}, function(arg_6_0, arg_6_1)
				if arg_6_0 == xyd.error.OK then
					arg_4_0.count = arg_6_1.times
					arg_4_0.cookTime = xyd.splitToNumber(arg_6_1.pots, "|")

					if arg_4_0.numTxt and not tolua.isnull(arg_4_0.numTxt) then
						arg_4_0.numTxt:setString(arg_4_0.count)
					end

					if arg_4_0.numList and next(arg_4_0.numList) then
						for iter_6_0, iter_6_1 in pairs(arg_4_0.numList) do
							if iter_6_1 == var_5_0 then
								table.remove(arg_4_0.numList, iter_6_0)

								break
							end
						end
					end

					if arg_4_0.yuanxiaoClick[var_5_0] and not tolua.isnull(arg_4_0.yuanxiaoClick[var_5_0]) then
						arg_4_0.yuanxiaoClick[var_5_0]:setVisible(true)
					end

					if arg_4_0.panContainer and not tolua.isnull(arg_4_0.panContainer) then
						arg_4_0:addEffect(arg_4_0.panContainer:getChildByName("yuanxiao_effect" .. var_5_0), 1)
					end

					arg_4_0:cookHandle(var_5_0, arg_4_0.cookNeedTime)
				end
			end)
		end
	end)

	for iter_4_2, iter_4_3 in ipairs(arg_4_0.yuanxiaoClick) do
		iter_4_3:setTouchEnabled(true)
		iter_4_3:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_7_0)
			if arg_7_0.name == "began" then
				return true
			elseif arg_7_0.name == "ended" then
				local var_7_0 = arg_4_0.cookTime[iter_4_2] + arg_4_0.cookNeedTime - xyd.ServerTime.get():getServerTime()

				if var_7_0 >= 0 then
					local var_7_1 = var_7_0 % 60

					arg_4_0:showDialog(string.format(var_0_3:translation("YUANXIAO_COOK_NOT_COMPLETE"), (var_7_0 - var_7_1) / 60, var_7_1))

					return
				end

				xyd.Backend.get():request(xyd.mid.YUANXIAO_FINISH_COOK, {
					index = iter_4_2
				}, function(arg_8_0, arg_8_1)
					if arg_8_0 == xyd.error.OK then
						arg_4_0.player:handleRewards({
							{
								item_num = 1,
								table_id = var_0_4
							}
						})

						arg_4_0.yuanxiaoNum = arg_4_0.yuanxiaoNum + 1
						arg_4_0.cookTime = xyd.splitToNumber(arg_8_1.pots, "|")

						table.insert(arg_4_0.numList, iter_4_2)

						if arg_4_0.yuanxiaoClick[iter_4_2] and not tolua.isnull(arg_4_0.yuanxiaoClick[iter_4_2]) then
							arg_4_0.yuanxiaoClick[iter_4_2]:setVisible(false)
						end

						if arg_4_0.panContainer and not tolua.isnull(arg_4_0.panContainer) then
							arg_4_0.panContainer:getChildByName("yuanxiao_effect" .. iter_4_2):removeAllChildren()
						end
					end
				end)
			end
		end)
	end

	arg_4_0:initAward(arg_4_0.leftPerson:getChildByName("left_person_click"), 1)
	arg_4_0:initAward(arg_4_0.rightPerson:getChildByName("right_person_click"), 2)
end

function var_0_0.initAward(arg_9_0, arg_9_1, arg_9_2)
	arg_9_1:setTouchEnabled(true)
	arg_9_1:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
		if arg_10_0.name == "began" then
			return true
		elseif arg_10_0.name == "ended" then
			if arg_9_0.yuanxiaoNum < 1 then
				arg_9_0:showDialog(var_0_3:translation("YUANXIAO_COOK_NO_ITEM"), arg_9_2 == 2)

				return
			end

			local var_10_0 = var_0_3:translation("YUANXIAO_CONFIRM")

			xyd.CommonAlertWindow.open(xyd.CommonAlertType.TWO_BTN, var_10_0, function()
				if not arg_9_0 or tolua.isnull(arg_9_0.container) then
					return
				end

				arg_9_0.activitiesModel:getActivityReward(arg_9_0.activity.table_id, arg_9_2, function(arg_12_0, arg_12_1)
					if arg_12_0 == xyd.error.OK then
						arg_9_0.player:getBackpack():removeItem({
							itemNum = 1,
							itemID = var_0_4
						})

						arg_9_0.yuanxiaoNum = arg_9_0.yuanxiaoNum - 1

						arg_9_0.player:handleRewards(arg_12_1.awards)
						arg_9_0:showDialog(var_0_3:translation("YUANXIAO_COOK_EAT"), arg_9_2 == 2, true)
					end
				end)
			end, nil, nil, xyd.ColorMode.ACTIVITY)
		end
	end)
end

function var_0_0.cookHandle(arg_13_0, arg_13_1, arg_13_2)
	arg_13_0.yuanxiaoHandle[arg_13_1] = var_0_1.performWithDelayGlobal(function()
		arg_13_0.yuanxiaoHandle[arg_13_1] = nil

		if arg_13_0.panContainer and not tolua.isnull(arg_13_0.panContainer) then
			local var_14_0 = arg_13_0.panContainer:getChildByName("yuanxiao_effect" .. arg_13_1)

			if var_14_0 then
				var_14_0:removeAllChildren()
				arg_13_0:addEffect(var_14_0, 2)
			end
		end
	end, arg_13_2)
end

function var_0_0.showDialog(arg_15_0, arg_15_1, arg_15_2, arg_15_3)
	if not arg_15_1 then
		arg_15_0.dialogPic:setFlippedX(false)
		arg_15_0.dialogTxt:setString(var_0_3:translation("YUANXIAO_COOK_STARVE"))
		arg_15_0.leftPerson:loadTexture("windows/activities/1089/left_person_n.png")
		arg_15_0.rightPerson:loadTexture("windows/activities/1089/right_person_n.png")

		return
	end

	if arg_15_2 then
		arg_15_0.dialogPic:setFlippedX(true)
	else
		arg_15_0.dialogPic:setFlippedX(false)
	end

	if not arg_15_2 and arg_15_3 then
		arg_15_0.leftPerson:loadTexture("windows/activities/1089/left_person_h.png")
	else
		arg_15_0.leftPerson:loadTexture("windows/activities/1089/left_person_n.png")
	end

	if arg_15_2 and arg_15_3 then
		arg_15_0.rightPerson:loadTexture("windows/activities/1089/right_person_h.png")
	else
		arg_15_0.rightPerson:loadTexture("windows/activities/1089/right_person_n.png")
	end

	arg_15_0.dialogTxt:setString(arg_15_1)

	if arg_15_0.dialogHandle then
		var_0_1.unscheduleGlobal(arg_15_0.dialogHandle)
	end

	arg_15_0.dialogHandle = var_0_1.performWithDelayGlobal(function()
		if arg_15_0.showDialog then
			arg_15_0:showDialog()
		end
	end, var_0_6)
end

function var_0_0.addEffect(arg_17_0, arg_17_1, arg_17_2)
	local var_17_0 = "skeletons/ui_effect/yuanxiao/yuanxiao" .. arg_17_2
	local var_17_1 = var_0_2.new(var_17_0 .. ".json", var_17_0 .. ".atlas", 1)

	var_17_1:addTo(arg_17_1)
	var_17_1:play(nil, true)
end

function var_0_0.release(arg_18_0)
	if arg_18_0.dialogHandle then
		var_0_1.unscheduleGlobal(arg_18_0.dialogHandle)
	end

	for iter_18_0, iter_18_1 in pairs(arg_18_0.yuanxiaoHandle) do
		var_0_1.unscheduleGlobal(iter_18_1)
	end
end

return var_0_0
