local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.SpineEffect")
local var_0_3 = import("framework.scheduler")
local var_0_4 = 10
local var_0_5 = 7

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.player = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	arg_2_0.leftTimes = arg_2_0.activity.details.left_times
	arg_2_0.buyTimes = arg_2_0.activity.details.buy_times
	arg_2_0.star = arg_2_0.activity.details.star

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setAnchorPoint(cc.p(0, 0))
	var_2_0:setPosition(0, 0)

	local var_2_1 = var_2_0:getChildByName("container")

	var_2_1:getChildByName("desc_text"):setString(xyd.tables.activities:desc(arg_2_0.activity.table_id))
	var_2_1:getChildByName("time_words"):setString(var_0_1:translation("ACTIVITY_TIME"))

	local var_2_2 = os.date("%m", arg_2_0.activity.start_time)
	local var_2_3 = os.date("%d", arg_2_0.activity.start_time)
	local var_2_4 = os.date("%m", arg_2_0.activity.end_time)
	local var_2_5 = os.date("%d", arg_2_0.activity.end_time)

	var_2_1:getChildByName("time_text"):setString(string.format(var_0_1:translation("TEAM_DATA_DATE"), var_2_2, var_2_3) .. "-" .. string.format(var_0_1:translation("TEAM_DATA_DATE"), var_2_4, var_2_5))

	local var_2_6 = math.ceil((xyd.ServerTime.get():getServerTime() - arg_2_0.activity.start_time) / xyd.OneDaySec)

	arg_2_0.grayList = {}

	for iter_2_0 = 1, 7 do
		arg_2_0.grayList[iter_2_0] = display.newFilteredSprite("windows/activities/1049/" .. iter_2_0 .. ".png", "GRAY", {
			0.2,
			0.3,
			0.5,
			0.1
		})

		arg_2_0.grayList[iter_2_0]:setAnchorPoint(cc.p(0, 0))
		arg_2_0.grayList[iter_2_0]:addTo(var_2_1:getChildByName("btn_" .. iter_2_0))
		arg_2_0.grayList[iter_2_0]:setVisible(false)
		var_2_1:getChildByName("btn_" .. iter_2_0):getChildByName("d" .. iter_2_0):setLocalZOrder(10)
	end

	for iter_2_1 = 1, var_0_5 do
		if var_2_6 <= 0 then
			break
		end

		local var_2_7 = var_2_1:getChildByName("btn_" .. iter_2_1)

		var_2_7:setTouchEnabled(true)

		if iter_2_1 ~= var_2_6 then
			arg_2_0.grayList[iter_2_1]:setVisible(true)
			arg_2_0.grayList[iter_2_1]:setTouchEnabled(true)
			var_2_7:getChildByName("lock_" .. iter_2_1):setTouchEnabled(true)

			local var_2_8 = arg_2_0.grayList[iter_2_1]

			if var_2_6 < iter_2_1 then
				var_2_8 = var_2_7:getChildByName("lock_" .. iter_2_1)

				arg_2_0.grayList[iter_2_1]:setVisible(false)
			end

			var_2_8:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_3_0)
				if arg_3_0.name == "began" then
					return true
				elseif arg_3_0.name == "ended" then
					local var_3_0 = var_0_1:translation("SAKURA_CAMPAIN_UNOPEN")

					if iter_2_1 < var_2_6 then
						var_3_0 = var_0_1:translation("SAKURA_CAMPAIN_ISOVER")
					end

					xyd.WindowManager.get():openWindow("toast", {
						message = var_3_0
					})
					xyd.playButtonSound()
				end
			end)
		else
			var_2_7:getChildByName("lock_" .. iter_2_1):setVisible(false)
			var_2_7:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
				if arg_4_0.name == "began" then
					var_2_7:setScale(0.9)

					return true
				elseif arg_4_0.name == "ended" then
					local var_4_0 = 0
					local var_4_1 = xyd.tables.activitySakuraCampaign:fightId(arg_2_0.player.lev, iter_2_1)
					local var_4_2 = xyd.tables.campaign:campaignType(var_4_1)
					local var_4_3 = arg_2_0.star
					local var_4_4 = {
						campaignID = var_4_1,
						campaignType = var_4_2,
						star = var_4_3,
						dailyLimit = arg_2_0.leftTimes,
						buyTimes = arg_2_0.buyTimes,
						maxBuyTime = xyd.tables.misc.sakuraSecurityBuyLimit
					}

					var_2_7:setScale(1)
					xyd.playButtonSound()
					xyd.WindowManager.get():openWindow("map_detail_window", var_4_4)
				end
			end)
		end
	end
end

function var_0_0.isShow(arg_5_0, arg_5_1)
	if arg_5_0.player.lev < var_0_4 then
		return false
	end

	if arg_5_0.activity then
		return xyd.tables.activities:isShow(arg_5_0.activity.table_id) == 1
	else
		return false
	end
end

function var_0_0.release(arg_6_0)
	var_0_0.super:release()
end

return var_0_0
