local var_0_0 = class("Mailbox", import(".BaseModel"))

function var_0_0.ctor(arg_1_0, ...)
	var_0_0.super.ctor(arg_1_0, ...)

	arg_1_0.mails_ = {}
	arg_1_0.isLoaded = false
	arg_1_0.hasNew = false
end

function var_0_0.onRegister(arg_2_0)
	var_0_0.super.onRegister(arg_2_0)
	arg_2_0:registerEvent(xyd.event.LOAD_MAIL_LIST, handler(arg_2_0, arg_2_0.onMailList_))
	arg_2_0:registerEvent(xyd.event.SET_MAIL_READ, handler(arg_2_0, arg_2_0.onMailRead_))
	arg_2_0:registerEvent(xyd.event.MAIL_ONEKEY, handler(arg_2_0, arg_2_0.onekeyEvent))
end

function var_0_0.loadMailList(arg_3_0, arg_3_1, arg_3_2)
	local var_3_0 = arg_3_1 or {}

	xyd.Backend.get():request(xyd.mid.LOAD_MAIL_LIST, var_3_0, function(arg_4_0, arg_4_1)
		if arg_3_2 then
			arg_3_2(arg_4_0, arg_4_1)
		end
	end)

	arg_3_0.isLoaded = true
end

function var_0_0.onMailList_(arg_5_0, arg_5_1)
	local var_5_0 = arg_5_1.params

	if not var_5_0 or not next(var_5_0) then
		return
	end

	arg_5_0.mails_ = var_5_0.mail_list or {}
	arg_5_0.total = var_5_0.total
	arg_5_0.newMailTotal = var_5_0.new_mail_total

	arg_5_0:checkNewMail()
end

function var_0_0.checkNewMail(arg_6_0)
	for iter_6_0 = #arg_6_0.mails_, 1, -1 do
		if arg_6_0.mails_[iter_6_0].category == xyd.specialMail.onlyAndroid then
			if device.platform ~= "android" then
				table.remove(arg_6_0.mails_, iter_6_0)

				arg_6_0.total = arg_6_0.total - 1
				arg_6_0.newMailTotal = arg_6_0.newMailTotal - 1
			end
		elseif arg_6_0.mails_[iter_6_0].category == xyd.specialMail.onlyIos and device.platform ~= "ios" then
			table.remove(arg_6_0.mails_, iter_6_0)

			arg_6_0.total = arg_6_0.total - 1
			arg_6_0.newMailTotal = arg_6_0.newMailTotal - 1
		end
	end

	xyd.EventDispatcher.get():dispatchEvent({
		name = xyd.event.MAIN_SCENE_BOTTOM_NOTIFY,
		params = {
			index = 2,
			show = arg_6_0:hasNewMail()
		}
	})
end

function var_0_0.hasNewMail(arg_7_0)
	if arg_7_0.newMailTotal and arg_7_0.newMailTotal > 0 then
		return true
	end

	return false
end

function var_0_0.onMailRead_(arg_8_0, arg_8_1)
	local var_8_0 = arg_8_1.params
	local var_8_1 = arg_8_1.userdata

	if var_8_0.changed == true then
		if var_8_0.is_new == 0 then
			for iter_8_0, iter_8_1 in pairs(arg_8_0.mails_) do
				if iter_8_1.id == var_8_1.id and iter_8_1.is_region == var_8_1.is_region then
					iter_8_1.is_new = 0

					if arg_8_0.newMailTotal then
						arg_8_0:decrNewMail()
					end

					break
				end
			end
		end

		if var_8_0.is_shown == 0 then
			for iter_8_2, iter_8_3 in pairs(arg_8_0.mails_) do
				if iter_8_3.id == var_8_1.id and iter_8_3.is_region == var_8_1.is_region then
					table.remove(arg_8_0.mails_, iter_8_2)

					arg_8_0.total = arg_8_0.total - 1

					break
				end
			end
		end

		if #arg_8_0.mails_ ~= arg_8_0.total and #arg_8_0.mails_ <= 5 then
			arg_8_0:loadMailList({
				load_num = #arg_8_0.mails_ + xyd.MailPerLoadNum
			}, function(arg_9_0)
				if arg_9_0 == xyd.error.OK then
					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.UPDATE_MAIL_LIST
					})
					xyd.EventDispatcher.get():dispatchEvent({
						name = xyd.event.MAIN_SCENE_BOTTOM_NOTIFY,
						params = {
							index = 2,
							show = arg_8_0:hasNewMail()
						}
					})
				end
			end)
		else
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.UPDATE_MAIL_LIST
			})
			xyd.EventDispatcher.get():dispatchEvent({
				name = xyd.event.MAIN_SCENE_BOTTOM_NOTIFY,
				params = {
					index = 2,
					show = arg_8_0:hasNewMail()
				}
			})
		end
	end

	local var_8_2 = var_8_0.rewards

	if var_8_2 and next(var_8_2) then
		local var_8_3 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER)

		for iter_8_4, iter_8_5 in pairs(var_8_2) do
			local var_8_4 = tonumber(iter_8_5.item) or 0

			if var_8_4 > 0 then
				var_8_3:getBackpack():addItemsByID(tonumber(var_8_4), tonumber(iter_8_5.num), true)
			end
		end
	end
end

function var_0_0.onekey(arg_10_0, arg_10_1, arg_10_2)
	local var_10_0 = arg_10_1 or {}

	xyd.Backend.get():request(xyd.mid.MAIL_ONEKEY, var_10_0, function(arg_11_0, arg_11_1)
		if arg_10_2 then
			arg_10_2(arg_11_0, arg_11_1)
		end
	end)

	arg_10_0.isLoaded = true
end

function var_0_0.onekeyEvent(arg_12_0, arg_12_1)
	local var_12_0 = arg_12_1.params

	if not var_12_0 then
		return
	end

	local var_12_1 = xyd.ModelManager.get():loadModel(xyd.ModelType.SELF_PLAYER):getBackpack()

	for iter_12_0, iter_12_1 in ipairs(var_12_0.awards) do
		if iter_12_1.table_id ~= -1 then
			var_12_1:addItemsByID(tonumber(iter_12_1.table_id), tonumber(iter_12_1.item_num), true)
		end
	end

	arg_12_0.mails_ = var_12_0.mail_list.mail_list or {}
	arg_12_0.total = var_12_0.mail_list.total
	arg_12_0.newMailTotal = var_12_0.mail_list.new_mail_total

	arg_12_0:checkNewMail()
end

function var_0_0.getMails(arg_13_0)
	return arg_13_0.mails_
end

function var_0_0.readMail(arg_14_0, arg_14_1, arg_14_2)
	local var_14_0 = {
		id = arg_14_1.id,
		is_region = arg_14_1.is_region
	}

	xyd.Backend.get():request(xyd.mid.SET_MAIL_READ, var_14_0, function(arg_15_0, arg_15_1)
		if arg_15_0 == xyd.error.OK and arg_14_2 then
			arg_14_2(arg_15_0)
		end
	end, var_14_0, false, false)
end

function var_0_0.getMailsNum(arg_16_0)
	return #arg_16_0.mails_
end

function var_0_0.getTotal(arg_17_0)
	return arg_17_0.total
end

function var_0_0.decrNewMail(arg_18_0)
	arg_18_0.newMailTotal = arg_18_0.newMailTotal - 1
end

function var_0_0.incrNewMail(arg_19_0)
	arg_19_0.newMailTotal = arg_19_0.newMailTotal + 1
end

return var_0_0
