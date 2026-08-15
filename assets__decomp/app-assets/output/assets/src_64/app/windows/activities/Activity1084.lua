local var_0_0 = class("Activity", import("app.windows.activities.BaseActivity"))
local var_0_1 = xyd.tables.translation

function var_0_0.ctor(arg_1_0, arg_1_1)
	var_0_0.super.ctor(arg_1_0, arg_1_1)

	arg_1_0.singleDogGiftTime = xyd.tables.misc.singleDogGiftTime
	arg_1_0.selfPlayer = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)
	arg_1_0.rollContainer = {}
	arg_1_0.curTimeNum = nil
	arg_1_0.countRoll = 0
	arg_1_0.singleDogModel_ = nil
	arg_1_0.textHandler = nil
end

function var_0_0.show(arg_2_0, arg_2_1)
	var_0_0.super.show(arg_2_0, arg_2_1)

	if not arg_2_0.res or arg_2_0.res == 0 then
		print("No res available.")

		return
	end

	local var_2_0 = xyd.AssetLoader.get():loadNodeFromJson(arg_2_0.res)

	var_2_0:addTo(arg_2_0.parent)
	var_2_0:setPosition(-22, 22)

	arg_2_0.container = var_2_0:getChildByName("container")

	arg_2_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = arg_3_0.container

	var_3_0:getChildByName("text_desc_title"):setString(var_0_1:translation("MONTH_CARD_VIP_TITLE"))

	if arg_3_0.selfPlayer.leftCardDay > 0 then
		var_3_0:getChildByName("btn_go"):setVisible(false)
	end

	var_3_0:getChildByName("btn_go"):addTouchEventListener(function(arg_4_0, arg_4_1)
		if arg_4_1 == ccui.TouchEventType.ended then
			xyd.WindowManager.get():openWindow("vip_recharge")
		end
	end)
	arg_3_0:initTextDesc()
	arg_3_0:initMiddleText()
end

function var_0_0.initTextDesc(arg_5_0)
	local var_5_0 = arg_5_0.container:getChildByName("desc_container")
	local var_5_1 = xyd.split(var_0_1:translation("MONTH_CARD_VIP_TEXT"), "\n")
	local var_5_2 = var_5_0:getContentSize()
	local var_5_3 = var_5_2.width
	local var_5_4 = var_5_2.height

	for iter_5_0 = 1, #var_5_1 do
		local var_5_5 = arg_5_0:createTextLabel(var_5_1[iter_5_0], var_5_3, cc.ui.TEXT_ALIGN_LEFT, 18, cc.c3b(0, 0, 0))

		var_5_5:addTo(var_5_0)
		var_5_5:setPosition(cc.p(0, var_5_4))
		var_5_5:setAnchorPoint(cc.p(0, 1))

		var_5_4 = var_5_4 - var_5_5:getContentSize().height
	end
end

function var_0_0.createTextLabel(arg_6_0, arg_6_1, arg_6_2, arg_6_3, arg_6_4, arg_6_5)
	local var_6_0 = {
		text = arg_6_1,
		align = arg_6_3,
		color = arg_6_5,
		size = arg_6_4,
		dimensions = cc.size(arg_6_2, 0)
	}

	return (xyd.AssetLoader.get():loadLabel(var_6_0))
end

function var_0_0.initMiddleText(arg_7_0)
	local var_7_0 = arg_7_0.container
	local var_7_1 = {
		"img_yellow",
		"img_purple",
		"img_blue"
	}
	local var_7_2 = {
		"MONTH_CARD_EQUIP_ADD",
		"MONTH_CARD_JINBI_ADD",
		"MONTH_CARD_WORK_ADD"
	}
	local var_7_3 = {
		cc.c4b(177, 96, 0, 255),
		cc.c4b(150, 0, 228, 255),
		cc.c4b(11, 102, 179, 255)
	}

	for iter_7_0 = 1, #var_7_1 do
		local var_7_4 = arg_7_0:createTextLabel(var_0_1:translation(var_7_2[iter_7_0]), 100, cc.ui.TEXT_ALIGN_CENTER, 22, cc.c3b(255, 255, 255))

		var_7_4:addTo(var_7_0)

		local var_7_5 = cc.p(var_7_0:getChildByName(var_7_1[iter_7_0]):getPosition())

		var_7_4:setPosition(cc.p(var_7_5.x, var_7_5.y - 5))
		var_7_4:enableOutline(var_7_3[iter_7_0], 1)
		var_7_4:setAnchorPoint(cc.p(0.5, 0.5))
	end
end

return var_0_0
