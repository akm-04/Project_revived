local var_0_0 = class("PicNoticeWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = import("app.common.ui.OnlineImageSprite")
local var_0_3 = "windows/pic_notice/default.png"
local var_0_4 = "windows/pic_notice/default_small.png"
local var_0_5 = 320

function var_0_0.ctor(arg_1_0, arg_1_1, arg_1_2)
	var_0_0.super.ctor(arg_1_0, arg_1_1, arg_1_2)

	arg_1_0.contents = arg_1_2.contents

	table.sort(arg_1_0.contents, function(arg_2_0, arg_2_1)
		return arg_2_0.weight < arg_2_1.weight
	end)

	arg_1_0.noTip = false
	arg_1_0.callback = arg_1_2.callback
end

function var_0_0.willOpen(arg_3_0, arg_3_1)
	arg_3_0:nodeByName("title"):setString(var_0_1:translation("PIC_NOTICE"))
	arg_3_0:nodeByName("lable_tip"):setString(var_0_1:translation("PIC_NOTICE_TIP"))

	local var_3_0 = arg_3_0:nodeByName("list_container")
	local var_3_1 = var_3_0:getContentSize()

	arg_3_0.itemHeight = var_3_1.height
	arg_3_0.listView = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_1.width, var_3_1.height),
		direction = cc.ui.UIListView.DIRECTION_HORIZONTAL
	}):addTo(var_3_0)

	arg_3_0.listView:setDelegate(handler(arg_3_0, arg_3_0.delegate))
	arg_3_0.listView:reload()

	arg_3_0.clickNode = arg_3_0:nodeByName("bg_click")
	arg_3_0.click = arg_3_0:nodeByName("click")

	arg_3_0.click:setVisible(false)
	arg_3_0.clickNode:setTouchEnabled(true)
	arg_3_0.clickNode:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_4_0)
		if arg_4_0.name == "began" then
			return true
		elseif arg_4_0.name == "ended" then
			arg_3_0.noTip = not arg_3_0.noTip

			arg_3_0.click:setVisible(arg_3_0.noTip)
		end
	end)

	local var_3_2 = arg_3_0:nodeByName("close_btn")

	xyd.nodeEventSample(var_3_2, nil, function()
		local var_5_0 = xyd.tables.sound:getSound("ui_close_window")

		audio.playSound(var_5_0, false)
		xyd.WindowManager.get():closeWindow(arg_3_0)
	end)
end

function var_0_0.updatePic(arg_6_0, arg_6_1)
	if arg_6_0.pSprite then
		arg_6_0.pSprite:removeSelf()
	end

	local var_6_0 = xyd.split(arg_6_1, "/") or {}
	local var_6_1 = var_6_0[#var_6_0] or ""
	local var_6_2 = {
		md5_code = 1,
		file_name = var_6_1,
		file_path = cc.FileUtils:getInstance():getWritablePath()
	}

	arg_6_0.pSprite = var_0_2.new(var_0_3, arg_6_1, 0, 0, var_6_2)

	arg_6_0.pSprite:addTo(arg_6_0:nodeByName("default"))
end

function var_0_0.didOpen(arg_7_0)
	arg_7_0:addBlockLayer()
end

function var_0_0.delegate(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	if cc.ui.UIListView.COUNT_TAG == arg_8_2 then
		return #arg_8_0.contents
	elseif cc.ui.UIListView.CELL_TAG == arg_8_2 then
		local var_8_0 = arg_8_0.listView:dequeueItem()

		if not var_8_0 then
			var_8_0 = arg_8_0.listView:newItem()
		else
			var_8_0:removeAllChildren(true)
		end

		local var_8_1 = arg_8_0:createItem(arg_8_0.contents[arg_8_3])

		var_8_0:setItemSize(var_0_5, arg_8_0.itemHeight)
		var_8_0:addContent(var_8_1)

		return var_8_0
	end
end

function var_0_0.createItem(arg_9_0, arg_9_1)
	local var_9_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/pic_notice/pic_notice_item.csb")

	var_9_0:setContentSize(var_0_5, arg_9_0.itemHeight)

	local var_9_1 = arg_9_1.small_pic
	local var_9_2 = xyd.split(var_9_1, "/") or {}
	local var_9_3 = var_9_2[#var_9_2] or ""
	local var_9_4 = {
		md5_code = 1,
		file_name = var_9_3,
		file_path = cc.FileUtils:getInstance():getWritablePath()
	}

	var_0_2.new(var_0_4, var_9_1, 0, 0, var_9_4):addTo(var_9_0:getChildByName("pic"))

	if not arg_9_0.chosenPic then
		arg_9_0.chosenPic = var_9_0:getChildByName("chosen")

		arg_9_0.chosenPic:setVisible(true)
		arg_9_0:updatePic(arg_9_1.pic)
	end

	var_9_0:setTouchEnabled(true)
	var_9_0:setTouchSwallowEnabled(false)
	var_9_0:addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_10_0)
		if arg_10_0.name == "began" then
			var_9_0:setScale(0.9)

			return true
		elseif arg_10_0.name == "ended" then
			var_9_0:setScale(1)

			if arg_9_0.chosenPic and not tolua.isnull(arg_9_0.chosenPic) then
				arg_9_0.chosenPic:setVisible(false)
			end

			arg_9_0.chosenPic = var_9_0:getChildByName("chosen")

			arg_9_0.chosenPic:setVisible(true)
			arg_9_0:updatePic(arg_9_1.pic)
		end
	end)

	return var_9_0
end

function var_0_0.willClose(arg_11_0)
	if arg_11_0.noTip then
		xyd.Backend.get():request(xyd.mid.READ_PIC_NOTICE, {}, nil, nil, false)
	end

	if arg_11_0.callback then
		arg_11_0.callback()
	end
end

function var_0_0.didClose(arg_12_0)
	return
end

return var_0_0
