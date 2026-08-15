local var_0_0 = class("ValentineChooseFriendItem", function()
	return cc.Node:create()
end)
local var_0_1 = xyd.tables.translation
local var_0_2 = 1000
local var_0_3 = xyd.tables.hero

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()

	arg_2_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
end

function var_0_0.contentView(arg_3_0)
	if arg_3_0.contentView_ == nil then
		arg_3_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_3_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/activities/1142/friend_item.csb"))
		arg_3_0.contentView_:addTo(arg_3_0)
		arg_3_0.contentView_:setTouchSwallowEnabled(false)
		arg_3_0:setContentSize(arg_3_0.contentView_:getContentSize().width, arg_3_0.contentView_:getContentSize().height)
	end

	return arg_3_0.contentView_
end

function var_0_0.setParams(arg_4_0, arg_4_1)
	arg_4_0.contentView_:nodeByName("lev"):setString(arg_4_1.lev)

	if arg_4_1.conquer_lev and arg_4_1.conquer_lev > 0 then
		xyd.setConquerLev(arg_4_1.conquer_lev, arg_4_0.contentView_:nodeByName("lev"), arg_4_0.contentView_:nodeByName("level_bg"), {
			x = -2,
			y = 3
		})
	end

	arg_4_0.contentView_:nodeByName("name"):setString(arg_4_1.player_name)

	if arg_4_1.is_online ~= 0 then
		arg_4_0.contentView_:nodeByName("is_online"):setString(var_0_1:translation("FRIEND_ONLINE_TEXT"))
	else
		arg_4_0.contentView_:nodeByName("is_online"):setString(var_0_1:translation("FRIEND_OFFLINE_TEXT"))
	end

	arg_4_0.socialSystem:setOnlineState(arg_4_0.contentView_:nodeByName("is_online"), arg_4_1)

	local var_4_0 = {
		avatar_id = arg_4_1.avatar_id,
		avatar_frame_id = arg_4_1.avatar_frame_id,
		playerInfo = arg_4_1
	}

	arg_4_0.contentView_:nodeByName("avatar"):setContentSize(80, 80)
	arg_4_0.contentView_:nodeByName("avatar"):setAnchorPoint(0.5, 0.5)
	arg_4_0.contentView_:nodeByName("region"):setString("S" .. arg_4_1.region)
	xyd.setPlayerAvatar(arg_4_0.contentView_:nodeByName("avatar"), var_4_0)
	arg_4_0.contentView_:nodeByName("choose_btn"):addTouchEventListener(function(arg_5_0, arg_5_1)
		if arg_5_1 == ccui.TouchEventType.ended then
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.VALENTINE_CHOOSE_FRIEND,
				params = {
					friend_info = arg_4_1
				}
			})
			xyd.WindowManager.get():closeWindow("valentine_choose_friend")
		end
	end)
end

local var_0_4 = class("ValentineChooseFriendWindow", import("app.common.ui.BaseWindow"))
local var_0_5 = xyd.tables.twoYearsCampaign
local var_0_6 = xyd.tables.translation
local var_0_7 = 1
local var_0_8 = 2
local var_0_9 = 1117

function var_0_4.ctor(arg_6_0, arg_6_1, arg_6_2)
	var_0_4.super.ctor(arg_6_0, arg_6_1, arg_6_2)

	arg_6_0.socialSystem = xyd.ModelManager.get():loadModel(xyd.ModelType.SOCIAL_SYSTEM)
	arg_6_0.activities = xyd.ModelManager.get():loadModel(xyd.ModelType.ACTIVITIES)
end

function var_0_4.willOpen(arg_7_0, arg_7_1)
	var_0_4.super.willOpen(arg_7_0, arg_7_1)
end

function var_0_4.didOpen(arg_8_0, arg_8_1)
	var_0_4.super.didOpen(arg_8_0, arg_8_1)
	arg_8_0:addBlockLayer()
	arg_8_0:layout()
end

function var_0_4.layout(arg_9_0)
	local var_9_0 = arg_9_0.activities:getActivityInfo(var_0_9)

	arg_9_0:nodeByName("txt_label"):setString(var_0_6:translation("VALENTINE_TIPS_TXT4"))
	arg_9_0.socialSystem:loadFriends({}, function(arg_10_0, arg_10_1)
		if arg_10_0 == xyd.error.OK then
			local var_10_0 = arg_9_0.socialSystem.friendlist

			arg_9_0:initFriendList(var_10_0)
		end
	end)
end

function var_0_4.initFriendList(arg_11_0, arg_11_1)
	if not arg_11_0.listView_ then
		arg_11_0.listView_ = cc.ui.UIListView.new({
			touchOnContent = true,
			viewRect = cc.rect(0, 0, 550, 531),
			padding_ = {
				top = 0,
				bottom = 0,
				left = 0,
				right = 0
			},
			direction = cc.ui.UIScrollView.DIRECTION_VERTICAL
		}):addTo(arg_11_0:nodeByName("friend_list"))
	else
		arg_11_0.listView_:removeAllItems()
	end

	for iter_11_0, iter_11_1 in pairs(arg_11_1) do
		local var_11_0 = arg_11_0.listView_:newItem()
		local var_11_1 = var_0_0.new()

		var_11_1:setParams(iter_11_1)
		var_11_0:addContent(var_11_1)
		var_11_0:setItemSize(var_11_1:getContentSize().width, var_11_1:getContentSize().height)
		arg_11_0.listView_:addItem(var_11_0)
	end

	arg_11_0.listView_:reload()
end

function var_0_4.willClose(arg_12_0)
	return
end

return var_0_4
