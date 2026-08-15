local var_0_0 = class("AnnounceWindow", import("app.common.ui.BaseWindow"))
local var_0_1 = xyd.tables.translation
local var_0_2 = "images/default_board.png"
local var_0_3 = 10
local var_0_4 = 70

var_0_0.BTN_GO = "close_btn"

function var_0_0.willOpen(arg_1_0, arg_1_1)
	local var_1_0 = arg_1_0:nodeByName(var_0_0.BTN_GO)

	var_1_0:setTouchSwallowEnabled(false)
	xyd.nodeEventSample(var_1_0, nil, function(arg_2_0)
		xyd.WindowManager.get():closeWindow("announce")
	end)
	arg_1_0:addBlockLayer(cc.c4b(0, 0, 25, 170))

	arg_1_0.subValue = 0
	arg_1_0.contents = {}

	local var_1_1 = arg_1_1.contents or {}

	arg_1_0.index = 1
	arg_1_0.tempArg = {}

	local var_1_2 = false

	for iter_1_0, iter_1_1 in pairs(var_1_1) do
		if iter_1_1.title ~= nil then
			table.insert(arg_1_0.tempArg, iter_1_1)

			if iter_1_1.contents ~= nil then
				var_1_2 = true
			end

			if not var_1_2 then
				arg_1_0.index = arg_1_0.index + 1
			end
		end
	end

	arg_1_0:layout()
end

function var_0_0.layout(arg_3_0)
	local var_3_0 = arg_3_0:nodeByName("content_list")

	arg_3_0.AnnounceList_ = cc.ui.UIListView.new({
		async = true,
		viewRect = cc.rect(0, 0, var_3_0:getWidth(), var_3_0:getHeight()),
		padding_ = {
			top = 0,
			bottom = 0,
			left = 0,
			right = 0
		},
		direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
	}):addTo(var_3_0)

	arg_3_0.AnnounceList_:setTouchSwallowEnabled(false)
	arg_3_0.AnnounceList_:setDelegate(handler(arg_3_0, arg_3_0.contentDelegate))
	arg_3_0:initBtns()

	if arg_3_0.flag == nil then
		arg_3_0:updateContent()

		arg_3_0.flag = true
	end
end

function var_0_0.scrollListener(arg_4_0, arg_4_1)
	if arg_4_1.name == "began" then
		arg_4_0.startClick_ = true
		arg_4_0.prevY_ = arg_4_1.y
	elseif arg_4_1.name == "moved" and 20 <= math.abs(arg_4_1.y - arg_4_0.prevY_) then
		arg_4_0.startClick_ = false
	end
end

function var_0_0.updateContent(arg_5_0)
	if not arg_5_0.index then
		arg_5_0.index = 1
	end

	local var_5_0 = {}

	if arg_5_0.tempArg[arg_5_0.index].contents and type(arg_5_0.tempArg[arg_5_0.index].contents) == "table" then
		var_5_0 = arg_5_0.tempArg[arg_5_0.index].contents
	end

	arg_5_0.contents = var_5_0

	arg_5_0.AnnounceList_:reload()
end

function var_0_0.initBtns(arg_6_0)
	for iter_6_0 = 1, #arg_6_0.tempArg do
		local var_6_0 = xyd.AssetLoader.get():loadNodeFromJson("windows/announce/label_item.csb")

		var_6_0:getChildByName("container"):getChildByName("text"):setString(arg_6_0.tempArg[iter_6_0].title)
		var_6_0:addTo(arg_6_0:nodeByName("down_btn"))
		var_6_0:pos(0, (1 - iter_6_0) * 70)
		var_6_0:setName(tostring(iter_6_0))
		var_6_0:setVisible(iter_6_0 ~= arg_6_0.index)
		xyd.nodeEventSample(var_6_0:getChildByName("container"):getChildByName("btn"), {
			scale = 1
		}, function(arg_7_0)
			arg_6_0:nodeByName("up_btn"):getChildByName(tostring(arg_6_0.index)):setVisible(false)
			arg_6_0:nodeByName("up_btn"):getChildByName(iter_6_0):setVisible(true)
			arg_6_0:nodeByName("down_btn"):getChildByName(tostring(arg_6_0.index)):setVisible(true)
			var_6_0:setVisible(false)

			arg_6_0.index = iter_6_0

			arg_6_0:updateContent()
		end)

		local var_6_1 = xyd.AssetLoader.get():loadNodeFromJson("windows/announce/label_item2.csb")

		var_6_1:getChildByName("container"):getChildByName("text"):setString(arg_6_0.tempArg[iter_6_0].title)
		var_6_1:getChildByName("container"):getChildByName("text"):enableOutline(cc.c4b(119, 65, 41, 255), 2)
		var_6_1:addTo(arg_6_0:nodeByName("up_btn"))
		var_6_1:pos(0, (1 - iter_6_0) * 70)
		var_6_1:setName(tostring(iter_6_0))
		var_6_1:setVisible(iter_6_0 == arg_6_0.index)
	end
end

function var_0_0.contentDelegate(arg_8_0, arg_8_1, arg_8_2, arg_8_3)
	if cc.ui.UIListView.COUNT_TAG == arg_8_2 then
		local var_8_0 = #arg_8_0.contents

		if arg_8_0.tempArg[arg_8_0.index].url and arg_8_0.tempArg[arg_8_0.index].url ~= "" then
			var_8_0 = #arg_8_0.contents + 1
		end

		return var_8_0
	elseif cc.ui.UIListView.CELL_TAG == arg_8_2 then
		local var_8_1 = arg_8_0.AnnounceList_:dequeueItem()

		if not var_8_1 then
			var_8_1 = arg_8_0.AnnounceList_:newItem()
		else
			var_8_1:removeAllChildren(true)
		end

		local var_8_2 = display.newNode()

		if arg_8_0.tempArg[arg_8_0.index].url and arg_8_0.tempArg[arg_8_0.index].url ~= "" and arg_8_3 == 1 then
			local var_8_3 = arg_8_0.tempArg[arg_8_0.index].url
			local var_8_4 = xyd.split(var_8_3, "/") or {}
			local var_8_5 = var_8_4[#var_8_4] or ""
			local var_8_6 = {
				md5_code = 1,
				file_name = var_8_5,
				file_path = cc.FileUtils:getInstance():getWritablePath()
			}
			local var_8_7 = import("app.common.ui.OnlineImageSprite").new(var_0_2, var_8_3, 0, 0, var_8_6)
			local var_8_8 = (arg_8_0:nodeByName("content_list"):getWidth() - var_0_3 * 2) / var_8_7:getWidth()

			var_8_7:setScale(var_8_8)
			var_8_2:addChild(var_8_7)
			var_8_1:addContent(var_8_2)
			var_8_1:setItemSize(arg_8_0:nodeByName("content_list"):getWidth(), var_8_7:getHeight() * var_8_8 + var_0_3 * 2)
		else
			if arg_8_0.tempArg[arg_8_0.index].url and arg_8_0.tempArg[arg_8_0.index].url ~= "" then
				arg_8_3 = arg_8_3 - 1
			end

			local var_8_9 = xyd.createUrlAndColorTxt(arg_8_0.contents[arg_8_3], cc.c3b(148, 98, 73), 24, arg_8_0:nodeByName("content_list"):getWidth() - var_0_3 * 2)
			local var_8_10 = var_8_9:getContentSize().height

			var_8_9:setPosition(-arg_8_0:nodeByName("content_list"):getWidth() / 2 + var_0_3, -var_8_10 / 2)
			var_8_2:addChild(var_8_9)
			var_8_1:addContent(var_8_2)
			var_8_1:setItemSize(arg_8_0:nodeByName("content_list"):getWidth(), var_8_10 + 10)
		end

		return var_8_1
	end
end

function var_0_0.didOpen(arg_9_0, arg_9_1)
	var_0_0.super:didOpen(arg_9_1)
end

return var_0_0
