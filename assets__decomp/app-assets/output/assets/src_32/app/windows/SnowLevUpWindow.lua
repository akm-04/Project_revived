local var_0_0 = class("SnowLevUpWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = require("framework.scheduler")
local var_0_2 = xyd.tables.translation
local var_0_3 = xyd.tables.item

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.snowActivity = xyd.ModelManager.get():loadModel(xyd.ModelType.SNOW_ACTIVITY)
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.backpack = arg_1_0.selfPlayer:getBackpack()
	arg_1_0.hero = arg_1_2.hero
	arg_1_0.itemID = xyd.tables.hero:levelItem(arg_1_0.hero:getTableID())
	arg_1_0.oldLev = arg_1_0.hero:getLevel()
	arg_1_0.newLev = arg_1_0.oldLev
	arg_1_0.curUseItemNum_ = 0
	arg_1_0.maxItemNum = 0
end

function var_0_0.willOpen(arg_2_0, arg_2_1)
	var_0_0.super:willOpen(arg_2_1)
	arg_2_0:layout()
	arg_2_0:addBlockLayer()
end

function var_0_0.layout(arg_3_0)
	arg_3_0:updateItemNum()
	arg_3_0:updateLev()
	arg_3_0:setupButton()
	arg_3_0:updateSelectNum()
	xyd.setItemBorder(arg_3_0:nodeByName("icon"), arg_3_0.itemID)
	arg_3_0:nodeByName("text_name"):setString(var_0_3:name(arg_3_0.itemID))
	arg_3_0:nodeByName("text_select_des"):setString(var_0_2:translation("SELECT_NUM"))
	arg_3_0:nodeByName("text_lev_des"):setString(var_0_2:translation("SNOW_ACTIVITY_LEV_UP"))
end

function var_0_0.updateItemNum(arg_4_0)
	local var_4_0 = arg_4_0.backpack:getItemNumByID(arg_4_0.itemID)

	arg_4_0.maxItemNum = var_4_0

	local var_4_1 = string.format(var_0_2:translation("SNOW_ACTIVITY_LEV_ITEM_NUM"), var_4_0)

	arg_4_0:nodeByName("text_count"):setString(var_4_1)
end

function var_0_0.updateLev(arg_5_0)
	arg_5_0:nodeByName("text_old_lev"):setString(arg_5_0.oldLev)
	arg_5_0:nodeByName("text_new_lev"):setString(arg_5_0.newLev)
end

function var_0_0.updateSelectNum(arg_6_0)
	local var_6_0 = arg_6_0.curUseItemNum_ .. " / " .. arg_6_0.maxItemNum

	arg_6_0:nodeByName("text_select_num"):setString(var_6_0)

	local var_6_1 = xyd.tables.hero:levelItemExp(arg_6_0.hero:getTableID()) * arg_6_0.curUseItemNum_
	local var_6_2 = arg_6_0.hero:getExp() + var_6_1

	arg_6_0.newLev = arg_6_0:getLevel(var_6_2, arg_6_0.oldLev)

	arg_6_0:updateLev()
end

function var_0_0.getLevel(arg_7_0, arg_7_1, arg_7_2)
	local var_7_0 = 100
	local var_7_1 = arg_7_2

	for iter_7_0 = arg_7_2, var_7_0 do
		if arg_7_1 >= xyd.tables.partnerExp:totalExp(iter_7_0) then
			var_7_1 = math.min(iter_7_0 + 1, var_7_0)
		else
			break
		end
	end

	return var_7_1
end

function var_0_0.getMaxItemNum(arg_8_0)
	local var_8_0 = xyd.tables.hero:levelItemExp(arg_8_0.hero:getTableID())
	local var_8_1 = arg_8_0.hero:getExp()
	local var_8_2 = xyd.tables.partnerExp:totalExp(100)
	local var_8_3 = math.ceil((var_8_2 - var_8_1) / var_8_0)

	if var_8_3 > arg_8_0.maxItemNum then
		var_8_3 = arg_8_0.maxItemNum
	end

	return var_8_3
end

function var_0_0.setupButton(arg_9_0)
	arg_9_0:nodeByName("btn_max"):addTouchEventListener(function(arg_10_0, arg_10_1)
		if arg_10_1 == ccui.TouchEventType.ended then
			arg_9_0.curUseItemNum_ = arg_9_0:getMaxItemNum()

			arg_9_0:updateSelectNum()
		end
	end)

	local function var_9_0(arg_11_0)
		if arg_9_0.curUseItemNum_ > 0 then
			arg_9_0.curUseItemNum_ = arg_9_0.curUseItemNum_ - 1

			arg_9_0:updateSelectNum()
		else
			if arg_11_0 then
				var_0_1.unscheduleGlobal(arg_11_0)

				arg_11_0 = nil
			end

			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_2:translation("HAS_DEL_MIN")
			})
		end
	end

	local function var_9_1(arg_12_0)
		if arg_9_0.curUseItemNum_ < arg_9_0.maxItemNum then
			arg_9_0.curUseItemNum_ = arg_9_0.curUseItemNum_ + 1

			arg_9_0:updateSelectNum()
		else
			if arg_12_0 then
				var_0_1.unscheduleGlobal(arg_12_0)

				arg_12_0 = nil
			end

			xyd.WindowManager.get():openWindow("toast", {
				message = var_0_2:translation("HAS_ADD_MAX")
			})
		end
	end

	xyd.buttonLongTouch(arg_9_0:nodeByName("btn_del"), var_9_0, var_9_0)
	xyd.buttonLongTouch(arg_9_0:nodeByName("btn_add"), var_9_1, var_9_1)
	arg_9_0:nodeByName("btn_use"):addTouchEventListener(function(arg_13_0, arg_13_1)
		if arg_13_1 == ccui.TouchEventType.ended and arg_9_0.curUseItemNum_ > 0 then
			local var_13_0 = {
				table_id = arg_9_0.hero:getTableID(),
				item_num = arg_9_0.curUseItemNum_
			}

			arg_9_0.snowActivity:addExp(var_13_0, function(arg_14_0, arg_14_1)
				if arg_14_0 == xyd.error.OK and arg_9_0 and not tolua.isnull(arg_9_0) then
					arg_9_0:update()
				end
			end)
		end
	end)
end

function var_0_0.update(arg_15_0)
	arg_15_0.curUseItemNum_ = 0
	arg_15_0.oldLev = arg_15_0.hero:getLevel()
	arg_15_0.newLev = arg_15_0.oldLev

	arg_15_0:updateItemNum()
	arg_15_0:updateLev()
	arg_15_0:updateSelectNum()

	local var_15_0 = xyd.WindowManager.get():getWindow("snow_info")

	if var_15_0 and not tolua.isnull(var_15_0) then
		var_15_0:updateLev()
	end
end

return var_0_0
