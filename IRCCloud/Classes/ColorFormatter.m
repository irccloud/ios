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
#import "NetworkConnection.h"

CTFontRef Courier = NULL, CourierBold, CourierOblique,CourierBoldOblique;
CTFontRef Helvetica, HelveticaBold, HelveticaOblique,HelveticaBoldOblique;
CTFontRef arrowFont;
UIFont *timestampFont;
NSDictionary *emojiMap;
NSDictionary *quotes;
float ColorFormatterCachedFontSize = 0.0f;

@implementation ColorFormatter

+(BOOL)shouldClearFontCache {
    if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 7) {
        return NO;
    } else {
        UIFontDescriptor *bodyFontDesciptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
        return ColorFormatterCachedFontSize != bodyFontDesciptor.pointSize;
    }
}

+(void)clearFontCache {
    CLS_LOG(@"Clearing font cache");
    if(Courier) {
        CFRelease(Courier);
        CFRelease(CourierBold);
        CFRelease(CourierBoldOblique);
        CFRelease(CourierOblique);
        CFRelease(Helvetica);
        CFRelease(HelveticaBold);
        CFRelease(HelveticaBoldOblique);
        CFRelease(HelveticaOblique);
        CFRelease(arrowFont);
    }
    Courier = CourierBold = CourierBoldOblique = CourierOblique = Helvetica = HelveticaBold = HelveticaBoldOblique = HelveticaOblique = arrowFont = NULL;
    timestampFont = NULL;
}

+(UIFont *)timestampFont {
    if(!timestampFont) {
        if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 7)
            timestampFont = [UIFont systemFontOfSize:FONT_SIZE];
        else {
            timestampFont = [UIFont preferredFontForTextStyle:UIFontTextStyleBody];
            timestampFont = [UIFont fontWithName:timestampFont.fontName size:timestampFont.pointSize * 0.8];
        }
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
                     @"nine":@"9⃣",
                     @"basketball":@"🏀",
                     @"earth_asia":@"🌏",
                     @"heart_eyes":@"😍",
                     @"arrow_heading_down":@"⤵️",
                     @"fearful":@"😨",
                     @"o":@"⭕️",
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
                     @"arrow_forward":@"▶️",
                     @"dvd":@"📀",
                     @"ram":@"🐏",
                     @"cloud":@"☁️",
                     @"curly_loop":@"➰",
                     @"trumpet":@"🎺",
                     @"love_hotel":@"🏩",
                     @"pig2":@"🐖",
                     @"fast_forward":@"⏩",
                     @"ox":@"🐂",
                     @"checkered_flag":@"🏁",
                     @"sunglasses":@"😎",
                     @"weary":@"😩",
                     @"heavy_multiplication_x":@"✖️",
                     @"last_quarter_moon":@"🌗",
                     @"confused":@"😕",
                     @"night_with_stars":@"🌃",
                     @"grin":@"😁",
                     @"lock_with_ink_pen":@"🔏",
                     @"paperclip":@"📎",
                     @"black_large_square":@"⬛️",
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
                     @"scissors":@"✂️",
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
                     @"snowflake":@"❄️",
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
                     @"black_medium_small_square":@"◾️",
                     @"briefcase":@"💼",
                     @"radio_button":@"🔘",
                     @"arrows_counterclockwise":@"🔄",
                     @"green_book":@"📗",
                     @"black_small_square":@"▪️",
                     @"page_with_curl":@"📃",
                     @"arrow_upper_left":@"↖",
                     @"running_shirt_with_sash":@"🎽",
                     @"octopus":@"🐙",
                     @"tiger2":@"🐅",
                     @"restroom":@"🚻",
                     @"surfer":@"🏄",
                     @"passport_control":@"🛂",
                     @"slot_machine":@"🎰",
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
                     @"page_facing_up":@"📄",
                     @"moneybag":@"💰",
                     @"arrow_lower_right":@"↘",
                     @"tennis":@"🎾",
                     @"baby_symbol":@"🚼",
                     @"circus_tent":@"🎪",
                     @"leopard":@"🐆",
                     @"black_circle":@"⚫️",
                     @"customs":@"🛃",
                     @"8ball":@"🎱",
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
                     @"currency_exchange":@"💱",
                     @"heavy_minus_sign":@"➖",
                     @"ski":@"🎿",
                     @"toilet":@"🚽",
                     @"ticket":@"🎫",
                     @"rabbit2":@"🐇",
                     @"umbrella":@"☔️",
                     @"trophy":@"🏆",
                     @"baggage_claim":@"🛄",
                     @"game_die":@"🎲",
                     @"potable_water":@"🚰",
                     @"rainbow":@"🌈",
                     @"laughing":@"😆",
                     @"satisfied":@"😆",
                     @"heavy_division_sign":@"➗",
                     @"cd":@"💿",
                     @"mute":@"🔇",
                     @"dizzy":@"💫",
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
                     @"bridge_at_night":@"🌉",
                     @"innocent":@"😇",
                     @"coffee":@"☕",
                     @"white_large_square":@"⬜️",
                     @"speaker":@"🔈",
                     @"speech_balloon":@"💬",
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
                     @"smiling_imp":@"😈",
                     @"parking":@"🅿️",
                     @"sound":@"🔉",
                     @"thought_balloon":@"💭",
                     @"sparkle":@"❇️",
                     @"chart_with_upwards_trend":@"📈",
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
                     @"eight_spoked_asterisk":@"✳️",
                     @"gemini":@"♊️",
                     @"gemini":@"♊",
                     @"white_flower":@"💮",
                     @"white_small_square":@"▫️",
                     @"chart_with_downwards_trend":@"📉",
                     @"spades":@"♠️",
                     @"dollar":@"💵",
                     @"five":@"5️⃣",
                     @"bulb":@"💡",
                     @"dart":@"🎯",
                     @"no_smoking":@"🚭",
                     @"zero":@"0⃣",
                     @"notes":@"🎶",
                     @"cancer":@"♋",
                     @"roller_coaster":@"🎢",
                     @"mountain_cableway":@"🚠",
                     @"bicyclist":@"🚴",
                     @"no_entry":@"⛔️",
                     @"seven":@"7️⃣",
                     @"leftwards_arrow_with_hook":@"↩️",
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
                     @"coffee":@"☕️",
                     @"arrow_left":@"⬅",
                     @"guitar":@"🎸",
                     @"walking":@"🚶",
                     @"microphone":@"🎤",
                     @"scorpius":@"♏",
                     @"arrow_heading_down":@"⤵",
                     @"ship":@"🚢",
                     @"mahjong":@"🀄️",
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
                     @"point_up":@"☝️",
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
                     @"eight_pointed_black_star":@"✴️",
                     @"free":@"🆓",
                     @"couple_with_heart":@"💑",
                     @"black_circle":@"⚫",
                     @"cancer":@"♋️",
                     @"monorail":@"🚝",
                     @"arrow_backward":@"◀️",
                     @"tanabata_tree":@"🎋",
                     @"droplet":@"💧",
                     @"virgo":@"♍️",
                     @"fr":@"🇫🇷",
                     @"white_medium_square":@"◻",
                     @"school_satchel":@"🎒",
                     @"minibus":@"🚐",
                     @"one":@"1⃣",
                     @"art":@"🎨",
                     @"airplane":@"✈",
                     @"vertical_traffic_light":@"🚦",
                     @"v":@"✌️",
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
                     @"recycle":@"♻️",
                     @"heart":@"❤️",
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
                     @"train":@"🚋",
                     @"fire_engine":@"🚒",
                     @"ribbon":@"🎀",
                     @"rotating_light":@"🚨",
                     @"arrow_up":@"⬆️",
                     @"part_alternation_mark":@"〽️",
                     @"ring":@"💍",
                     @"golf":@"⛳️",
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
                     @"one":@"1️⃣",
                     @"couplekiss":@"💏",
                     @"ghost":@"👻",
                     @"sparkling_heart":@"💖",
                     @"sos":@"🆘",
                     @"guardsman":@"💂",
                     @"u7121":@"🈚️",
                     @"a":@"🅰",
                     @"trolleybus":@"🚎",
                     @"baby_bottle":@"🍼",
                     @"three":@"3️⃣",
                     @"ophiuchus":@"⛎",
                     @"taxi":@"🚕",
                     @"jack_o_lantern":@"🎃",
                     @"helicopter":@"🚁",
                     @"anchor":@"⚓",
                     @"congratulations":@"㊗️",
                     @"o2":@"🅾",
                     @"angel":@"👼",
                     @"rewind":@"⏪",
                     @"heartpulse":@"💗",
                     @"snowflake":@"❄",
                     @"dancer":@"💃",
                     @"up":@"🆙",
                     @"b":@"🅱",
                     @"leo":@"♌️",
                     @"busstop":@"🚏",
                     @"libra":@"♎️",
                     @"secret":@"㊙️",
                     @"star":@"⭐️",
                     @"oncoming_taxi":@"🚖",
                     @"christmas_tree":@"🎄",
                     @"steam_locomotive":@"🚂",
                     @"cake":@"🍰",
                     @"arrow_double_up":@"⏫",
                     @"two":@"2⃣",
                     @"watch":@"⌚️",
                     @"relaxed":@"☺️",
                     @"parking":@"🅿",
                     @"alien":@"👽",
                     @"sagittarius":@"♐️",
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
                     @"bento":@"🍱",
                     @"snowman":@"⛄️",
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
                     @"arrow_left":@"⬅️",
                     @"arrow_down":@"⬇️",
                     @"alarm_clock":@"⏰",
                     @"it":@"🇮🇹",
                     @"fountain":@"⛲️",
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
                     @"interrobang":@"⁉️",
                     @"balloon":@"🎈",
                     @"train2":@"🚆",
                     @"fork_and_knife":@"🍴",
                     @"arrow_right":@"➡️",
                     @"sweet_potato":@"🍠",
                     @"airplane":@"✈️",
                     @"fountain":@"⛲",
                     @"two_women_holding_hands":@"👭",
                     @"barber":@"💈",
                     @"tent":@"⛺️",
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
                     @"scorpius":@"♏️",
                     @"sandal":@"👡",
                     @"clubs":@"♣️",
                     @"boat":@"⛵",
                     @"sailboat":@"⛵",
                     @"honey_pot":@"🍯",
                     @"curry":@"🍛",
                     @"light_rail":@"🚈",
                     @"three":@"3⃣",
                     @"sake":@"🍶",
                     @"oden":@"🍢",
                     @"clock11":@"🕚",
                     @"clock630":@"🕡",
                     @"hourglass":@"⌛️",
                     @"dancers":@"👯",
                     @"capricorn":@"♑️",
                     @"purse":@"👛",
                     @"loop":@"➿",
                     @"hash":@"#️⃣",
                     @"baby":@"👶",
                     @"m":@"Ⓜ",
                     @"boot":@"👢",
                     @"ramen":@"🍜",
                     @"station":@"🚉",
                     @"wine_glass":@"🍷",
                     @"watch":@"⌚",
                     @"sushi":@"🍣",
                     @"sunny":@"☀",
                     @"anchor":@"⚓️",
                     @"partly_sunny":@"⛅️",
                     @"clock12":@"🕛",
                     @"clock730":@"🕢",
                     @"ideograph_advantage":@"🉐",
                     @"hourglass":@"⌛",
                     @"handbag":@"👜",
                     @"cloud":@"☁",
                     @"construction_worker":@"👷",
                     @"footprints":@"👣",
                     @"spaghetti":@"🍝",
                     @"cocktail":@"🍸",
                     @"fried_shrimp":@"🍤",
                     @"pear":@"🍐",
                     @"clock130":@"🕜",
                     @"clock830":@"🕣",
                     @"accept":@"🉑",
                     @"boat":@"⛵️",
                     @"sailboat":@"⛵️",
                     @"pouch":@"👝",
                     @"princess":@"👸",
                     @"bust_in_silhouette":@"👤",
                     @"eight":@"8️⃣",
                     @"open_hands":@"👐",
                     @"left_right_arrow":@"↔️",
                     @"arrow_upper_left":@"↖️",
                     @"bread":@"🍞",
                     @"tangerine":@"🍊",
                     @"tropical_drink":@"🍹",
                     @"fish_cake":@"🍥",
                     @"peach":@"🍑",
                     @"clock230":@"🕝",
                     @"clock930":@"🕤",
                     @"aries":@"♈️",
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
                     @"email":@"✉️",
                     @"envelope":@"✉️",
                     @"clock330":@"🕞",
                     @"clock1030":@"🕥",
                     @"clock2":@"🕑",
                     @"m":@"Ⓜ️",
                     @"athletic_shoe":@"👟",
                     @"wave":@"👋",
                     @"white_small_square":@"▫",
                     @"boy":@"👦",
                     @"bangbang":@"‼",
                     @"womans_hat":@"👒",
                     @"banana":@"🍌",
                     @"speak_no_evil":@"🙊",
                     @"shaved_ice":@"🍧",
                     @"phone":@"☎️",
                     @"telephone":@"☎️",
                     @"strawberry":@"🍓",
                     @"clock430":@"🕟",
                     @"cn":@"🇨🇳",
                     @"clock1130":@"🕦",
                     @"clock3":@"🕒",
                     @"ok_hand":@"👌",
                     @"diamonds":@"♦️",
                     @"girl":@"👧",
                     @"relaxed":@"☺",
                     @"eyeglasses":@"👓",
                     @"pineapple":@"🍍",
                     @"raising_hand":@"🙋",
                     @"four":@"4⃣",
                     @"ice_cream":@"🍨",
                     @"information_source":@"ℹ️",
                     @"hamburger":@"🍔",
                     @"four_leaf_clover":@"🍀",
                     @"pencil2":@"✏️",
                     @"u55b6":@"🈺",
                     @"clock1230":@"🕧",
                     @"clock4":@"🕓",
                     @"part_alternation_mark":@"〽",
                     @"aquarius":@"♒️",
                     @"+1":@"👍",
                     @"thumbsup":@"👍",
                     @"man":@"👨",
                     @"necktie":@"👔",
                     @"eyes":@"👀",
                     @"bangbang":@"‼️",
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
                     @"warning":@"⚠️",
                     @"jeans":@"👖",
                     @"ear":@"👂",
                     @"arrow_up_down":@"↕️",
                     @"arrow_upper_right":@"↗️",
                     @"person_with_pouting_face":@"🙎",
                     @"blossom":@"🌼",
                     @"smiley_cat":@"😺",
                     @"poultry_leg":@"🍗",
                     @"leaves":@"🍃",
                     @"fist":@"✊",
                     @"es":@"🇪🇸",
                     @"small_red_triangle_down":@"🔻",
                     @"white_medium_square":@"◻️",
                     @"clock7":@"🕖",
                     @"tv":@"📺",
                     @"taurus":@"♉️",
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
                     @"rice_ball":@"🍙",
                     @"mount_fuji":@"🗻",
                     @"tomato":@"🍅",
                     @"seedling":@"🌱",
                     @"arrow_down_small":@"🔽",
                     @"clock9":@"🕘",
                     @"vhs":@"📼",
                     @"church":@"⛪️",
                     @"beginner":@"🔰",
                     @"u7981":@"🈲",
                     @"feet":@"🐾",
                     @"paw_prints":@"🐾",
                     @"hearts":@"♥️",
                     @"dromedary_camel":@"🐪",
                     @"bikini":@"👙",
                     @"pencil2":@"✏",
                     @"tongue":@"👅",
                     @"cat":@"🐱",
                     @"european_castle":@"🏰",
                     @"herb":@"🌿",
                     @"kissing_cat":@"😽",
                     @"five":@"5⃣",
                     @"tokyo_tower":@"🗼",
                     @"seven":@"7⃣",
                     @"eggplant":@"🍆",
                     @"ballot_box_with_check":@"☑️",
                     @"spades":@"♠",
                     @"evergreen_tree":@"🌲",
                     @"cold_sweat":@"😰",
                     @"hocho":@"🔪",
                     @"knife":@"🔪",
                     @"clock10":@"🕙",
                     @"two":@"2️⃣",
                     @"trident":@"🔱",
                     @"u7a7a":@"🈳",
                     @"aries":@"♈",
                     @"newspaper":@"📰",
                     @"congratulations":@"㊗",
                     @"pisces":@"♓️",
                     @"camel":@"🐫",
                     @"point_up_2":@"👆",
                     @"convenience_store":@"🏪",
                     @"dragon_face":@"🐲",
                     @"hash":@"#⃣",
                     @"black_nib":@"✒",
                     @"pouting_cat":@"😾",
                     @"sleepy":@"😪",
                     @"statue_of_liberty":@"🗽",
                     @"taurus":@"♉",
                     @"grapes":@"🍇",
                     @"no_good":@"🙅",
                     @"deciduous_tree":@"🌳",
                     @"scream":@"😱",
                     @"wheelchair":@"♿️",
                     @"black_nib":@"✒️",
                     @"heavy_check_mark":@"✔️",
                     @"four":@"4️⃣",
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
                     @"stars":@"🌠",
                     @"ok_woman":@"🙆",
                     @"six":@"6️⃣",
                     @"microscope":@"🔬",
                     @"u7121":@"🈚",
                     @"mailbox":@"📫",
                     @"u6307":@"🈯️",
                     @"white_square_button":@"🔳",
                     @"zap":@"⚡",
                     @"u6e80":@"🈵",
                     @"calling":@"📲",
                     @"mouse":@"🐭",
                     @"zap":@"⚡️",
                     @"hearts":@"♥",
                     @"point_left":@"👈",
                     @"department_store":@"🏬",
                     @"horse":@"🐴",
                     @"arrow_lower_right":@"↘️",
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
                     @"black_medium_square":@"◼️",
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
                     @"soccer":@"⚽️",
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
                     @"fuelpump":@"⛽️",
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
                     @"hotsprings":@"♨️",
                     @"pig":@"🐷",
                     @"hatching_chick":@"🐣",
                     @"office":@"🏢",
                     @"hushed":@"😯",
                     @"six":@"6⃣",
                     @"full_moon_with_face":@"🌝",
                     @"stuck_out_tongue":@"😛",
                     @"eight":@"8⃣",
                     @"cherry_blossom":@"🌸",
                     @"information_source":@"ℹ",
                     @"cry":@"😢",
                     @"no_mouth":@"😶",
                     @"globe_with_meridians":@"🌐",
                     @"arrow_heading_up":@"⤴️",
                     @"soon":@"🔜",
                     @"postal_horn":@"📯",
                     @"u5272":@"🈹",
                     @"large_blue_diamond":@"🔷",
                     @"symbols":@"🔣",
                     @"signal_strength":@"📶",
                     @"name_badge":@"📛",
                     @"loudspeaker":@"📢",
                     @"negative_squared_cross_mark":@"❎",
                     @"arrow_right_hook":@"↪️",
                     @"bee":@"🐝",
                     @"honeybee":@"🐝",
                     @"sunny":@"☀️",
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
                     @"exclamation":@"❗️",
                     @"heavy_exclamation_mark":@"❗️",
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
                     @"loud_sound":@"🔊",
                     @"small_blue_diamond":@"🔹",
                     @"memo":@"📝",
                     @"pencil":@"📝",
                     @"fire":@"🔥",
                     @"key":@"🔑",
                     @"outbox_tray":@"📤",
                     @"triangular_ruler":@"📐",
                     @"fish":@"🐟",
                     @"whale2":@"🐋",
                     @"arrow_lower_left":@"↙️",
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
                     @"white_medium_small_square":@"◽️",
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
                     @"baseball":@"⚾️",
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
                     @"white_circle":@"⚪️",
                     @"earth_americas":@"🌎",
                     @"relieved":@"😌",
                     @"nine":@"9️⃣",
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
                     @"zero":@"0️⃣",
                     @"racehorse":@"🐎",
                     
                     @"doge":@"🐶",
                     @"<3":@"❤️",
                     @"</3":@"💔",
                     @")":@"😃",
                     @"-)":@"😃",
                     @"(":@"😞",
                     @"'(":@"😢",
                     @"_(":@"😭",
                     @";)":@"😉",
                     @";p":@"😜",
                     @"simple_smile":@":)"};
    
    static NSRegularExpression *_pattern;
    if(!_pattern) {
        NSError *err;
        NSString *pattern = [NSString stringWithFormat:@"\\B:(%@):\\B", [[[[[emojiMap.allKeys componentsJoinedByString:@"|"] stringByReplacingOccurrencesOfString:@"-" withString:@"\\-"] stringByReplacingOccurrencesOfString:@"+" withString:@"\\+"] stringByReplacingOccurrencesOfString:@"(" withString:@"\\("] stringByReplacingOccurrencesOfString:@")" withString:@"\\)"]];
        _pattern = [NSRegularExpression
                    regularExpressionWithPattern:pattern
                    options:0
                    error:&err];
    }
    return _pattern;
}

+(NSRegularExpression *)spotify {
    static NSRegularExpression *_pattern = nil;
    if(!_pattern) {
        NSString *pattern = @"spotify:([^<>\"\\s]+)";
        _pattern = [NSRegularExpression
                    regularExpressionWithPattern:pattern
                    options:0
                    error:nil];
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
(?:academy|accountants|active|actor|aero|agency|airforce|archi|army|arpa|asia|associates|attorney|auction|audio|autos|axa|a[cdefgilmnoqrstuwxz])\
|(?:bar|bargains|bayern|beer|berlin|best|bid|bike|bio|biz|black|blackfriday|blue|bmw|boutique|brussels|build|builders|buzz|bzh|b[abdefghijmnorstvwyz])\
|(?:cab|camera|camp|cancerresearch|capetown|capital|cards|care|career|careers|cash|cat|catering|center|ceo|cheap|christmas|church|citic|city|claims|cleaning|clinic|clothing|club|codes|coffee|college|cologne|com|community|company|computer|condos|construction|consulting|contractors|cooking|cool|coop|country|credit|creditcard|cruises|cuisinella|c[acdfghiklmnoruvwxyz])\
|(?:dance|dating|deals|degree|democrat|dental|dentist|desi|diamonds|digital|direct|directory|discount|dnp|domains|durban|d[ejkmoz])\
|(?:edu|education|email|engineer|engineering|enterprises|equipment|estate|eus|events|exchange|expert|exposed|e[cegrstu])\
|(?:fail|farm|feedback|finance|financial|fish|fishing|fitness|flights|florist|foo|foundation|frogans|fund|furniture|futbol|f[ijkmor])\
|(?:gal|gallery|gent|gift|gives|glass|global|globo|gmo|gop|gov|graphics|gratis|green|gripe|guide|guitars|guru|g[abdefghilmnpqrstuwy])\
|(?:hamburg|haus|hiphop|hiv|holdings|holiday|homes|horse|host|house|h[kmnrtu])\
|(?:immobilien|industries|info|ink|institute|insure|int|international|investments|i[delmnoqrst])\
|(?:jetzt|jobs|joburg|juegos|j[emop])\
|(?:kaufen|kim|kitchen|kiwi|koeln|krd|kred|k[eghimnprwyz])\
|(?:lacaixa|land|lawyer|lease|lgbt|life|lighting|limited|limo|link|loans|london|lotto|luxe|luxury|l[abcikrstuvy])\
|(?:maison|management|mango|market|marketing|media|meet|melbourne|menu|miami|mil|mini|mobi|moda|moe|monash|mortgage|moscow|motorcycles|museum|m[acdeghklmnopqrstuvwxyz])\
|(?:nagoya|name|navy|net|neustar|ngo|nhk|ninja|nra|nrw|nyc|n[acefgilopruz])\
|(?:okinawa|onl|org|organic|ovh|om)\
|(?:paris|partners|parts|photo|photography|photos|physio|pics|pictures|pink|place|plumbing|post|praxi|press|pro|productions|properties|pub|p[aefghklmnrstwy])\
|(?:qpon|quebec|qa)\
|(?:recipes|red|rehab|reise|reisen|ren|rentals|repair|report|republican|rest|reviews|rich|rio|rocks|rodeo|ruhr|ryukyu|r[eosuw])\
|(?:saarland|scb|schmidt|schule|scot|services|sexy|shiksha|shoes|singles|social|software|sohu|solar|solutions|soy|space|spiegel|supplies|supply|support|surf|surgery|suzuki|systems|s[abcdeghijklmnortuvxyz])\
|(?:tattoo|tax|technology|tel|tienda|tips|tirol|today|tokyo|tools|town|toys|trade|training|travel|t[cdfghjklmnoprtvwz])\
|(?:university|uno|u[agksyz])\
|(?:vacations|vegas|ventures|versicherung|vet|viajes|villas|vision|vlaanderen|vodka|vote|voting|voto|voyage|v[aceginu])\
|(?:wang|watch|webcam|website|wed|whoswho|wien|wiki|works|wtc|wtf|w[fs])\
|(?:\u0434\u0435\u0442\u0438|\u043c\u043e\u043d|\u043c\u043e\u0441\u043a\u0432\u0430|\u043e\u043d\u043b\u0430\u0439\u043d|\u043e\u0440\u0433|\u0440\u0444|\u0441\u0430\u0439\u0442|\u0441\u0440\u0431|\u0443\u043a\u0440|\u049b\u0430\u0437|\u0627\u0644\u0627\u0631\u062f\u0646|\u0627\u0644\u062c\u0632\u0627\u0626\u0631|\u0627\u0644\u0633\u0639\u0648\u062f\u064a\u0629|\u0627\u0644\u0645\u063a\u0631\u0628|\u0627\u0645\u0627\u0631\u0627\u062a|\u0627\u06cc\u0631\u0627\u0646|\u0628\u0627\u0632\u0627\u0631|\u0628\u06be\u0627\u0631\u062a|\u062a\u0648\u0646\u0633|\u0633\u0648\u0631\u064a\u0629|\u0634\u0628\u0643\u0629|\u0639\u0645\u0627\u0646|\u0641\u0644\u0633\u0637\u064a\u0646|\u0642\u0637\u0631|\u0645\u0635\u0631|\u0645\u0644\u064a\u0633\u064a\u0627|\u0645\u0648\u0642\u0639|\u092d\u093e\u0930\u0924|\u0938\u0902\u0917\u0920\u0928|\u09ad\u09be\u09b0\u09a4|\u0a2d\u0a3e\u0a30\u0a24|\u0aad\u0abe\u0ab0\u0aa4|\u0b87\u0ba8\u0bcd\u0ba4\u0bbf\u0baf\u0bbe|\u0b87\u0bb2\u0b99\u0bcd\u0b95\u0bc8|\u0b9a\u0bbf\u0b99\u0bcd\u0b95\u0baa\u0bcd\u0baa\u0bc2\u0bb0\u0bcd|\u0c2d\u0c3e\u0c30\u0c24\u0c4d|\u0dbd\u0d82\u0d9a\u0dcf|\u0e44\u0e17\u0e22|\u307f\u3093\u306a|\u4e16\u754c|\u4e2d\u4fe1|\u4e2d\u56fd|\u4e2d\u570b|\u4e2d\u6587\u7f51|\u516c\u53f8|\u516c\u76ca|\u53f0\u6e7e|\u53f0\u7063|\u5546\u57ce|\u5546\u6807|\u5728\u7ebf|\u6211\u7231\u4f60|\u624b\u673a|\u653f\u52a1|\u65b0\u52a0\u5761|\u673a\u6784|\u6e38\u620f|\u79fb\u52a8|\u7ec4\u7ec7\u673a\u6784|\u7f51\u5740|\u7f51\u7edc|\u96c6\u56e2|\u9999\u6e2f|\uc0bc\uc131|\ud55c\uad6d|xn\\-\\-3bst00m|xn\\-\\-3ds443g|xn\\-\\-3e0b707e|xn\\-\\-45brj9c|xn\\-\\-4gbrim|xn\\-\\-55qw42g|xn\\-\\-55qx5d|xn\\-\\-6frz82g|xn\\-\\-6qq986b3xl|xn\\-\\-80adxhks|xn\\-\\-80ao21a|xn\\-\\-80asehdb|xn\\-\\-80aswg|xn\\-\\-90a3ac|xn\\-\\-c1avg|xn\\-\\-cg4bki|xn\\-\\-clchc0ea0b2g2a9gcd|xn\\-\\-czr694b|xn\\-\\-czru2d|xn\\-\\-d1acj3b|xn\\-\\-fiq228c5hs|xn\\-\\-fiq64b|xn\\-\\-fiqs8s|xn\\-\\-fiqz9s|xn\\-\\-fpcrj9c3d|xn\\-\\-fzc2c9e2c|xn\\-\\-gecrj9c|xn\\-\\-h2brj9c|xn\\-\\-i1b6b1a6a2e|xn\\-\\-io0a7i|xn\\-\\-j1amh|xn\\-\\-j6w193g|xn\\-\\-kprw13d|xn\\-\\-kpry57d|xn\\-\\-kput3i|xn\\-\\-l1acc|xn\\-\\-lgbbat1ad8j|xn\\-\\-mgb9awbf|xn\\-\\-mgba3a4f16a|xn\\-\\-mgbaam7a8h|xn\\-\\-mgbab2bd|xn\\-\\-mgbayh7gpa|xn\\-\\-mgbbh1a71e|xn\\-\\-mgbc0a9azcg|xn\\-\\-mgberp4a5d4ar|xn\\-\\-mgbx4cd0ab|xn\\-\\-ngbc5azd|xn\\-\\-nqv7f|xn\\-\\-nqv7fs00ema|xn\\-\\-o3cw4h|xn\\-\\-ogbpf8fl|xn\\-\\-p1ai|xn\\-\\-pgbs0dh|xn\\-\\-q9jyb4c|xn\\-\\-rhqv96g|xn\\-\\-s9brj9c|xn\\-\\-ses554g|xn\\-\\-unup4y|xn\\-\\-wgbh1c|xn\\-\\-wgbl6a|xn\\-\\-xkc2al3hye2a|xn\\-\\-xkc2dl3a5ee0h|xn\\-\\-yfro4i67o|xn\\-\\-ygbi2ammx|xn\\-\\-zfr164b|xxx|xyz)\
|(?:yachts|yandex|yokohama|y[et])\
|(?:zone|z[amw])))";
    NSString *GOOD_IRI_CHAR = @"a-zA-Z0-9\u00A0-\uD7FF\uF900-\uFDCF\uFDF0-\uFFEF";
    NSString *pattern = [NSString stringWithFormat:@"((?:[a-z_-]+:\\/{1,3}(?:(?:[a-zA-Z0-9\\$\\-\\_\\.\\+\\!\\*\\'\\(\\)\
\\,\\;\\?\\&\\=]|(?:\\%%[a-fA-F0-9]{2})){1,64}(?:\\:(?:[a-zA-Z0-9\\$\\-\\_\
\\.\\+\\!\\*\\'\\(\\)\\,\\;\\?\\&\\=]|(?:\\%%[a-fA-F0-9]{2})){1,25})?\\@)?)?\
((?:(?:[%@][%@\\-]{0,64}\\.)+%@\
|(?:(?:25[0-5]|2[0-4]\
[0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9])\\.(?:25[0-5]|2[0-4][0-9]\
|[0-1][0-9]{2}|[1-9][0-9]|[1-9]|0)\\.(?:25[0-5]|2[0-4][0-9]|[0-1]\
[0-9]{2}|[1-9][0-9]|[1-9]|0)\\.(?:25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}\
|[1-9][0-9]|[0-9])))\
(?:\\:\\d{1,5})?)\
([\\/\\?\\#](?:(?:[%@\\;\\/\\?\\:\\@\\&\\=\\#\\~\\$\
\\-\\.\\+\\!\\*\\'\\(\\)\\,\\_\\^\\{\\}\\[\\]])|(?:\\%%[a-fA-F0-9]{2}))*)?\
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

+(BOOL)unbalanced:(NSString *)input {
    if(!quotes)
        quotes = @{@"\"":@"\"",@"'": @"'",@")": @"(",@"]": @"[",@"}": @"{",@">": @"<",@"”": @"“",@"’": @"‘",@"»": @"«"};
    
    NSString *lastChar = [input substringFromIndex:input.length - 1];
    
    return [quotes objectForKey:lastChar] && [input componentsSeparatedByString:lastChar].count != [input componentsSeparatedByString:[quotes objectForKey:lastChar]].count;
}

+(NSAttributedString *)format:(NSString *)input defaultColor:(UIColor *)color mono:(BOOL)mono linkify:(BOOL)linkify server:(Server *)server links:(NSArray **)links {
    if(!color)
        color = [UIColor blackColor];
    
    int bold = -1, italics = -1, underline = -1, fg = -1, bg = -1;
    UIColor *fgColor = nil, *bgColor = nil;
    CTFontRef font, boldFont, italicFont, boldItalicFont;
    CGFloat lineSpacing = 6;
    NSMutableArray *matches = [[NSMutableArray alloc] init];
    
    if(!Courier) {
        if([[[[UIDevice currentDevice].systemVersion componentsSeparatedByString:@"."] objectAtIndex:0] intValue] < 7) {
            arrowFont = CTFontCreateWithName((CFStringRef)@"HiraMinProN-W3", FONT_SIZE, NULL);
            Courier = CTFontCreateWithName((CFStringRef)@"Courier", FONT_SIZE, NULL);
            CourierBold = CTFontCreateWithName((CFStringRef)@"Courier-Bold", FONT_SIZE, NULL);
            CourierOblique = CTFontCreateWithName((CFStringRef)@"Courier-Oblique", FONT_SIZE, NULL);
            CourierBoldOblique = CTFontCreateWithName((CFStringRef)@"Courier-BoldOblique", FONT_SIZE, NULL);
            Helvetica = CTFontCreateWithName((CFStringRef)@"Helvetica", FONT_SIZE, NULL);
            HelveticaBold = CTFontCreateWithName((CFStringRef)@"Helvetica-Bold", FONT_SIZE, NULL);
            HelveticaOblique = CTFontCreateWithName((CFStringRef)@"Helvetica-Oblique", FONT_SIZE, NULL);
            HelveticaBoldOblique = CTFontCreateWithName((CFStringRef)@"Helvetica-BoldOblique", FONT_SIZE, NULL);
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
            ColorFormatterCachedFontSize = bodyFontDesciptor.pointSize;
        }
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
    BOOL disableConvert = [[NetworkConnection sharedInstance] prefs] && [[[[NetworkConnection sharedInstance] prefs] objectForKey:@"emoji-disableconvert"] boolValue];
    if(!disableConvert) {
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
                    if(fgColor)
                        [attributes addObject:@{
                         (NSString *)kCTForegroundColorAttributeName:(__bridge id)[fgColor CGColor],
                         @"start":@(fg),
                         @"length":@(i - fg)
                         }];
                    fg = -1;
                }
                if(bg != -1) {
                    if(bgColor)
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
        results = [[self spotify] matchesInString:[[output string] lowercaseString] options:0 range:NSMakeRange(0, [output length])];
        for(NSTextCheckingResult *result in results) {
            NSString *url = [[output string] substringWithRange:result.range];
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
                NSRange range = result.range;
                
                if([self unbalanced:url] || [url hasSuffix:@"."] || [url hasSuffix:@"?"] || [url hasSuffix:@"!"] || [url hasSuffix:@","]) {
                    url = [url substringToIndex:url.length - 1];
                    range.length--;
                }
                
                CFStringRef safe_escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)url, (CFStringRef)@"%#", (CFStringRef)@"^", kCFStringEncodingUTF8);

                url = [NSString stringWithString:(__bridge NSString *)safe_escaped];
                CFRelease(safe_escaped);
                
                if([url rangeOfString:@"://"].location == NSNotFound) {
                    if([url hasPrefix:@"irc."])
                        url = [NSString stringWithFormat:@"irc://%@", url];
                    else
                        url = [NSString stringWithFormat:@"http://%@", url];
                }
                
                [matches addObject:[NSTextCheckingResult linkCheckingResultWithRange:range URL:[NSURL URLWithString:url]]];
            }
        }
    } else {
        if(server) {
            NSArray *results = [[self ircChannelRegexForServer:server] matchesInString:[[output string] lowercaseString] options:0 range:NSMakeRange(0, [output length])];
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
    }
    if(links)
        *links = [NSArray arrayWithArray:matches];
    return output;
}
@end
