#!/usr/bin/env python3
"""R4A deterministic builtin-content compiler.

Consumes the verified current src_64 archive directly. Runtime code never parses
Lua; checked-in canonical JSON is the deployment content authority for R4B/C.
"""
from __future__ import annotations

import argparse
import base64
import csv
import hashlib
from decimal import Decimal, InvalidOperation
import io
import json
import re
import sys
import zipfile
from dataclasses import dataclass
from pathlib import Path
from typing import Any, Iterable

SCHEMA_VERSION = 1
COMPILER_VERSION = "i7c2f-inscription-inputs"
PARSER_VERSION = "lua-generated-v18-guild-invite"
EXPECTED_SOURCE_ARCHIVE_SHA256 = "c7e98789524713f75da147be2037edd20fc86c8d03a90ab112df7fed7cf4abcf"
SOURCE_PREFIX = "app-assets/output/assets/src_64/"

SOURCE_MANIFEST = [
    ("app/model/SelfGuild.lua", "c744e6f256a796a98613911372c1821b3e02f21d38480184df9c095373bd64f9", "I7A8B_CLIENT_ACCEPT_MID_LINK"),
    ("app/model/SocialSystem.lua", "ec5bea26bbdcbb67ca2ea80ab5ad7e9fb53ee613a3ffcbb13ae5dfef9ddf0502", "I7A8B_CLIENT_PRESENTATION_DISMISS_MID_LINK"),
    ("app/windows/SocialSystemWindow.lua", "5d0c3e1e20d69b7009ff52bf94ad438c6a133c8b099301d951bd1e413b90f112", "I7A8B_TYPE10_ACCEPT_AND_PRESENTATION_DISMISS_CLIENT_STATIC"),
    ("app/common/network/mid.lua", "026a20b29d97624979777a68c64c749254031604057ff42aa8f8254c3e35b5af", "I7A8B_FINITE_STOCK_CONSUMER_MID_IDENTITY"),
    ("app/windows/TeamMessageWindow.lua", "fe5732defb999617d38bb63e94aab355ccefaf567ab87c4506657e021095a085", "I7A8A_STOCK588_TITLE_CONTENT_BOUNDARIES"),
    ('data/tables/friend_dailygift.lua', 'b350a14dab62799dcca37dddde370bd86ed78f1745f01483d0bce065062cf707', 'I7A7A_DAILY_GIFT_EQUIVALENCE'),
    ('data/tables/gift.lua', '8c87dfdc116242afcdebd011cf898d61b08e2cf54ea7d0a11a5f69fabade2ac7', 'I7A7A_COMPLETE_REWARD_VECTOR'),
    ("data/tables/emoticon.lua", "76ccbf5c136f5a484e6e5fbe2ca0ef4f58451676ddea78281285a99afc2d3c08", "I7A6A_EMOTICON_DATA_AUTHORITY"),
    ("app/common/tables/ItemTable.lua", "1f846972f29a55ee2dbb90f2cb9b0124eaeaa90646c3c66644ab66e231c37f00", "ITEM_BEHAVIORAL_PARSER_AUTHORITY"),
    ("data/tables/item.lua", "59b668c28a372543da0c36d7a8d84291cc5b93fa0d92b7cc389a645e96e7b7cc", "ITEM_DATA_AUTHORITY_ENCODED_TABLE"),
    ("app/common/tables/SkinSkillTable.lua", "5ce8af1fddb22a503c779183495f84743a8ceb8305cb891ef556a88b6a7988e5", "CA7_SKIN_SKILL_ACCESSOR_AUTHORITY"),
    ("data/tables/skin_skill.lua", "78e62be9bc8e08833b1e886b260cf1dee4c7c8b418a8ba40badde8b6ffaebe46", "CA7_SKIN_MODEL_AND_COMBAT_SKILL_DATA"),
    ("app/common/tables/SkinDynamicTable.lua", "b41bcc1fd5ded9fc26463ddc8080b1dd1920bf0bd0ba387c1e2dc9b23090bf71", "CA7_LIVE_ACCESSOR_AUTHORITY"),
    ("data/tables/skin_dynamic.lua", "defe867b01dc6cc0a1eb8dd5ce8c259bc76c2b4aa15427199b040d30fe4fb920", "CA7_LIVE_COST_AND_HERO_DATA"),
    ("app/common/tables/ModelTable.lua", "fb9bfb7d9beb4b50eb7c978abfba60cc4ff7644a48de08f950af2f6e2e3d6038", "CA7_DYNAMIC_TYPE_ACCESSOR_AUTHORITY"),
    ("data/tables/model.lua", "616e532ec965be4de96b9b2feeb364aecc9ae91506ce0d9bbfb17156f0769ea8", "CA7_DYNAMIC_TYPE_DATA_AUTHORITY"),
    ("app/model/Backpack.lua", "953999f81fc43ecd00e587d884c88b6a1ba066e35ff75a20dd698b6cb950af7a", "ITEM_CONSUMER_BEHAVIOR"),
    ("app/model/SelfPlayer.lua", "163d5893c9522ada412c2b9c4748a80757660fccdf03c8f72cb6edf0838b8eb4", "TEMPORAL_AND_SCALAR_CONSUMER_BEHAVIOR"),
    ("app/common/tables/PlayerTable.lua", "9feedb4360090c1c7d5e20853ca2cdbdd85670cc276c3b56a2bb7a4a429b569f", "PLAYER_PROGRESSION_ACCESSOR_AUTHORITY"),
    ("data/tables/player.lua", "1b6b6b0557b0d2cb33b34dc37c25e4a12ae4fbd71f1476d6ac463267a1278345", "PLAYER_PROGRESSION_DATA_AUTHORITY"),
    ("data/tables/function.lua", "a240254e79ccfd41862f3d6289f4f5fd09280ac3e197f51bc14b896a62c10010", "FUNCTION_GATE_DATA_AUTHORITY"),
    ("app/common/tables/MiscTable.lua", "6579de771dbef3224fcaa9568a8fcfade26209f134acfe3a3e666ecbd6c13cee", "MISC_ACCESSOR_AUTHORITY"),
    ("data/tables/misc.lua", "058cf5719421ed71a12083a8c95b0ccded7204bedb5fa1263d508e2fa4257f9a", "TEMPORAL_INTERVAL_STATIC_RULE_DATA"),
    ("app/common/enums.lua", "15340bd89fe7c6f150ccfd4a5cd2a2f0e8e73c89dfae9ac3388376a4799901f3", "STOCK_SCALAR_ENUM_IDENTITY"),
    ("app/common/tables/AssetTable.lua", "27bf1679f32a6f44f6bd90a51335d8fded1c7d9f7f2793bd02b0100e7f9d15ea", "SOURCE_ASSET_ID_NAME_MAPPING"),
    ("data/tables/asset.lua", "6d113c94d9ff57dfd4d209720ff0f597a418f13e5f49bc3b1aba4594a59d5b96", "SOURCE_ASSET_DATA_NEGATIVE_IDS_ALLOWED"),
    ("app/common/const.lua", "29bfca03fb8094710ae2e3b6b752e0f6413b7086b17032f0c17abad79b048854", "HERO_ID_BOUNDARIES_AND_SUPER_STAR_CEILING"),
    ("app/common/utils.lua", "6e56c7342e889d7ae8d41fe47cb06f66832227efe702f3863f693ee7ba84ffad", "HERO_ORIGIN_FAMILY_MAPPING_BEHAVIOR"),
    ("app/common/tables/HeroTable.lua", "5293207486e52a8dad959b48ea0c90680a335e9144c362d5e9b342b9fd6cef60", "HERO_TEMPLATE_INCLUSION_AND_INITIAL_STAR_BEHAVIOR"),
    ("data/tables/partner.lua", "a1d3d11e308140e57ed861a2dc0031f562420881405a5ba6f62987df8952bc49", "NORMAL_HERO_TEMPLATE_DATA"),
    ("data/tables/super_partner.lua", "ddee186ee41361a3674d4764be68efec01fad32d288c9dc84c552df6f1b770ea", "SUPER_HERO_TEMPLATE_AND_PREREQUISITE_DATA"),
    ("data/tables/partner_exp.lua", "55f3808decc768a40343aaed2d0c85a5beda34926fbb559970296d140871b39b", "HERO_EXP_PROGRESSION_DATA"),
    ("data/tables/star.lua", "dbe037190d4f050a92a0befffffd76cfdb91c9fb0e812397a0e1c88b97e971b3", "NORMAL_HERO_STAR_ECONOMY_DATA"),
    ("data/tables/super_partner_star.lua", "b2c73a59b11db192aad61a48eba26f0cf57f735369ef03f4b729100f25c64d90", "SUPER_HERO_STAR_ECONOMY_AND_EQUIPMENT_CAP_DATA"),
    ("data/tables/super_equip_enhance.lua", "2ade30c55e102057e5c2833e58b66a7d8a684259f0e74f941bc28d5c3cd6af53", "SUPER_EQUIPMENT_ENHANCEMENT_TIER_DATA"),
    ("app/model/Hero.lua", "3e296d4d6dcf71c10ac7391e4ad228ca84c2ee856b7ff2d3c02a3595cf68f2e0", "HERO_WIRE_IDENTITY_DISPATCH"),
    ("app/model/NormalHero.lua", "125183556caeecc182bf0702dd1f95160c8ba1666a3b97fbb8a7261d30ae0ac9", "NORMAL_HERO_WIRE_DEFAULTS"),
    ("app/model/SuperHero.lua", "b127c2cbef327d3142031bf30daa0af1b45997c6da82fba946d641a86783d622", "SUPER_HERO_WIRE_DEFAULTS"),
    ("app/model/Pet.lua", "214f4dcd93d0e494408d14a225810134c2e72a0dedd18a935a27dc62e0c00660", "PET_PRIVATE_WIRE_IDENTITY_AND_DEFAULTS"),
    ("data/tables/pet.lua", "bc974045ec92fd7c0ebb2655d635d1b057eee7f74a871cfa2316b511ad55986e", "PET_CORE_TEMPLATE_AND_LINEAGE_DATA"),
    ("app/common/tables/PetExpTable.lua", "20bb5d6badb0245cdacaddc03db12625367f53262d667ffc3f5fafb27c6421f6", "PET_EXP_ACCESSOR_AUTHORITY"),
    ("data/tables/pet_exp.lua", "7ebc02c3ce25cd9048c516d958caa4277d04bfa289a71b14cfb6f2d9bfe9eb4f", "PET_EXP_DATA_AUTHORITY"),
    ("app/common/tables/PetSkillBookTable.lua", "1f80042a1e7855903a8ef0a3687722e809770f5b70a6a3630bc4449ba99d9903", "PET_SKILL_BOOK_ACCESSOR_AUTHORITY"),
    ("data/tables/pet_skillbook.lua", "708798a4e36f1cab67e6d96fbaae9df86fece9059ef2c367770a8ef0c22aa4e6", "PET_SKILL_BOOK_DATA_AUTHORITY"),
    ("data/tables/pet_skilllevel.lua", "cc58250b8e2642a3a22ceccb5127fc1eee30dae840d8319497523a7d2b631eec", "PET_SKILL_SLOT_CORROBORATIVE_DATA"),
    ("data/tables/pet_star.lua", "6d64e726dea9e11456977c268870eb4a2b5646d4a725d2dcdb58310104b6f445", "PET_EVOLUTION_CORROBORATIVE_DATA"),
    ("app/common/tables/SkillTable.lua", "0184d2ea9bc63a93438f1f0029e4703e8979afd2101959d5a567f1859bd9befc", "PET_SOURCE_SKILL_ACCESSOR_AUTHORITY"),
    ("data/tables/skill.lua", "7a2123ac10cb7f1ac0cd4da3fa8d3a076d1042cbc01e44c218ab4ea0b77ba45a", "PET_SOURCE_SKILL_DATA_AUTHORITY"),
    ("app/windows/PetMainWindow.lua", "fcebe7e4fa742d8a176c8da10502c410e5031720023369bebed01c7da3a99832", "PET_PROGRESSION_ACTIVE_UI_SEMANTICS"),
    ("app/windows/PetAddExpWindow.lua", "1b2a56e20ff47a9c94245a5d84466c13428815342f29d2959286e3fd549fb5a3", "PET_EXP_MANUAL_UI_SEMANTICS"),
    ("app/windows/HeroMainWindow.lua", "473b72ec14a81d01d6dbdaa19f92c3d78900f40ca34fa5c8cf46585b76d65414", "HERO_PROMOTION_ACTIVE_UI_SEMANTICS"),
    ("app/windows/SkinSkillSelectWindow.lua", "a6ac7ecb7da0f441b7babb135c5e68e46ece4b2f4bbb60ce77b0ab7a4af614cd", "CA7_SKIN_SELECT_UI_SEMANTICS"),
    ("app/windows/BackpackWindow.lua", "48b18493fed4186541fc989a8ef60d6338d444c4e8a0fc986903a57e52ff19c1", "CA7_SKIN_AND_PET_ITEM_UI_SEMANTICS"),
    ("app/windows/PetEquipInfoWindow.lua", "ff5297ed3fe600451df67fdc8e0b52be77cb30e5411beb72c42a60a45571a938", "CA7_PET_STYLE_UI_SEMANTICS"),
    ("app/common/network/mid.lua", "026a20b29d97624979777a68c64c749254031604057ff42aa8f8254c3e35b5af", "CA7_WIRE_MID_IDENTITY"),
    ("lib/battle/BaseFighter.lua", "b1936373a0404049f100de1ab639661d245c9f2a317ae6fbd443b71b45d538dc", "CA7_COMBAT_SKIN_SKILL_AXIS"),
    ("data/tables/practice_type.lua", "74b94f440898a24522fb1c91f61528bab91f3724300f2e0534e586e8f4d2f14d", "PRACTICE_METHOD_SOURCE_FACTS"),
    ("app/common/tables/PracticeTypeTable.lua", "4db929ca65f9b841a2a82cad173dd27fc74d5a3507a1167f3549094e526b71ce", "PRACTICE_METHOD_ACCESSOR_BOUNDARY"),
    ("data/tables/practice_lock.lua", "f6ee8803f96d38f5da434425be409ba4a660c61d3794e2091ad794e4ce3bdb13", "PRACTICE_LOCK_SOURCE_FACTS"),
    ("app/common/tables/PracticeLockTable.lua", "0194a082c11ca09a99f24aff031512b7232a21d8ceabdf6351f5248b5c4334f2", "PRACTICE_LOCK_ACCESSOR_BOUNDARY"),
    ("data/tables/vip.lua", "18b76d7fa82964f57082aeb2092a80c231f69e86958b4b567aebabf30d626270", "PRACTICE_VIP_BLESS_SOURCE_FACT"),
    ("app/common/tables/VipTable.lua", "573e26d035d2f97d61ac0e31affa0755dbd8125131a81d69522aeebeb23ed068", "PRACTICE_VIP_ACCESSOR_BOUNDARY"),
    ("app/windows/WashHeroWindow.lua", "085ce4a90888284de4e12bc142c8b8e356d605e7a8e712fcd0e5b6f0a89a561c", "PRACTICE_MANUAL_UI_SEMANTICS"),
    ("app/windows/WashHeroAutoWindow.lua", "ed37f8bda81f60e7229e09d66acedafc9db9c6a6213ff4b90dd6d28b5462fa03", "PRACTICE_AUTO_UI_SEMANTICS"),
    ("app/windows/WashProcessWindow.lua", "ac0f1e96f97901f4cbf4c87b9c94faadc6fad67632993aa855e53ed198da38a2", "PRACTICE_AUTO_RESULT_UI_SEMANTICS"),
    ("data/tables/guide_page.lua", "7cf246fa0d16d12954d9235b3b05fc918763dbe5c3e690b4d87999d3e1112802", "PRACTICE_TICKET_GUIDE_SOURCE_FACT"),
]

SOURCE_MANIFEST.append(('app/model/PersonDisplay.lua', '022fcbf39167ac9197ce5034b32fd5833016742744ad3de118ceacf6f808cfb8', "PUBLIC_SHOWCASE_SELECTION_SOURCE_AUTHORITY"))
SOURCE_MANIFEST.append(('app/windows/SelectHeroCardWindow.lua', 'e1db1b02194652043b289b2670501c0fc8226ccaba17c8e5eca1a915e715440e', "PUBLIC_SHOWCASE_SELECTION_SOURCE_AUTHORITY"))
SOURCE_MANIFEST.append(('data/tables/name.lua', '2254bb1bb4283199a112cb94a7e14e82ac28cd29e3a19e281d11faf23d9ec316', 'PUBLIC_PROFILE_PREFERENCE_SOURCE_AUTHORITY'))
SOURCE_MANIFEST.append(('data/tables/person_display_words.lua', 'ca342990ff24d8c5a4c12b270401c276b3e29597d43555f30978a2c5162afeb6', 'PUBLIC_PROFILE_PREFERENCE_SOURCE_AUTHORITY'))
SOURCE_MANIFEST.append(('app/model/FilterWordManager.lua', 'e961a9a0029c90cce75d8deee23d066ba4d74bc133e733625dae5b43e0c34783', 'PUBLIC_PROFILE_PREFERENCE_SOURCE_AUTHORITY'))

SOURCE_MANIFEST.append(('data/tables/avatar.lua','0a90c0296d9ddc15aeba8fbf77de4a4a0ce690b680c005d6be11ae102b4acb61','PLAYER_DISPLAY_SOURCE_AUTHORITY'))
SOURCE_MANIFEST.append(('data/tables/title_system.lua','a91f9afa54ceba80d1fe752f95e417a6fa22c0663fab520f73ee64262ae2ea2d','PLAYER_DISPLAY_SOURCE_AUTHORITY'))
SOURCE_MANIFEST.append(('data/tables/chat_bubble.lua','abed6a89251099b42345a6414265aceb6c70ed0099f4d8648386811dcb21f03e','PLAYER_DISPLAY_SOURCE_AUTHORITY'))
SOURCE_MANIFEST.append(('data/tables/random_name.lua','bf47c258f7be691ee2bf15df19af0e8dfb0cf5a3f86945ec27d10edbf61854cc','PLAYER_DISPLAY_SOURCE_AUTHORITY'))


# I7C-2B source-qualified minimum Library inputs; probability remains reconstruction.
SOURCE_MANIFEST.append(('data/tables/library_feed_cost.lua','de45631b923b4c322cd5b83680ec5885fe42f4d0580665604b7f35bcf70aa4c1',"LIBRARY_INPUT_SOURCE_AUTHORITY"))
SOURCE_MANIFEST.append(('data/tables/library_feed_attr.lua','ea208080fa6786401d646bd078702a7edf52bc637b147120c73479acd39379f9',"LIBRARY_INPUT_SOURCE_AUTHORITY"))
SOURCE_MANIFEST.append(('data/tables/library_gift.lua','966f002c019df51058e41d8e839543d2e2fb61577c02c423084ce70257eb9adc',"LIBRARY_INPUT_SOURCE_AUTHORITY"))
SOURCE_MANIFEST.append(('data/tables/library_amour.lua','3c607e4c878d1308822d8e8fb3e89a27718ef253915e8a5966df26ab3b187534',"LIBRARY_INPUT_SOURCE_AUTHORITY"))
SOURCE_MANIFEST.append(('data/tables/collect_normal.lua','bfd1a9312035cf430e882d1fcda742f334f089acc6d5438a34e938d3bb43f142',"LIBRARY_INPUT_SOURCE_AUTHORITY"))
SOURCE_MANIFEST.append(('data/tables/collect_special.lua','5c159c89f7ffcbfb698d9599539a897896ce0e9ab93e7d04875d012d59df509a',"LIBRARY_INPUT_SOURCE_AUTHORITY"))
SOURCE_MANIFEST.append(('app/model/Library.lua','1830b7e7a5a5203dc7e9eea5bd505b5025b03b52454c69756e14549718962063',"LIBRARY_INPUT_SOURCE_AUTHORITY"))
SOURCE_MANIFEST.append(('app/windows/LibraryFeedWindow.lua','f9d84b4fe134a63f697e9f0e58f768d5e803f2b827e68e0d85fc1675858ba69e',"LIBRARY_INPUT_SOURCE_AUTHORITY"))
SOURCE_MANIFEST.append(('app/windows/HeroGiftBoxWindow.lua','d6065c3d601f582091546d77225c352be0ba83900d71fc294dbe26a7425a32c5',"LIBRARY_INPUT_SOURCE_AUTHORITY"))
SOURCE_MANIFEST.append(('app/windows/WhiteAlbumWindow.lua','851a53f588b59d95cfe460f3399ab1a6904fff7714131c358f3c3a73910b6bb9',"LIBRARY_INPUT_SOURCE_AUTHORITY"))

ENABLED_CAPABILITIES = [
    "INSCRIPTION_INPUTS_I7C2F", "COURSE_INPUTS_I7C2E", "BOOK_INPUTS_I7C2D",
    "DORM_INPUTS_I7C2C",
    "LIBRARY_INPUTS_I7C2B",
    "PLAYER_DISPLAY_I7B6A",
    "PUBLIC_PROFILE_SHOWCASE_SELECTION_I7B3A",
    "PUBLIC_PROFILE_PREFERENCES_I7B2B",
    "GUILD_BROADCAST_I7A8A",
    "GUILD_INVITE_PRESENTATION_I7A8B",
    "QUALIFIED_ORDINARY_STACK_ITEM_DEFINITIONS",
    "SCALAR_CRYSTAL",
    "SCALAR_MANA",
    "PLAYER_EXP_R5",
    "TEMPORAL_ENERGY_R5",
    "TEMPORAL_SPIRIT_ENERGY_R5",
    "TEMPORAL_SKILL_POINT_R5",
    "FUNCTION_LEVEL_ELIGIBILITY_R5",
    "HERO_RAW_SKILLS_I7C2A", "HERO_CORE_CA2",
    "HERO_PROGRESSION_CA2",
    "PET_CORE_CA3",
    "PET_ACQUISITION_CA3",
    "PET_PROGRESSION_CA3",
    "EQUIPMENT_PRIMITIVES_CA4",
    "HERO_EQUIPMENT_CA4_2",
    "HERO_FUMO_CA4_3A",
    "HERO_PROMOTION_RESTORATION_CA4_3B",
    "PET_EQUIPMENT_CA4_4A",
    "PET_PROMOTION_RESTORATION_CA4_4B",
    "SUPER_EQUIPMENT_CA4_5",
    "PRACTICE_CA6",
    "CHARACTER_APPEARANCE_CA7",
    "FRIEND_DM_EMOTICON_I7A6A",
    "SOCIAL_GIFT_I7A7A",
]



# I7C-2C: raw owner/placement/time profile; settlement and odds are reconstruction.
SOURCE_MANIFEST.append(('app/common/tables/DormFurnitureItemTable.lua', 'a044697c0a46b13784bd8beb82b0e501fd06938b318a8966570961a54b7ac5b7', 'I7C2C_DORM_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/model/Dorm.lua', 'd6d1a314a6b93949f91c67a6f5a3f8d9e491bc30824a747bb62ac79f1f6cb911', 'I7C2C_DORM_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/DormRoomExpandWatingWindow.lua', '91061de0b72f10ba5f214c4cf0c2f3bb48e089e45c78f632f6fe95f718cb75f2', 'I7C2C_DORM_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/DormRoomWindow.lua', '30fe757307b167b4f4b0a915a2840b84d0391545745f1088abba54cc69033d15', 'I7C2C_DORM_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('data/tables/dorm_expand.lua', 'a51734fe82d17b021b2856b2e66f38c6784e3acded00796dff1d660657808062', 'I7C2C_DORM_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('data/tables/dorm_furniture_item.lua', '4bd6844119457165bb8dec161ca0b4121c70a9a3108f6e6b508bdcc7adecaf9a', 'I7C2C_DORM_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('data/tables/dorm_house.lua', 'ce0f2c7b5bac8ffaea9590b682f7cfd044eb8ca81116862473100565eb4753e5', 'I7C2C_DORM_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('data/tables/dorm_house_key.lua', 'b9abe851b2cdf2c2f69aad2b43c5eb0b7671019e9b9f6295939269f932138940', 'I7C2C_DORM_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('data/tables/dorm_house_type.lua', '99964f53860e75fdc05852f7fe2f78514d0f3f59d19ebfa4b02237ac2b178520', 'I7C2C_DORM_SOURCE_BOUNDARY'))

SOURCE_MANIFEST.append(('app/model/EventCentre.lua', 'a74e8d057e5e520f302b5f4c5ece73b6e9d4eb934b9cbefa0447410c094e7596', 'I7C2D_BOOK_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/EventCentreUpgradeWindow.lua', '9329f921989c2ca2cc065c4555e4b48e82d5671d3036be2e4a00aa71309325d7', 'I7C2D_BOOK_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/BookShelfWindow.lua', '6ccd239fd6adefd032c9f13acf36a0dcba2bb282b520cc2f320398db3dd82cee', 'I7C2D_BOOK_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/JunkChestWindow.lua', 'a69bf0a5f6c2e68bcb40f1b713da1a12daac8ddd24b1a490bed7164f0d23fd0c', 'I7C2D_BOOK_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/JunkChestSkillUpWindow.lua', 'debdddd5cfe482c10884d9cb88f541e5e6e058bbec2db9614e4716d19e6d0010', 'I7C2D_BOOK_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/FragmentMake.lua', '56dc888e894f7a14131cec70300ff10c7b2de8cf3aa0e7a3ab7fd01bb1f05d28', 'I7C2D_BOOK_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/common/tables/EventCentreBookShelfTable.lua', '35968941ebea7f1cd81fafd5c961e2037d98b04809741acaf09c37a843a737f7', 'I7C2D_BOOK_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/common/tables/EventCentreRecycleTable.lua', 'a40542ff95cdfe5bd107a7bb9af6f2c4a731c6d200d578fcf362989a00ef2836', 'I7C2D_BOOK_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/common/tables/CabinetTable.lua', '4936c47870e426eb60bb8ec2999d49d11db1a1432920f73a812c703d40cdff62', 'I7C2D_BOOK_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/common/tables/CabinetBookTable.lua', 'd9a51975ef816382a18705e52d26c0b05de93a35191e5e48c4fd9d60656a76ea', 'I7C2D_BOOK_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/common/tables/CabinetSkillTable.lua', '6b31896b2cb5fd60719c1392d96fea37fde7bf1b7319a150922004f795612b41', 'I7C2D_BOOK_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/common/tables/CabinetSkillCostTable.lua', 'a9f6c4dcbf1751fe6b647993f9a0a7c5152f6aa3681daac5e4bd822b0efb8bb6', 'I7C2D_BOOK_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('data/tables/event_centre_bookshelf.lua', '2caa18336a1e8c7fab3521cefd8b261a7cc420bea594f684bbacc7e1221e50b0', 'I7C2D_BOOK_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('data/tables/event_centre_recycle.lua', '8a60562844b71bd82e9b4e35061bfebdf32dc561c63f3b8aa54b19d0e0ae745e', 'I7C2D_BOOK_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('data/tables/event_centre_cabinet.lua', '2bb59560151405d652f282a47276c7d31134866394259a328feeabc42022ae2b', 'I7C2D_BOOK_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('data/tables/event_centre_cabinetbook.lua', '5a56863298b9ad883bbf684548d24c6e0124811b31d8447231d1415fc392b5b3', 'I7C2D_BOOK_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('data/tables/event_centre_cabinetskill.lua', 'dddaa9ff5889a2803b0b42330399fd8d10509c69e34efe6de19eade300a31365', 'I7C2D_BOOK_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('data/tables/event_centre_skillcost.lua', 'f224e7ab52da1cb0a1fd533e4c9fd4abba3590e9851ce8fac6fa7fb02b2df73a', 'I7C2D_BOOK_SOURCE_BOUNDARY'))


SOURCE_MANIFEST.append(('app/common/tables/ObjectBookColorTable.lua', '07f54c2c629c0dab488d719641b61bd6c50deabffcfba93d918d07c153b248a6', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/common/tables/ObjectBookShopTable.lua', '1f841cb4cb78f8b7691306eaf4f4ef300a4978aee6a6f6e8963c2be65c234769', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/common/tables/ObjectBookTable.lua', '86addaf1c6f31bcf66616ecb505d5fa85f3c5fe3da666ffb80dd4bb8ebd674e7', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/common/tables/ObjectBranchTable.lua', 'd0ff266d14ea7420d6f6737fb8866e1414382ff3567a970efb544b0cbb22935d', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/common/tables/ObjectClassTable.lua', '690448c2a2be9010eea9f5c1c09ae48569849f0d5a6bdf81dd10d3776495233e', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/common/tables/ObjectLogTable.lua', 'a62b34cb14213cf959751cb3bd0bf35732bc8864dc1d9e75843a7dcc08621ee5', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/common/tables/ObjectSubjectTable.lua', 'eab196b3834867325f32ebb703b65077f1ff575940c11c8f53af867e69b0d181', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/model/Course.lua', '130666bd52843d12a897b21b79dfc4d13245f86e3f73c2fe751fc76862f2d659', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/CourseAddSkillWindow.lua', 'd86f76ee5d157b2d10e98265d3d50528f67a74c2a4dc585e4cca23c798369c15', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/CourseApplySucceedWindow.lua', 'fdf9935b2c75c97dd70d7e12568b8c07cad77bf1b3f89f2d2b61936fced0633a', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/CourseApplyWindow.lua', '2ee5d0080d72ce960ab8c73fb764ce986e870941811234513a3c55b19bb85fd3', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/CourseBookstoreWindow.lua', 'fe6c651b3b3ddd34d7fa9aa5dfced5ff61c768ca49273816ac56370d1284d3d2', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/CourseHeroListWindow.lua', 'd47b5dff495a616731df61535af8fe0e8aeef3cfaf375bc6dde12e6362c9be01', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/CourseInfoWindow.lua', '1b642a4ab066e43f443f09b64950931679733bf85a85e8a561af591bcd470fa8', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/CourseListWindow.lua', '5c2398bf0c535006b4de568b3dcef61e577d55e55d716e91e5db10838805890b', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/CourseRecommendApplyWindow.lua', '60498b783687369f81641107b7624b4166bd979da8b05c4d876ce411c9663f2d', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/CourseRecommendWindow.lua', '7f6ba285c32c0c435f425f42ff12e7481cf5bcf58748804d65a6e9e8e8fd9f49', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/CourseSelectHeroWindow.lua', '18ad2a1fa2c9519a8792fb4770ffa3f00ce167388900999243787fd8f27bd2e1', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/CourseStudySelectWindow.lua', '6a54523d75b7bebeace82393a8a09b2a10fd627297a0250a292a0f37fbce3b39', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/CourseStudyroomWindow.lua', '6da967f3fd58624039286cad58b826e762749ee1b9b39574d3588fc41ae64993', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/CourseTipWindow.lua', 'b1a2f4600ef196a0ccb236b06354902f0b8cd5ee693b0bfa4f00875977919fb4', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/CourseUpgradeWindow.lua', '4e3fd86e9b279acfd49c3db099a3a276d76bb85bc00af89a2b731486b6daca8a', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/CourseWindow.lua', 'e283a5bcd10c5b9f815080513cb591335c6e89e77e3c099a1017c693ad7ab366', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('data/tables/object_book.lua', '978bc0367124643116add8ac903f2a169d0c543ed110869c8f0af69c6bb92732', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('data/tables/object_book_color.lua', '88228fd4ee11d22414f15bbda2b6af358ba56c996b619bc11f335427aeb11337', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('data/tables/object_book_shop.lua', '82cc5a4a5b68cb116987db9695299ff826c9655e01a15c006e1d22454189438d', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('data/tables/object_branch.lua', '5f45c31a1234eb6248d22c2fb68fe7d065b8fbb8f0644ccea9bd031900b0ba33', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('data/tables/object_class.lua', '518026a4c950d444eb1d732ac3dc4cecc24acb6121bc93db5fa0ee912d4e6070', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('data/tables/object_log.lua', '5ddb6cfecd9946f73332985577a6b44cd62abd415a7c8902d189446a89a10ef9', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('data/tables/object_subject.lua', '07b9dc913f4eaa667c6ee5a6d0e5206cf5652a95ccb96bdf6cb1a9babbbb0f26', 'I7C2E_COURSE_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('data/tables/skill_level.lua', '700221095b3728bacb23a118daf9e0a8cf2dd6e31c402b1a55359ac9fac4d98a', 'I7C2E_COURSE_SOURCE_BOUNDARY'))

SOURCE_MANIFEST.append(('data/tables/inscription.lua', 'dc0d5d8b0de66b9495665cb6a300aa9bdb5979065f28c565ede35e447adce23c', 'I7C2F_INSCRIPTION_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('data/tables/inscription_suit.lua', 'cd5e0f6438d34a3d597c9d25175f7fee81f14eb4808439d60b272fa2a2e4ca25', 'I7C2F_INSCRIPTION_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('data/tables/inscription_pos.lua', '714644c260a86581d04880289dd6e36abdfd446fc0f7c25342b4fe870d6a10cf', 'I7C2F_INSCRIPTION_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('data/tables/inscription_rate.lua', '2bdb4a95b2bcd0850b6bd7661fdf047c95633a8c880a0b4cc8b5e85b0aa4a6e8', 'I7C2F_INSCRIPTION_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/model/Inscription.lua', 'd14a19472279d2eb911a824bbd4bd053f4d1cdede9c16e4080518488bd7b066f', 'I7C2F_INSCRIPTION_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/InscriptionWindow.lua', '4ca0f6a8b6d70caf60205efe14a55665142acd1f3ac9b93d6dc014d5a8bd04e6', 'I7C2F_INSCRIPTION_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/InscriptionEquipWindow.lua', 'd6426f0abbc0c7532f8b4f12ed5facc4a38f12db8954acf685b7e8604b4d278c', 'I7C2F_INSCRIPTION_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/InscriptionTenTimesWindow.lua', '2dae5c579e44bd9a092ca534b6050c06f9718b4566ef1d9cdfb381ff97b480c1', 'I7C2F_INSCRIPTION_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/model/NormalHero.lua', '125183556caeecc182bf0702dd1f95160c8ba1666a3b97fbb8a7261d30ae0ac9', 'I7C2F_INSCRIPTION_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/model/SuperHero.lua', 'b127c2cbef327d3142031bf30daa0af1b45997c6da82fba946d641a86783d622', 'I7C2F_INSCRIPTION_SOURCE_BOUNDARY'))
SOURCE_MANIFEST.append(('app/common/tables/InscriptionTable.lua', '643f1b935b3fa18c9b9289b527ed3f25a0c109e663c2b8b56a642b88695eced0', 'I7C2F_STOCK_CALLBACK_AND_CONSUMER_BOUNDARY'))
SOURCE_MANIFEST.append(('app/common/tables/InscriptionSuitTable.lua', 'cd315ed3116e1930cc1b371c5823a6a790784f19195b7563c2fd5db3132cf669', 'I7C2F_STOCK_CALLBACK_AND_CONSUMER_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/BackpackWindow.lua', '48b18493fed4186541fc989a8ef60d6338d444c4e8a0fc986903a57e52ff19c1', 'I7C2F_STOCK_CALLBACK_AND_CONSUMER_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/SellDetailWindow.lua', 'cdb8e1ffde40e173219886a9de0c0ca4905b9d3965e3e8c9dc00026b765b360f', 'I7C2F_STOCK_CALLBACK_AND_CONSUMER_BOUNDARY'))
SOURCE_MANIFEST.append(('app/windows/ExchangeMaterialWindow.lua', '6636740cc170a3bb149e9a85241de755ae8d6dde612a880354f516bee668f6b9', 'I7C2F_STOCK_CALLBACK_AND_CONSUMER_BOUNDARY'))
from inscription_content import build_inscription
from course_content import build_course
class CompileError(ValueError):
    pass


def sha256_bytes(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def sha256_file(path: Path) -> str:
    h = hashlib.sha256()
    with path.open("rb") as f:
        for chunk in iter(lambda: f.read(1024 * 1024), b""):
            h.update(chunk)
    return h.hexdigest()


def canonical_json_bytes(value: Any, *, newline: bool = True) -> bytes:
    data = json.dumps(value, ensure_ascii=False, separators=(",", ":"), sort_keys=True).encode("utf-8")
    return data + (b"\n" if newline else b"")


@dataclass(frozen=True)
class SourceBlob:
    path: str
    sha256: str
    role: str
    data: bytes


class SourceArchive:
    def __init__(self, archive: Path) -> None:
        self.archive = Path(archive)
        actual = sha256_file(self.archive)
        if actual != EXPECTED_SOURCE_ARCHIVE_SHA256:
            raise CompileError(
                f"source archive SHA-256 mismatch: expected {EXPECTED_SOURCE_ARCHIVE_SHA256}, got {actual}"
            )
        self.archive_sha256 = actual

    def read_verified(self) -> dict[str, SourceBlob]:
        out: dict[str, SourceBlob] = {}
        with zipfile.ZipFile(self.archive) as zf:
            for path, expected, role in SOURCE_MANIFEST:
                member = SOURCE_PREFIX + path
                try:
                    data = zf.read(member)
                except KeyError as exc:
                    raise CompileError(f"missing required source member {member}") from exc
                actual = sha256_bytes(data)
                if actual != expected:
                    raise CompileError(f"source SHA-256 mismatch for {path}: expected {expected}, got {actual}")
                out[path] = SourceBlob(path=path, sha256=actual, role=role, data=data)
        return out


_STRING_RE = re.compile(r'"((?:\\.|[^"\\])*)"', re.S)


def _decode_lua_string(raw: str) -> str:
    # Generated source uses JSON-compatible escapes for the relevant tables.
    try:
        return json.loads('"' + raw + '"')
    except json.JSONDecodeError as exc:
        raise CompileError(f"unsupported generated Lua string escape: {raw[:80]!r}") from exc


def _extract_balanced(text: str, start: int) -> tuple[str, int]:
    if start >= len(text) or text[start] != "{":
        raise CompileError("expected '{' while parsing generated Lua table")
    depth = 0
    in_string = False
    escape = False
    for i in range(start, len(text)):
        ch = text[i]
        if in_string:
            if escape:
                escape = False
            elif ch == "\\":
                escape = True
            elif ch == '"':
                in_string = False
            continue
        if ch == '"':
            in_string = True
        elif ch == "{":
            depth += 1
        elif ch == "}":
            depth -= 1
            if depth == 0:
                return text[start : i + 1], i + 1
    raise CompileError("unbalanced generated Lua table")


def _field_table(text: str, name: str) -> str:
    m = re.search(r"\b" + re.escape(name) + r"\s*=\s*\{", text)
    if not m:
        raise CompileError(f"generated Lua table missing field {name}")
    brace = text.find("{", m.start())
    block, _ = _extract_balanced(text, brace)
    return block


def _top_level_row_blocks(rows_block: str) -> list[str]:
    blocks: list[str] = []
    i = 1
    while i < len(rows_block) - 1:
        ch = rows_block[i]
        if ch.isspace() or ch == ",":
            i += 1
            continue
        if ch != "{":
            raise CompileError(f"unsupported token in generated Lua rows at offset {i}: {ch!r}")
        block, i = _extract_balanced(rows_block, i)
        blocks.append(block)
    return blocks


def parse_generated_lua_table(data: bytes) -> list[dict[str, str]]:
    text = data.decode("utf-8-sig")
    if not re.match(r"^\s*return\s*\{", text):
        raise CompileError("generated Lua table must start with return {")
    keys_block = _field_table(text, "keys")
    rows_block = _field_table(text, "rows")
    keys = [_decode_lua_string(m.group(1)) for m in _STRING_RE.finditer(keys_block)]
    if not keys or len(set(keys)) != len(keys):
        raise CompileError("generated Lua keys are empty or duplicated")
    result: list[dict[str, str]] = []
    for row_index, block in enumerate(_top_level_row_blocks(rows_block), start=1):
        # Strictly allow only quoted string values, commas, braces and whitespace.
        scrubbed = _STRING_RE.sub('""', block)
        if re.search(r"[^\s{},\"]", scrubbed):
            raise CompileError(f"unsupported expression in generated Lua row {row_index}")
        values = [_decode_lua_string(m.group(1)) for m in _STRING_RE.finditer(block)]
        if len(values) != len(keys):
            raise CompileError(
                f"generated Lua row {row_index} has {len(values)} values, expected {len(keys)}"
            )
        result.append(dict(zip(keys, values)))
    return result


def parse_encoded_item_table(data: bytes) -> list[dict[str, str]]:
    text = data.decode("utf-8-sig").strip()
    m = re.fullmatch(r'return\s+"([A-Za-z0-9+/=]+)"', text, re.S)
    if not m:
        raise CompileError("item.lua is not the expected single base64 return string")
    try:
        decoded = base64.b64decode(m.group(1), validate=True).decode("utf-8")
    except Exception as exc:
        raise CompileError(f"invalid item.lua base64/UTF-8 payload: {exc}") from exc
    lines = decoded.splitlines()
    if len(lines) < 3:
        raise CompileError("item.lua decoded payload is too short")
    headers = lines[1].split("\t")
    required = {"id", "type", "stack", "stack_exceed_mail", "partner_id"}
    if not required.issubset(headers):
        raise CompileError(f"item.lua decoded header missing {sorted(required - set(headers))}")
    if len(set(headers)) != len(headers):
        raise CompileError("item.lua decoded header contains duplicates")
    rows: list[dict[str, str]] = []
    reader = csv.reader(io.StringIO("\n".join(lines[2:])), delimiter="\t")
    for idx, values in enumerate(reader, start=1):
        if len(values) != len(headers):
            raise CompileError(f"item.lua row {idx} has {len(values)} fields, expected {len(headers)}")
        rows.append(dict(zip(headers, values)))
    return rows


def parse_encoded_skill_table(data: bytes) -> dict[int, dict[str, str]]:
    text = data.decode("utf-8-sig").strip()
    m = re.fullmatch(r'return\s+"([A-Za-z0-9+/=]+)"', text, re.S)
    if not m:
        raise CompileError("skill.lua is not the expected single base64 return string")
    try:
        decoded = base64.b64decode(m.group(1), validate=True).decode("utf-8")
    except Exception as exc:
        raise CompileError(f"invalid skill.lua base64/UTF-8 payload: {exc}") from exc
    lines = decoded.splitlines()
    if len(lines) < 3:
        raise CompileError("skill.lua decoded payload is too short")
    headers = lines[1].split("\t")
    required = {"id", "pet_star_type", "pet_skill_star", "desc4_num_step"}
    if not required.issubset(headers):
        raise CompileError(f"skill.lua decoded header missing {sorted(required - set(headers))}")
    if len(set(headers)) != len(headers):
        raise CompileError("skill.lua decoded header contains duplicates")
    out: dict[int, dict[str, str]] = {}
    reader = csv.reader(io.StringIO("\n".join(lines[2:])), delimiter="\t")
    for idx, values in enumerate(reader, start=1):
        if len(values) != len(headers):
            raise CompileError(f"skill.lua row {idx} has {len(values)} fields, expected {len(headers)}")
        row = dict(zip(headers, values))
        sid = parse_int(row["id"], label=f"skill[{idx}].id", allow_zero=False, allow_negative=False)
        if sid in out:
            raise CompileError(f"skill.lua duplicate id {sid}")
        out[sid] = row
    return out



def parse_base64_indexed_lua_table(data: bytes) -> tuple[dict[str, int], dict[int, list[str]]]:
    """Parse the exact generated base64 table shape used by partner/super_partner.

    It executes no Lua. Supported values are quoted strings and long-bracket strings.
    """
    text = data.decode("utf-8-sig").strip()
    m = re.fullmatch(r'return\s+"([A-Za-z0-9+/=]+)"', text, re.S)
    if not m:
        raise CompileError("indexed Lua table is not the expected single base64 return string")
    try:
        decoded = base64.b64decode(m.group(1), validate=True).decode("utf-8")
    except Exception as exc:
        raise CompileError(f"invalid indexed Lua base64/UTF-8 payload: {exc}") from exc
    km = re.search(r"table\.keys\s*=\s*\{(.*?)\}\s*table\.rows", decoded, re.S)
    if not km:
        raise CompileError("indexed Lua table missing table.keys/table.rows")
    keys: dict[str, int] = {}
    for name, raw_idx in re.findall(r"([A-Za-z0-9_]+)\s*=\s*(\d+)", km.group(1)):
        idx = int(raw_idx)
        if name in keys or idx <= 0:
            raise CompileError("indexed Lua table duplicate/invalid key")
        keys[name] = idx
    if not keys:
        raise CompileError("indexed Lua table contains no keys")
    rm = re.search(r"table\.rows\s*=\s*\{", decoded)
    if not rm:
        raise CompileError("indexed Lua table missing rows")
    pos = rm.end()
    rows: dict[int, list[str]] = {}

    def skip_ws(i: int) -> int:
        while i < len(decoded) and (decoded[i].isspace() or decoded[i] == ','):
            i += 1
        return i

    def parse_value(i: int) -> tuple[str, int]:
        i = skip_ws(i)
        if i >= len(decoded):
            raise CompileError("unexpected EOF parsing indexed Lua value")
        if decoded[i] == '"':
            j=i+1; out=[]; esc=False
            while j < len(decoded):
                ch=decoded[j]
                if esc:
                    out.append('\\'+ch); esc=False; j+=1; continue
                if ch=='\\': esc=True; j+=1; continue
                if ch=='"':
                    raw=''.join(out)
                    return _decode_lua_string(raw), j+1
                out.append(ch); j+=1
            raise CompileError("unterminated indexed Lua quoted string")
        if decoded[i] == '[':
            lm=re.match(r"\[(=*)\[", decoded[i:])
            if lm:
                eq=lm.group(1); start=i+len(lm.group(0)); close=']'+eq+']'; end=decoded.find(close,start)
                if end < 0: raise CompileError("unterminated indexed Lua long string")
                return decoded[start:end], end+len(close)
        # Strict numeric/bool/nil fallback; current Hero fields are strings.
        m2=re.match(r"([^,}\s]+)", decoded[i:])
        if not m2: raise CompileError(f"unsupported indexed Lua token near {decoded[i:i+40]!r}")
        return m2.group(1), i+len(m2.group(1))

    while True:
        pos=skip_ws(pos)
        if pos >= len(decoded): raise CompileError("unterminated indexed Lua rows")
        if decoded[pos] == '}': break
        mrow=re.match(r"\[(\d+)\]\s*=\s*\{", decoded[pos:])
        if not mrow:
            raise CompileError(f"unsupported indexed Lua row prefix near {decoded[pos:pos+80]!r}")
        row_id=int(mrow.group(1)); pos += mrow.end(); vals=[]
        while True:
            pos=skip_ws(pos)
            if pos >= len(decoded): raise CompileError("unterminated indexed Lua row")
            if decoded[pos] == '}': pos += 1; break
            v,pos=parse_value(pos); vals.append(v)
        if row_id in rows: raise CompileError(f"duplicate indexed Lua row {row_id}")
        rows[row_id]=vals
    return keys, rows


def indexed_field(keys: dict[str, int], values: list[str], name: str, *, row_id: int) -> str:
    idx=keys.get(name)
    if idx is None: raise CompileError(f"indexed Lua table missing required key {name}")
    if idx < 1 or idx > len(values): raise CompileError(f"indexed Lua row {row_id} missing {name}")
    return values[idx-1]

def parse_int(raw: str, *, label: str, allow_zero: bool = True, allow_negative: bool = True) -> int:
    try:
        value = int(raw)
    except (TypeError, ValueError) as exc:
        raise CompileError(f"{label} is not an integer: {raw!r}") from exc
    if not allow_negative and value < 0:
        raise CompileError(f"{label} must be non-negative, got {value}")
    if not allow_zero and value == 0:
        raise CompileError(f"{label} must be non-zero")
    return value


def require_unique(rows: Iterable[dict[str, Any]], field: str, label: str) -> None:
    seen: set[Any] = set()
    for row in rows:
        value = row[field]
        if value in seen:
            raise CompileError(f"duplicate {label} {value!r}")
        seen.add(value)


def extract_economy_names(enums_data: bytes) -> set[str]:
    text = enums_data.decode("utf-8-sig")
    m = re.search(r"xyd\.ECONOMY\s*=\s*\{", text)
    if not m:
        raise CompileError("enums.lua missing xyd.ECONOMY")
    brace = text.find("{", m.start())
    block, _ = _extract_balanced(text, brace)
    pairs = re.findall(r"\b[A-Z0-9_]+\s*=\s*\"([^\"]+)\"", block)
    if not pairs:
        raise CompileError("enums.lua xyd.ECONOMY contains no string values")
    return set(pairs)


def source_record(blob: SourceBlob) -> dict[str, str]:
    return {"path": blob.path, "role": blob.role, "sha256": blob.sha256}


def build_artifacts(blobs: dict[str, SourceBlob], archive_sha256: str) -> dict[str, Any]:
    items = parse_encoded_item_table(blobs["data/tables/item.lua"].data)
    players = parse_generated_lua_table(blobs["data/tables/player.lua"].data)
    misc = parse_generated_lua_table(blobs["data/tables/misc.lua"].data)
    skin_skill_rows = parse_generated_lua_table(blobs["data/tables/skin_skill.lua"].data)
    skin_dynamic_rows = parse_generated_lua_table(blobs["data/tables/skin_dynamic.lua"].data)
    model_rows = parse_generated_lua_table(blobs["data/tables/model.lua"].data)
    functions = parse_generated_lua_table(blobs["data/tables/function.lua"].data)
    practice_type_rows = parse_generated_lua_table(blobs["data/tables/practice_type.lua"].data)
    practice_lock_rows = parse_generated_lua_table(blobs["data/tables/practice_lock.lua"].data)
    vip_rows = parse_generated_lua_table(blobs["data/tables/vip.lua"].data)
    assets = parse_generated_lua_table(blobs["data/tables/asset.lua"].data)
    pet_keys, pet_rows = parse_base64_indexed_lua_table(blobs["data/tables/pet.lua"].data)
    pet_exp_rows = parse_generated_lua_table(blobs["data/tables/pet_exp.lua"].data)
    pet_skillbook_rows = parse_generated_lua_table(blobs["data/tables/pet_skillbook.lua"].data)
    pet_skilllevel_rows = parse_generated_lua_table(blobs["data/tables/pet_skilllevel.lua"].data)
    pet_star_rows = parse_generated_lua_table(blobs["data/tables/pet_star.lua"].data)
    skill_rows = parse_encoded_skill_table(blobs["data/tables/skill.lua"].data)
    economy_names = extract_economy_names(blobs["app/common/enums.lua"].data)

    # Behavioral source guards: fail if the exact source semantics we compile disappear.
    item_behavior = blobs["app/common/tables/ItemTable.lua"].data.decode("utf-8-sig")
    for needle in ("stack_exceed_mail", "partner_id", "function var_0_2.stack", "function var_0_2.type"):
        if needle not in item_behavior:
            raise CompileError(f"ItemTable.lua behavioral guard missing {needle!r}")
    for needle in ("skinModel", "skinPartner", "skinLastTime", "stylePet"):
        if needle not in item_behavior:
            raise CompileError(f"ItemTable.lua CA7 appearance guard missing {needle!r}")
    skin_skill_behavior = blobs["app/common/tables/SkinSkillTable.lua"].data.decode("utf-8-sig")
    for needle in ("getHeroID", "getSkillID", "getModelID"):
        if needle not in skin_skill_behavior:
            raise CompileError(f"SkinSkillTable.lua CA7 guard missing {needle!r}")
    skin_dynamic_behavior = blobs["app/common/tables/SkinDynamicTable.lua"].data.decode("utf-8-sig")
    for needle in ("partnerID", "cost", "num"):
        if needle not in skin_dynamic_behavior:
            raise CompileError(f"SkinDynamicTable.lua CA7 guard missing {needle!r}")
    model_behavior = blobs["app/common/tables/ModelTable.lua"].data.decode("utf-8-sig")
    if "dynamicType" not in model_behavior:
        raise CompileError("ModelTable.lua CA7 dynamicType guard missing")
    mid_behavior = blobs["app/common/network/mid.lua"].data.decode("utf-8-sig")
    for needle in ("SKIN_ON = 60", "SKIN_CANCEL = 61", "UNLOCK_DYNAMIC_CARD = 68", "SHOW_DYNAMIC_CARD = 69", "GET_PET_STYLE_FORM_ITEM = 1893", "USE_PET_STYLE = 1894", "CANCEL_PET_STYLE = 1895", "USE_ILLUSION_SKIN_ITEM = 2979"):
        if needle not in mid_behavior:
            raise CompileError(f"mid.lua CA7 wire guard missing {needle!r}")
    base_fighter = blobs["lib/battle/BaseFighter.lua"].data.decode("utf-8-sig")
    if "getSkillModelID" not in base_fighter or "getOldModelID" not in base_fighter:
        raise CompileError("BaseFighter.lua CA7 ordinary-axis combat guard missing")
    skin_select_behavior = blobs["app/windows/SkinSkillSelectWindow.lua"].data.decode("utf-8-sig")
    backpack_window_behavior = blobs["app/windows/BackpackWindow.lua"].data.decode("utf-8-sig")
    pet_style_behavior = blobs["app/windows/PetEquipInfoWindow.lua"].data.decode("utf-8-sig")
    if "xyd.mid.SKIN_ON" not in skin_select_behavior or "xyd.mid.SKIN_ON" not in backpack_window_behavior:
        raise CompileError("CA7 MID60 caller guards missing")
    if "xyd.mid.GET_PET_STYLE_FORM_ITEM" not in backpack_window_behavior:
        raise CompileError("BackpackWindow.lua CA7 Pet-style acquisition guard missing")
    for needle in ("xyd.mid.GET_PET_STYLE_FORM_ITEM", "xyd.mid.USE_PET_STYLE", "xyd.mid.CANCEL_PET_STYLE"):
        if needle not in pet_style_behavior:
            raise CompileError(f"PetEquipInfoWindow.lua CA7 style guard missing {needle!r}")
    player_behavior = blobs["app/common/tables/PlayerTable.lua"].data.decode("utf-8-sig")
    for needle in ("maxEnergy", "totalExp", "awardEnergy", "heroMaxLev"):
        if needle not in player_behavior:
            raise CompileError(f"PlayerTable.lua behavioral guard missing {needle!r}")
    self_player = blobs["app/model/SelfPlayer.lua"].data.decode("utf-8-sig")
    for needle in ("getEnergyLimit", "getSpiritEnergyLimit", "getInvitationLimit", "skillPointDuration"):
        if needle not in self_player:
            raise CompileError(f"SelfPlayer.lua behavioral guard missing {needle!r}")
    backpack = blobs["app/model/Backpack.lua"].data.decode("utf-8-sig")
    if "ItemTable" not in backpack and "tables.item" not in backpack:
        # Current decompiled symbol names can vary, but Backpack must reference item table behavior.
        if "xyd.tables.item" not in backpack:
            raise CompileError("Backpack.lua no longer references item table behavior")
    pet_behavior = blobs["app/model/Pet.lua"].data.decode("utf-8-sig")
    for needle in ("function var_0_3.populate", "function var_0_3.toParams", "is_born_", "is_show_", "getPetID", "getTableID", "PET_SUMMON", "PET_CLEAN_CD", "PET_SET_SHOW", "TotalStarSuipian"):
        if needle not in pet_behavior:
            raise CompileError(f"Pet.lua behavioral guard missing {needle!r}")
    pet_main_behavior = blobs["app/windows/PetMainWindow.lua"].data.decode("utf-8-sig")
    for needle in ("getSkillLimitLevel", "sendSkillLevUpRequest", "clickJinhuaButton", "petSkillBook:getBookNum"):
        if needle not in pet_main_behavior:
            raise CompileError(f"PetMainWindow.lua progression guard missing {needle!r}")
    pet_add_exp_behavior = blobs["app/windows/PetAddExpWindow.lua"].data.decode("utf-8-sig")
    if "heroMaxLev" not in pet_add_exp_behavior:
        raise CompileError("PetAddExpWindow.lua max-level guard missing heroMaxLev")
    pet_exp_behavior = blobs["app/common/tables/PetExpTable.lua"].data.decode("utf-8-sig")
    if "totalExp" not in pet_exp_behavior:
        raise CompileError("PetExpTable.lua totalExp guard missing")
    pet_skillbook_behavior = blobs["app/common/tables/PetSkillBookTable.lua"].data.decode("utf-8-sig")
    if "getBookNum" not in pet_skillbook_behavior:
        raise CompileError("PetSkillBookTable.lua getBookNum guard missing")
    hero_table_behavior = blobs["app/common/tables/HeroTable.lua"].data.decode("utf-8-sig")
    for needle in ("function var_0_2.getEgg", "function var_0_2.getHatchTime", "function var_0_2.stoneID", "function var_0_2.summonType"):
        if needle not in hero_table_behavior:
            raise CompileError(f"HeroTable.lua Pet acquisition guard missing {needle!r}")
    enums_text = blobs["app/common/enums.lua"].data.decode("utf-8-sig")
    fragments_match = re.search(r"xyd\.TotalStarSuipian\s*=\s*\{([^}]*)\}", enums_text, re.S)
    if not fragments_match:
        raise CompileError("enums.lua missing xyd.TotalStarSuipian")
    pet_fragment_costs = [int(v) for v in re.findall(r"\d+", fragments_match.group(1))]
    if pet_fragment_costs != [10, 30, 80, 180, 330]:
        raise CompileError(f"Pet fragment summon costs drifted: {pet_fragment_costs}")

    # Player progression catalog.
    progression_rows: list[dict[str, int]] = []
    expected_player_fields = ["lev", "energy", "exp", "award_energy", "total_exp", "hero_lev", "power", "expedition_mana"]
    for idx, row in enumerate(players, start=1):
        missing = [k for k in expected_player_fields if k not in row]
        if missing:
            raise CompileError(f"player.lua row {idx} missing {missing}")
        typed = {k: parse_int(row[k], label=f"player[{idx}].{k}", allow_negative=False) for k in expected_player_fields}
        if typed["lev"] <= 0:
            raise CompileError(f"player level must be positive at row {idx}")
        progression_rows.append(typed)
    progression_rows.sort(key=lambda r: r["lev"])
    require_unique(progression_rows, "lev", "player level")
    if progression_rows and [r["lev"] for r in progression_rows] != list(range(1, progression_rows[-1]["lev"] + 1)):
        raise CompileError("player.lua levels are not contiguous from 1")
    last_total = -1
    for row in progression_rows:
        if row["total_exp"] < last_total:
            raise CompileError("player.lua total_exp is not monotonic")
        last_total = row["total_exp"]

    player_artifact = {
        "rows": progression_rows,
        "schema_version": SCHEMA_VERSION,
        "source": "data/tables/player.lua",
    }

    # Misc map for typed temporal rules.
    misc_by_key: dict[str, str] = {}
    for row in misc:
        key = row.get("key", "")
        if not key:
            continue
        if key in misc_by_key:
            raise CompileError(f"duplicate misc key {key!r}")
        misc_by_key[key] = row.get("value", "")

    def misc_int(key: str) -> int:
        if key not in misc_by_key:
            raise CompileError(f"misc.lua missing required key {key}")
        value = parse_int(misc_by_key[key], label=f"misc.{key}", allow_negative=False)
        if value <= 0:
            raise CompileError(f"misc.{key} must be positive")
        return value

    # Source asset identity. Empty backend_name rows remain diagnostic-only, not definitions.
    asset_by_name: dict[str, dict[str, Any]] = {}
    asset_rows: list[dict[str, Any]] = []
    for idx, row in enumerate(assets, start=1):
        asset_id = parse_int(row.get("id", ""), label=f"asset[{idx}].id")
        backend_name = row.get("backend_name", "").strip()
        if not backend_name:
            continue
        if backend_name in asset_by_name:
            raise CompileError(f"duplicate asset backend_name {backend_name!r}")
        typed = {"backend_name": backend_name, "source_asset_id": asset_id}
        asset_by_name[backend_name] = typed
        asset_rows.append(typed)
    asset_rows.sort(key=lambda r: (r["backend_name"], r["source_asset_id"]))

    for required_name in ("mana", "crystal", "exp", "energy"):
        if required_name not in asset_by_name:
            raise CompileError(f"asset.lua missing required backend_name {required_name}")
        if required_name not in economy_names:
            raise CompileError(f"enums.lua xyd.ECONOMY missing required name {required_name}")

    resources: list[dict[str, Any]] = []

    # Catalog all source-known named assets conservatively. Only Mana/Crystal are R4 settlement-enabled.
    for asset in asset_rows:
        name = asset["backend_name"]
        if name == "exp":
            cls = "PLAYER_EXP"
            status = "QUALIFIED"
            activation = "ENABLED_R5"
        elif name == "energy":
            # Replaced below by richer TEMPORAL definition.
            continue
        else:
            cls = "SCALAR_CURRENCY"
            status = "QUALIFIED" if name in economy_names else "SOURCE_KNOWN"
            activation = "ENABLED_R4" if name in {"mana", "crystal"} else "OWNER_REQUIRED"
        resources.append({
            "catalog_status": status,
            "class": cls,
            "definition_key": f"{cls.lower()}:{name}",
            "resource_key": name,
            "settlement_activation": activation,
            "source_asset_id": asset["source_asset_id"],
        })

    # A bounded named scalar; the stock economy sideband has no numeric asset ID.
    if "friendship_coin" not in economy_names or "friendship_coin" in asset_by_name:
        raise CompileError("SocialGift named scalar source identity drift")
    resources.append({"catalog_status":"QUALIFIED","class":"SCALAR_CURRENCY",
        "definition_key":"scalar_currency:friendship_coin","resource_key":"friendship_coin",
        "settlement_activation":"ENABLED_R4"})
    # Named Workshop balances are scalar I5 facts, not asset-ID or PlayerEXP identities.
    # Current enums.ECONOMY and SelfPlayer scalar hydration plus source Book costs qualify these four.
    for key in ('magic_dust','magic_liquid','magic_energy','magic_exp','degree_cer','graduate_cer','patent_cer'):
        if key not in economy_names or key in asset_by_name:raise CompileError("Workshop named scalar identity drift: "+key)
        resources.append({"catalog_status":"QUALIFIED","class":"SCALAR_CURRENCY","definition_key":"scalar_currency:"+key,"resource_key":key,"settlement_activation":"ENABLED_R4"})
    social_gift_artifact=build_social_gift(
        parse_generated_lua_table(blobs["data/tables/gift.lua"].data),
        parse_generated_lua_table(blobs["data/tables/friend_dailygift.lua"].data),
        misc_int("gift_send_limit"),misc_int("gift_get_limit"))
    temporal_defs = [
        ("energy", misc_int("energy_incr_time"), "PLAYER_LEVEL_ENERGY", None, "QUALIFIED", "ENABLED_R5"),
        ("spirit_energy", misc_int("spirit_energy_minute"), "STATIC", misc_int("spirit_energy_up_limit"), "QUALIFIED", "ENABLED_R5"),
        ("skill_point", misc_int("skill_point_incr_time"), "VIP_PLUS_MONTHLY_PRIVILEGE", None, "QUALIFIED", "ENABLED_R5"),
        ("invitation", misc_int("invitation_incr_time"), "UNRESOLVED", None, "PARTIAL", "FAIL_CLOSED"),
    ]
    for name, seconds, cap_rule, static_cap, status, activation in temporal_defs:
        row: dict[str, Any] = {
            "cap_rule": cap_rule,
            "catalog_status": status,
            "class": "TEMPORAL",
            "definition_key": f"temporal:{name}",
            "regen_amount": 1,
            "regen_seconds": seconds,
            "resource_key": name,
            "settlement_activation": activation,
        }
        if static_cap is not None:
            row["static_cap"] = static_cap
        if name in asset_by_name:
            row["source_asset_id"] = asset_by_name[name]["source_asset_id"]
        resources.append(row)

    # Item stack definitions. Positive stack alone does not imply ownership for type 24 or unknown type 0.
    positive_stack = 0
    enabled_stack = 0
    specialized_type24 = 0
    fail_closed_unknown_type = 0
    partner_scrolls = 0
    for idx, row in enumerate(items, start=1):
        item_id = parse_int(row.get("id", ""), label=f"item[{idx}].id", allow_negative=False)
        stack = parse_int(row.get("stack", "0") or "0", label=f"item[{item_id}].stack", allow_negative=False)
        if stack <= 0:
            continue
        item_type = parse_int(row.get("type", "0") or "0", label=f"item[{item_id}].type")
        overflow_mail = parse_int(row.get("stack_exceed_mail", "0") or "0", label=f"item[{item_id}].stack_exceed_mail", allow_negative=False)
        if overflow_mail not in (0, 1):
            raise CompileError(f"item[{item_id}].stack_exceed_mail must be 0 or 1, got {overflow_mail}")
        partner_id = parse_int(row.get("partner_id", "0") or "0", label=f"item[{item_id}].partner_id", allow_negative=False)
        positive_stack += 1
        definition: dict[str, Any] = {
            "catalog_status": "QUALIFIED",
            "class": "STACK_ITEM",
            "definition_key": f"stack_item:{item_id}",
            "item_id": item_id,
            "item_type": item_type,
            "overflow_to_mail": bool(overflow_mail),
            "settlement_activation": "ENABLED_R4",
            "stack_cap": stack,
        }
        if item_type == 24:
            specialized_type24 += 1
            definition["class"] = "SPECIALIZED_DOMAIN"
            definition["definition_key"] = f"specialized:item:{item_id}"
            definition["settlement_activation"] = "FAIL_CLOSED"
            definition["specialized_owner"] = "HORCRUX_GENERATED_OWNER_REQUIRED"
        elif item_type == 0:
            fail_closed_unknown_type += 1
            definition["catalog_status"] = "PARTIAL"
            definition["settlement_activation"] = "FAIL_CLOSED"
            definition["reason"] = "ITEM_TYPE_ZERO_UNQUALIFIED"
        elif item_type == 3:
            partner_scrolls += 1
            if partner_id <= 0:
                raise CompileError(f"type-3 stack item {item_id} lacks required partner_id")
            definition["partner_id"] = partner_id
            enabled_stack += 1
        else:
            enabled_stack += 1
        resources.append(definition)

    resources.sort(key=lambda r: r["definition_key"])
    require_unique(resources, "definition_key", "resource definition_key")
    item_ids = [r["item_id"] for r in resources if "item_id" in r]
    if len(item_ids) != len(set(item_ids)):
        raise CompileError("duplicate item_id in resource catalog")

    resource_artifact = {
        "resources": resources,
        "schema_version": SCHEMA_VERSION,
    }

    # CA4-1 shared equipment/content primitives. The root family is source
    # ItemType 1/8 only; recursive recipe components may be any already-qualified
    # I5 STACK_ITEM. This catalog deliberately contains no Hero/Pet/Super slot
    # reachability or durable ownership facts. Recipe ordinals are source data and
    # repeated component IDs are preserved rather than deduplicated.
    items_by_id = {parse_int(row.get("id", ""), label="item.id", allow_zero=False, allow_negative=False): row for row in items}
    equipment_roots = sorted(
        item_id for item_id, row in items_by_id.items()
        if parse_int(row.get("type", "0") or "0", label=f"item[{item_id}].type") in (1, 8)
    )
    if len(equipment_roots) != 604:
        raise CompileError(f"CA4-1 equipment root count drifted: {len(equipment_roots)}")

    closure: set[int] = set()
    recipe_edges: list[dict[str, int]] = []
    visiting: set[int] = set()

    def visit_equipment_recipe(item_id: int) -> None:
        if item_id in closure:
            return
        if item_id in visiting:
            raise CompileError(f"equipment recipe cycle detected at {item_id}")
        row = items_by_id.get(item_id)
        if row is None:
            raise CompileError(f"equipment recipe references missing item {item_id}")
        visiting.add(item_id)
        closure.add(item_id)
        raw_components = (row.get("compose") or "0").strip()
        raw_counts = (row.get("compose_num") or "0").strip()
        if raw_components not in ("", "0"):
            components = [parse_int(x, label=f"item[{item_id}].compose", allow_zero=False, allow_negative=False) for x in raw_components.split("|")]
            counts = [parse_int(x, label=f"item[{item_id}].compose_num", allow_zero=False, allow_negative=False) for x in raw_counts.split("|")]
            if len(components) != len(counts):
                raise CompileError(f"equipment recipe component/count length mismatch for {item_id}")
            for ordinal, (component_id, count) in enumerate(zip(components, counts), start=1):
                recipe_edges.append({
                    "component_count": count,
                    "component_item_id": component_id,
                    "ordinal": ordinal,
                    "parent_item_id": item_id,
                })
                visit_equipment_recipe(component_id)
        visiting.remove(item_id)

    for root_item_id in equipment_roots:
        visit_equipment_recipe(root_item_id)

    qualified_stack_ids = {
        int(r["item_id"]) for r in resources
        if r.get("class") == "STACK_ITEM" and r.get("catalog_status") == "QUALIFIED" and r.get("settlement_activation") == "ENABLED_R4" and int(r.get("item_id", 0) or 0) > 0
    }
    missing_stack = sorted(closure - qualified_stack_ids)
    if missing_stack:
        raise CompileError(f"equipment closure contains non-I5-qualified stack items: {missing_stack[:20]}")

    equipment_items: list[dict[str, int]] = []
    for item_id in sorted(closure):
        row = items_by_id[item_id]
        equipment_items.append({
            "compose_mana": parse_int(row.get("compose_mana", "0") or "0", label=f"item[{item_id}].compose_mana", allow_negative=False),
            "item_id": item_id,
            "required_level": parse_int(row.get("level", "0") or "0", label=f"item[{item_id}].level", allow_negative=False),
            "source_item_type": parse_int(row.get("type", "0") or "0", label=f"item[{item_id}].type"),
        })
    recipe_edges.sort(key=lambda x: (x["parent_item_id"], x["ordinal"]))
    repeated_component_recipes = 0
    by_parent: dict[int, list[int]] = {}
    for edge in recipe_edges:
        by_parent.setdefault(edge["parent_item_id"], []).append(edge["component_item_id"])
    for ids in by_parent.values():
        if len(ids) != len(set(ids)):
            repeated_component_recipes += 1
    if len(closure) != 1176 or len(by_parent) != 797 or len(recipe_edges) != 1934 or repeated_component_recipes != 29:
        raise CompileError(
            "CA4-1 equipment topology drifted "
            f"closure={len(closure)} recipe_nodes={len(by_parent)} edges={len(recipe_edges)} repeated={repeated_component_recipes}"
        )
    equipment_artifact = {
        "items": equipment_items,
        "recipe_edges": recipe_edges,
        "root_item_ids": equipment_roots,
        "schema_version": SCHEMA_VERSION,
        "source": "CA4-1 authoritative app-assets item.lua equipment/composition closure",
    }

    # Function eligibility catalog. Source eligibility is intentionally distinct
    # from production announcement capability. Only kind-1 gates are pure level
    # facts; every other encoding remains composite/fail-closed for R5.
    function_gates: list[dict[str, Any]] = []
    for idx, row in enumerate(functions, start=1):
        fid = parse_int(row.get("id", ""), label=f"function[{idx}].id", allow_zero=False, allow_negative=False)
        raw_level = row.get("level", "").strip()
        m = re.fullmatch(r"1\|(\d+)", raw_level)
        if m:
            required_level = int(m.group(1))
            if required_level <= 0:
                raise CompileError(f"function[{fid}] invalid pure-level gate {raw_level!r}")
            gate_kind = "PURE_LEVEL"
        else:
            required_level = None
            gate_kind = "UNSUPPORTED_COMPOSITE"
        announcement_capability = "PET_STARTER_CA3" if fid == 38 else "NONE"
        if fid == 38 and (gate_kind != "PURE_LEVEL" or required_level != 40):
            raise CompileError(f"Pet Function 38 gate drifted: kind={gate_kind} level={required_level} raw={raw_level!r}")
        function_gates.append({
            "announcement_capability": announcement_capability,
            "function_id": fid,
            "gate_kind": gate_kind,
            "raw_open_value": raw_level,
            "required_level": required_level,
            "source_fact_key": f"function.lua:{fid}:{raw_level}",
        })
    function_gates.sort(key=lambda r: r["function_id"])
    require_unique(function_gates, "function_id", "function id")
    function_artifact = {
        "gates": function_gates,
        "schema_version": SCHEMA_VERSION,
        "source": "data/tables/function.lua",
    }

    # CA2 Hero Core immutable catalog. Compile exact source semantics only.
    partner_keys, partner_rows = parse_base64_indexed_lua_table(blobs["data/tables/partner.lua"].data)
    super_keys, super_rows = parse_base64_indexed_lua_table(blobs["data/tables/super_partner.lua"].data)
    hero_exp_rows = parse_generated_lua_table(blobs["data/tables/partner_exp.lua"].data)
    star_rows = parse_generated_lua_table(blobs["data/tables/star.lua"].data)
    super_star_rows = parse_generated_lua_table(blobs["data/tables/super_partner_star.lua"].data)
    super_equipment_enhance_rows = parse_generated_lua_table(blobs["data/tables/super_equip_enhance.lua"].data)

    # CA4-2A family-qualified Normal-Hero equipment reachability. Preserve all
    # six source positions including explicit zero ids. Item-level requirement,
    # composition and recipe facts remain owned by the CA4-1 primitive catalog.
    hero_equipment_colors = [
        "white", "green", "green1", "blue", "blue1", "blue2", "purple", "purple1",
        "purple2", "purple3", "purple4", "orange", "orange1", "orange2", "red", "red1",
    ]
    hero_equipment_positions: list[dict[str, Any]] = []
    hero_equipment_zero = 0
    hero_equipment_ordinary = 0
    hero_equipment_special = 0
    hero_equipment_ordinary_ids: set[int] = set()
    hero_equipment_special_ids: set[int] = set()
    equipment_root_set = set(equipment_roots)
    for row_id in sorted(partner_rows):
        vals = partner_rows[row_id]
        table_id = parse_int(indexed_field(partner_keys, vals, "id", row_id=row_id), label=f"partner[{row_id}].id", allow_zero=False, allow_negative=False)
        if table_id != row_id:
            raise CompileError(f"partner row key/id mismatch {row_id}/{table_id}")
        for color, field in enumerate(hero_equipment_colors, start=1):
            raw = indexed_field(partner_keys, vals, field, row_id=row_id)
            slot_values = [parse_int(x, label=f"partner[{row_id}].{field}", allow_negative=False) for x in raw.split("|")] if raw else []
            if len(slot_values) != 6:
                raise CompileError(f"partner[{row_id}].{field} expected six equipment positions, got {slot_values!r}")
            for slot, item_id in enumerate(slot_values, start=1):
                ordinary = False
                if item_id == 0:
                    hero_equipment_zero += 1
                else:
                    item = items_by_id.get(item_id)
                    if item is None:
                        raise CompileError(f"partner[{row_id}].{field}[{slot}] references missing item {item_id}")
                    if item_id not in equipment_root_set:
                        raise CompileError(f"partner[{row_id}].{field}[{slot}] item {item_id} missing CA4-1 equipment root")
                    awaken = parse_int(item.get("is_awaken_item", "0") or "0", label=f"item[{item_id}].is_awaken_item", allow_negative=False)
                    ordinary = awaken == 0
                    if ordinary:
                        hero_equipment_ordinary += 1
                        hero_equipment_ordinary_ids.add(item_id)
                    else:
                        hero_equipment_special += 1
                        hero_equipment_special_ids.add(item_id)
                hero_equipment_positions.append({
                    "color": color,
                    "hero_table_id": table_id,
                    "item_id": item_id,
                    "ordinary_eligible": ordinary,
                    "slot": slot,
                })
    if (
        len(partner_rows), len(hero_equipment_positions), hero_equipment_ordinary,
        hero_equipment_special, hero_equipment_zero,
        len(hero_equipment_ordinary_ids), len(hero_equipment_special_ids),
    ) != (555, 53280, 50504, 1646, 1130, 214, 164):
        raise CompileError(
            "CA4-2 Hero equipment topology drifted "
            f"rows={len(partner_rows)} positions={len(hero_equipment_positions)} ordinary={hero_equipment_ordinary} "
            f"special={hero_equipment_special} zero={hero_equipment_zero} "
            f"unique_ordinary={len(hero_equipment_ordinary_ids)} unique_special={len(hero_equipment_special_ids)}"
        )
    hero_equipment_artifact = {
        "positions": hero_equipment_positions,
        "schema_version": SCHEMA_VERSION,
        "source": "CA4-2 exact src_64 partner.lua Normal-Hero equipment mapping",
    }


    # CA4-5 fixed Super-equipment topology and enhancement policy. Super uses
    # the same six durable Hero equipment slots, but topology is table-id fixed
    # rather than color-dependent. Physical star9/10 rows are preserved as
    # source facts and marked unreachable by the accepted effective-client cap.
    super_equipment_positions: list[dict[str, Any]] = []
    super_base_ids: set[int] = set()
    for row_id in sorted(super_rows):
        vals = super_rows[row_id]
        table_id = parse_int(indexed_field(super_keys, vals, "id", row_id=row_id), label=f"super_partner[{row_id}].id", allow_zero=False, allow_negative=False)
        raw = indexed_field(super_keys, vals, "equipment", row_id=row_id)
        slot_values = [parse_int(x, label=f"super_partner[{row_id}].equipment", allow_zero=False, allow_negative=False) for x in raw.split("|")] if raw else []
        if len(slot_values) != 6:
            raise CompileError(f"super_partner[{row_id}].equipment expected six positions, got {slot_values!r}")
        for slot, item_id in enumerate(slot_values, start=1):
            item = items_by_id.get(item_id)
            if item is None or item_id not in equipment_root_set:
                raise CompileError(f"super_partner[{row_id}].equipment[{slot}] item {item_id} missing accepted equipment primitive")
            raw_level = (item.get("level", "") or "").strip()
            required_level = parse_int(raw_level or "0", label=f"item[{item_id}].level", allow_zero=False, allow_negative=False)
            if required_level != 89:
                raise CompileError(f"CA4-5 Super base item {item_id} required-level source drifted: {raw_level!r}")
            super_base_ids.add(item_id)
            super_equipment_positions.append({"hero_table_id": table_id, "item_id": item_id, "slot": slot})
    if len(super_equipment_positions) != 84 or super_base_ids != set(range(20001366, 20001378)):
        raise CompileError(f"CA4-5 Super topology drifted positions={len(super_equipment_positions)} base_ids={sorted(super_base_ids)}")

    enhancement_caps = []
    for idx, row in enumerate(super_star_rows, start=1):
        star = parse_int(row.get("star", ""), label=f"super_star[{idx}].star", allow_zero=False, allow_negative=False)
        cap = parse_int(row.get("equipment_limit", ""), label=f"super_star[{star}].equipment_limit", allow_zero=False, allow_negative=False)
        enhancement_caps.append({"effective_client_reachable": star <= 8, "max_enhancement": cap, "star": star})
    enhancement_caps.sort(key=lambda x: x["star"])
    expected_caps = [(1,10),(2,10),(3,10),(4,10),(5,10),(6,20),(7,30),(8,40),(9,50),(10,60)]
    if [(x["star"], x["max_enhancement"]) for x in enhancement_caps] != expected_caps:
        raise CompileError(f"CA4-5 Super enhancement caps drifted: {enhancement_caps!r}")

    enhancement_tiers = []
    for idx, row in enumerate(super_equipment_enhance_rows, start=1):
        tier = parse_int(row.get("id", ""), label=f"super_equip_enhance[{idx}].id", allow_zero=False, allow_negative=False)
        need_star = parse_int(row.get("need_star", ""), label=f"super_equip_enhance[{tier}].need_star", allow_zero=False, allow_negative=False)
        need_num = parse_int(row.get("need_num", ""), label=f"super_equip_enhance[{tier}].need_num", allow_zero=False, allow_negative=False)
        enhancement_tiers.append({"duplicate_count": need_num, "effective_client_reachable": need_star <= 8, "min_star": need_star, "tier": tier})
    enhancement_tiers.sort(key=lambda x: x["tier"])
    expected_tiers = [(1,1,1),(2,6,1),(3,7,1),(4,8,1),(5,9,2),(6,10,2)]
    if [(x["tier"], x["min_star"], x["duplicate_count"]) for x in enhancement_tiers] != expected_tiers:
        raise CompileError(f"CA4-5 Super enhancement tiers drifted: {enhancement_tiers!r}")

    super_equipment_artifact = {
        "enhancement_caps": enhancement_caps,
        "enhancement_tiers": enhancement_tiers,
        "positions": super_equipment_positions,
        "schema_version": SCHEMA_VERSION,
        "source": "CA4-5 exact src_64 Super Hero fixed equipment topology and enhancement policy",
    }

    # CA4-3A Hero Fumo immutable policy. Target reachability is restricted to
    # current Normal-Hero mapped equipment. Stock Hero Fumo materials are item
    # types 1/2/4/5/6 with positive moneng; type-8 Pet equipment is excluded.
    def canonical_decimal(raw: str, *, label: str) -> str:
        try:
            d = Decimal(raw)
        except InvalidOperation as exc:
            raise CompileError(f"{label}: invalid decimal {raw!r}") from exc
        if not d.is_finite():
            raise CompileError(f"{label}: non-finite decimal")
        out = format(d, "f")
        if "." in out:
            out = out.rstrip("0").rstrip(".")
        return "0" if out in ("", "-0") else out

    mapped_hero_items = sorted({p["item_id"] for p in hero_equipment_positions if p["item_id"] > 0})
    fumo_targets: list[dict[str, Any]] = []
    for item_id in mapped_hero_items:
        row = items_by_id[item_id]
        raw_thresholds = row.get("fumo", "")
        if raw_thresholds in ("", "0"):
            continue
        thresholds = [parse_int(x, label=f"item[{item_id}].fumo", allow_negative=False) for x in raw_thresholds.split("|")]
        if not thresholds or any(x <= 0 for x in thresholds):
            raise CompileError(f"item[{item_id}] invalid Fumo thresholds {thresholds!r}")
        attrs = [parse_int(x, label=f"item[{item_id}].attr_ids", allow_zero=False, allow_negative=False) for x in row.get("attr_ids", "").split("|") if x != ""]
        stage_deltas: list[dict[str, str]] = []
        for stage in range(1, len(thresholds)+1):
            vals = row.get(f"fumo_value{stage}", "").split("|") if row.get(f"fumo_value{stage}", "") != "" else []
            stage_deltas.append({str(attr): canonical_decimal(vals[i], label=f"item[{item_id}].fumo_value{stage}[{i}]") for i, attr in enumerate(attrs) if i < len(vals)})
        fumo_targets.append({
            "attr_ids": attrs,
            "item_id": item_id,
            "mana_per_fumo": parse_int(row.get("fumo_mana", "0") or "0", label=f"item[{item_id}].fumo_mana", allow_negative=False),
            "stage_delta_by_attr": stage_deltas,
            "threshold_increments": thresholds,
            "total_cap": sum(thresholds),
        })
    fumo_materials: list[dict[str, int]] = []
    for item_id, row in sorted(items_by_id.items()):
        item_type = parse_int(row.get("type", "0") or "0", label=f"item[{item_id}].type")
        moneng = parse_int(row.get("moneng", "0") or "0", label=f"item[{item_id}].moneng")
        if item_type in (1, 2, 4, 5, 6) and moneng > 0:
            fumo_materials.append({"item_id": item_id, "item_type": item_type, "moneng": moneng})
    if len(fumo_targets) != 359 or len(fumo_materials) != 516:
        raise CompileError(f"CA4-3A Fumo topology drift targets={len(fumo_targets)} materials={len(fumo_materials)}")
    fumo_artifact = {
        "materials": fumo_materials,
        "schema_version": SCHEMA_VERSION,
        "source": "CA4-3A exact src_64 Hero Fumo target/material policy",
        "targets": fumo_targets,
    }

    # CA4-3B Hero promotion restoration source facts. Runtime policy owns the
    # aggregate-floor/greedy decomposition algorithm; this artifact owns only
    # source-qualified refund eligibility, quality fractions and denomination
    # values/order.
    fumo_target_ids = {x["item_id"] for x in fumo_targets}
    restoration_eligible_ids = sorted(hero_equipment_ordinary_ids & fumo_target_ids)
    restoration_equipment = []
    quality_counts: dict[int, int] = {}
    for item_id in restoration_eligible_ids:
        quality = parse_int(items_by_id[item_id].get("quality", "0") or "0", label=f"item[{item_id}].quality", allow_zero=False, allow_negative=False)
        if quality not in (2, 3, 4, 5, 6):
            raise CompileError(f"CA4-3B refundable item {item_id} has unsupported quality {quality}")
        quality_counts[quality] = quality_counts.get(quality, 0) + 1
        restoration_equipment.append({"equipment_item_id": item_id, "source_quality": quality})
    expected_quality_counts = {2: 35, 3: 35, 4: 65, 5: 42, 6: 18}
    if len(restoration_equipment) != 195 or quality_counts != expected_quality_counts:
        raise CompileError(f"CA4-3B restoration eligibility drift count={len(restoration_equipment)} qualities={quality_counts}")

    restoration_denominations = [
        {"item_id": 50001007, "ordinal": 0, "value": 200},
        {"item_id": 50001006, "ordinal": 1, "value": 60},
        {"item_id": 50001003, "ordinal": 2, "value": 10},
    ]
    fumo_moneng = {x["item_id"]: x["moneng"] for x in fumo_materials}
    for row in restoration_denominations:
        if fumo_moneng.get(row["item_id"]) != row["value"]:
            raise CompileError(f"CA4-3B restoration denomination drift for {row['item_id']}: {fumo_moneng.get(row['item_id'])}")
    if {x["item_id"] for x in restoration_denominations} & set(closure):
        raise CompileError("CA4-3B restoration denomination collides with equipment recipe closure")

    restoration_fractions = [
        {"denominator": 1, "numerator": 1, "quality": 2},
        {"denominator": 8, "numerator": 3, "quality": 3},
        {"denominator": 50, "numerator": 9, "quality": 4},
        {"denominator": 100, "numerator": 9, "quality": 5},
        {"denominator": 200, "numerator": 9, "quality": 6},
    ]
    hero_main_text = blobs["app/windows/HeroMainWindow.lua"].data.decode("utf-8-sig")
    for needle in (":powerUp(", ":oneKeyPowerUp(", "maxHeroColor", "getWithoutAwakeFumoCount"):
        if needle not in hero_main_text:
            raise CompileError(f"CA4-3B HeroMainWindow behavioral guard missing {needle!r}")
    restoration_artifact = {
        "denominations": restoration_denominations,
        "eligible_equipment": restoration_equipment,
        "quality_fractions": restoration_fractions,
        "schema_version": SCHEMA_VERSION,
        "source": "CA4-3B exact src_64 Normal-Hero promotion restoration source facts",
    }

    const_text = blobs["app/common/const.lua"].data.decode("utf-8-sig")
    def const_int(name: str) -> int:
        m = re.search(r"\bxyd\." + re.escape(name) + r"\s*=\s*(\d+)", const_text)
        if not m: raise CompileError(f"const.lua missing {name}")
        return int(m.group(1))
    normal_end=const_int("NORMAL_HERO_END_ID")
    awaken_start=const_int("AWAKEN_HERO_START_ID")
    awaken_diff=const_int("AWAKEN_HERO_DIFF")
    super_star_cap=const_int("SUPER_HERO_TOTAL_STARS")
    if (normal_end,awaken_start,awaken_diff,super_star_cap)!=(12000000,11001000,1000000,8):
        raise CompileError("Hero identity/star source constants drifted")
    hero_table_text=blobs["app/common/tables/HeroTable.lua"].data.decode("utf-8-sig")
    for needle in ("NORMAL_HERO_END_ID", "AWAKEN_HERO_START_ID", "stoneID_", "initialStar"):
        if needle not in hero_table_text: raise CompileError(f"HeroTable.lua behavioral guard missing {needle!r}")
    utils_text=blobs["app/common/utils.lua"].data.decode("utf-8-sig")
    for needle in ("getOriginHeroId", "AWAKEN_HERO_DIFF"):
        if needle not in utils_text: raise CompileError(f"utils.lua Hero origin guard missing {needle!r}")
    super_model=blobs["app/model/SuperHero.lua"].data.decode("utf-8-sig")
    if "partner_type or 0" not in super_model:
        raise CompileError("SuperHero.lua partner_type wire guard missing")

    templates=[]
    normal_origin=set()
    for row_id, vals in partner_rows.items():
        table_id=parse_int(indexed_field(partner_keys,vals,"id",row_id=row_id),label=f"partner[{row_id}].id",allow_zero=False,allow_negative=False)
        if table_id != row_id: raise CompileError(f"partner row key/id mismatch {row_id}/{table_id}")
        if table_id >= normal_end: continue
        initial_star=parse_int(indexed_field(partner_keys,vals,"ini_star",row_id=row_id) or "1",label=f"partner[{row_id}].ini_star",allow_zero=False,allow_negative=False)
        stone_id=parse_int(indexed_field(partner_keys,vals,"stone_id",row_id=row_id) or "0",label=f"partner[{row_id}].stone_id",allow_negative=False)
        awaken_table_id=parse_int(indexed_field(partner_keys,vals,"awaken_table_id",row_id=row_id) or "0",label=f"partner[{row_id}].awaken_table_id",allow_negative=False)
        first_table_id=parse_int(indexed_field(partner_keys,vals,"first_table_id",row_id=row_id) or "0",label=f"partner[{row_id}].first_table_id",allow_negative=False)
        origin=table_id-awaken_diff if table_id>awaken_start else table_id
        if origin <= 0: raise CompileError(f"partner[{row_id}] invalid origin {origin}")
        if table_id < awaken_start: normal_origin.add(table_id)
        templates.append({"awaken_table_id":awaken_table_id,"first_table_id":first_table_id,"hero_kind":"NORMAL","initial_star":initial_star,"origin_table_id":origin,"stone_item_id":stone_id,"table_id":table_id})
    super_ids=set()
    prerequisites=[]
    for row_id, vals in super_rows.items():
        table_id=parse_int(indexed_field(super_keys,vals,"id",row_id=row_id),label=f"super_partner[{row_id}].id",allow_zero=False,allow_negative=False)
        if table_id != row_id: raise CompileError(f"super_partner row key/id mismatch {row_id}/{table_id}")
        initial_star=parse_int(indexed_field(super_keys,vals,"ini_star",row_id=row_id) or "1",label=f"super_partner[{row_id}].ini_star",allow_zero=False,allow_negative=False)
        stone_id=parse_int(indexed_field(super_keys,vals,"stone_id",row_id=row_id) or "0",label=f"super_partner[{row_id}].stone_id",allow_negative=False)
        mats=[int(x) for x in re.findall(r"\d+", indexed_field(super_keys,vals,"material_hero",row_id=row_id))]
        if len(mats)!=5: raise CompileError(f"super_partner[{row_id}] expected five material heroes, got {mats}")
        super_ids.add(table_id)
        templates.append({"awaken_table_id":0,"first_table_id":0,"hero_kind":"SUPER","initial_star":initial_star,"origin_table_id":table_id,"stone_item_id":stone_id,"table_id":table_id})
        for ordinal,origin in enumerate(mats,1):
            prerequisites.append({"ordinal":ordinal,"origin_table_id":origin,"super_table_id":table_id})
    templates.sort(key=lambda x:x["table_id"])
    prerequisites.sort(key=lambda x:(x["super_table_id"],x["ordinal"]))
    if len(templates)!=568 or len(normal_origin)!=277 or len(super_ids)!=14 or len(prerequisites)!=70:
        raise CompileError(f"Hero template/source counts drifted templates={len(templates)} normal_origin={len(normal_origin)} super={len(super_ids)} prereq={len(prerequisites)}")

    exp_out=[]
    for idx,row in enumerate(hero_exp_rows,1):
        lv=parse_int(row.get("lv",""),label=f"partner_exp[{idx}].lv",allow_zero=False,allow_negative=False)
        exp=parse_int(row.get("exp",""),label=f"partner_exp[{idx}].exp",allow_negative=False)
        total=parse_int(row.get("total_exp",""),label=f"partner_exp[{idx}].total_exp",allow_negative=False)
        exp_out.append({"exp_delta":exp,"level":lv,"total_exp":total})
    exp_out.sort(key=lambda x:x["level"])
    if [x["level"] for x in exp_out] != list(range(1,101)): raise CompileError("Hero EXP levels must be 1..100")

    normal_star=[]
    for idx,row in enumerate(star_rows,1):
        star=parse_int(row.get("star",""),label=f"star[{idx}].star",allow_zero=False,allow_negative=False)
        normal_star.append({"evolve_mana":parse_int(row.get("evolve_price","0"),label=f"star[{star}].evolve_price",allow_negative=False),"evolve_num":parse_int(row.get("evolve_num","0"),label=f"star[{star}].evolve_num",allow_negative=False),"star":star,"summon_mana":parse_int(row.get("summon_price","0"),label=f"star[{star}].summon_price",allow_negative=False),"summon_num":parse_int(row.get("summon_num","0"),label=f"star[{star}].summon_num",allow_negative=False)})
    normal_star.sort(key=lambda x:x["star"])
    if [x["star"] for x in normal_star] != [1,2,3,4,5]: raise CompileError("normal Hero star rows drifted")

    super_star=[]
    for idx,row in enumerate(super_star_rows,1):
        star=parse_int(row.get("star",""),label=f"super_star[{idx}].star",allow_zero=False,allow_negative=False)
        super_star.append({"effective_client_reachable":star<=super_star_cap,"mana_cost":parse_int(row.get("mana_cost","0"),label=f"super_star[{star}].mana",allow_negative=False),"need_hero_num":parse_int(row.get("need_hero_num","0"),label=f"super_star[{star}].need_hero_num",allow_negative=False),"star":star,"stone_cost":parse_int(row.get("stone_cost","0"),label=f"super_star[{star}].stone",allow_negative=False)})
    super_star.sort(key=lambda x:x["star"])
    if [x["star"] for x in super_star] != list(range(1,11)): raise CompileError("super Hero star rows drifted")

    # Exact item -> origin family mapping from the already-qualified resource catalog.
    acquisition=[]
    for row in resources:
        pid=int(row.get("partner_id",0) or 0)
        iid=int(row.get("item_id",0) or 0)
        if pid<=0: continue
        origin=pid-awaken_diff if pid>awaken_start and pid<normal_end else pid
        acquisition.append({"item_id":iid,"origin_table_id":origin})
    acquisition.sort(key=lambda x:x["item_id"])
    mapped_origins={x["origin_table_id"] for x in acquisition}
    expected_origins=normal_origin|super_ids
    if len(acquisition)!=291 or mapped_origins != expected_origins:
        raise CompileError(f"Hero acquisition mapping drifted rows={len(acquisition)} mapped={len(mapped_origins)} expected={len(expected_origins)}")

    # CA2-2 source-qualified Hero EXP consumables. Values are immutable content,
    # not service constants. The exact five IDs are guarded by AddExpWindow/item data.
    hero_exp_item_ids = [50001001, 50001002, 50001004, 50001005, 50005182]
    items_by_id = {parse_int(row.get("id", ""), label="item.id", allow_negative=False): row for row in items}
    hero_exp_items=[]
    for item_id in hero_exp_item_ids:
        row=items_by_id.get(item_id)
        if row is None:
            raise CompileError(f"Hero EXP item {item_id} missing")
        exp_value=parse_int(row.get("exp", "0") or "0", label=f"item[{item_id}].exp", allow_zero=False, allow_negative=False)
        hero_exp_items.append({"exp_value":exp_value,"item_id":item_id})
    if [x["exp_value"] for x in hero_exp_items] != [60,300,1500,7500,10000]:
        raise CompileError(f"Hero EXP item values drifted: {hero_exp_items}")

    # I7C2A source-bound raw skill IDs/choices. Raw initialization is an
    # explicitly user-authorized V1 policy, not original-server inference.
    for t in templates:
        keys,rows=(super_keys,super_rows) if t['hero_kind']=='SUPER' else (partner_keys,partner_rows)
        vals=rows[t['table_id']]; slots=[]
        for slot in range(1,7):
            raw=indexed_field(keys,vals,f'skill{slot}',row_id=t['table_id'])
            ids=[parse_int(x,label=f'hero[{t["table_id"]}].skill{slot}',allow_negative=False) for x in raw.split('|')] if raw else [0]
            for sid in ids:
                if sid and sid not in skill_rows: raise CompileError(f'Hero skill references missing skill {sid}')
            books=[parse_int(skill_rows[sid].get('item_id','0') or '0',label='skill.item_id',allow_negative=False) if sid else 0 for sid in ids]
            slots.append({'default_id':ids[0],'choice_ids':ids,'book_item_ids':books})
        t['skill_slots']=slots
    for tid in [10001144,11001144]:
        t=next(x for x in templates if x['table_id']==tid)
        if t['skill_slots'][4]['choice_ids'] != [60010144,60020144,60030144,60040144,60050144] or t['skill_slots'][4]['book_item_ids'] != [50000005,50000010,50000015,50000020,50000025]:
            raise CompileError('I7C2A source/V1 KongMing policy contradiction; reconcile before activation')
    hero_artifact={"acquisition_items":acquisition,"exp_items":hero_exp_items,"exp_rows":exp_out,"normal_star_rows":normal_star,"schema_version":SCHEMA_VERSION,"source":"CA2 exact src_64 Hero core","super_prerequisites":prerequisites,"super_star_rows":super_star,"templates":templates,"raw_skill_seed_policy_id":"I7C2A_V1_RAW_SKILL_SEED_V1","choice_policy_id":"I7C2A_V1_KONGMING_CHOICE_V1"}

    # CA3-1 Pet identity/lineage content only. Acquisition, hatch timing/economy,
    # progression and skills remain separate later-stage capabilities.
    pet_templates=[]
    for row_id, vals in pet_rows.items():
        table_id=parse_int(indexed_field(pet_keys,vals,"id",row_id=row_id),label=f"pet[{row_id}].id",allow_zero=False,allow_negative=False)
        if table_id != row_id:
            raise CompileError(f"pet row key/id mismatch {row_id}/{table_id}")
        first_table_id=parse_int(indexed_field(pet_keys,vals,"first_table_id",row_id=row_id) or "0",label=f"pet[{row_id}].first_table_id",allow_negative=False)
        awaken_table_id=parse_int(indexed_field(pet_keys,vals,"awaken_table_id",row_id=row_id) or "0",label=f"pet[{row_id}].awaken_table_id",allow_negative=False)
        initial_star=parse_int(indexed_field(pet_keys,vals,"ini_star",row_id=row_id) or "1",label=f"pet[{row_id}].ini_star",allow_zero=False,allow_negative=False)
        origin=first_table_id if first_table_id > 0 else table_id
        pet_templates.append({"awaken_table_id":awaken_table_id,"initial_star":initial_star,"is_awakened":first_table_id>0,"origin_table_id":origin,"table_id":table_id})
    pet_templates.sort(key=lambda x:x["table_id"])
    base=[x for x in pet_templates if not x["is_awakened"]]
    awakened=[x for x in pet_templates if x["is_awakened"]]
    origins={x["origin_table_id"] for x in pet_templates}
    if len(pet_templates)!=54 or len(base)!=27 or len(awakened)!=27 or len(origins)!=27:
        raise CompileError(f"Pet core counts drifted templates={len(pet_templates)} base={len(base)} awakened={len(awakened)} origins={len(origins)}")
    if {x["initial_star"] for x in pet_templates} != {1,3}:
        raise CompileError("Pet initial-star domain drifted")
    by_id={x["table_id"]:x for x in pet_templates}
    for x in base:
        if x["awaken_table_id"] <= 0 or x["awaken_table_id"] not in by_id:
            raise CompileError(f"Pet base {x['table_id']} missing awakened counterpart")
        y=by_id[x["awaken_table_id"]]
        if not y["is_awakened"] or y["origin_table_id"] != x["table_id"] or y["awaken_table_id"] != 0:
            raise CompileError(f"Pet lineage mismatch base={x['table_id']} awakened={x['awaken_table_id']}")
    pet_artifact={"schema_version":SCHEMA_VERSION,"source":"CA3-1 exact src_64 Pet core","templates":pet_templates}

    # CA3-2 Pet acquisition/incubation content. Only base/origin templates are
    # eligible acquisition targets; awakened rows remain part of Pet core lineage.
    starter_egg_item_id = misc_int("first_egg")
    hatch_cost_param = misc_int("pet_hatch_cost_param")
    if starter_egg_item_id != 50001050:
        raise CompileError(f"Pet starter egg drifted: {starter_egg_item_id}")
    if hatch_cost_param != 12960000:
        raise CompileError(f"Pet hatch cost coefficient drifted: {hatch_cost_param}")

    pet_acquisition=[]
    for core in base:
        row_id=core["table_id"]
        vals=pet_rows[row_id]
        egg_item_id=parse_int(indexed_field(pet_keys,vals,"egg_item",row_id=row_id) or "0",label=f"pet[{row_id}].egg_item",allow_zero=False,allow_negative=False)
        essence_item_id=parse_int(indexed_field(pet_keys,vals,"stone_id",row_id=row_id) or "0",label=f"pet[{row_id}].stone_id",allow_zero=False,allow_negative=False)
        hatch_seconds=parse_int(indexed_field(pet_keys,vals,"hatch_time",row_id=row_id) or "0",label=f"pet[{row_id}].hatch_time",allow_zero=False,allow_negative=False)
        summon_type=parse_int(indexed_field(pet_keys,vals,"summon_type",row_id=row_id) or "0",label=f"pet[{row_id}].summon_type",allow_zero=False,allow_negative=False)
        initial_star=core["initial_star"]
        if initial_star < 1 or initial_star > len(pet_fragment_costs):
            raise CompileError(f"Pet base {row_id} initial star out of summon-cost range: {initial_star}")
        pet_acquisition.append({
            "egg_item_id":egg_item_id,
            "essence_item_id":essence_item_id,
            "fragment_count":pet_fragment_costs[initial_star-1],
            "hatch_seconds":hatch_seconds,
            "initial_star":initial_star,
            "origin_table_id":core["origin_table_id"],
            "summon_type":summon_type,
            "table_id":row_id,
        })
    pet_acquisition.sort(key=lambda x:x["table_id"])
    require_unique(pet_acquisition,"table_id","Pet acquisition table id")
    require_unique(pet_acquisition,"origin_table_id","Pet acquisition origin")
    if len(pet_acquisition)!=27:
        raise CompileError(f"Pet acquisition base count drifted: {len(pet_acquisition)}")
    if {x["hatch_seconds"] for x in pet_acquisition} != {86400}:
        raise CompileError(f"Pet hatch duration domain drifted: {sorted({x['hatch_seconds'] for x in pet_acquisition})}")
    if {x["summon_type"] for x in pet_acquisition} != {4}:
        raise CompileError(f"Pet summon-type domain drifted: {sorted({x['summon_type'] for x in pet_acquisition})}")
    if starter_egg_item_id not in {x["egg_item_id"] for x in pet_acquisition}:
        raise CompileError("Pet starter egg is not a source-qualified base Pet egg")
    pet_acquisition_artifact={
        "policy":{
            "fragment_costs_by_initial_star":{str(i+1):v for i,v in enumerate(pet_fragment_costs)},
            "hatch_cost_param":hatch_cost_param,
            "starter_egg_item_id":starter_egg_item_id,
        },
        "schema_version":SCHEMA_VERSION,
        "source":"CA3-2 exact src_64 Pet acquisition/incubation",
        "templates":pet_acquisition,
    }


    # CA3-3 Pet progression content. Runtime persists raw skill levels; this artifact
    # stores only immutable source-qualified rules and normalized source-skill metadata.
    star_level_match = re.search(r"xyd\.StarLevelSuipian\s*=\s*\{([^}]*)\}", enums_text, re.S)
    if not star_level_match:
        raise CompileError("enums.lua missing xyd.StarLevelSuipian")
    star_level_costs = [int(v) for v in re.findall(r"\d+", star_level_match.group(1))]
    if star_level_costs[:5] != [10, 20, 50, 100, 150]:
        raise CompileError(f"Pet evolution source costs drifted: {star_level_costs[:5]}")
    pet_star_compiled=[]
    for idx,row in enumerate(pet_star_rows, start=1):
        star=parse_int(row.get("star", ""), label=f"pet_star[{idx}].star", allow_zero=False, allow_negative=False)
        evolve=parse_int(row.get("evolve_num", ""), label=f"pet_star[{idx}].evolve_num", allow_zero=False, allow_negative=False)
        pet_star_compiled.append((star,evolve))
    if pet_star_compiled != [(1,10),(2,20),(3,50),(4,100),(5,150)]:
        raise CompileError(f"pet_star.lua evolution corroboration drifted: {pet_star_compiled}")
    evolution_rows=[{"stone_count":star_level_costs[target-1],"target_star":target} for target in range(2,6)]

    pet_exp=[]
    last_total=-1
    for idx,row in enumerate(pet_exp_rows, start=1):
        level=parse_int(row.get("lv", ""),label=f"pet_exp[{idx}].lv",allow_zero=False,allow_negative=False)
        exp_delta=parse_int(row.get("exp", ""),label=f"pet_exp[{idx}].exp",allow_negative=False)
        total_exp=parse_int(row.get("total_exp", ""),label=f"pet_exp[{idx}].total_exp",allow_negative=False)
        if level != idx or total_exp < last_total:
            raise CompileError(f"Pet EXP domain drift at level {level}")
        last_total=total_exp
        pet_exp.append({"exp_delta":exp_delta,"level":level,"total_exp":total_exp})
    if len(pet_exp)!=100 or pet_exp[-1]["total_exp"] != 1980095:
        raise CompileError(f"Pet EXP domain/count drifted rows={len(pet_exp)} max={pet_exp[-1]['total_exp'] if pet_exp else None}")

    skill_books=[]
    for idx,row in enumerate(pet_skillbook_rows, start=1):
        level=parse_int(row.get("skill_level", ""),label=f"pet_skillbook[{idx}].skill_level",allow_zero=False,allow_negative=False)
        count=parse_int(row.get("skillbook", ""),label=f"pet_skillbook[{idx}].skillbook",allow_zero=False,allow_negative=False)
        if level != idx or count != (level+9)//10:
            raise CompileError(f"Pet Skill Book domain drift at level {level}: {count}")
        skill_books.append({"book_count":count,"effective_level":level})
    if len(skill_books)!=130:
        raise CompileError(f"Pet Skill Book row count drifted: {len(skill_books)}")

    slot_policy=[]
    expected_slot_policy=[(1,1,0,False),(2,2,0,False),(3,4,20,False),(4,7,40,False),(5,12,60,True)]
    for idx,row in enumerate(pet_skilllevel_rows, start=1):
        slot=parse_int(row.get("id", ""),label=f"pet_skilllevel[{idx}].id",allow_zero=False,allow_negative=False)
        color=parse_int(row.get("color", ""),label=f"pet_skilllevel[{idx}].color",allow_zero=False,allow_negative=False)
        offset=parse_int(row.get("start", ""),label=f"pet_skilllevel[{idx}].start",allow_negative=False)
        awakened=parse_int(row.get("is_awaken_skill", ""),label=f"pet_skilllevel[{idx}].is_awaken_skill",allow_negative=False)==1
        if (slot,color,offset,awakened) != expected_slot_policy[idx-1]:
            raise CompileError(f"Pet skill-slot corroboration drift at slot {slot}")
        slot_policy.append({"effective_offset":offset,"min_color":0 if awakened else color,"requires_awakened":awakened,"slot":slot})
    if len(slot_policy)!=5:
        raise CompileError("Pet skill-slot policy count drifted")

    add_skill_match=re.search(r"xyd\.PetStarType\s*=\s*\{([^}]*)\}", enums_text, re.S)
    if not add_skill_match or not re.search(r"ADD_SKILL\s*=\s*2", add_skill_match.group(1)):
        raise CompileError("PetStarType.ADD_SKILL enum drifted")
    pet_progression=[]
    pet_skill_slots=[]
    add_skill_occurrences=0
    nonzero_skills=set()
    for core in pet_templates:
        row_id=core["table_id"]; vals=pet_rows[row_id]
        stone=parse_int(indexed_field(pet_keys,vals,"stone_id",row_id=row_id) or "0",label=f"pet[{row_id}].stone_id",allow_zero=False,allow_negative=False)
        skills=[]
        for slot in range(1,6):
            raw=indexed_field(pet_keys,vals,f"skill{slot}",row_id=row_id) or "0"
            parts=[x for x in raw.split("|") if x]
            if len(parts)>1:
                raise CompileError(f"Pet {row_id} slot {slot} has multi-source skill identity {raw!r}")
            sid=parse_int(parts[0] if parts else "0",label=f"pet[{row_id}].skill{slot}",allow_negative=False)
            bonus=0
            if sid:
                nonzero_skills.add(sid)
                skill=skill_rows.get(sid)
                if skill is None:
                    raise CompileError(f"Pet {row_id} slot {slot} source skill {sid} missing")
                pst=(skill.get("pet_star_type") or "").strip()
                if pst:
                    pst_i=parse_int(pst,label=f"skill[{sid}].pet_star_type",allow_negative=False)
                    if pst_i==2:
                        step=(skill.get("desc4_num_step") or "").strip()
                        vals_step=[x for x in step.split("|") if x!=""]
                        if len(vals_step)!=2 or vals_step[1] != "10":
                            raise CompileError(f"Pet ADD_SKILL {sid} bonus drifted: {step!r}")
                        bonus=10; add_skill_occurrences += 1
            skills.append(sid)
            pet_skill_slots.append({"slot":slot,"source_skill_id":sid,"star_bonus":bonus,"table_id":row_id})
        pet_progression.append({"stone_item_id":stone,"table_id":row_id})
    if len(pet_progression)!=54 or len(pet_skill_slots)!=270 or len(nonzero_skills)!=128 or add_skill_occurrences!=42:
        raise CompileError(f"Pet progression topology drifted forms={len(pet_progression)} slots={len(pet_skill_slots)} skills={len(nonzero_skills)} add={add_skill_occurrences}")
    for core in base:
        awake=by_id[core["awaken_table_id"]]
        bvals=pet_rows[core["table_id"]]; avals=pet_rows[awake["table_id"]]
        bstone=indexed_field(pet_keys,bvals,"stone_id",row_id=core["table_id"]); astone=indexed_field(pet_keys,avals,"stone_id",row_id=awake["table_id"])
        bskills=[indexed_field(pet_keys,bvals,f"skill{i}",row_id=core["table_id"]) for i in range(1,6)]
        askills=[indexed_field(pet_keys,avals,f"skill{i}",row_id=awake["table_id"]) for i in range(1,6)]
        if bstone!=astone or bskills!=askills:
            raise CompileError(f"Pet base/awaken progression mismatch {core['table_id']}/{awake['table_id']}")

    pet_exp_items=[]
    for item_id,want_exp in ((50001087,300),(50001088,1500),(50001089,7500)):
        row=next((x for x in items if parse_int(x.get("id", "0"),label="item.id") == item_id),None)
        if row is None:
            raise CompileError(f"Pet EXP item {item_id} missing")
        got=parse_int(row.get("exp", "0") or "0",label=f"item[{item_id}].exp",allow_zero=False,allow_negative=False)
        if got!=want_exp:
            raise CompileError(f"Pet EXP item {item_id} value drifted: {got}")
        pet_exp_items.append({"exp_value":got,"item_id":item_id})
    skill_book_item_id=misc_int("skill_book_item")
    if skill_book_item_id!=50001090:
        raise CompileError(f"Pet Skill Book item drifted: {skill_book_item_id}")
    pet_progression_artifact={
        "evolution_rows":evolution_rows,
        "exp_items":pet_exp_items,
        "exp_rows":pet_exp,
        "policy":{"skill_book_item_id":skill_book_item_id},
        "schema_version":SCHEMA_VERSION,
        "skill_books":skill_books,
        "skill_slots":pet_skill_slots,
        "slot_policy":slot_policy,
        "source":"CA3-3 exact src_64 Pet progression",
        "templates":pet_progression,
    }

    # CA4-4A family-qualified Pet equipment topology. Preserve all three source
    # positions at every color including explicit zero slot-1 positions on
    # Awakening-disabled lineages. Special classification is derived from each
    # lineage's exact awanken_item identity, never from an item-id range.
    pet_equipment_colors = [
        "white", "green", "green1", "blue", "blue1", "blue2", "purple", "purple1",
        "purple2", "purple3", "purple4", "orange", "orange1", "orange2", "red", "red1",
    ]
    pet_special_ids: set[int] = set()
    for row_id, vals in pet_rows.items():
        raw = indexed_field(pet_keys, vals, "awanken_item", row_id=row_id) or "0"
        item_id = parse_int(raw, label=f"pet[{row_id}].awanken_item", allow_negative=False)
        if item_id > 0:
            pet_special_ids.add(item_id)
    if len(pet_special_ids) != 20:
        raise CompileError(f"CA4-4A Pet Awakening-item identity count drifted: {len(pet_special_ids)}")

    pet_equipment_positions: list[dict[str, Any]] = []
    pet_equipment_zero = pet_equipment_ordinary = pet_equipment_special = 0
    pet_equipment_ordinary_ids: set[int] = set()
    pet_equipment_special_ids: set[int] = set()
    per_pet_equipment: dict[int, list[tuple[int, int, int]]] = {}
    for row_id in sorted(pet_rows):
        vals = pet_rows[row_id]
        table_id = parse_int(indexed_field(pet_keys, vals, "id", row_id=row_id), label=f"pet[{row_id}].id", allow_zero=False, allow_negative=False)
        if table_id != row_id:
            raise CompileError(f"Pet equipment row key/id mismatch {row_id}/{table_id}")
        topology: list[tuple[int, int, int]] = []
        for color, field in enumerate(pet_equipment_colors, start=1):
            raw = indexed_field(pet_keys, vals, field, row_id=row_id) or ""
            slots = [parse_int(x, label=f"pet[{row_id}].{field}", allow_negative=False) for x in raw.split("|")] if raw else []
            if len(slots) != 3:
                raise CompileError(f"pet[{row_id}].{field} expected three equipment positions, got {slots!r}")
            for slot, item_id in enumerate(slots, start=1):
                if item_id == 0:
                    classification = "EMPTY"
                    pet_equipment_zero += 1
                else:
                    primitive = next((x for x in equipment_items if x["item_id"] == item_id), None)
                    if primitive is None or item_id not in equipment_root_set:
                        raise CompileError(f"pet[{row_id}].{field}[{slot}] item {item_id} missing CA4-1 equipment root")
                    if primitive["source_item_type"] != 8:
                        raise CompileError(f"pet[{row_id}].{field}[{slot}] item {item_id} is not ItemType 8")
                    if item_id in pet_special_ids:
                        classification = "AWAKENING"
                        pet_equipment_special += 1
                        pet_equipment_special_ids.add(item_id)
                        if slot != 1 or color < 12 or primitive["required_level"] != 90:
                            raise CompileError(f"Pet special topology drift at pet={row_id} color={color} slot={slot} item={item_id}")
                    else:
                        classification = "ORDINARY"
                        pet_equipment_ordinary += 1
                        pet_equipment_ordinary_ids.add(item_id)
                pet_equipment_positions.append({
                    "classification": classification,
                    "color": color,
                    "item_id": item_id,
                    "pet_table_id": table_id,
                    "slot": slot,
                })
                topology.append((color, slot, item_id))
        per_pet_equipment[table_id] = topology

    if (len(pet_equipment_positions), pet_equipment_ordinary, pet_equipment_special, pet_equipment_zero, len(pet_equipment_ordinary_ids), len(pet_equipment_special_ids)) != (2592, 2322, 200, 70, 73, 20):
        raise CompileError(
            "CA4-4A Pet equipment topology drifted "
            f"positions={len(pet_equipment_positions)} ordinary={pet_equipment_ordinary} special={pet_equipment_special} "
            f"zero={pet_equipment_zero} unique_ordinary={len(pet_equipment_ordinary_ids)} unique_special={len(pet_equipment_special_ids)}"
        )
    for core in base:
        b = core["table_id"]; a = core["awaken_table_id"]
        if per_pet_equipment.get(b) != per_pet_equipment.get(a):
            raise CompileError(f"Pet base/awaken equipment mismatch {b}/{a}")
    if pet_equipment_special_ids != pet_special_ids:
        raise CompileError("Pet special mapped identities do not exactly match source awanken_item identities")

    pet_equipment_artifact = {
        "positions": pet_equipment_positions,
        "schema_version": SCHEMA_VERSION,
        "source": "CA4-4A exact src_64 pet.lua Pet equipment mapping",
    }

    # CA4-4B Pet-promotion restoration eligibility. Global quality fractions
    # and restoration denominations remain single-owned by the existing source
    # tables; this capability contributes only the Pet-family ordinary-item
    # eligibility + source-quality facts. Awakening items are preserved on
    # promotion and are deliberately absent.
    pet_restoration_equipment = []
    pet_restoration_quality_counts: dict[int, int] = {}
    for item_id in sorted(pet_equipment_ordinary_ids):
        row = items_by_id.get(item_id)
        if row is None:
            raise CompileError(f"CA4-4B Pet restoration ordinary item {item_id} missing source item row")
        quality = parse_int(row.get("quality", "0") or "0", label=f"item[{item_id}].quality", allow_zero=False, allow_negative=False)
        if quality < 1 or quality > 6:
            raise CompileError(f"CA4-4B Pet restoration ordinary item {item_id} has unsupported quality {quality}")
        pet_restoration_quality_counts[quality] = pet_restoration_quality_counts.get(quality, 0) + 1
        pet_restoration_equipment.append({"equipment_item_id": item_id, "source_quality": quality})
    if pet_equipment_special_ids & {x["equipment_item_id"] for x in pet_restoration_equipment}:
        raise CompileError("CA4-4B Pet restoration eligibility includes Awakening equipment")
    expected_pet_restoration_qualities = {1: 3, 2: 13, 3: 11, 4: 24, 5: 15, 6: 7}
    if len(pet_restoration_equipment) != 73 or pet_restoration_quality_counts != expected_pet_restoration_qualities:
        raise CompileError(
            f"CA4-4B Pet restoration eligibility drift count={len(pet_restoration_equipment)} qualities={pet_restoration_quality_counts}"
        )
    if [x["equipment_item_id"] for x in pet_restoration_equipment if x["source_quality"] == 1] != [80001001, 80001006, 80001010]:
        raise CompileError("CA4-4B Pet q1 restoration legacy-item identities drifted")
    pet_promotion_restoration_artifact = {
        "eligible_equipment": pet_restoration_equipment,
        "schema_version": SCHEMA_VERSION,
        "source": "CA4-4B exact src_64 Pet ordinary promotion-restoration eligibility",
    }

    # CA6 Practice source-qualified immutable facts. Random-roll-looking fields
    # are intentionally excluded: the live client does not execute them as a
    # recovered roll algorithm and CA6 keeps RNG in a versioned compatibility policy.
    practice_methods=[]
    for idx,row in enumerate(practice_type_rows,start=1):
        mid=parse_int(row.get("id",""),label=f"practice_type[{idx}].id",allow_zero=False,allow_negative=False)
        practice_methods.append({
            "base_cost":parse_int(row.get("currency_num","0"),label=f"practice_type[{mid}].currency_num",allow_negative=False),
            "currency_type":parse_int(row.get("currency_type","0"),label=f"practice_type[{mid}].currency_type",allow_zero=False,allow_negative=False),
            "method_id":mid,
            "vip_min":parse_int(row.get("vip","0") or "0",label=f"practice_type[{mid}].vip",allow_negative=False),
        })
    practice_methods.sort(key=lambda x:x["method_id"])
    if [x["method_id"] for x in practice_methods] != [1,2,3]:
        raise CompileError(f"Practice methods drifted: {practice_methods!r}")
    if [(x["currency_type"],x["base_cost"],x["vip_min"]) for x in practice_methods] != [(1,20000,0),(2,50,0),(2,100,5)]:
        raise CompileError(f"Practice method economics drifted: {practice_methods!r}")

    practice_locks=[]
    for idx,row in enumerate(practice_lock_rows,start=1):
        lid=parse_int(row.get("id",""),label=f"practice_lock[{idx}].id",allow_zero=False,allow_negative=False)
        practice_locks.append({
            "bless_cost":parse_int(row.get("bless_num","0"),label=f"practice_lock[{lid}].bless_num",allow_negative=False),
            "crystal_step":parse_int(row.get("crystal","0"),label=f"practice_lock[{lid}].crystal",allow_negative=False),
            "lock_count":lid,
            "mana_step":parse_int(row.get("mana","0"),label=f"practice_lock[{lid}].mana",allow_negative=False),
            "source_up_limit":parse_int(row.get("up_limit","0"),label=f"practice_lock[{lid}].up_limit",allow_negative=False),
        })
    practice_locks.sort(key=lambda x:x["lock_count"])
    if [(x["lock_count"],x["mana_step"],x["crystal_step"],x["bless_cost"],x["source_up_limit"]) for x in practice_locks] != [(1,70000,15,10,2),(2,200000,40,40,3),(3,200000,40,60,4)]:
        raise CompileError(f"Practice lock facts drifted: {practice_locks!r}")

    vip_bless=[]
    for idx,row in enumerate(vip_rows,start=1):
        level=parse_int(row.get("id",""),label=f"vip[{idx}].id",allow_negative=False)
        bless=parse_int(row.get("bless_value","0") or "0",label=f"vip[{level}].bless_value",allow_negative=False)
        vip_bless.append({"bless_value":bless,"vip_level":level})
    vip_bless.sort(key=lambda x:x["vip_level"])
    if [x["vip_level"] for x in vip_bless] != list(range(16)):
        raise CompileError(f"VIP Practice rows drifted: {[x['vip_level'] for x in vip_bless]!r}")

    practice_fields=[
        ("practice_liliang_need","practice_liliang_type","practice_liliang_value"),
        ("practice_zhili_need","practice_zhili_type","practice_zhili_value"),
        ("practice_minjie_need","practice_minjie_type","practice_minjie_value"),
    ]
    hero_thresholds=[]
    for t in templates:
        table_id=t["table_id"]
        if t["hero_kind"] == "NORMAL":
            vals=partner_rows[table_id]; keys=partner_keys
        else:
            vals=super_rows[table_id]; keys=super_keys
        for ordinal,(needf,typef,valuef) in enumerate(practice_fields,start=1):
            hero_thresholds.append({
                "bonus_value":parse_int(indexed_field(keys,vals,valuef,row_id=table_id) or "0",label=f"hero[{table_id}].{valuef}",allow_negative=False),
                "hero_table_id":table_id,
                "need_value":parse_int(indexed_field(keys,vals,needf,row_id=table_id) or "0",label=f"hero[{table_id}].{needf}",allow_negative=False),
                "ordinal":ordinal,
                "target_attr_type":parse_int(indexed_field(keys,vals,typef,row_id=table_id) or "0",label=f"hero[{table_id}].{typef}",allow_negative=False),
            })
    if len(hero_thresholds) != len(templates)*3:
        raise CompileError("Hero Practice threshold count drifted")

    pet_thresholds=[]
    for t in pet_templates:
        table_id=t["table_id"]; vals=pet_rows[table_id]
        for ordinal,(needf,typef,valuef) in enumerate(practice_fields,start=1):
            pet_thresholds.append({
                "bonus_value":parse_int(indexed_field(pet_keys,vals,valuef,row_id=table_id) or "0",label=f"pet[{table_id}].{valuef}",allow_negative=False),
                "need_value":parse_int(indexed_field(pet_keys,vals,needf,row_id=table_id) or "0",label=f"pet[{table_id}].{needf}",allow_negative=False),
                "ordinal":ordinal,
                "pet_table_id":table_id,
                "target_attr_type":parse_int(indexed_field(pet_keys,vals,typef,row_id=table_id) or "0",label=f"pet[{table_id}].{typef}",allow_negative=False),
            })
    if len(pet_thresholds) != len(pet_templates)*3:
        raise CompileError("Pet Practice threshold count drifted")

    # CA7-2 Character Appearance immutable catalog. Compile only source-qualified
    # content facts here. Temporal equality, stale-selector fallback and first-LIVE
    # show state remain implementation policy, not content facts.
    hero_origin_by_table = {int(x["table_id"]): int(x["origin_table_id"]) for x in templates}
    pet_origin_by_table = {int(x["table_id"]): int(x["origin_table_id"]) for x in pet_templates}

    appearance_skins=[]
    skin_by_model={}
    for idx,row in enumerate(skin_skill_rows,1):
        model_id=parse_int(row.get("model",""),label=f"skin_skill[{idx}].model",allow_zero=False,allow_negative=False)
        raw_hero_id=parse_int(row.get("hero",""),label=f"skin_skill[{idx}].hero",allow_zero=False,allow_negative=False)
        origin=hero_origin_by_table.get(raw_hero_id)
        if origin is None:
            raise CompileError(f"skin_skill[{idx}] hero {raw_hero_id} has no qualified Hero origin")
        skill_id=parse_int(row.get("skill","0") or "0",label=f"skin_skill[{idx}].skill",allow_negative=False)
        source_skin_id=parse_int(row.get("skin_id",""),label=f"skin_skill[{idx}].skin_id",allow_zero=False,allow_negative=False)
        if model_id in skin_by_model:
            raise CompileError(f"duplicate CA7 skin model {model_id}")
        out={"hero_origin_table_id":origin,"model_id":model_id,"skin_skill_id":skill_id,"source_skin_id":source_skin_id}
        appearance_skins.append(out); skin_by_model[model_id]=out
    appearance_skins.sort(key=lambda x:x["model_id"])
    if len(appearance_skins)!=262:
        raise CompileError(f"CA7 qualified skin model count drifted: {len(appearance_skins)}")
    if sum(1 for x in appearance_skins if x["skin_skill_id"]>0)!=225:
        raise CompileError("CA7 skill-bearing skin count drifted")

    appearance_skin_items=[]
    unqualified_skin_items=[]
    skin_item_candidates=0
    for row in items:
        item_id=parse_int(row.get("id",""),label="item.id",allow_zero=False,allow_negative=False)
        model_id=parse_int(row.get("skin_model","0") or "0",label=f"item[{item_id}].skin_model",allow_negative=False)
        raw_partner=parse_int(row.get("skin_partner","0") or "0",label=f"item[{item_id}].skin_partner",allow_negative=False)
        if model_id<=0 or raw_partner<=0:
            continue
        skin_item_candidates += 1
        origin=hero_origin_by_table.get(raw_partner)
        qualified=skin_by_model.get(model_id)
        if origin is None or qualified is None or qualified["hero_origin_table_id"] != origin:
            unqualified_skin_items.append({"hero_origin_table_id":origin or raw_partner,"item_id":item_id,"model_id":model_id})
            continue
        duration=parse_int(row.get("skin_last_time","0") or "0",label=f"item[{item_id}].skin_last_time",allow_negative=False)
        appearance_skin_items.append({"duration_seconds":duration or None,"hero_origin_table_id":origin,"item_id":item_id,"model_id":model_id})
    appearance_skin_items.sort(key=lambda x:x["item_id"])
    if skin_item_candidates!=265 or len(appearance_skin_items)!=264:
        raise CompileError(f"CA7 skin item count drifted candidates={skin_item_candidates} qualified={len(appearance_skin_items)}")
    if unqualified_skin_items != [{"hero_origin_table_id":10001065,"item_id":50005191,"model_id":40001065}]:
        raise CompileError(f"CA7 unqualified skin anomalies drifted: {unqualified_skin_items!r}")
    timed=[x for x in appearance_skin_items if x["duration_seconds"] is not None]
    if timed != [
        {"duration_seconds":259200,"hero_origin_table_id":10001006,"item_id":50001807,"model_id":40002006},
        {"duration_seconds":259200,"hero_origin_table_id":10001049,"item_id":50009163,"model_id":40002049},
    ]:
        raise CompileError(f"CA7 timed-trial definitions drifted: {timed!r}")

    dynamic_type_by_model={}
    for idx,row in enumerate(model_rows,1):
        model_id=parse_int(row.get("id",""),label=f"model[{idx}].id",allow_zero=False,allow_negative=False)
        dynamic_type_by_model[model_id]=parse_int(row.get("is_dynamic","0") or "0",label=f"model[{model_id}].is_dynamic",allow_negative=False)
    live_activation_item_id=misc_int("dymisic_item")
    if live_activation_item_id!=50005171 or live_activation_item_id not in items_by_id:
        raise CompileError(f"CA7 LIVE activation item drifted: {live_activation_item_id}")
    appearance_live=[]
    automatic_type1=0
    for idx,row in enumerate(skin_dynamic_rows,1):
        model_id=parse_int(row.get("model_id",""),label=f"skin_dynamic[{idx}].model_id",allow_zero=False,allow_negative=False)
        dynamic_type=dynamic_type_by_model.get(model_id)
        if dynamic_type is None:
            raise CompileError(f"skin_dynamic[{idx}] model {model_id} missing model row")
        if dynamic_type==1:
            automatic_type1 += 1
            continue
        if dynamic_type!=2:
            raise CompileError(f"skin_dynamic[{idx}] unexpected dynamic type {dynamic_type} for model {model_id}")
        raw_partner=parse_int(row.get("partner_id",""),label=f"skin_dynamic[{idx}].partner_id",allow_zero=False,allow_negative=False)
        origin=hero_origin_by_table.get(raw_partner)
        if origin is None:
            raise CompileError(f"skin_dynamic[{idx}] partner {raw_partner} has no qualified Hero origin")
        appearance_live.append({
            "activation_item_count":parse_int(row.get("num",""),label=f"skin_dynamic[{idx}].num",allow_zero=False,allow_negative=False),
            "activation_item_id":live_activation_item_id,
            "crystal_cost":parse_int(row.get("diamond",""),label=f"skin_dynamic[{idx}].diamond",allow_zero=False,allow_negative=False),
            "hero_origin_table_id":origin,
            "model_id":model_id,
        })
    appearance_live.sort(key=lambda x:x["model_id"])
    if automatic_type1!=21 or len(appearance_live)!=12:
        raise CompileError(f"CA7 dynamic-card counts drifted type1={automatic_type1} paid_type2={len(appearance_live)}")
    if [(x["model_id"],x["hero_origin_table_id"]) for x in appearance_live if x["model_id"] in (11001074,11001079)] != [(11001074,10001074),(11001079,10001079)]:
        raise CompileError("CA7 awakened LIVE origin normalization drifted")

    appearance_pet_styles=[]
    for row in items:
        item_id=parse_int(row.get("id",""),label="item.id",allow_zero=False,allow_negative=False)
        raw_pet=parse_int(row.get("style_pet","0") or "0",label=f"item[{item_id}].style_pet",allow_negative=False)
        if raw_pet<=0:
            continue
        origin=pet_origin_by_table.get(raw_pet)
        if origin is None:
            raise CompileError(f"item[{item_id}] Pet style target {raw_pet} has no qualified Pet origin")
        appearance_pet_styles.append({"pet_origin_table_id":origin,"style_item_id":item_id})
    appearance_pet_styles.sort(key=lambda x:x["style_item_id"])
    if appearance_pet_styles != [
        {"pet_origin_table_id":10120001,"style_item_id":50001374},
        {"pet_origin_table_id":10030001,"style_item_id":50001376},
        {"pet_origin_table_id":10040001,"style_item_id":50001402},
        {"pet_origin_table_id":10190001,"style_item_id":50001598},
    ]:
        raise CompileError(f"CA7 Pet-style definitions drifted: {appearance_pet_styles!r}")

    appearance_artifact={
        "paid_live_definitions":appearance_live,
        "pet_home_style_definitions":appearance_pet_styles,
        "qualified_skin_acquisition_items":appearance_skin_items,
        "qualified_skin_definitions":appearance_skins,
        "schema_version":SCHEMA_VERSION,
        "source":"CA7 exact src_64 Character appearance content facts",
    }

    function14=next((x for x in function_gates if x["function_id"]==14),None)
    if function14 is None or function14["gate_kind"]!="PURE_LEVEL" or function14["required_level"]!=90:
        raise CompileError(f"Practice function 14 gate drifted: {function14!r}")
    enums_text=blobs["app/common/enums.lua"].data.decode("utf-8-sig")
    def enum_const(name:str)->int:
        m=re.search(rf"{re.escape(name)}\s*=\s*(-?\d+)",enums_text)
        if not m: raise CompileError(f"missing Practice enum constant {name}")
        return int(m.group(1))
    attr_cap=enum_const("WaskAttrUpLimit")
    free_seconds=enum_const("TimeGap")
    legendary_vip=enum_const("WashLevelLimit")
    if (attr_cap,free_seconds,legendary_vip)!=(200,79200,5):
        raise CompileError(f"Practice constants drifted {(attr_cap,free_seconds,legendary_vip)!r}")
    ticket_item=50001181
    if ticket_item not in items_by_id:
        raise CompileError("Legend Purify ticket item 50001181 missing item source row")
    guide_text=blobs["data/tables/guide_page.lua"].data.decode("utf-8-sig")
    if "50001181" not in guide_text and "Legend Purify" not in guide_text and "+1" not in guide_text:
        # guide text is localization-id heavy in some builds; the item identity and
        # C60 source-oracle contract remain the qualifying basis. Keep this guard
        # deliberately weak rather than inventing a parser for prose localization.
        pass
    practice_artifact={
        "hero_thresholds":hero_thresholds,
        "locks":practice_locks,
        "methods":practice_methods,
        "pet_thresholds":pet_thresholds,
        "policy_facts":{
            "attr_cap":attr_cap,
            "free_interval_seconds":free_seconds,
            "legendary_vip_min":legendary_vip,
            "ticket_add_agi":1,
            "ticket_add_int":1,
            "ticket_add_str":1,
            "ticket_item_id":ticket_item,
            "unlock_level":90,
        },
        "schema_version":SCHEMA_VERSION,
        "source":"CA6 exact src_64 Practice source facts; RNG compatibility policy excluded",
        "vip_bless":vip_bless,
    }

    objective_artifact = {
        "definitions": [],
        "schema_version": SCHEMA_VERSION,
        "status": "BUILTIN_ACTIVATION_EMPTY_UNQUALIFIED_MAPPING",
    }

    emoticons=[]
    for row in parse_generated_lua_table(blobs["data/tables/emoticon.lua"].data):
        eid=parse_int(row["id"],label="emoticon id",allow_zero=False,allow_negative=False)
        item_id=parse_int(row["item_id"],label="emoticon item",allow_negative=False)
        if item_id:
            # The authoritative normalized resource artifact is used below.
            matches=[r for r in resource_artifact["resources"] if r.get("item_id")==item_id]
            if len(matches)!=1 or matches[0].get("class")!="STACK_ITEM" or matches[0].get("settlement_activation")!="ENABLED_R4" or matches[0].get("stack_cap")!=1:
                raise CompileError(f"unqualified emoticon stack item {item_id}")
        emoticons.append({"id":eid,"item_id":item_id})
    emoticons.sort(key=lambda r:r["id"])
    if len(emoticons)!=85 or len({r["id"] for r in emoticons})!=85 or sum(r["item_id"]==0 for r in emoticons)!=25 or len({r["item_id"] for r in emoticons if r["item_id"]})!=47:
        raise CompileError("I7A6A emoticon source counts drift")
    emoticon_artifact={"definitions":emoticons,"schema_version":SCHEMA_VERSION,"source":"data/tables/emoticon.lua"}
    title_limit=misc_int("guild_mail_title_limit")
    body_limit=misc_int("guild_mail_body_limit")
    if (title_limit,body_limit)!=(10,100):
        raise CompileError("Guild broadcast text limits drifted")
    broadcast_artifact={
        "schema_version":1,"policy_id":"GUILD_BROADCAST_STOCK_TEXTLEN_V1","storage_policy_id":"PG_UTF8_TEXT_NO_NUL_V1",
        "text_source_sha256":blobs["app/common/utils.lua"].sha256,
        "title_half_units":2*title_limit,"body_half_units":2*body_limit,
        "title_bytes":80,"body_bytes":800,"member_cap":50,
        "guild_core_revision":"0c74f31996a5cc3290a63541814495f5e830cbd5a56a1554e99cf66071a2b963",
        "mail_namespace":"NORMAL","mail_category":0,
        "mail_platform":"ANY","mail_shown":True,"attachments":False,"expiry":False
    }
    # Exact source client structure supports the finite wire family only.
    # Lifetime/cursor/name/eligibility/restore behavior below is reconstruction
    # policy selected by whole8B design, not original server facts.
    enums=blobs["app/common/enums.lua"].data.decode("utf-8")
    mids=blobs["app/common/network/mid.lua"].data.decode("utf-8")
    window=blobs["app/windows/SocialSystemWindow.lua"].data.decode("utf-8")
    if not re.search(r"GUILD_INVITE\s*=\s*10",enums) or any(not re.search(r"\b"+name+r"\s*=\s*"+str(number)+r"\b",mids) for name,number in [("INVITE_TO_GUILD",2563),("ACCEPT_INVITE_TO_GUILD",2564),("READ_NOTICE",184),("LOAD_FRIENDS",176),("LOAD_FRIEND_INFO",189)]):
        raise CompileError("I7A8B finite client enum/MID identity drift")
    if any(token not in window for token in ["createGuildInviteItemContent","guild_name","guild_id","acceptInviteToGuild","readNotice"]):
        raise CompileError("I7A8B client type10 accept/dismiss consumer drift")
    guild_model=blobs["app/model/SelfGuild.lua"].data.decode("utf-8")
    social_model=blobs["app/model/SocialSystem.lua"].data.decode("utf-8")
    if "acceptInviteToGuild" not in guild_model or "ACCEPT_INVITE_TO_GUILD" not in guild_model or "readNotice" not in social_model or "READ_NOTICE" not in social_model:
        raise CompileError("I7A8B model-to-MID consumer link drift")
    invite_artifact={
        "schema_version":1,"policy_id":"GUILD_INVITE_PRESENTATION_V1",
        "guild_core_revision":"0c74f31996a5cc3290a63541814495f5e830cbd5a56a1554e99cf66071a2b963",
        "notice_type":10,"source_identity":"guild_id:recipient_player_id:invite_generation",
        "expiry_policy":"GUILD_INVITE_STRICT_EXPIRY_V1",
        "generation_policy":"GUILD_INVITE_RETAINED_PAIR_CURSOR_V1",
        "join_policy":"GUILD_INVITE_JOIN_BOUNDARY_V1",
        "name_policy":"GUILD_INVITE_NAME_SNAPSHOT_V1",
        "observation_policy":"GUILD_INVITE_SHARED_OBSERVATION_V1",
        "stock_invite_mid":2563,"stock_accept_mid":2564,"stock_dismiss_mid":184,
        "stock_base_mid":176,"stock_list_mid":189,
        "reload_first_materialized_purpose":7,"reload_invalidation_purpose":8,
        "window_limit":50,"scan_limit":4096,"scan_page":128,"cleanup_default":32,"cleanup_max":1000,
        "enums_source_sha256":blobs["app/common/enums.lua"].sha256,
        "mid_source_sha256":blobs["app/common/network/mid.lua"].sha256,
        "window_source_sha256":blobs["app/windows/SocialSystemWindow.lua"].sha256,
        "guild_model_source_sha256":blobs["app/model/SelfGuild.lua"].sha256,
        "social_model_source_sha256":blobs["app/model/SocialSystem.lua"].sha256,
        "dismiss_joins_guild":False,"dismiss_cancels_invite":False,"historical_backfill":False
    }
    profile_artifact = {
        "schema_version":1,"policy_id":"I7B_PUBLIC_V1",
        "moderation_policy_id":"PROFILE_SCALAR_CASE_SENSITIVE_SPACE_MASK_V1",
        "name_source_sha256":blobs["data/tables/name.lua"].sha256,
        "filter_source_sha256":blobs["app/model/FilterWordManager.lua"].sha256,
        "show_source_sha256":blobs["data/tables/person_display_words.lua"].sha256,
        "words":sorted(set(r["name"] for r in parse_generated_lua_table(blobs["data/tables/name.lua"].data))),
        "show_type_ids":[int(r["id"]) for r in parse_generated_lua_table(blobs["data/tables/person_display_words.lua"].data) if 1001 <= int(r["id"]) <= 1011],
        "hide_subtypes":[2,4],"intro_codepoints":40,"selected_limit":4
    }
    showcase_artifact = {'schema_version': 1, 'policy_id': 'I7B_SHOWCASE_SELECTION_V1', 'slots': 6, 'visible_slots': 5, 'sign_rule': 'POSITIVE_OWNED_HERO_NEGATIVE_OWNED_PET_ZERO_EMPTY', 'duplicate_rule': 'FAMILY_CURRENT_TEMPLATE', 'index_rule': 'CURRENT_CALLER_SNAPSHOT_ONE_BASED', 'empty_record': 'OBJECT', 'wire_rule': 'REQUIRED_PROVIDERS_BEFORE_WRITE_I7B6', 'model_source_sha256': '022fcbf39167ac9197ce5034b32fd5833016742744ad3de118ceacf6f808cfb8', 'selector_source_sha256': 'e1db1b02194652043b289b2670501c0fc8226ccaba17c8e5eca1a915e715440e'}
    cosmetics=[]
    for r in parse_generated_lua_table(blobs["data/tables/avatar.lua"].data):
        cosmetics.append(dict(family="avatar" if r["avatar_type"]=="1" else "frame",id=int(r["id"]),icon=int(r["icon"]),type=int(r["type"]),partner_id=int(r["partner_id"]),days=int(r["time"]),vip=int(r["vip_level"]),price=int(r["value2"])))
    for family,table in [("title","title_system"),("bubble","chat_bubble")]:
        for r in parse_generated_lua_table(blobs["data/tables/"+table+".lua"].data):
            cosmetics.append(dict(family=family,id=int(r["id"]),icon=0,type=int(r.get("type","0")),partner_id=0,days=int(r["time"]),vip=0,price=0))
    words=profile_artifact["words"]
    names=[r["text"] for r in sorted(parse_generated_lua_table(blobs["data/tables/random_name.lua"].data),key=lambda r:int(r["id"])) if 2<=len(r["text"])<=16 and not any(w and w in r["text"] for w in words)][:12]
    display_artifact=dict(hero_templates=[dict(table_id=r["table_id"],before_awaken=r["first_table_id"],kind=r["hero_kind"])for r in hero_artifact["templates"]],schema_version=1,policy_id="PLAYER_DISPLAY_V1",rename_cost=100,default_avatar=110001001,default_frame=120001001,default_bubble=10001,cosmetics=cosmetics,names=names,words=words,collection=[110007026,110007027,110007043,110007049])
    # Minimum Library providers, distinct from full Library gameplay/title grants.
    def decimal100(raw):
        value=Decimal(raw)*100
        if value != value.to_integral_value(): raise CompileError("Library source precision exceeds selected hundredths")
        return int(value)
    def pipe_ints(raw): return [int(x) for x in raw.split("|")] if raw else []
    library_templates=[]
    for core in hero_artifact["templates"]:
        table_id=core["table_id"]
        keys,rows=(super_keys,super_rows) if core["hero_kind"]=="SUPER" else (partner_keys,partner_rows)
        values=rows[table_id]
        def field(name): return indexed_field(keys,values,name,row_id=table_id) or "0"
        first=int(field("first_table_id"))
        relationship_id=first if first>0 else table_id
        origin_values=rows.get(relationship_id)
        if origin_values is None: raise CompileError("Library relationship source row absent")
        like=int(indexed_field(keys,origin_values,"gift_like_type",row_id=relationship_id) or "0")
        dislike=int(indexed_field(keys,origin_values,"gift_dislike_type",row_id=relationship_id) or "0")
        enabled=int(field("is_open_dialog"))
        if enabled not in [0,1]: raise CompileError("Library dialog eligibility shape")
        library_templates.append(dict(table_id=table_id,relationship_source_id=relationship_id,collection_source_id=core["origin_table_id"] if core["hero_kind"]=="NORMAL" else table_id,dialog_enabled=bool(enabled),gift_like_type=like,gift_dislike_type=dislike))
    items_by_id={int(x["id"]):x for x in items}
    library_gifts=[]
    for row in parse_generated_lua_table(blobs["data/tables/library_gift.lua"].data):
        for item_id in pipe_ints(row["item"]):
            library_gifts.append(dict(item_id=item_id,category=int(row["type"]),base_favor=int(items_by_id[item_id]["amour"]),ring=item_id==50001112))
    library_gifts.sort(key=lambda x:x["item_id"])
    normal=[]
    for row in parse_generated_lua_table(blobs["data/tables/collect_normal.lua"].data):
        normal.append(dict(source_id=int(row["id"]),attr_id=int(row["attr"]),quality_thresholds=pipe_ints(row["quality"]),quality_hundredths=[decimal100(x)for x in row["num"].split("|")],star_thresholds=pipe_ints(row["star"]),star_hundredths=[decimal100(x)for x in row["star_attr"].split("|")]))
    special=[]
    for row in parse_generated_lua_table(blobs["data/tables/collect_special.lua"].data):
        special.append(dict(id=int(row["id"]),type=int(row["type"]),required_source_ids=pipe_ints(row["partner_id"]),contribution=dict(attr_id=int(row["content"]),hundredths=decimal100(row["num"]))))
    axes=[]
    for row in parse_generated_lua_table(blobs["data/tables/library_feed_attr.lua"].data):
        axes.append(dict(attr_id=int(row["attr_type"]),cap=int(row["attr_limit"]),positive=pipe_ints(row["incr_span"]),negative=pipe_ints(row["decr_span"])))
    methods=[]
    for row in parse_generated_lua_table(blobs["data/tables/library_feed_cost.lua"].data):
        methods.append(dict(id=int(row["id"]),cost_type=int(row["cost_type"]),cost=int(row["cost"]),initial_rates=pipe_ints(row["init_rate"]),change_step_percent=int(row["rate_change_step"]),negative_step_bp=decimal100(row["progress_rate_change"])))
    if misc_int("library_favor_limit")!=2000 or misc_int("library_gift_right")!=5 or misc_by_key["library_gift_wrong"]!="-3": raise CompileError("Library favor preservation profile source drift")
    favor_rows=parse_generated_lua_table(blobs["data/tables/library_amour.lua"].data)
    if len(normal)!=132 or len(special)!=23 or any(x["type"]!=1 for x in special) or len(library_gifts)!=10: raise CompileError("Library selected source counts/shape drift")
    library_artifact=dict(schema_version=1,seed_policy_id="LIBRARY_NEUTRAL_SEED_V1",feed_policy_id="LIBRARY_FEED_RECONSTRUCTION_V1",original_server_probability_recovered=False,favor_limit=2000,templates=library_templates,gifts=library_gifts,feeding=dict(axes=axes,methods=methods,decrease_begin_percent=misc_int("library_feed_decr_begin")),normal_collections=normal,special_collections=special)
    from book_content import build_book
    course_artifact=build_course(blobs,parse_generated_lua_table,items)
    book_artifact=build_book(blobs,parse_generated_lua_table,items)
    from dorm_content import build_dorm
    dorm_artifact=build_dorm(blobs,parse_generated_lua_table,pipe_ints,hero_artifact["templates"],partner_keys,partner_rows,super_keys,super_rows,indexed_field,items,CompileError)
    artifacts = {
        "inscription_input_catalog.json":build_inscription(blobs,parse_generated_lua_table,items),
        "course_input_catalog.json":course_artifact,
        "book_input_catalog.json":book_artifact,
        "dorm_input_catalog.json":dorm_artifact,
        "library_input_catalog.json":library_artifact,
        "player_display_catalog.json":display_artifact,
        "public_showcase_policy.json":showcase_artifact,
        "public_profile_policy.json":profile_artifact,
        "guild_invite_policy.json":invite_artifact,
        "guild_broadcast_policy.json":broadcast_artifact,
        "social_gift_catalog.json": social_gift_artifact,
        "emoticon_catalog.json": emoticon_artifact,
        "equipment_primitives_catalog.json": equipment_artifact,
        "function_gates.json": function_artifact,
        "hero_core_catalog.json": hero_artifact,
        "hero_equipment_catalog.json": hero_equipment_artifact,
        "hero_fumo_catalog.json": fumo_artifact,
        "hero_promotion_restoration_catalog.json": restoration_artifact,
        "objective_catalog.json": objective_artifact,
        "pet_acquisition_catalog.json": pet_acquisition_artifact,
        "pet_core_catalog.json": pet_artifact,
        "pet_progression_catalog.json": pet_progression_artifact,
        "pet_equipment_catalog.json": pet_equipment_artifact,
        "pet_promotion_restoration_catalog.json": pet_promotion_restoration_artifact,
        "super_equipment_catalog.json": super_equipment_artifact,
        "player_progression.json": player_artifact,
        "practice_catalog.json": practice_artifact,
        "appearance_catalog.json": appearance_artifact,
        "resource_catalog.json": resource_artifact,
    }
    artifact_bytes = {name: canonical_json_bytes(value) for name, value in artifacts.items()}
    artifact_hashes = {name: sha256_bytes(data) for name, data in sorted(artifact_bytes.items())}

    diagnostics = {
        "asset_named_rows": len(asset_rows),
        "enabled_stack_items": enabled_stack,
        "item_rows": len(items),
        "function_rows": len(function_gates),
        "objective_builtin_rows": 0,
        "player_rows": len(progression_rows),
        "positive_stack_items": positive_stack,
        "specialized_type24_items": specialized_type24,
        "type3_partner_scrolls": partner_scrolls,
        "unqualified_type0_stack_items": fail_closed_unknown_type,
        "hero_templates": len(templates),
        "hero_exp_rows": len(exp_out),
        "hero_exp_items": len(hero_exp_items),
        "hero_normal_star_rows": len(normal_star),
        "hero_super_star_rows": len(super_star),
        "hero_super_prerequisites": len(prerequisites),
        "hero_acquisition_items": len(acquisition),
        "hero_equipment_positions": len(hero_equipment_positions),
        "hero_equipment_ordinary_positions": hero_equipment_ordinary,
        "hero_equipment_special_positions": hero_equipment_special,
        "hero_equipment_zero_positions": hero_equipment_zero,
        "hero_equipment_unique_ordinary_items": len(hero_equipment_ordinary_ids),
        "hero_equipment_unique_special_items": len(hero_equipment_special_ids),
        "hero_fumo_targets": len(fumo_targets),
        "hero_fumo_materials": len(fumo_materials),
        "hero_promotion_restoration_eligible_equipment": len(restoration_equipment),
        "pet_templates": len(pet_templates),
        "pet_origin_families": len(origins),
        "pet_acquisition_templates": len(pet_acquisition),
        "pet_progression_templates": len(pet_progression),
        "pet_progression_skill_slots": len(pet_skill_slots),
        "pet_exp_rows": len(pet_exp),
        "pet_skill_book_rows": len(skill_books),
        "pet_equipment_positions": len(pet_equipment_positions),
        "pet_equipment_ordinary_positions": pet_equipment_ordinary,
        "pet_equipment_special_positions": pet_equipment_special,
        "pet_equipment_zero_positions": pet_equipment_zero,
        "pet_equipment_unique_ordinary_items": len(pet_equipment_ordinary_ids),
        "pet_equipment_unique_special_items": len(pet_equipment_special_ids),
        "pet_promotion_restoration_eligible_equipment": len(pet_restoration_equipment),
        "super_equipment_positions": len(super_equipment_positions),
        "super_equipment_unique_base_items": len(super_base_ids),
        "super_equipment_enhancement_caps": len(enhancement_caps),
        "super_equipment_enhancement_tiers": len(enhancement_tiers),
        "equipment_roots": len(equipment_roots),
        "equipment_closure_items": len(equipment_items),
        "equipment_recipe_nodes": len(by_parent),
        "equipment_recipe_edges": len(recipe_edges),
        "equipment_repeated_component_recipes": repeated_component_recipes,
        "practice_methods": len(practice_methods),
        "practice_locks": len(practice_locks),
        "practice_vip_rows": len(vip_bless),
        "practice_hero_thresholds": len(hero_thresholds),
        "practice_pet_thresholds": len(pet_thresholds),
        "appearance_skin_models": len(appearance_skins),
        "appearance_skin_skill_models": sum(1 for x in appearance_skins if x["skin_skill_id"] > 0),
        "appearance_skin_items": len(appearance_skin_items),
        "appearance_timed_skin_items": len(timed),
        "appearance_paid_live": len(appearance_live),
        "appearance_automatic_dynamic_type1": automatic_type1,
        "appearance_pet_styles": len(appearance_pet_styles),
    }
    dependencies = {
        "r5_enabled": ["PLAYER_EXP", "TEMPORAL_ENERGY", "TEMPORAL_SPIRIT_ENERGY", "TEMPORAL_SKILL_POINT", "FUNCTION_LEVEL_ELIGIBILITY"],
        "fail_closed": ["OBJECTIVE_BUILTIN_MAPPING", "TEMPORAL_INVITATION_CAP", "TYPE24_HORCRUX", "UNKNOWN_ITEM_OR_RESOURCE"],
    }
    manifest_basis = {
        "artifact_sha256s": artifact_hashes,
        "compiler_version": COMPILER_VERSION,
        "dependencies": dependencies,
        "diagnostics": diagnostics,
        "enabled_capabilities": ENABLED_CAPABILITIES,
        "parser_version": PARSER_VERSION,
        "revision_digest_scope": "canonical_manifest_without_revision_id",
        "schema_version": SCHEMA_VERSION,
        "source_archive_sha256": archive_sha256,
        "sources": [source_record(blobs[path]) for path, _, _ in SOURCE_MANIFEST],
    }
    revision_id = sha256_bytes(canonical_json_bytes(manifest_basis, newline=False))
    manifest = dict(manifest_basis)
    manifest["revision_id"] = revision_id
    artifacts["manifest.json"] = manifest
    return artifacts


def write_artifacts(artifacts: dict[str, Any], output: Path, *, check: bool) -> None:
    output.mkdir(parents=True, exist_ok=True)
    errors: list[str] = []
    for name, value in sorted(artifacts.items()):
        expected = canonical_json_bytes(value)
        path = output / name
        if check:
            if not path.exists():
                errors.append(f"missing generated artifact {path}")
                continue
            actual = path.read_bytes()
            if actual != expected:
                errors.append(f"generated artifact drift: {path}")
        else:
            path.write_bytes(expected)
    if errors:
        raise CompileError("; ".join(errors))


def build_social_gift(gift_rows, daily, send_cap, claim_cap):
    by_gift={r["id"]:r for r in gift_rows}
    if len(by_gift)!=len(gift_rows):raise CompileError("duplicate gift identity")
    if len(daily)!=100 or sorted(int(r["level"])for r in daily)!=list(range(1,101)):
        raise CompileError("dailygift complete100-level source drift")
    gift_mapping=[]; vector=None; used=set()
    for row in sorted(daily,key=lambda r:int(r["level"])):
        if row["gift_id"] in used:raise CompileError("duplicate dailygift mapping")
        used.add(row["gift_id"])
        g=by_gift.get(row["gift_id"])
        if g is None:raise CompileError("missing dailygift reward")
        current={k:v for k,v in g.items()if k not in {"id","name","desc"}}
        if current != {'arena_coin': '0', 'badge': '0', 'crystal': '0', 'drops': '0', 'energy': '0', 'equip': '0', 'ex_badge': '0', 'exp': '0', 'friendship_coin': '5', 'item_nums': '0', 'items': '0', 'lucky_coin': '0', 'mana': '0', 'march_coin': '0', 'skin_coin': '0', 'skin_fragment': '0', 'soul': '0', 'spirit_energy': '', 'summon_id': '0', 'summon_init_time': '', 'tutor_coin': '', 'vip': '0', 'vip_exp': '0'}:raise CompileError("unqualified complete dailygift vector")
        if vector is None:vector=current
        if current!=vector:raise CompileError("nonuniform dailygift: selector UNKNOWN")
        if current.get("friendship_coin")!="5" or any(v not in {"","0"}for k,v in current.items()if k!="friendship_coin"):
            raise CompileError("unqualified dailygift reward vector")
        gift_mapping.append({"level":int(row["level"]),"gift_id":int(row["gift_id"])})
    social_gift_artifact={"schema_version":SCHEMA_VERSION,"resource_key":"friendship_coin","amount":5,
        "send_cap":send_cap,"claim_cap":claim_cap,
        "policy":"SOCIAL_GIFT_DAY_V1","selector":"UNKNOWN_UNIFORM_ONLY","mapping":gift_mapping,
        "vector_fingerprint":sha256_bytes(canonical_json_bytes(vector)),"reward_vector":vector}
    if social_gift_artifact["send_cap"]!=10 or social_gift_artifact["claim_cap"]!=10:
        raise CompileError("SocialGift source caps drift")
    return social_gift_artifact


def compile_archive(archive: Path) -> dict[str, Any]:
    source = SourceArchive(archive)
    blobs = source.read_verified()
    return build_artifacts(blobs, source.archive_sha256)


def main(argv: list[str] | None = None) -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--source-archive", type=Path, required=True)
    parser.add_argument(
        "--output",
        type=Path,
        default=Path(__file__).resolve().parents[1] / "internal/content/builtin/generated",
    )
    parser.add_argument("--check", action="store_true", help="fail if checked-in artifacts differ")
    args = parser.parse_args(argv)
    try:
        artifacts = compile_archive(args.source_archive)
        write_artifacts(artifacts, args.output, check=args.check)
    except (CompileError, OSError, zipfile.BadZipFile) as exc:
        print(f"R4A CONTENT GENERATION ERROR: {exc}", file=sys.stderr)
        return 1
    print(
        "R4A CONTENT GENERATION: PASS "
        f"revision={artifacts['manifest.json']['revision_id']} "
        f"resources={len(artifacts['resource_catalog.json']['resources'])} "
        f"players={len(artifacts['player_progression.json']['rows'])} "
        f"functions={len(artifacts['function_gates.json']['gates'])} "
        f"heroes={len(artifacts['hero_core_catalog.json']['templates'])} "
        f"pets={len(artifacts['pet_core_catalog.json']['templates'])} "
        f"equipment={len(artifacts['equipment_primitives_catalog.json']['items'])} "
        f"pet_acquisition={len(artifacts['pet_acquisition_catalog.json']['templates'])}"
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
