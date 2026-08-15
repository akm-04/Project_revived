local var_0_0 = class("MailItem", function()
	return cc.Node:create()
end)
local var_0_1 = 604800

function var_0_0.ctor(arg_2_0)
	arg_2_0:contentView()

	arg_2_0.container = arg_2_0:contentView():nodeByName("container")
end

function var_0_0.setParams(arg_3_0, arg_3_1)
	arg_3_0.params = arg_3_1
	arg_3_0.mail = arg_3_1.mail
	arg_3_0.callback = arg_3_1.callback

	if arg_3_0.mail.attach and next(arg_3_0.mail.attach) then
		for iter_3_0, iter_3_1 in pairs(arg_3_0.mail.attach) do
			local var_3_0 = tonumber(iter_3_1.item) or 0

			if var_3_0 > 0 then
				arg_3_0.item = var_3_0

				break
			end
		end
	end

	arg_3_0:layout()
end

function var_0_0.layout(arg_4_0)
	arg_4_0:setItemView()
	arg_4_0:registerTouchEvent()
end

function var_0_0.getTableID(arg_5_0)
	return arg_5_0.tableID
end

function var_0_0.setItemView(arg_6_0)
	arg_6_0:contentView():nodeByName("title"):setString(arg_6_0.mail.title)
	arg_6_0:contentView():nodeByName("sender"):setString(arg_6_0.mail.from)
	arg_6_0:contentView():nodeByName("date"):setString(os.date("%Y-%m-%d", arg_6_0.mail.created_time))

	local var_6_0 = arg_6_0:contentView():nodeByName("icon")

	if arg_6_0.mail.is_eb and tonumber(arg_6_0.mail.is_eb) == 1 then
		local var_6_1

		if arg_6_0.mail.is_new and arg_6_0.mail.is_new > 0 then
			var_6_1 = xyd.AssetLoader.get():loadSprite("windows/mailbox/mail_special_icon2.png")
		else
			var_6_1 = xyd.AssetLoader.get():loadSprite("windows/mailbox/mail_special_icon1.png")
		end

		xyd.displaySpriteOnContainer(var_6_1, var_6_0, false)
	elseif arg_6_0.item then
		xyd.setItemBorder(var_6_0, arg_6_0.item)
	elseif arg_6_0.icon then
		local var_6_2 = xyd.AssetLoader.get():loadSprite(arg_6_0.icon)

		xyd.displaySpriteOnContainer(var_6_2, var_6_0, true)
	elseif arg_6_0.mail.is_new and arg_6_0.mail.is_new > 0 then
		local var_6_3 = xyd.AssetLoader.get():loadSprite("windows/mailbox/mail_icon2.png")

		xyd.displaySpriteOnContainer(var_6_3, var_6_0, false)
	else
		local var_6_4 = xyd.AssetLoader.get():loadSprite("windows/mailbox/mail_icon1.png")

		xyd.displaySpriteOnContainer(var_6_4, var_6_0, false)
	end

	if arg_6_0.mail.expired_time and arg_6_0.mail.expired_time > 0 then
		local var_6_5 = xyd.ServerTime.get():getServerTime()
		local var_6_6 = arg_6_0.mail.expired_time - var_6_5

		if var_6_6 > 0 then
			local var_6_7 = math.floor(var_6_6 / 86400) + 1
			local var_6_8

			if var_6_7 > 1 then
				var_6_8 = cc.c4b(180, 117, 74, 255)
			elseif var_6_7 == 1 then
				var_6_8 = cc.c4b(255, 0, 0, 255)
			else
				arg_6_0:contentView():nodeByName("text_count"):setVisible(false)

				return
			end

			arg_6_0:contentView():nodeByName("text_count"):setColor(var_6_8)

			local var_6_9 = string.format(xyd.tables.translation:translation("MAIL_LEFT_DAYS"), xyd.secondsToString1(var_6_6, 1))

			arg_6_0:contentView():nodeByName("text_count"):setString(var_6_9)
		else
			arg_6_0:contentView():nodeByName("text_count"):setVisible(false)
		end
	elseif arg_6_0.mail.created_time and arg_6_0.mail.created_time > 0 then
		local var_6_10 = xyd.ServerTime.get():getServerTime() - arg_6_0.mail.created_time

		if var_6_10 > 0 then
			local var_6_11 = math.floor((var_0_1 - var_6_10) / 86400) + 1
			local var_6_12

			if var_6_11 > 1 then
				var_6_12 = cc.c4b(180, 117, 74, 255)
			elseif var_6_11 == 1 then
				var_6_12 = cc.c4b(255, 0, 0, 255)
			else
				arg_6_0:contentView():nodeByName("text_count"):setVisible(false)

				return
			end

			arg_6_0:contentView():nodeByName("text_count"):setColor(var_6_12)

			local var_6_13 = string.format(xyd.tables.translation:translation("MAIL_LEFT_DAYS"), xyd.secondsToString1(var_0_1 - var_6_10, 1))

			arg_6_0:contentView():nodeByName("text_count"):setString(var_6_13)
		else
			arg_6_0:contentView():nodeByName("text_count"):setVisible(false)
		end
	else
		arg_6_0:contentView():nodeByName("text_count"):setVisible(false)
	end
end

local function var_0_2(arg_7_0, arg_7_1, arg_7_2)
	if arg_7_0.callback then
		arg_7_0.callback(arg_7_2)
	end
end

function var_0_0.registerTouchEvent(arg_8_0)
	arg_8_0:contentView():setTouchEnabled(true)
	arg_8_0:contentView():setTouchSwallowEnabled(false)

	local var_8_0 = arg_8_0.container
	local var_8_1 = arg_8_0.params

	arg_8_0:contentView():addNodeEventListener(cc.NODE_TOUCH_EVENT, function(arg_9_0)
		if arg_9_0.name == "began" then
			arg_8_0.prevX_ = arg_9_0.x
			arg_8_0.prevY_ = arg_9_0.y
			arg_8_0.startClick_ = true
		elseif arg_9_0.name == "moved" then
			if math.abs(arg_9_0.y - arg_8_0.prevY_) > 5 or math.abs(arg_9_0.x - arg_8_0.prevX_) > 5 then
				arg_8_0.startClick_ = false
			end
		elseif arg_9_0.name == "ended" and arg_8_0.startClick_ then
			var_0_2(arg_8_0, arg_9_0, var_8_1)
		elseif arg_9_0.name == "canceled" then
			-- block empty
		end

		return true
	end)
end

function var_0_0.contentView(arg_10_0)
	if arg_10_0.contentView_ == nil then
		arg_10_0.contentView_ = import("app.common.ui.BaseWindow"):new()

		arg_10_0.contentView_:setupContentView_(xyd.AssetLoader.get():loadNodeFromJson("windows/mailbox/mail_item.csb"))
		arg_10_0.contentView_:nodeByName("lbl_sener"):setString(xyd.tables.translation:translation("SENDER"))
		arg_10_0.contentView_:addTo(arg_10_0):setAnchorPoint(0.5, 0.5)
		arg_10_0.contentView_:setTouchSwallowEnabled(false)

		local var_10_0 = arg_10_0.contentView_:nodeByName("container")

		arg_10_0.contentView_:setContentSize(var_10_0:getContentSize())
	end

	return arg_10_0.contentView_
end

return var_0_0
