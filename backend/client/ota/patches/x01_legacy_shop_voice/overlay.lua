-- x01: the shop keeper speaks with a hero voice file.
--
-- shop_config.lua carries real hero lines for the shop keeper (buzhi's voice1/3/4/5 among them) next to shop-only
-- recordings, and the shop screens reach them through ShopTable.dialogClick/dialogBuy/dialogSoldOut - outside every
-- hero window, so the hero-table redirect never saw them. Route the sound through the same map; it only rewrites a
-- path the legacy manifest carries, so shop-only lines (shamoke_shop, shop1_sound, ...) keep their stock audio.

local function gxbShopVoiceMap(path)
	local legacyVoice = xyd.gxbLegacyVoice

	if not legacyVoice or not legacyVoice.map then
		return path
	end

	return legacyVoice.map(path)
end

local gxbShopDialogClick = var_0_0.dialogClick

function var_0_0.dialogClick(gxbShopSelf, gxbShopId)
	local dialog, sound, duration = gxbShopDialogClick(gxbShopSelf, gxbShopId)

	return dialog, gxbShopVoiceMap(sound), duration
end

local gxbShopDialogBuy = var_0_0.dialogBuy

function var_0_0.dialogBuy(gxbShopSelf, gxbShopId)
	local dialog, sound, duration = gxbShopDialogBuy(gxbShopSelf, gxbShopId)

	return dialog, gxbShopVoiceMap(sound), duration
end

local gxbShopDialogSoldOut = var_0_0.dialogSoldOut

function var_0_0.dialogSoldOut(gxbShopSelf, gxbShopId)
	local dialog, sound, duration = gxbShopDialogSoldOut(gxbShopSelf, gxbShopId)

	return dialog, gxbShopVoiceMap(sound), duration
end
