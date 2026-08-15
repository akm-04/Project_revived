local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation
local var_0_2 = require("framework.scheduler")
local var_0_3 = import("app.model.Hero")
local var_0_4 = 4

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)
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

	local var_2_1 = var_2_0:getChildByName("bg")
	local var_2_2 = xyd.tables.activities:title(arg_2_0.activity.table_id)
	local var_2_3 = xyd.AssetLoader.get():loadSprite(var_2_2)

	var_2_3:addTo(var_2_0)
	var_2_3:setAnchorPoint(cc.p(0.5, 0.5))
	var_2_3:setPosition(var_2_0:getChildByName("title_pos"):getPosition())

	local var_2_4 = var_2_1:getChildByName("detail_btn")

	var_2_4:setTouchEnabled(true)
	var_2_4:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_3_0)
		if arg_3_0.name == "began" then
			var_2_4:setScale(0.9)

			return true
		elseif arg_3_0.name == "ended" then
			var_2_4:setScale(1)
			xyd.WebView:getInstance():openURL(xyd.tables.misc.anniversary_share_url)
		end
	end)

	local var_2_5 = var_2_1:getChildByName("share_btn")

	var_2_5:setTouchEnabled(true)
	var_2_5:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
		if arg_4_0.name == "began" then
			var_2_5:setScale(0.9)

			return true
		elseif arg_4_0.name == "ended" then
			var_2_5:setScale(1)

			if arg_2_0.activity.details.is_award == 0 then
				arg_2_0.activitiesModel:getActivityReward(arg_2_0.activity.table_id, 1, function(arg_5_0, arg_5_1)
					if arg_5_0 == xyd.error.OK then
						arg_2_0.activity.details.is_award = 1
						arg_2_0.handle = var_0_2.performWithDelayGlobal(function()
							xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):handleRewards(arg_5_1.awards)
						end, var_0_4)
					end
				end)
			end

			local var_4_0 = xyd.tables.fbShare
			local var_4_1 = xyd.FBShareType.ANNIVERSARY

			xyd.fbShare(var_4_0:type(var_4_1), var_4_0:title(var_4_1), var_4_0:content(var_4_1), var_4_0:link(var_4_1), var_4_0:imgLink(var_4_1))
		end
	end)
end

function var_0_0.release(arg_7_0)
	if arg_7_0.handle then
		var_0_2.unscheduleGlobal(arg_7_0.handle)
	end
end

return var_0_0
