//
//  ColorFormatter.m
//
//  Copyright (C) 2013 IRCCloud, Ltd.
//  Licensed under the Apache License, Version 2.0 (the "License");
//  you may not use this file except in compliance with the License.
//  You may obtain a copy of the License at
//
//  http://www.apache.org/licenses/LICENSE-2.0
//
//  Unless required by applicable law or agreed to in writing, software
//  distributed under the License is distributed on an "AS IS" BASIS,
//  WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
//  See the License for the specific language governing permissions and
//  limitations under the License.


#import <CoreText/CoreText.h>
#import "ColorFormatter.h"
#import "TTTAttributedLabel.h"
#import "UIColor+IRCCloud.h"
#import "NSURL+IDN.h"

CTFontRef Courier, CourierBold, CourierOblique,CourierBoldOblique;
CTFontRef Helvetica, HelveticaBold, HelveticaOblique,HelveticaBoldOblique;
CTFontRef arrowFont;
UIFont *timestampFont;
NSDictionary *emojiMap;

@implementation ColorFormatter

+(void)clearFontCache {
    Courier = CourierBold = CourierBoldOblique = CourierOblique = Helvetica = HelveticaBold = HelveticaBoldOblique = HelveticaOblique = nil;
    timestampFont = nil;
}

+(UIFont *)timestampFont {
    if(!timestampFont) {
#ifdef __IPHONE_7_0
        if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 7)
#endif
            timestampFont = [UIFont systemFontOfSize:FONT_SIZE];
#ifdef __IPHONE_7_0
        else {
            timestampFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            timestampFont = [UIFont fontWithName:timestampFont.fontName size:timestampFont.pointSize * 0.8];
        }
#endif
    }
    return timestampFont;
}

+(NSRegularExpression *)emoji {
    if(!emojiMap)
        emojiMap = @{
                     @"poodle":@"🐩",
                     @"black_joker":@"🃏",
                     @"dog2":@"🐕",
                     @"hotel":@"🏨",
                     @"fuelpump":@"⛽",
                     @"mouse2":@"🐁",
                     @"basketball":@"🏀",
                     @"earth_asia":@"🌏",
                     @"heart_eyes":@"😍",
                     @"fearful":@"😨",
                     @"waning_gibbous_moon":@"🌖",
                     @"pensive":@"😔",
                     @"mahjong":@"🀄",
                     @"closed_umbrella":@"🌂",
                     @"grinning":@"😀",
                     @"mag_right":@"🔎",
                     @"round_pushpin":@"📍",
                     @"nut_and_bolt":@"🔩",
                     @"no_bell":@"🔕",
                     @"incoming_envelope":@"📨",
                     @"repeat":@"🔁",
                     @"notebook_with_decorative_cover":@"📔",
                     @"dvd":@"📀",
                     @"ram":@"🐏",
                     @"curly_loop":@"➰",
                     @"trumpet":@"🎺",
                     @"love_hotel":@"🏩",
                     @"pig2":@"🐖",
                     @"fast_forward":@"⏩",
                     @"ox":@"🐂",
                     @"checkered_flag":@"🏁",
                     @"sunglasses":@"😎",
                     @"weary":@"😩",
                     @"last_quarter_moon":@"🌗",
                     @"confused":@"😕",
                     @"stars":@"🌃",
                     @"grin":@"😁",
                     @"lock_with_ink_pen":@"🔏",
                     @"paperclip":@"📎",
                     @"seat":@"💺",
                     @"envelope_with_arrow":@"📩",
                     @"bookmark":@"🔖",
                     @"closed_book":@"📕",
                     @"repeat_one":@"🔂",
                     @"file_folder":@"📁",
                     @"violin":@"🎻",
                     @"boar":@"🐗",
                     @"water_buffalo":@"🐃",
                     @"snowboarder":@"🏂",
                     @"smirk":@"😏",
                     @"bath":@"🛀",
                     @"waning_crescent_moon":@"🌘",
                     @"confounded":@"😖",
                     @"sunrise_over_mountains":@"🌄",
                     @"joy":@"😂",
                     @"straight_ruler":@"📏",
                     @"computer":@"💻",
                     @"link":@"🔗",
                     @"arrows_clockwise":@"🔃",
                     @"book":@"📖",
                     @"open_book":@"📖",
                     @"open_file_folder":@"📂",
                     @"left_right_arrow":@"↔",
                     @"musical_score":@"🎼",
                     @"elephant":@"🐘",
                     @"cow2":@"🐄",
                     @"womens":@"🚺",
                     @"runner":@"🏃",
                     @"running":@"🏃",
                     @"bathtub":@"🛁",
                     @"crescent_moon":@"🌙",
                     @"arrow_up_down":@"↕",
                     @"sunrise":@"🌅",
                     @"smiley":@"😃",
                     @"kissing":@"😗",
                     @"briefcase":@"💼",
                     @"radio_button":@"🔘",
                     @"arrows_counterclockwise":@"🔄",
                     @"green_book":@"📗",
                     @"page_with_curl":@"📃",
                     @"arrow_upper_left":@"↖",
                     @"running_shirt_with_sash":@"🎽",
                     @"octopus":@"🐙",
                     @"tiger2":@"🐅",
                     @"restroom":@"🚻",
                     @"surfer":@"🏄",
                     @"passport_control":@"🛂",
                     @"slot_machine":@"🎰",
                     @"zero":@"0⃣",
                     @"phone":@"☎",
                     @"telephone":@"☎",
                     @"kissing_heart":@"😘",
                     @"city_sunset":@"🌆",
                     @"arrow_upper_right":@"↗",
                     @"smile":@"😄",
                     @"minidisc":@"💽",
                     @"back":@"🔙",
                     @"low_brightness":@"🔅",
                     @"blue_book":@"📘",
                     @"one":@"1⃣",
                     @"page_facing_up":@"📄",
                     @"moneybag":@"💰",
                     @"arrow_lower_right":@"↘",
                     @"tennis":@"🎾",
                     @"baby_symbol":@"🚼",
                     @"circus_tent":@"🎪",
                     @"leopard":@"🐆",
                     @"customs":@"🛃",
                     @"8ball":@"🎱",
                     @"two":@"2⃣",
                     @"kissing_smiling_eyes":@"😙",
                     @"city_sunrise":@"🌇",
                     @"heavy_plus_sign":@"➕",
                     @"arrow_lower_left":@"↙",
                     @"sweat_smile":@"😅",
                     @"ballot_box_with_check":@"☑",
                     @"floppy_disk":@"💾",
                     @"high_brightness":@"🔆",
                     @"muscle":@"💪",
                     @"orange_book":@"📙",
                     @"date":@"📅",
                     @"three":@"3⃣",
                     @"currency_exchange":@"💱",
                     @"heavy_minus_sign":@"➖",
                     @"ski":@"🎿",
                     @"toilet":@"🚽",
                     @"ticket":@"🎫",
                     @"rabbit2":@"🐇",
                     @"trophy":@"🏆",
                     @"baggage_claim":@"🛄",
                     @"game_die":@"🎲",
                     @"potable_water":@"🚰",
                     @"four":@"4⃣",
                     @"rainbow":@"🌈",
                     @"laughing":@"😆",
                     @"satisfied":@"😆",
                     @"heavy_division_sign":@"➗",
                     @"cd":@"💿",
                     @"mute":@"🔇",
                     @"dizzy":@"💫",
                     @"five":@"5⃣",
                     @"calendar":@"📆",
                     @"heavy_dollar_sign":@"💲",
                     @"wc":@"🚾",
                     @"clapper":@"🎬",
                     @"umbrella":@"☔",
                     @"cat2":@"🐈",
                     @"horse_racing":@"🏇",
                     @"door":@"🚪",
                     @"bowling":@"🎳",
                     @"non-potable_water":@"🚱",
                     @"left_luggage":@"🛅",
                     @"six":@"6⃣",
                     @"bridge_at_night":@"🌉",
                     @"innocent":@"😇",
                     @"coffee":@"☕",
                     @"speech_balloon":@"💬",
                     @"seven":@"7⃣",
                     @"card_index":@"📇",
                     @"credit_card":@"💳",
                     @"wavy_dash":@"〰",
                     @"shower":@"🚿",
                     @"performing_arts":@"🎭",
                     @"dragon":@"🐉",
                     @"no_entry_sign":@"🚫",
                     @"football":@"🏈",
                     @"flower_playing_cards":@"🎴",
                     @"bike":@"🚲",
                     @"carousel_horse":@"🎠",
                     @"eight":@"8⃣",
                     @"smiling_imp":@"😈",
                     @"sound":@"🔉",
                     @"thought_balloon":@"💭",
                     @"chart_with_upwards_trend":@"📈",
                     @"nine":@"9⃣",
                     @"yen":@"💴",
                     @"diamond_shape_with_a_dot_inside":@"💠",
                     @"video_game":@"🎮",
                     @"smoking":@"🚬",
                     @"rugby_football":@"🏉",
                     @"musical_note":@"🎵",
                     @"no_bicycles":@"🚳",
                     @"ferris_wheel":@"🎡",
                     @"wink":@"😉",
                     @"vs":@"🆚",
                     @"gemini":@"♊",
                     @"white_flower":@"💮",
                     @"chart_with_downwards_trend":@"📉",
                     @"dollar":@"💵",
                     @"bulb":@"💡",
                     @"dart":@"🎯",
                     @"no_smoking":@"🚭",
                     @"notes":@"🎶",
                     @"cancer":@"♋",
                     @"roller_coaster":@"🎢",
                     @"mountain_cableway":@"🚠",
                     @"bicyclist":@"🚴",
                     @"100":@"💯",
                     @"leo":@"♌",
                     @"arrow_backward":@"◀",
                     @"euro":@"💶",
                     @"anger":@"💢",
                     @"black_large_square":@"⬛",
                     @"put_litter_in_its_place":@"🚮",
                     @"saxophone":@"🎷",
                     @"mountain_bicyclist":@"🚵",
                     @"virgo":@"♍",
                     @"fishing_pole_and_fish":@"🎣",
                     @"aerial_tramway":@"🚡",
                     @"green_heart":@"💚",
                     @"white_large_square":@"⬜",
                     @"libra":@"♎",
                     @"arrow_heading_up":@"⤴",
                     @"pound":@"💷",
                     @"bomb":@"💣",
                     @"do_not_litter":@"🚯",
                     @"arrow_left":@"⬅",
                     @"guitar":@"🎸",
                     @"walking":@"🚶",
                     @"microphone":@"🎤",
                     @"scorpius":@"♏",
                     @"arrow_heading_down":@"⤵",
                     @"ship":@"🚢",
                     @"sagittarius":@"♐",
                     @"yellow_heart":@"💛",
                     @"arrow_up":@"⬆",
                     @"registered":@"®",
                     @"truck":@"🚚",
                     @"money_with_wings":@"💸",
                     @"zzz":@"💤",
                     @"capricorn":@"♑",
                     @"arrow_down":@"⬇",
                     @"scissors":@"✂",
                     @"musical_keyboard":@"🎹",
                     @"movie_camera":@"🎥",
                     @"rowboat":@"🚣",
                     @"no_pedestrians":@"🚷",
                     @"aquarius":@"♒",
                     @"purple_heart":@"💜",
                     @"cl":@"🆑",
                     @"articulated_lorry":@"🚛",
                     @"chart":@"💹",
                     @"boom":@"💥",
                     @"collision":@"💥",
                     @"pisces":@"♓",
                     @"wind_chime":@"🎐",
                     @"children_crossing":@"🚸",
                     @"cinema":@"🎦",
                     @"speedboat":@"🚤",
                     @"gift_heart":@"💝",
                     @"cool":@"🆒",
                     @"white_check_mark":@"✅",
                     @"bouquet":@"💐",
                     @"kr":@"🇰🇷",
                     @"tractor":@"🚜",
                     @"tm":@"™",
                     @"confetti_ball":@"🎊",
                     @"sweat_drops":@"💦",
                     @"rice_scene":@"🎑",
                     @"mens":@"🚹",
                     @"headphones":@"🎧",
                     @"white_circle":@"⚪",
                     @"traffic_light":@"🚥",
                     @"revolving_hearts":@"💞",
                     @"pill":@"💊",
                     @"free":@"🆓",
                     @"couple_with_heart":@"💑",
                     @"black_circle":@"⚫",
                     @"monorail":@"🚝",
                     @"fr":@"🇫🇷",
                     @"tanabata_tree":@"🎋",
                     @"droplet":@"💧",
                     @"white_medium_square":@"◻",
                     @"school_satchel":@"🎒",
                     @"minibus":@"🚐",
                     @"art":@"🎨",
                     @"airplane":@"✈",
                     @"vertical_traffic_light":@"🚦",
                     @"heart_decoration":@"💟",
                     @"black_medium_square":@"◼",
                     @"kiss":@"💋",
                     @"id":@"🆔",
                     @"wedding":@"💒",
                     @"email":@"✉",
                     @"envelope":@"✉",
                     @"mountain_railway":@"🚞",
                     @"crossed_flags":@"🎌",
                     @"dash":@"💨",
                     @"tram":@"🚊",
                     @"mortar_board":@"🎓",
                     @"white_medium_small_square":@"◽",
                     @"ambulance":@"🚑",
                     @"tophat":@"🎩",
                     @"construction":@"🚧",
                     @"ab":@"🆎",
                     @"black_medium_small_square":@"◾",
                     @"love_letter":@"💌",
                     @"heartbeat":@"💓",
                     @"new":@"🆕",
                     @"suspension_railway":@"🚟",
                     @"ru":@"🇷🇺",
                     @"bamboo":@"🎍",
                     @"hankey":@"💩",
                     @"poop":@"💩",
                     @"shit":@"💩",
                     @"fire_engine":@"🚒",
                     @"ribbon":@"🎀",
                     @"rotating_light":@"🚨",
                     @"ring":@"💍",
                     @"broken_heart":@"💔",
                     @"ng":@"🆖",
                     @"skull":@"💀",
                     @"dolls":@"🎎",
                     @"bus":@"🚌",
                     @"beer":@"🍺",
                     @"police_car":@"🚓",
                     @"gift":@"🎁",
                     @"triangular_flag_on_post":@"🚩",
                     @"gem":@"💎",
                     @"japanese_goblin":@"👺",
                     @"two_hearts":@"💕",
                     @"ok":@"🆗",
                     @"information_desk_person":@"💁",
                     @"flags":@"🎏",
                     @"oncoming_bus":@"🚍",
                     @"beers":@"🍻",
                     @"sparkles":@"✨",
                     @"oncoming_police_car":@"🚔",
                     @"birthday":@"🎂",
                     @"rocket":@"🚀",
                     @"couplekiss":@"💏",
                     @"ghost":@"👻",
                     @"sparkling_heart":@"💖",
                     @"sos":@"🆘",
                     @"guardsman":@"💂",
                     @"a":@"🅰",
                     @"trolleybus":@"🚎",
                     @"baby_bottle":@"🍼",
                     @"ophiuchus":@"⛎",
                     @"taxi":@"🚕",
                     @"jack_o_lantern":@"🎃",
                     @"helicopter":@"🚁",
                     @"anchor":@"⚓",
                     @"o2":@"🅾",
                     @"angel":@"👼",
                     @"rewind":@"⏪",
                     @"heartpulse":@"💗",
                     @"snowflake":@"❄",
                     @"dancer":@"💃",
                     @"up":@"🆙",
                     @"b":@"🅱",
                     @"busstop":@"🚏",
                     @"oncoming_taxi":@"🚖",
                     @"christmas_tree":@"🎄",
                     @"steam_locomotive":@"🚂",
                     @"cake":@"🍰",
                     @"arrow_double_up":@"⏫",
                     @"parking":@"🅿",
                     @"alien":@"👽",
                     @"cupid":@"💘",
                     @"church":@"⛪",
                     @"lipstick":@"💄",
                     @"arrow_double_down":@"⏬",
                     @"bride_with_veil":@"👰",
                     @"cookie":@"🍪",
                     @"car":@"🚗",
                     @"red_car":@"🚗",
                     @"santa":@"🎅",
                     @"railway_car":@"🚃",
                     @"train":@"🚃",
                     @"bento":@"🍱",
                     @"sparkle":@"❇",
                     @"space_invader":@"👾",
                     @"family":@"👪",
                     @"blue_heart":@"💙",
                     @"nail_care":@"💅",
                     @"no_entry":@"⛔",
                     @"person_with_blond_hair":@"👱",
                     @"chocolate_bar":@"🍫",
                     @"oncoming_automobile":@"🚘",
                     @"fireworks":@"🎆",
                     @"bullettrain_side":@"🚄",
                     @"stew":@"🍲",
                     @"it":@"🇮🇹",
                     @"alarm_clock":@"⏰",
                     @"imp":@"👿",
                     @"couple":@"👫",
                     @"massage":@"💆",
                     @"man_with_gua_pi_mao":@"👲",
                     @"candy":@"🍬",
                     @"blue_car":@"🚙",
                     @"sparkler":@"🎇",
                     @"bullettrain_front":@"🚅",
                     @"egg":@"🍳",
                     @"jp":@"🇯🇵",
                     @"heart":@"❤",
                     @"us":@"🇺🇸",
                     @"two_men_holding_hands":@"👬",
                     @"arrow_right":@"➡",
                     @"haircut":@"💇",
                     @"man_with_turban":@"👳",
                     @"hourglass_flowing_sand":@"⏳",
                     @"lollipop":@"🍭",
                     @"balloon":@"🎈",
                     @"train2":@"🚆",
                     @"fork_and_knife":@"🍴",
                     @"sweet_potato":@"🍠",
                     @"fountain":@"⛲",
                     @"two_women_holding_hands":@"👭",
                     @"barber":@"💈",
                     @"older_man":@"👴",
                     @"high_heel":@"👠",
                     @"golf":@"⛳",
                     @"custard":@"🍮",
                     @"rice":@"🍚",
                     @"tada":@"🎉",
                     @"metro":@"🚇",
                     @"tea":@"🍵",
                     @"dango":@"🍡",
                     @"clock530":@"🕠",
                     @"cop":@"👮",
                     @"womans_clothes":@"👚",
                     @"syringe":@"💉",
                     @"leftwards_arrow_with_hook":@"↩",
                     @"older_woman":@"👵",
                     @"sandal":@"👡",
                     @"boat":@"⛵",
                     @"sailboat":@"⛵",
                     @"honey_pot":@"🍯",
                     @"curry":@"🍛",
                     @"light_rail":@"🚈",
                     @"sake":@"🍶",
                     @"oden":@"🍢",
                     @"clock11":@"🕚",
                     @"clock630":@"🕡",
                     @"dancers":@"👯",
                     @"purse":@"👛",
                     @"loop":@"➿",
                     @"baby":@"👶",
                     @"m":@"Ⓜ",
                     @"boot":@"👢",
                     @"ramen":@"🍜",
                     @"station":@"🚉",
                     @"wine_glass":@"🍷",
                     @"watch":@"⌚",
                     @"sushi":@"🍣",
                     @"sunny":@"☀",
                     @"clock12":@"🕛",
                     @"clock730":@"🕢",
                     @"ideograph_advantage":@"🉐",
                     @"hourglass":@"⌛",
                     @"handbag":@"👜",
                     @"cloud":@"☁",
                     @"construction_worker":@"👷",
                     @"footprints":@"👣",
                     @"hash":@"#⃣",
                     @"spaghetti":@"🍝",
                     @"cocktail":@"🍸",
                     @"fried_shrimp":@"🍤",
                     @"pear":@"🍐",
                     @"clock130":@"🕜",
                     @"clock830":@"🕣",
                     @"accept":@"🉑",
                     @"pouch":@"👝",
                     @"princess":@"👸",
                     @"bust_in_silhouette":@"👤",
                     @"open_hands":@"👐",
                     @"bread":@"🍞",
                     @"tangerine":@"🍊",
                     @"tropical_drink":@"🍹",
                     @"fish_cake":@"🍥",
                     @"peach":@"🍑",
                     @"clock230":@"🕝",
                     @"clock930":@"🕤",
                     @"clock1":@"🕐",
                     @"mans_shoe":@"👞",
                     @"shoe":@"👞",
                     @"point_up":@"☝",
                     @"facepunch":@"👊",
                     @"punch":@"👊",
                     @"japanese_ogre":@"👹",
                     @"busts_in_silhouette":@"👥",
                     @"crown":@"👑",
                     @"fries":@"🍟",
                     @"lemon":@"🍋",
                     @"icecream":@"🍦",
                     @"cherries":@"🍒",
                     @"black_small_square":@"▪",
                     @"clock330":@"🕞",
                     @"clock1030":@"🕥",
                     @"clock2":@"🕑",
                     @"athletic_shoe":@"👟",
                     @"wave":@"👋",
                     @"white_small_square":@"▫",
                     @"boy":@"👦",
                     @"bangbang":@"‼",
                     @"womans_hat":@"👒",
                     @"banana":@"🍌",
                     @"speak_no_evil":@"🙊",
                     @"shaved_ice":@"🍧",
                     @"strawberry":@"🍓",
                     @"clock430":@"🕟",
                     @"cn":@"🇨🇳",
                     @"clock1130":@"🕦",
                     @"clock3":@"🕒",
                     @"ok_hand":@"👌",
                     @"girl":@"👧",
                     @"relaxed":@"☺",
                     @"eyeglasses":@"👓",
                     @"pineapple":@"🍍",
                     @"raising_hand":@"🙋",
                     @"ice_cream":@"🍨",
                     @"hamburger":@"🍔",
                     @"four_leaf_clover":@"🍀",
                     @"u55b6":@"🈺",
                     @"clock1230":@"🕧",
                     @"clock4":@"🕓",
                     @"part_alternation_mark":@"〽",
                     @"+1":@"👍",
                     @"thumbsup":@"👍",
                     @"man":@"👨",
                     @"necktie":@"👔",
                     @"eyes":@"👀",
                     @"apple":@"🍎",
                     @"raised_hands":@"🙌",
                     @"hibiscus":@"🌺",
                     @"doughnut":@"🍩",
                     @"pizza":@"🍕",
                     @"maple_leaf":@"🍁",
                     @"clock5":@"🕔",
                     @"gb":@"🇬🇧",
                     @"uk":@"🇬🇧",
                     @"-1":@"👎",
                     @"thumbsdown":@"👎",
                     @"wolf":@"🐺",
                     @"woman":@"👩",
                     @"shirt":@"👕",
                     @"tshirt":@"👕",
                     @"green_apple":@"🍏",
                     @"person_frowning":@"🙍",
                     @"sunflower":@"🌻",
                     @"meat_on_bone":@"🍖",
                     @"fallen_leaf":@"🍂",
                     @"scream_cat":@"🙀",
                     @"small_red_triangle":@"🔺",
                     @"clock6":@"🕕",
                     @"clap":@"👏",
                     @"bear":@"🐻",
                     @"jeans":@"👖",
                     @"ear":@"👂",
                     @"person_with_pouting_face":@"🙎",
                     @"blossom":@"🌼",
                     @"smiley_cat":@"😺",
                     @"poultry_leg":@"🍗",
                     @"leaves":@"🍃",
                     @"fist":@"✊",
                     @"es":@"🇪🇸",
                     @"small_red_triangle_down":@"🔻",
                     @"clock7":@"🕖",
                     @"tv":@"📺",
                     @"de":@"🇩🇪",
                     @"panda_face":@"🐼",
                     @"hand":@"✋",
                     @"raised_hand":@"✋",
                     @"dress":@"👗",
                     @"nose":@"👃",
                     @"arrow_forward":@"▶",
                     @"pray":@"🙏",
                     @"corn":@"🌽",
                     @"heart_eyes_cat":@"😻",
                     @"rice_cracker":@"🍘",
                     @"mushroom":@"🍄",
                     @"chestnut":@"🌰",
                     @"v":@"✌",
                     @"arrow_up_small":@"🔼",
                     @"clock8":@"🕗",
                     @"radio":@"📻",
                     @"pig_nose":@"🐽",
                     @"kimono":@"👘",
                     @"lips":@"👄",
                     @"rabbit":@"🐰",
                     @"ear_of_rice":@"🌾",
                     @"smirk_cat":@"😼",
                     @"interrobang":@"⁉",
                     @"mount_fuji":@"🗻",
                     @"rice_ball":@"🍙",
                     @"tomato":@"🍅",
                     @"seedling":@"🌱",
                     @"arrow_down_small":@"🔽",
                     @"clock9":@"🕘",
                     @"vhs":@"📼",
                     @"beginner":@"🔰",
                     @"u7981":@"🈲",
                     @"feet":@"🐾",
                     @"paw_prints":@"🐾",
                     @"dromedary_camel":@"🐪",
                     @"bikini":@"👙",
                     @"pencil2":@"✏",
                     @"tongue":@"👅",
                     @"cat":@"🐱",
                     @"european_castle":@"🏰",
                     @"herb":@"🌿",
                     @"kissing_cat":@"😽",
                     @"tokyo_tower":@"🗼",
                     @"eggplant":@"🍆",
                     @"spades":@"♠",
                     @"evergreen_tree":@"🌲",
                     @"cold_sweat":@"😰",
                     @"hocho":@"🔪",
                     @"clock10":@"🕙",
                     @"trident":@"🔱",
                     @"u7a7a":@"🈳",
                     @"aries":@"♈",
                     @"newspaper":@"📰",
                     @"congratulations":@"㊗",
                     @"camel":@"🐫",
                     @"point_up_2":@"👆",
                     @"convenience_store":@"🏪",
                     @"dragon_face":@"🐲",
                     @"black_nib":@"✒",
                     @"pouting_cat":@"😾",
                     @"sleepy":@"😪",
                     @"statue_of_liberty":@"🗽",
                     @"taurus":@"♉",
                     @"grapes":@"🍇",
                     @"no_good":@"🙅",
                     @"deciduous_tree":@"🌳",
                     @"scream":@"😱",
                     @"gun":@"🔫",
                     @"mailbox_closed":@"📪",
                     @"black_square_button":@"🔲",
                     @"u5408":@"🈴",
                     @"secret":@"㊙",
                     @"iphone":@"📱",
                     @"recycle":@"♻",
                     @"clubs":@"♣",
                     @"dolphin":@"🐬",
                     @"flipper":@"🐬",
                     @"point_down":@"👇",
                     @"school":@"🏫",
                     @"whale":@"🐳",
                     @"heavy_check_mark":@"✔",
                     @"warning":@"⚠",
                     @"tired_face":@"😫",
                     @"japan":@"🗾",
                     @"copyright":@"©",
                     @"melon":@"🍈",
                     @"crying_cat_face":@"😿",
                     @"palm_tree":@"🌴",
                     @"astonished":@"😲",
                     @"ok_woman":@"🙆",
                     @"microscope":@"🔬",
                     @"u7121":@"🈚",
                     @"mailbox":@"📫",
                     @"white_square_button":@"🔳",
                     @"zap":@"⚡",
                     @"u6e80":@"🈵",
                     @"calling":@"📲",
                     @"mouse":@"🐭",
                     @"hearts":@"♥",
                     @"point_left":@"👈",
                     @"department_store":@"🏬",
                     @"horse":@"🐴",
                     @"tropical_fish":@"🐠",
                     @"heavy_multiplication_x":@"✖",
                     @"grimacing":@"😬",
                     @"moyai":@"🗿",
                     @"new_moon_with_face":@"🌚",
                     @"watermelon":@"🍉",
                     @"bow":@"🙇",
                     @"cactus":@"🌵",
                     @"flushed":@"😳",
                     @"diamonds":@"♦",
                     @"telescope":@"🔭",
                     @"u6307":@"🈯",
                     @"mailbox_with_mail":@"📬",
                     @"red_circle":@"🔴",
                     @"u6709":@"🈶",
                     @"capital_abcd":@"🔠",
                     @"vibration_mode":@"📳",
                     @"cow":@"🐮",
                     @"wheelchair":@"♿",
                     @"point_right":@"👉",
                     @"factory":@"🏭",
                     @"monkey_face":@"🐵",
                     @"shell":@"🐚",
                     @"blowfish":@"🐡",
                     @"house":@"🏠",
                     @"sob":@"😭",
                     @"first_quarter_moon_with_face":@"🌛",
                     @"see_no_evil":@"🙈",
                     @"sleeping":@"😴",
                     @"angry":@"😠",
                     @"hotsprings":@"♨",
                     @"crystal_ball":@"🔮",
                     @"end":@"🔚",
                     @"mailbox_with_no_mail":@"📭",
                     @"large_blue_circle":@"🔵",
                     @"soccer":@"⚽",
                     @"abcd":@"🔡",
                     @"mobile_phone_off":@"📴",
                     @"u6708":@"🈷",
                     @"fax":@"📠",
                     @"tiger":@"🐯",
                     @"star":@"⭐",
                     @"bug":@"🐛",
                     @"izakaya_lantern":@"🏮",
                     @"lantern":@"🏮",
                     @"dog":@"🐶",
                     @"turtle":@"🐢",
                     @"house_with_garden":@"🏡",
                     @"open_mouth":@"😮",
                     @"baseball":@"⚾",
                     @"last_quarter_moon_with_face":@"🌜",
                     @"kissing_closed_eyes":@"😚",
                     @"hear_no_evil":@"🙉",
                     @"tulip":@"🌷",
                     @"eight_spoked_asterisk":@"✳",
                     @"rage":@"😡",
                     @"dizzy_face":@"😵",
                     @"six_pointed_star":@"🔯",
                     @"on":@"🔛",
                     @"postbox":@"📮",
                     @"u7533":@"🈸",
                     @"large_orange_diamond":@"🔶",
                     @"1234":@"🔢",
                     @"no_mobile_phones":@"📵",
                     @"books":@"📚",
                     @"satellite":@"📡",
                     @"x":@"❌",
                     @"eight_pointed_black_star":@"✴",
                     @"ant":@"🐜",
                     @"japanese_castle":@"🏯",
                     @"pig":@"🐷",
                     @"hatching_chick":@"🐣",
                     @"office":@"🏢",
                     @"hushed":@"😯",
                     @"full_moon_with_face":@"🌝",
                     @"stuck_out_tongue":@"😛",
                     @"cherry_blossom":@"🌸",
                     @"information_source":@"ℹ",
                     @"cry":@"😢",
                     @"no_mouth":@"😶",
                     @"globe_with_meridians":@"🌐",
                     @"soon":@"🔜",
                     @"postal_horn":@"📯",
                     @"u5272":@"🈹",
                     @"large_blue_diamond":@"🔷",
                     @"symbols":@"🔣",
                     @"signal_strength":@"📶",
                     @"name_badge":@"📛",
                     @"loudspeaker":@"📢",
                     @"negative_squared_cross_mark":@"❎",
                     @"bee":@"🐝",
                     @"honeybee":@"🐝",
                     @"frog":@"🐸",
                     @"baby_chick":@"🐤",
                     @"goat":@"🐐",
                     @"post_office":@"🏣",
                     @"sun_with_face":@"🌞",
                     @"stuck_out_tongue_winking_eye":@"😜",
                     @"ocean":@"🌊",
                     @"rose":@"🌹",
                     @"mask":@"😷",
                     @"persevere":@"😣",
                     @"o":@"⭕",
                     @"new_moon":@"🌑",
                     @"top":@"🔝",
                     @"small_orange_diamond":@"🔸",
                     @"scroll":@"📜",
                     @"abc":@"🔤",
                     @"camera":@"📷",
                     @"closed_lock_with_key":@"🔐",
                     @"mega":@"📣",
                     @"beetle":@"🐞",
                     @"snowman":@"⛄",
                     @"crocodile":@"🐊",
                     @"hamster":@"🐹",
                     @"hatched_chick":@"🐥",
                     @"sheep":@"🐑",
                     @"european_post_office":@"🏤",
                     @"star2":@"🌟",
                     @"arrow_right_hook":@"↪",
                     @"volcano":@"🌋",
                     @"stuck_out_tongue_closed_eyes":@"😝",
                     @"smile_cat":@"😸",
                     @"triumph":@"😤",
                     @"waxing_crescent_moon":@"🌒",
                     @"partly_sunny":@"⛅",
                     @"neutral_face":@"😐",
                     @"underage":@"🔞",
                     @"speaker":@"🔊",
                     @"small_blue_diamond":@"🔹",
                     @"memo":@"📝",
                     @"pencil":@"📝",
                     @"fire":@"🔥",
                     @"key":@"🔑",
                     @"outbox_tray":@"📤",
                     @"triangular_ruler":@"📐",
                     @"fish":@"🐟",
                     @"whale2":@"🐋",
                     @"bird":@"🐦",
                     @"question":@"❓",
                     @"monkey":@"🐒",
                     @"hospital":@"🏥",
                     @"swimmer":@"🏊",
                     @"disappointed":@"😞",
                     @"milky_way":@"🌌",
                     @"blush":@"😊",
                     @"joy_cat":@"😹",
                     @"disappointed_relieved":@"😥",
                     @"first_quarter_moon":@"🌓",
                     @"expressionless":@"😑",
                     @"keycap_ten":@"🔟",
                     @"grey_question":@"❔",
                     @"battery":@"🔋",
                     @"telephone_receiver":@"📞",
                     @"bar_chart":@"📊",
                     @"video_camera":@"📹",
                     @"flashlight":@"🔦",
                     @"inbox_tray":@"📥",
                     @"lock":@"🔒",
                     @"bookmark_tabs":@"📑",
                     @"snail":@"🐌",
                     @"penguin":@"🐧",
                     @"grey_exclamation":@"❕",
                     @"rooster":@"🐓",
                     @"bank":@"🏦",
                     @"worried":@"😟",
                     @"earth_africa":@"🌍",
                     @"yum":@"😋",
                     @"frowning":@"😦",
                     @"moon":@"🌔",
                     @"waxing_gibbous_moon":@"🌔",
                     @"unamused":@"😒",
                     @"cyclone":@"🌀",
                     @"tent":@"⛺",
                     @"electric_plug":@"🔌",
                     @"pager":@"📟",
                     @"clipboard":@"📋",
                     @"wrench":@"🔧",
                     @"unlock":@"🔓",
                     @"package":@"📦",
                     @"koko":@"🈁",
                     @"ledger":@"📒",
                     @"snake":@"🐍",
                     @"koala":@"🐨",
                     @"chicken":@"🐔",
                     @"atm":@"🏧",
                     @"exclamation":@"❗",
                     @"heavy_exclamation_mark":@"❗",
                     @"rat":@"🐀",
                     @"earth_americas":@"🌎",
                     @"relieved":@"😌",
                     @"anguished":@"😧",
                     @"full_moon":@"🌕",
                     @"sweat":@"😓",
                     @"foggy":@"🌁",
                     @"mag":@"🔍",
                     @"pushpin":@"📌",
                     @"hammer":@"🔨",
                     @"bell":@"🔔",
                     @"e-mail":@"📧",
                     @"sa":@"🈂",
                     @"notebook":@"📓",
                     @"twisted_rightwards_arrows":@"🔀",
                     @"racehorse":@"🐎"};
    
    static NSRegularExpression *_pattern;
    if(!_pattern) {
        NSError *err;
        NSString *pattern = [NSString stringWithFormat:@":(%@):", [[[emojiMap.allKeys componentsJoinedByString:@"|"] stringByReplacingOccurrencesOfString:@"-" withString:@"\\-"] stringByReplacingOccurrencesOfString:@"+" withString:@"\\+"]];
        _pattern = [NSRegularExpression
                    regularExpressionWithPattern:pattern
                    options:0
                    error:&err];
    }
    return _pattern;
}

+(NSRegularExpression *)email {
    static NSRegularExpression *_pattern = nil;
    if(!_pattern) {
        //Ported from Android: https://github.com/android/platform_frameworks_base/blob/master/core/java/android/util/Patterns.java
        NSString *pattern = @"[a-zA-Z0-9\\+\\.\\_\\%\\-\\+]{1,256}\\@[a-zA-Z0-9][a-zA-Z0-9\\-]{0,64}(\\.[a-zA-Z0-9][a-zA-Z0-9\\-]{0,25})+";
        _pattern = [NSRegularExpression
                    regularExpressionWithPattern:pattern
                    options:0
                    error:nil];
    }
    return _pattern;
}

+(NSRegularExpression *)webURL {
    static NSRegularExpression *_pattern = nil;
    if(!_pattern) {
    //Ported from Android: https://github.com/android/platform_frameworks_base/blob/master/core/java/android/util/Patterns.java
    NSString *TOP_LEVEL_DOMAIN_STR_FOR_WEB_URL = @"(?:\
(?:aero|arpa|asia|a[cdefgilmnoqrstuwxz])\
|(?:biz|b[abdefghijmnorstvwyz])\
|(?:cat|com|coop|c[acdfghiklmnoruvxyz])\
|d[ejkmoz]\
|(?:edu|e[cegrstu])\
|f[ijkmor]\
|(?:gov|g[abdefghilmnpqrstuwy])\
|h[kmnrtu]\
|(?:info|int|i[delmnoqrst])\
|(?:jobs|j[emop])\
|k[eghimnprwyz]\
|l[abcikrstuvy]\
|(?:mil|mobi|museum|m[acdeghklmnopqrstuvwxyz])\
|(?:name|net|n[acefgilopruz])\
|(?:org|om)\
|(?:pro|p[aefghklmnrstwy])\
|qa\
|r[eosuw]\
|s[abcdeghijklmnortuvyz]\
|(?:tel|travel|t[cdfghjklmnoprtvwz])\
|u[agksyz]\
|v[aceginu]\
|w[fs]\
|(?:\u03b4\u03bf\u03ba\u03b9\u03bc\u03ae|\u0438\u0441\u043f\u044b\u0442\u0430\u043d\u0438\u0435|\u0440\u0444|\u0441\u0440\u0431|\u05d8\u05e2\u05e1\u05d8|\u0622\u0632\u0645\u0627\u06cc\u0634\u06cc|\u0625\u062e\u062a\u0628\u0627\u0631|\u0627\u0644\u0627\u0631\u062f\u0646|\u0627\u0644\u062c\u0632\u0627\u0626\u0631|\u0627\u0644\u0633\u0639\u0648\u062f\u064a\u0629|\u0627\u0644\u0645\u063a\u0631\u0628|\u0627\u0645\u0627\u0631\u0627\u062a|\u0628\u06be\u0627\u0631\u062a|\u062a\u0648\u0646\u0633|\u0633\u0648\u0631\u064a\u0629|\u0641\u0644\u0633\u0637\u064a\u0646|\u0642\u0637\u0631|\u0645\u0635\u0631|\u092a\u0930\u0940\u0915\u094d\u0937\u093e|\u092d\u093e\u0930\u0924|\u09ad\u09be\u09b0\u09a4|\u0a2d\u0a3e\u0a30\u0a24|\u0aad\u0abe\u0ab0\u0aa4|\u0b87\u0ba8\u0bcd\u0ba4\u0bbf\u0baf\u0bbe|\u0b87\u0bb2\u0b99\u0bcd\u0b95\u0bc8|\u0b9a\u0bbf\u0b99\u0bcd\u0b95\u0baa\u0bcd\u0baa\u0bc2\u0bb0\u0bcd|\u0baa\u0bb0\u0bbf\u0b9f\u0bcd\u0b9a\u0bc8|\u0c2d\u0c3e\u0c30\u0c24\u0c4d|\u0dbd\u0d82\u0d9a\u0dcf|\u0e44\u0e17\u0e22|\u30c6\u30b9\u30c8|\u4e2d\u56fd|\u4e2d\u570b|\u53f0\u6e7e|\u53f0\u7063|\u65b0\u52a0\u5761|\u6d4b\u8bd5|\u6e2c\u8a66|\u9999\u6e2f|\ud14c\uc2a4\ud2b8|\ud55c\uad6d|xn\\-\\-0zwm56d|xn\\-\\-11b5bs3a9aj6g|xn\\-\\-3e0b707e|xn\\-\\-45brj9c|xn\\-\\-80akhbyknj4f|xn\\-\\-90a3ac|xn\\-\\-9t4b11yi5a|xn\\-\\-clchc0ea0b2g2a9gcd|xn\\-\\-deba0ad|xn\\-\\-fiqs8s|xn\\-\\-fiqz9s|xn\\-\\-fpcrj9c3d|xn\\-\\-fzc2c9e2c|xn\\-\\-g6w251d|xn\\-\\-gecrj9c|xn\\-\\-h2brj9c|xn\\-\\-hgbk6aj7f53bba|xn\\-\\-hlcj6aya9esc7a|xn\\-\\-j6w193g|xn\\-\\-jxalpdlp|xn\\-\\-kgbechtv|xn\\-\\-kprw13d|xn\\-\\-kpry57d|xn\\-\\-lgbbat1ad8j|xn\\-\\-mgbaam7a8h|xn\\-\\-mgbayh7gpa|xn\\-\\-mgbbh1a71e|xn\\-\\-mgbc0a9azcg|xn\\-\\-mgberp4a5d4ar|xn\\-\\-o3cw4h|xn\\-\\-ogbpf8fl|xn\\-\\-p1ai|xn\\-\\-pgbs0dh|xn\\-\\-s9brj9c|xn\\-\\-wgbh1c|xn\\-\\-wgbl6a|xn\\-\\-xkc2al3hye2a|xn\\-\\-xkc2dl3a5ee0h|xn\\-\\-yfro4i67o|xn\\-\\-ygbi2ammx|xn\\-\\-zckzah|xxx)\
|y[et]\
|z[amw]))";
    NSString *GOOD_IRI_CHAR = @"a-zA-Z0-9\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF";
    NSString *pattern = [NSString stringWithFormat:@"((?:(http|https|Http|Https|rtsp|Rtsp|irc|ircs):\\/\\/(?:(?:[a-zA-Z0-9\\$\\-\\_\\.\\+\\!\\*\\'\\(\\)\
\\,\\;\\?\\&\\=]|(?:\\%%[a-fA-F0-9]{2})){1,64}(?:\\:(?:[a-zA-Z0-9\\$\\-\\_\
\\.\\+\\!\\*\\'\\(\\)\\,\\;\\?\\&\\=]|(?:\\%%[a-fA-F0-9]{2})){1,25})?\\@)?)?\
((?:(?:[%@][%@\\-]{0,64}\\.)+%@\
|(?:(?:25[0-5]|2[0-4]\
[0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9])\\.(?:25[0-5]|2[0-4][0-9]\
|[0-1][0-9]{2}|[1-9][0-9]|[1-9]|0)\\.(?:25[0-5]|2[0-4][0-9]|[0-1]\
[0-9]{2}|[1-9][0-9]|[1-9]|0)\\.(?:25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}\
|[1-9][0-9]|[0-9])))\
(?:\\:\\d{1,5})?)\
(\\/(?:(?:[%@\\;\\/\\?\\:\\@\\&\\=\\#\\~\\$\
\\-\\.\\+\\!\\*\\'\\(\\)\\,\\_])|(?:\\%%[a-fA-F0-9]{2}))*)?\
(?:\\b|$)", GOOD_IRI_CHAR, GOOD_IRI_CHAR, TOP_LEVEL_DOMAIN_STR_FOR_WEB_URL, GOOD_IRI_CHAR];
    _pattern = [NSRegularExpression
            regularExpressionWithPattern:pattern
            options:0
            error:nil];
    }
    return _pattern;
}

+(NSRegularExpression *)ircChannelRegexForServer:(Server *)s {
    NSString *pattern;
    if(s && s.CHANTYPES.length) {
        pattern = [NSString stringWithFormat:@"(\\s|^)([%@][^\\ufe0e\\ufe0f\\u20e3<>!?\"()\\[\\],\\s\\u0001]+)", s.CHANTYPES];
    } else {
        pattern = [NSString stringWithFormat:@"(\\s|^)([#][^\\ufe0e\\ufe0f\\u20e3<>!?\"()\\[\\],\\s\\u0001]+)"];
    }
    
    return [NSRegularExpression
            regularExpressionWithPattern:pattern
            options:0
            error:nil];
}

+(NSAttributedString *)format:(NSString *)input defaultColor:(UIColor *)color mono:(BOOL)mono linkify:(BOOL)linkify server:(Server *)server links:(NSArray **)links {
    int bold = -1, italics = -1, underline = -1, fg = -1, bg = -1;
    UIColor *fgColor = nil, *bgColor = nil;
    CTFontRef font, boldFont, italicFont, boldItalicFont;
    CGFloat lineSpacing = 6;
    NSMutableArray *matches = [[NSMutableArray alloc] init];
    
    if(!Courier) {
#ifdef __IPHONE_7_0
        if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 7) {
#endif
            arrowFont = CTFontCreateWithName((CFStringRef)@"HiraMinProN-W3", FONT_SIZE, NULL);
            Courier = CTFontCreateWithName((CFStringRef)@"Courier", FONT_SIZE, NULL);
            CourierBold = CTFontCreateWithName((CFStringRef)@"Courier-Bold", FONT_SIZE, NULL);
            CourierOblique = CTFontCreateWithName((CFStringRef)@"Courier-Oblique", FONT_SIZE, NULL);
            CourierBoldOblique = CTFontCreateWithName((CFStringRef)@"Courier-BoldOblique", FONT_SIZE, NULL);
            Helvetica = CTFontCreateWithName((CFStringRef)@"Helvetica", FONT_SIZE, NULL);
            HelveticaBold = CTFontCreateWithName((CFStringRef)@"Helvetica-Bold", FONT_SIZE, NULL);
            HelveticaOblique = CTFontCreateWithName((CFStringRef)@"Helvetica-Oblique", FONT_SIZE, NULL);
            HelveticaBoldOblique = CTFontCreateWithName((CFStringRef)@"Helvetica-BoldOblique", FONT_SIZE, NULL);
#ifdef __IPHONE_7_0
        } else {
            UIFontDescriptor *bodyFontDesciptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
            UIFontDescriptor *boldBodyFontDescriptor = [bodyFontDesciptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
            UIFontDescriptor *italicBodyFontDescriptor = [bodyFontDesciptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
            UIFontDescriptor *boldItalicBodyFontDescriptor = [bodyFontDesciptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold|UIFontDescriptorTraitItalic];
            arrowFont = CTFontCreateWithName((CFStringRef)@"HiraMinProN-W3", bodyFontDesciptor.pointSize * 0.8, NULL);
            Courier = CTFontCreateWithName((CFStringRef)@"Courier", bodyFontDesciptor.pointSize * 0.8, NULL);
            CourierBold = CTFontCreateWithName((CFStringRef)@"Courier-Bold", bodyFontDesciptor.pointSize * 0.8, NULL);
            CourierOblique = CTFontCreateWithName((CFStringRef)@"Courier-Oblique", bodyFontDesciptor.pointSize * 0.8, NULL);
            CourierBoldOblique = CTFontCreateWithName((CFStringRef)@"Courier-BoldOblique", bodyFontDesciptor.pointSize * 0.8, NULL);
            Helvetica = CTFontCreateWithName((CFStringRef)[bodyFontDesciptor.fontAttributes objectForKey:UIFontDescriptorNameAttribute], bodyFontDesciptor.pointSize * 0.8, NULL);
            HelveticaBold = CTFontCreateWithName((CFStringRef)[boldBodyFontDescriptor.fontAttributes objectForKey:UIFontDescriptorNameAttribute], boldBodyFontDescriptor.pointSize * 0.8, NULL);
            HelveticaOblique = CTFontCreateWithName((CFStringRef)[italicBodyFontDescriptor.fontAttributes objectForKey:UIFontDescriptorNameAttribute], italicBodyFontDescriptor.pointSize * 0.8, NULL);
            HelveticaBoldOblique = CTFontCreateWithName((CFStringRef)[boldItalicBodyFontDescriptor.fontAttributes objectForKey:UIFontDescriptorNameAttribute], boldItalicBodyFontDescriptor.pointSize * 0.8, NULL);
        }
#endif
    }
    if(mono) {
        font = Courier;
        boldFont = CourierBold;
        italicFont = CourierOblique;
        boldItalicFont = CourierBoldOblique;
    } else {
        font = Helvetica;
        boldFont = HelveticaBold;
        italicFont = HelveticaOblique;
        boldItalicFont = HelveticaBoldOblique;
    }
    NSMutableArray *attributes = [[NSMutableArray alloc] init];
    NSMutableArray *arrowIndex = [[NSMutableArray alloc] init];
    
    NSMutableString *text = [[NSMutableString alloc] initWithFormat:@"%@%c", input, CLEAR];
    NSInteger offset = 0;
    NSArray *results = [[self emoji] matchesInString:[text lowercaseString] options:0 range:NSMakeRange(0, text.length)];
    for(NSTextCheckingResult *result in results) {
        for(int i = 1; i < result.numberOfRanges; i++) {
            NSRange range = [result rangeAtIndex:i];
            range.location -= offset;
            NSString *token = [text substringWithRange:range];
            if([emojiMap objectForKey:token.lowercaseString]) {
                NSString *emoji = [emojiMap objectForKey:token.lowercaseString];
                [text replaceCharactersInRange:NSMakeRange(range.location - 1, range.length + 2) withString:emoji];
                offset += range.length - emoji.length + 2;
            }
        }
    }
    
    for(int i = 0; i < text.length; i++) {
        switch([text characterAtIndex:i]) {
            case 0x2190:
            case 0x2192:
            case 0x2194:
            case 0x21D0:
                [arrowIndex addObject:@(i)];
                break;
            case BOLD:
                if(bold == -1) {
                    bold = i;
                } else {
                    if(italics != -1) {
                        if(italics < bold - 1) {
                            [attributes addObject:@{
                             (NSString *)kCTFontAttributeName:(__bridge id)italicFont,
                             @"start":@(italics),
                             @"length":@(bold - italics)
                             }];
                        }
                        [attributes addObject:@{
                         (NSString *)kCTFontAttributeName:(__bridge id)boldItalicFont,
                         @"start":@(bold),
                         @"length":@(i - bold)
                         }];
                        italics = i;
                    } else {
                        [attributes addObject:@{
                         (NSString *)kCTFontAttributeName:(__bridge id)boldFont,
                         @"start":@(bold),
                         @"length":@(i - bold)
                         }];
                    }
                    bold = -1;
                }
                [text deleteCharactersInRange:NSMakeRange(i,1)];
                i--;
                continue;
            case ITALICS:
            case 29:
                if(italics == -1) {
                    italics = i;
                } else {
                    if(bold != -1) {
                        if(bold < italics - 1) {
                            [attributes addObject:@{
                             (NSString *)kCTFontAttributeName:(__bridge id)boldFont,
                             @"start":@(bold),
                             @"length":@(italics - bold)
                             }];
                        }
                        [attributes addObject:@{
                         (NSString *)kCTFontAttributeName:(__bridge id)boldItalicFont,
                         @"start":@(italics),
                         @"length":@(i - italics)
                         }];
                        bold = i;
                    } else {
                        [attributes addObject:@{
                         (NSString *)kCTFontAttributeName:(__bridge id)italicFont,
                         @"start":@(italics),
                         @"length":@(i - italics)
                         }];
                    }
                    italics = -1;
                }
                [text deleteCharactersInRange:NSMakeRange(i,1)];
                i--;
                continue;
            case UNDERLINE:
                if(underline == -1) {
                    underline = i;
                } else {
                    [attributes addObject:@{
                     (NSString *)kCTUnderlineStyleAttributeName:@1,
                     @"start":@(underline),
                     @"length":@(i - underline)
                     }];
                    underline = -1;
                }
                [text deleteCharactersInRange:NSMakeRange(i,1)];
                i--;
                continue;
            case COLOR_MIRC:
            case COLOR_RGB:
                if(fg != -1) {
                    [attributes addObject:@{
                     (NSString *)kCTForegroundColorAttributeName:(__bridge id)[fgColor CGColor],
                     @"start":@(fg),
                     @"length":@(i - fg)
                     }];
                    fg = -1;
                }
                if(bg != -1) {
                    [attributes addObject:@{
                     (NSString *)kTTTBackgroundFillColorAttributeName:(__bridge id)[bgColor CGColor],
                     @"start":@(bg),
                     @"length":@(i - bg)
                     }];
                    bg = -1;
                }
                BOOL rgb = [text characterAtIndex:i] == COLOR_RGB;
                int count = 0;
                [text deleteCharactersInRange:NSMakeRange(i,1)];
                if(i < text.length) {
                    while(i+count < text.length && (([text characterAtIndex:i+count] >= '0' && [text characterAtIndex:i+count] <= '9') ||
                                                    (rgb && (([text characterAtIndex:i+count] >= 'a' && [text characterAtIndex:i+count] <= 'f')||
                                                            ([text characterAtIndex:i+count] >= 'A' && [text characterAtIndex:i+count] <= 'F'))))) {
                        if((++count == 2 && !rgb) || (count == 6))
                            break;
                    }
                    if(count > 0) {
                        if(count < 3 && !rgb) {
                            int color = [[text substringWithRange:NSMakeRange(i, count)] intValue];
                            if(color > 15) {
                                count--;
                                color /= 10;
                            }
                            fgColor = [UIColor mIRCColor:color];
                        } else {
                            fgColor = [UIColor colorFromHexString:[text substringWithRange:NSMakeRange(i, count)]];
                        }
                        [text deleteCharactersInRange:NSMakeRange(i,count)];
                        fg = i;
                    }
                }
                if(i < text.length && [text characterAtIndex:i] == ',') {
                    [text deleteCharactersInRange:NSMakeRange(i,1)];
                    count = 0;
                    while(i+count < text.length && (([text characterAtIndex:i+count] >= '0' && [text characterAtIndex:i+count] <= '9') ||
                                                    (rgb && (([text characterAtIndex:i+count] >= 'a' && [text characterAtIndex:i+count] <= 'f')||
                                                             ([text characterAtIndex:i+count] >= 'A' && [text characterAtIndex:i+count] <= 'F'))))) {
                        if(++count == 2 && !rgb)
                            break;
                    }
                    if(count > 0) {
                        if(count < 3 && !rgb) {
                            int color = [[text substringWithRange:NSMakeRange(i, count)] intValue];
                            if(color > 15) {
                                count--;
                                color /= 10;
                            }
                            bgColor = [UIColor mIRCColor:color];
                        } else {
                            bgColor = [UIColor colorFromHexString:[text substringWithRange:NSMakeRange(i, count)]];
                        }
                        [text deleteCharactersInRange:NSMakeRange(i,count)];
                        bg = i;
                    }
                }
                i--;
                continue;
            case CLEAR:
                if(fg != -1) {
                    [attributes addObject:@{
                     (NSString *)kCTForegroundColorAttributeName:(__bridge id)[fgColor CGColor],
                     @"start":@(fg),
                     @"length":@(i - fg)
                     }];
                    fg = -1;
                }
                if(bg != -1) {
                    [attributes addObject:@{
                     (NSString *)kTTTBackgroundFillColorAttributeName:(__bridge id)[bgColor CGColor],
                     @"start":@(bg),
                     @"length":@(i - bg)
                     }];
                    bg = -1;
                }
                if(bold != -1 && italics != -1) {
                    if(bold < italics) {
                        [attributes addObject:@{
                         (NSString *)kCTFontAttributeName:(__bridge id)boldFont,
                         @"start":@(bold),
                         @"length":@(italics - bold)
                         }];
                        [attributes addObject:@{
                         (NSString *)kCTFontAttributeName:(__bridge id)boldItalicFont,
                         @"start":@(italics),
                         @"length":@(i - italics)
                         }];
                    } else {
                        [attributes addObject:@{
                         (NSString *)kCTFontAttributeName:(__bridge id)italicFont,
                         @"start":@(italics),
                         @"length":@(bold - italics)
                         }];
                        [attributes addObject:@{
                         (NSString *)kCTFontAttributeName:(__bridge id)boldItalicFont,
                         @"start":@(bold),
                         @"length":@(i - bold)
                         }];
                    }
                } else if(bold != -1) {
                    [attributes addObject:@{
                     (NSString *)kCTFontAttributeName:(__bridge id)boldFont,
                     @"start":@(bold),
                     @"length":@(i - bold)
                     }];
                } else if(italics != -1) {
                    [attributes addObject:@{
                     (NSString *)kCTFontAttributeName:(__bridge id)italicFont,
                     @"start":@(italics),
                     @"length":@(i - italics)
                     }];
                } else if(underline != -1) {
                    [attributes addObject:@{
                     (NSString *)kCTUnderlineStyleAttributeName:@1,
                     @"start":@(underline),
                     @"length":@(i - underline)
                     }];
                }
                bold = -1;
                italics = -1;
                underline = -1;
                [text deleteCharactersInRange:NSMakeRange(i,1)];
                i--;
                continue;
        }
    }
    
    NSMutableAttributedString *output = [[NSMutableAttributedString alloc] initWithString:text];
    [output addAttributes:@{(NSString *)kCTFontAttributeName:(__bridge id)font} range:NSMakeRange(0, text.length)];
    [output addAttributes:@{(NSString *)kCTForegroundColorAttributeName:(__bridge id)[color CGColor]} range:NSMakeRange(0, text.length)];

    for(NSNumber *i in arrowIndex) {
        [output addAttributes:@{(NSString *)kCTFontAttributeName:(__bridge id)arrowFont} range:NSMakeRange([i intValue], 1)];
    }
    
    CTParagraphStyleSetting paragraphStyle;
    paragraphStyle.spec = kCTParagraphStyleSpecifierLineSpacing;
    paragraphStyle.valueSize = sizeof(CGFloat);
    paragraphStyle.value = &lineSpacing;
    
    CTParagraphStyleRef style = CTParagraphStyleCreate((const CTParagraphStyleSetting*) &paragraphStyle, 1);
    [output addAttribute:(NSString*)kCTParagraphStyleAttributeName value:(__bridge id)style range:NSMakeRange(0, [output length])];
    CFRelease(style);
    
    for(NSDictionary *dict in attributes) {
        [output addAttributes:dict range:NSMakeRange([[dict objectForKey:@"start"] intValue], [[dict objectForKey:@"length"] intValue])];
    }
    
    if(linkify) {
        NSArray *results = [[self email] matchesInString:[[output string] lowercaseString] options:0 range:NSMakeRange(0, [output length])];
        for(NSTextCheckingResult *result in results) {
            NSString *url = [[output string] substringWithRange:result.range];
            url = [NSString stringWithFormat:@"mailto:%@", url];
            [matches addObject:[NSTextCheckingResult linkCheckingResultWithRange:result.range URL:[NSURL URLWithString:url]]];
        }
        if(server) {
            results = [[self ircChannelRegexForServer:server] matchesInString:[[output string] lowercaseString] options:0 range:NSMakeRange(0, [output length])];
            if(results.count) {
                for(NSTextCheckingResult *match in results) {
                    NSRange matchRange = [match rangeAtIndex:2];
                    if([[[output string] substringWithRange:matchRange] hasSuffix:@"."]) {
                        NSRange ranges[1] = {NSMakeRange(matchRange.location, matchRange.length - 1)};
                        [matches addObject:[NSTextCheckingResult regularExpressionCheckingResultWithRanges:ranges count:1 regularExpression:match.regularExpression]];
                    } else {
                        NSRange ranges[1] = {NSMakeRange(matchRange.location, matchRange.length)};
                        [matches addObject:[NSTextCheckingResult regularExpressionCheckingResultWithRanges:ranges count:1 regularExpression:match.regularExpression]];
                    }
                }
            }
        }
        results = [[self webURL] matchesInString:[[output string] lowercaseString] options:0 range:NSMakeRange(0, [output length])];
        for(NSTextCheckingResult *result in results) {
            BOOL overlap = NO;
            for(NSTextCheckingResult *match in matches) {
                if(result.range.location >= match.range.location && result.range.location <= match.range.location + match.range.length) {
                    overlap = YES;
                    break;
                }
            }
            if(!overlap) {
                NSString *url = [NSURL IDNEncodedURL:[[output string] substringWithRange:result.range]];
                if([url rangeOfString:@"://"].location == NSNotFound)
                    url = [NSString stringWithFormat:@"http://%@", url];
                [matches addObject:[NSTextCheckingResult linkCheckingResultWithRange:result.range URL:[NSURL URLWithString:url]]];
            }
        }
    } else {
        if(server) {
            NSArray *results = [[self ircChannelRegexForServer:server] matchesInString:[[output string] lowercaseString] options:0 range:NSMakeRange(0, [output length])];
            if(results.count) {
                for(NSTextCheckingResult *match in results) {
                    if([[[output string] substringWithRange:match.range] hasSuffix:@"."]) {
                        NSRange ranges[1] = {NSMakeRange(match.range.location, match.range.length - 1)};
                        [matches addObject:[NSTextCheckingResult regularExpressionCheckingResultWithRanges:ranges count:1 regularExpression:match.regularExpression]];
                    } else {
                        [matches addObject:match];
                    }
                }
            }
        }
    }
    if(links)
        *links = [NSArray arrayWithArray:matches];
    return output;
}
@end
