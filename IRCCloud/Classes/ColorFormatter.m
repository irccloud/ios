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


#import "ColorFormatter.h"
#import "LinkTextView.h"
#import "UIColor+IRCCloud.h"
#import "NSURL+IDN.h"
#import "NetworkConnection.h"

id Courier = NULL, CourierBold, CourierOblique,CourierBoldOblique;
id Helvetica, HelveticaBold, HelveticaOblique,HelveticaBoldOblique;
id arrowFont, chalkboardFont, markerFont, awesomeFont, largeEmojiFont;
UIFont *timestampFont, *monoTimestampFont;
NSDictionary *emojiMap;
NSDictionary *quotes;
float ColorFormatterCachedFontSize = 0.0f;

extern BOOL __compact;

@implementation ColorFormatter

+(BOOL)shouldClearFontCache {
    return ColorFormatterCachedFontSize != FONT_SIZE;
}

+(void)clearFontCache {
    CLS_LOG(@"Clearing font cache");
    Courier = CourierBold = CourierBoldOblique = CourierOblique = Helvetica = HelveticaBold = HelveticaBoldOblique = HelveticaOblique = chalkboardFont = markerFont = arrowFont = NULL;
    timestampFont = monoTimestampFont = awesomeFont = NULL;
}

+(UIFont *)timestampFont {
    if(!timestampFont) {
        timestampFont = [UIFont systemFontOfSize:FONT_SIZE - 2];
    }
    return timestampFont;
}

+(UIFont *)monoTimestampFont {
    if(!monoTimestampFont) {
        monoTimestampFont = [UIFont fontWithName:@"Courier" size:FONT_SIZE - 2];
    }
    return monoTimestampFont;
}

+(UIFont *)awesomeFont {
    if(!awesomeFont) {
        awesomeFont = [UIFont fontWithName:@"FontAwesome" size:FONT_SIZE];
    }
    return awesomeFont;
}

+(UIFont *)messageFont:(BOOL)mono {
    return mono?Courier:Helvetica;
}

+(NSRegularExpression *)emoji {
    if(!emojiMap)
        emojiMap = @{
                     @"interrobang":@"⁉️",
                     @"tm":@"™️",
                     @"information_source":@"ℹ️",
                     @"left_right_arrow":@"↔️",
                     @"arrow_up_down":@"↕️",
                     @"arrow_upper_left":@"↖️",
                     @"arrow_upper_right":@"↗️",
                     @"arrow_lower_right":@"↘️",
                     @"arrow_lower_left":@"↙️",
                     @"keyboard":@"⌨️",
                     @"sunny":@"☀️",
                     @"cloud":@"☁️",
                     @"umbrella":@"☂️",
                     @"snowman":@"☃️",
                     @"comet":@"☄️",
                     @"ballot_box_with_check":@"☑️",
                     @"umbrella_with_rain_drops":@"☔️",
                     @"coffee":@"☕️",
                     @"shamrock":@"☘",
                     @"skull_and_crossbones":@"☠️",
                     @"radioactive_sign":@"☢️",
                     @"biohazard_sign":@"☣️",
                     @"orthodox_cross":@"☦️",
                     @"wheel_of_dharma":@"☸️",
                     @"white_frowning_face":@"☹️",
                     @"aries":@"♈️",
                     @"taurus":@"♉️",
                     @"sagittarius":@"♐️",
                     @"capricorn":@"♑️",
                     @"aquarius":@"♒️",
                     @"pisces":@"♓️",
                     @"spades":@"♠️",
                     @"clubs":@"♣️",
                     @"hearts":@"♥️",
                     @"diamonds":@"♦️",
                     @"hotsprings":@"♨️",
                     @"hammer_and_pick":@"⚒",
                     @"anchor":@"⚓️",
                     @"crossed_swords":@"⚔",
                     @"scales":@"⚖",
                     @"alembic":@"⚗",
                     @"gear":@"⚙",
                     @"scissors":@"✂️",
                     @"white_check_mark":@"✅",
                     @"airplane":@"✈️",
                     @"email":@"✉️",
                     @"envelope":@"✉️",
                     @"black_nib":@"✒️",
                     @"heavy_check_mark":@"✔️",
                     @"heavy_multiplication_x":@"✖️",
                     @"star_of_david":@"✡️",
                     @"sparkles":@"✨",
                     @"eight_spoked_asterisk":@"✳️",
                     @"eight_pointed_black_star":@"✴️",
                     @"snowflake":@"❄️",
                     @"sparkle":@"❇️",
                     @"question":@"❓",
                     @"grey_question":@"❔",
                     @"grey_exclamation":@"❕",
                     @"exclamation":@"❗️",
                     @"heavy_exclamation_mark":@"❗️",
                     @"heavy_heart_exclamation_mark_ornament":@"❣️",
                     @"heart":@"❤️",
                     @"heavy_plus_sign":@"➕",
                     @"heavy_minus_sign":@"➖",
                     @"heavy_division_sign":@"➗",
                     @"arrow_heading_up":@"⤴️",
                     @"arrow_heading_down":@"⤵️",
                     @"wavy_dash":@"〰️",
                     @"congratulations":@"㊗️",
                     @"secret":@"㊙️",
                     @"copyright":@"©️",
                     @"registered":@"®️",
                     @"bangbang":@"‼️",
                     @"leftwards_arrow_with_hook":@"↩️",
                     @"arrow_right_hook":@"↪️",
                     @"watch":@"⌚️",
                     @"hourglass":@"⌛️",
                     @"eject":@"⏏",
                     @"fast_forward":@"⏩",
                     @"rewind":@"⏪",
                     @"arrow_double_up":@"⏫",
                     @"arrow_double_down":@"⏬",
                     @"black_right_pointing_double_triangle_with_vertical_bar":@"⏭",
                     @"black_left_pointing_double_triangle_with_vertical_bar":@"⏮",
                     @"black_right_pointing_triangle_with_double_vertical_bar":@"⏯",
                     @"alarm_clock":@"⏰",
                     @"stopwatch":@"⏱",
                     @"timer_clock":@"⏲",
                     @"hourglass_flowing_sand":@"⏳",
                     @"double_vertical_bar":@"⏸",
                     @"black_square_for_stop":@"⏹",
                     @"black_circle_for_record":@"⏺",
                     @"m":@"Ⓜ️",
                     @"black_small_square":@"▪️",
                     @"white_small_square":@"▫️",
                     @"arrow_forward":@"▶️",
                     @"arrow_backward":@"◀️",
                     @"white_medium_square":@"◻️",
                     @"black_medium_square":@"◼️",
                     @"white_medium_small_square":@"◽️",
                     @"black_medium_small_square":@"◾️",
                     @"phone":@"☎️",
                     @"telephone":@"☎️",
                     @"point_up":@"☝️",
                     @"star_and_crescent":@"☪️",
                     @"peace_symbol":@"☮️",
                     @"yin_yang":@"☯️",
                     @"relaxed":@"☺️",
                     @"gemini":@"♊️",
                     @"cancer":@"♋️",
                     @"leo":@"♌️",
                     @"virgo":@"♍️",
                     @"libra":@"♎️",
                     @"scorpius":@"♏️",
                     @"recycle":@"♻️",
                     @"wheelchair":@"♿️",
                     @"atom_symbol":@"⚛",
                     @"fleur_de_lis":@"⚜",
                     @"warning":@"⚠️",
                     @"zap":@"⚡️",
                     @"white_circle":@"⚪️",
                     @"black_circle":@"⚫️",
                     @"coffin":@"⚰",
                     @"funeral_urn":@"⚱",
                     @"soccer":@"⚽️",
                     @"baseball":@"⚾️",
                     @"snowman_without_snow":@"⛄️",
                     @"partly_sunny":@"⛅️",
                     @"thunder_cloud_and_rain":@"⛈",
                     @"ophiuchus":@"⛎",
                     @"pick":@"⛏",
                     @"helmet_with_white_cross":@"⛑",
                     @"chains":@"⛓",
                     @"no_entry":@"⛔️",
                     @"shinto_shrine":@"⛩",
                     @"church":@"⛪️",
                     @"mountain":@"⛰",
                     @"umbrella_on_ground":@"⛱",
                     @"fountain":@"⛲️",
                     @"golf":@"⛳️",
                     @"ferry":@"⛴",
                     @"boat":@"⛵️",
                     @"sailboat":@"⛵️",
                     @"skier":@"⛷",
                     @"ice_skate":@"⛸",
                     @"person_with_ball":@"⛹",
                     @"tent":@"⛺️",
                     @"fuelpump":@"⛽️",
                     @"fist":@"✊",
                     @"hand":@"✋",
                     @"raised_hand":@"✋",
                     @"v":@"✌️",
                     @"writing_hand":@"✍️",
                     @"pencil2":@"✏️",
                     @"latin_cross":@"✝️",
                     @"x":@"❌",
                     @"negative_squared_cross_mark":@"❎",
                     @"arrow_right":@"➡️",
                     @"curly_loop":@"➰",
                     @"loop":@"➿",
                     @"arrow_left":@"⬅️",
                     @"arrow_up":@"⬆️",
                     @"arrow_down":@"⬇️",
                     @"black_large_square":@"⬛️",
                     @"white_large_square":@"⬜️",
                     @"star":@"⭐️",
                     @"o":@"⭕️",
                     @"part_alternation_mark":@"〽️",
                     @"mahjong":@"🀄️",
                     @"black_joker":@"🃏",
                     @"a":@"🅰️",
                     @"b":@"🅱️",
                     @"o2":@"🅾️",
                     @"parking":@"🅿️",
                     @"ab":@"🆎",
                     @"cl":@"🆑",
                     @"cool":@"🆒",
                     @"free":@"🆓",
                     @"id":@"🆔",
                     @"new":@"🆕",
                     @"ng":@"🆖",
                     @"ok":@"🆗",
                     @"sos":@"🆘",
                     @"up":@"🆙",
                     @"vs":@"🆚",
                     @"koko":@"🈁",
                     @"sa":@"🈂️",
                     @"u7121":@"🈚️",
                     @"u6307":@"🈯️",
                     @"u7981":@"🈲",
                     @"u7a7a":@"🈳",
                     @"u5408":@"🈴",
                     @"u6e80":@"🈵",
                     @"u6709":@"🈶",
                     @"u6708":@"🈷️",
                     @"u7533":@"🈸",
                     @"u5272":@"🈹",
                     @"u55b6":@"🈺",
                     @"ideograph_advantage":@"🉐",
                     @"accept":@"🉑",
                     @"cyclone":@"🌀",
                     @"foggy":@"🌁",
                     @"closed_umbrella":@"🌂",
                     @"night_with_stars":@"🌃",
                     @"sunrise_over_mountains":@"🌄",
                     @"sunrise":@"🌅",
                     @"city_sunset":@"🌆",
                     @"city_sunrise":@"🌇",
                     @"rainbow":@"🌈",
                     @"bridge_at_night":@"🌉",
                     @"ocean":@"🌊",
                     @"volcano":@"🌋",
                     @"milky_way":@"🌌",
                     @"earth_africa":@"🌍",
                     @"earth_americas":@"🌎",
                     @"earth_asia":@"🌏",
                     @"globe_with_meridians":@"🌐",
                     @"new_moon":@"🌑",
                     @"waxing_crescent_moon":@"🌒",
                     @"first_quarter_moon":@"🌓",
                     @"moon":@"🌔",
                     @"waxing_gibbous_moon":@"🌔",
                     @"full_moon":@"🌕",
                     @"waning_gibbous_moon":@"🌖",
                     @"last_quarter_moon":@"🌗",
                     @"waning_crescent_moon":@"🌘",
                     @"crescent_moon":@"🌙",
                     @"new_moon_with_face":@"🌚",
                     @"first_quarter_moon_with_face":@"🌛",
                     @"last_quarter_moon_with_face":@"🌜",
                     @"full_moon_with_face":@"🌝",
                     @"sun_with_face":@"🌞",
                     @"star2":@"🌟",
                     @"stars":@"🌠",
                     @"thermometer":@"🌡",
                     @"mostly_sunny":@"🌤",
                     @"sun_small_cloud":@"🌤",
                     @"barely_sunny":@"🌥",
                     @"sun_behind_cloud":@"🌥",
                     @"partly_sunny_rain":@"🌦",
                     @"sun_behind_rain_cloud":@"🌦",
                     @"rain_cloud":@"🌧",
                     @"snow_cloud":@"🌨",
                     @"lightning":@"🌩",
                     @"lightning_cloud":@"🌩",
                     @"tornado":@"🌪",
                     @"tornado_cloud":@"🌪",
                     @"fog":@"🌫",
                     @"wind_blowing_face":@"🌬",
                     @"hotdog":@"🌭",
                     @"taco":@"🌮",
                     @"burrito":@"🌯",
                     @"chestnut":@"🌰",
                     @"seedling":@"🌱",
                     @"evergreen_tree":@"🌲",
                     @"deciduous_tree":@"🌳",
                     @"palm_tree":@"🌴",
                     @"cactus":@"🌵",
                     @"hot_pepper":@"🌶",
                     @"tulip":@"🌷",
                     @"cherry_blossom":@"🌸",
                     @"rose":@"🌹",
                     @"hibiscus":@"🌺",
                     @"sunflower":@"🌻",
                     @"blossom":@"🌼",
                     @"corn":@"🌽",
                     @"ear_of_rice":@"🌾",
                     @"herb":@"🌿",
                     @"four_leaf_clover":@"🍀",
                     @"maple_leaf":@"🍁",
                     @"fallen_leaf":@"🍂",
                     @"leaves":@"🍃",
                     @"mushroom":@"🍄",
                     @"tomato":@"🍅",
                     @"eggplant":@"🍆",
                     @"grapes":@"🍇",
                     @"melon":@"🍈",
                     @"watermelon":@"🍉",
                     @"tangerine":@"🍊",
                     @"lemon":@"🍋",
                     @"banana":@"🍌",
                     @"pineapple":@"🍍",
                     @"apple":@"🍎",
                     @"green_apple":@"🍏",
                     @"pear":@"🍐",
                     @"peach":@"🍑",
                     @"cherries":@"🍒",
                     @"strawberry":@"🍓",
                     @"hamburger":@"🍔",
                     @"pizza":@"🍕",
                     @"meat_on_bone":@"🍖",
                     @"poultry_leg":@"🍗",
                     @"rice_cracker":@"🍘",
                     @"rice_ball":@"🍙",
                     @"rice":@"🍚",
                     @"curry":@"🍛",
                     @"ramen":@"🍜",
                     @"spaghetti":@"🍝",
                     @"bread":@"🍞",
                     @"fries":@"🍟",
                     @"sweet_potato":@"🍠",
                     @"dango":@"🍡",
                     @"oden":@"🍢",
                     @"sushi":@"🍣",
                     @"fried_shrimp":@"🍤",
                     @"fish_cake":@"🍥",
                     @"icecream":@"🍦",
                     @"shaved_ice":@"🍧",
                     @"ice_cream":@"🍨",
                     @"doughnut":@"🍩",
                     @"cookie":@"🍪",
                     @"chocolate_bar":@"🍫",
                     @"candy":@"🍬",
                     @"lollipop":@"🍭",
                     @"custard":@"🍮",
                     @"honey_pot":@"🍯",
                     @"cake":@"🍰",
                     @"bento":@"🍱",
                     @"stew":@"🍲",
                     @"egg":@"🍳",
                     @"fork_and_knife":@"🍴",
                     @"tea":@"🍵",
                     @"sake":@"🍶",
                     @"wine_glass":@"🍷",
                     @"cocktail":@"🍸",
                     @"tropical_drink":@"🍹",
                     @"beer":@"🍺",
                     @"beers":@"🍻",
                     @"baby_bottle":@"🍼",
                     @"knife_fork_plate":@"🍽",
                     @"champagne":@"🍾",
                     @"popcorn":@"🍿",
                     @"ribbon":@"🎀",
                     @"gift":@"🎁",
                     @"birthday":@"🎂",
                     @"jack_o_lantern":@"🎃",
                     @"christmas_tree":@"🎄",
                     @"santa":@"🎅",
                     @"fireworks":@"🎆",
                     @"sparkler":@"🎇",
                     @"balloon":@"🎈",
                     @"tada":@"🎉",
                     @"confetti_ball":@"🎊",
                     @"tanabata_tree":@"🎋",
                     @"crossed_flags":@"🎌",
                     @"bamboo":@"🎍",
                     @"dolls":@"🎎",
                     @"flags":@"🎏",
                     @"wind_chime":@"🎐",
                     @"rice_scene":@"🎑",
                     @"school_satchel":@"🎒",
                     @"mortar_board":@"🎓",
                     @"medal":@"🎖",
                     @"reminder_ribbon":@"🎗",
                     @"studio_microphone":@"🎙",
                     @"level_slider":@"🎚",
                     @"control_knobs":@"🎛",
                     @"film_frames":@"🎞",
                     @"admission_tickets":@"🎟",
                     @"carousel_horse":@"🎠",
                     @"ferris_wheel":@"🎡",
                     @"roller_coaster":@"🎢",
                     @"fishing_pole_and_fish":@"🎣",
                     @"microphone":@"🎤",
                     @"movie_camera":@"🎥",
                     @"cinema":@"🎦",
                     @"headphones":@"🎧",
                     @"art":@"🎨",
                     @"tophat":@"🎩",
                     @"circus_tent":@"🎪",
                     @"ticket":@"🎫",
                     @"clapper":@"🎬",
                     @"performing_arts":@"🎭",
                     @"video_game":@"🎮",
                     @"dart":@"🎯",
                     @"slot_machine":@"🎰",
                     @"8ball":@"🎱",
                     @"game_die":@"🎲",
                     @"bowling":@"🎳",
                     @"flower_playing_cards":@"🎴",
                     @"musical_note":@"🎵",
                     @"notes":@"🎶",
                     @"saxophone":@"🎷",
                     @"guitar":@"🎸",
                     @"musical_keyboard":@"🎹",
                     @"trumpet":@"🎺",
                     @"violin":@"🎻",
                     @"musical_score":@"🎼",
                     @"running_shirt_with_sash":@"🎽",
                     @"tennis":@"🎾",
                     @"ski":@"🎿",
                     @"basketball":@"🏀",
                     @"checkered_flag":@"🏁",
                     @"snowboarder":@"🏂",
                     @"runner":@"🏃",
                     @"running":@"🏃",
                     @"surfer":@"🏄",
                     @"sports_medal":@"🏅",
                     @"trophy":@"🏆",
                     @"horse_racing":@"🏇",
                     @"football":@"🏈",
                     @"rugby_football":@"🏉",
                     @"swimmer":@"🏊",
                     @"weight_lifter":@"🏋",
                     @"golfer":@"🏌",
                     @"racing_motorcycle":@"🏍",
                     @"racing_car":@"🏎",
                     @"cricket_bat_and_ball":@"🏏",
                     @"volleyball":@"🏐",
                     @"field_hockey_stick_and_ball":@"🏑",
                     @"ice_hockey_stick_and_puck":@"🏒",
                     @"table_tennis_paddle_and_ball":@"🏓",
                     @"snow_capped_mountain":@"🏔",
                     @"camping":@"🏕",
                     @"beach_with_umbrella":@"🏖",
                     @"building_construction":@"🏗",
                     @"house_buildings":@"🏘",
                     @"cityscape":@"🏙",
                     @"derelict_house_building":@"🏚",
                     @"classical_building":@"🏛",
                     @"desert":@"🏜",
                     @"desert_island":@"🏝",
                     @"national_park":@"🏞",
                     @"stadium":@"🏟",
                     @"house":@"🏠",
                     @"house_with_garden":@"🏡",
                     @"office":@"🏢",
                     @"post_office":@"🏣",
                     @"european_post_office":@"🏤",
                     @"hospital":@"🏥",
                     @"bank":@"🏦",
                     @"atm":@"🏧",
                     @"hotel":@"🏨",
                     @"love_hotel":@"🏩",
                     @"convenience_store":@"🏪",
                     @"school":@"🏫",
                     @"department_store":@"🏬",
                     @"factory":@"🏭",
                     @"izakaya_lantern":@"🏮",
                     @"lantern":@"🏮",
                     @"japanese_castle":@"🏯",
                     @"european_castle":@"🏰",
                     @"waving_white_flag":@"🏳",
                     @"waving_black_flag":@"🏴",
                     @"rosette":@"🏵",
                     @"label":@"🏷",
                     @"badminton_racquet_and_shuttlecock":@"🏸",
                     @"bow_and_arrow":@"🏹",
                     @"amphora":@"🏺",
                     @"skin-tone-2":@"🏻",
                     @"skin-tone-3":@"🏼",
                     @"skin-tone-4":@"🏽",
                     @"skin-tone-5":@"🏾",
                     @"skin-tone-6":@"🏿",
                     @"rat":@"🐀",
                     @"mouse2":@"🐁",
                     @"ox":@"🐂",
                     @"water_buffalo":@"🐃",
                     @"cow2":@"🐄",
                     @"tiger2":@"🐅",
                     @"leopard":@"🐆",
                     @"rabbit2":@"🐇",
                     @"cat2":@"🐈",
                     @"dragon":@"🐉",
                     @"crocodile":@"🐊",
                     @"whale2":@"🐋",
                     @"snail":@"🐌",
                     @"snake":@"🐍",
                     @"racehorse":@"🐎",
                     @"ram":@"🐏",
                     @"goat":@"🐐",
                     @"sheep":@"🐑",
                     @"monkey":@"🐒",
                     @"rooster":@"🐓",
                     @"chicken":@"🐔",
                     @"dog2":@"🐕",
                     @"pig2":@"🐖",
                     @"boar":@"🐗",
                     @"elephant":@"🐘",
                     @"octopus":@"🐙",
                     @"shell":@"🐚",
                     @"bug":@"🐛",
                     @"ant":@"🐜",
                     @"bee":@"🐝",
                     @"honeybee":@"🐝",
                     @"beetle":@"🐞",
                     @"fish":@"🐟",
                     @"tropical_fish":@"🐠",
                     @"blowfish":@"🐡",
                     @"turtle":@"🐢",
                     @"hatching_chick":@"🐣",
                     @"baby_chick":@"🐤",
                     @"hatched_chick":@"🐥",
                     @"bird":@"🐦",
                     @"penguin":@"🐧",
                     @"koala":@"🐨",
                     @"poodle":@"🐩",
                     @"dromedary_camel":@"🐪",
                     @"camel":@"🐫",
                     @"dolphin":@"🐬",
                     @"flipper":@"🐬",
                     @"mouse":@"🐭",
                     @"cow":@"🐮",
                     @"tiger":@"🐯",
                     @"rabbit":@"🐰",
                     @"cat":@"🐱",
                     @"dragon_face":@"🐲",
                     @"whale":@"🐳",
                     @"horse":@"🐴",
                     @"monkey_face":@"🐵",
                     @"dog":@"🐶",
                     @"pig":@"🐷",
                     @"frog":@"🐸",
                     @"hamster":@"🐹",
                     @"wolf":@"🐺",
                     @"bear":@"🐻",
                     @"panda_face":@"🐼",
                     @"pig_nose":@"🐽",
                     @"feet":@"🐾",
                     @"paw_prints":@"🐾",
                     @"chipmunk":@"🐿",
                     @"eyes":@"👀",
                     @"eye":@"👁",
                     @"ear":@"👂",
                     @"nose":@"👃",
                     @"lips":@"👄",
                     @"tongue":@"👅",
                     @"point_up_2":@"👆",
                     @"point_down":@"👇",
                     @"point_left":@"👈",
                     @"point_right":@"👉",
                     @"facepunch":@"👊",
                     @"punch":@"👊",
                     @"wave":@"👋",
                     @"ok_hand":@"👌",
                     @"+1":@"👍",
                     @"thumbsup":@"👍",
                     @"-1":@"👎",
                     @"thumbsdown":@"👎",
                     @"clap":@"👏",
                     @"open_hands":@"👐",
                     @"crown":@"👑",
                     @"womans_hat":@"👒",
                     @"eyeglasses":@"👓",
                     @"necktie":@"👔",
                     @"shirt":@"👕",
                     @"tshirt":@"👕",
                     @"jeans":@"👖",
                     @"dress":@"👗",
                     @"kimono":@"👘",
                     @"bikini":@"👙",
                     @"womans_clothes":@"👚",
                     @"purse":@"👛",
                     @"handbag":@"👜",
                     @"pouch":@"👝",
                     @"mans_shoe":@"👞",
                     @"shoe":@"👞",
                     @"athletic_shoe":@"👟",
                     @"high_heel":@"👠",
                     @"sandal":@"👡",
                     @"boot":@"👢",
                     @"footprints":@"👣",
                     @"bust_in_silhouette":@"👤",
                     @"busts_in_silhouette":@"👥",
                     @"boy":@"👦",
                     @"girl":@"👧",
                     @"man":@"👨",
                     @"woman":@"👩",
                     @"family":@"👨‍👩‍👦",
                     @"man-woman-boy":@"👨‍👩‍👦",
                     @"couple":@"👫",
                     @"man_and_woman_holding_hands":@"👫",
                     @"two_men_holding_hands":@"👬",
                     @"two_women_holding_hands":@"👭",
                     @"cop":@"👮",
                     @"dancers":@"👯",
                     @"bride_with_veil":@"👰",
                     @"person_with_blond_hair":@"👱",
                     @"man_with_gua_pi_mao":@"👲",
                     @"man_with_turban":@"👳",
                     @"older_man":@"👴",
                     @"older_woman":@"👵",
                     @"baby":@"👶",
                     @"construction_worker":@"👷",
                     @"princess":@"👸",
                     @"japanese_ogre":@"👹",
                     @"japanese_goblin":@"👺",
                     @"ghost":@"👻",
                     @"angel":@"👼",
                     @"alien":@"👽",
                     @"space_invader":@"👾",
                     @"imp":@"👿",
                     @"skull":@"💀",
                     @"information_desk_person":@"💁",
                     @"guardsman":@"💂",
                     @"dancer":@"💃",
                     @"lipstick":@"💄",
                     @"nail_care":@"💅",
                     @"massage":@"💆",
                     @"haircut":@"💇",
                     @"barber":@"💈",
                     @"syringe":@"💉",
                     @"pill":@"💊",
                     @"kiss":@"💋",
                     @"love_letter":@"💌",
                     @"ring":@"💍",
                     @"gem":@"💎",
                     @"couplekiss":@"💏",
                     @"bouquet":@"💐",
                     @"couple_with_heart":@"💑",
                     @"wedding":@"💒",
                     @"heartbeat":@"💓",
                     @"broken_heart":@"💔",
                     @"two_hearts":@"💕",
                     @"sparkling_heart":@"💖",
                     @"heartpulse":@"💗",
                     @"cupid":@"💘",
                     @"blue_heart":@"💙",
                     @"green_heart":@"💚",
                     @"yellow_heart":@"💛",
                     @"purple_heart":@"💜",
                     @"gift_heart":@"💝",
                     @"revolving_hearts":@"💞",
                     @"heart_decoration":@"💟",
                     @"diamond_shape_with_a_dot_inside":@"💠",
                     @"bulb":@"💡",
                     @"anger":@"💢",
                     @"bomb":@"💣",
                     @"zzz":@"💤",
                     @"boom":@"💥",
                     @"collision":@"💥",
                     @"sweat_drops":@"💦",
                     @"droplet":@"💧",
                     @"dash":@"💨",
                     @"hankey":@"💩",
                     @"poop":@"💩",
                     @"shit":@"💩",
                     @"muscle":@"💪",
                     @"dizzy":@"💫",
                     @"speech_balloon":@"💬",
                     @"thought_balloon":@"💭",
                     @"white_flower":@"💮",
                     @"100":@"💯",
                     @"moneybag":@"💰",
                     @"currency_exchange":@"💱",
                     @"heavy_dollar_sign":@"💲",
                     @"credit_card":@"💳",
                     @"yen":@"💴",
                     @"dollar":@"💵",
                     @"euro":@"💶",
                     @"pound":@"💷",
                     @"money_with_wings":@"💸",
                     @"chart":@"💹",
                     @"seat":@"💺",
                     @"computer":@"💻",
                     @"briefcase":@"💼",
                     @"minidisc":@"💽",
                     @"floppy_disk":@"💾",
                     @"cd":@"💿",
                     @"dvd":@"📀",
                     @"file_folder":@"📁",
                     @"open_file_folder":@"📂",
                     @"page_with_curl":@"📃",
                     @"page_facing_up":@"📄",
                     @"date":@"📅",
                     @"calendar":@"📆",
                     @"card_index":@"📇",
                     @"chart_with_upwards_trend":@"📈",
                     @"chart_with_downwards_trend":@"📉",
                     @"bar_chart":@"📊",
                     @"clipboard":@"📋",
                     @"pushpin":@"📌",
                     @"round_pushpin":@"📍",
                     @"paperclip":@"📎",
                     @"straight_ruler":@"📏",
                     @"triangular_ruler":@"📐",
                     @"bookmark_tabs":@"📑",
                     @"ledger":@"📒",
                     @"notebook":@"📓",
                     @"notebook_with_decorative_cover":@"📔",
                     @"closed_book":@"📕",
                     @"book":@"📖",
                     @"open_book":@"📖",
                     @"green_book":@"📗",
                     @"blue_book":@"📘",
                     @"orange_book":@"📙",
                     @"books":@"📚",
                     @"name_badge":@"📛",
                     @"scroll":@"📜",
                     @"memo":@"📝",
                     @"pencil":@"📝",
                     @"telephone_receiver":@"📞",
                     @"pager":@"📟",
                     @"fax":@"📠",
                     @"satellite_antenna":@"📡",
                     @"loudspeaker":@"📢",
                     @"mega":@"📣",
                     @"outbox_tray":@"📤",
                     @"inbox_tray":@"📥",
                     @"package":@"📦",
                     @"e-mail":@"📧",
                     @"incoming_envelope":@"📨",
                     @"envelope_with_arrow":@"📩",
                     @"mailbox_closed":@"📪",
                     @"mailbox":@"📫",
                     @"mailbox_with_mail":@"📬",
                     @"mailbox_with_no_mail":@"📭",
                     @"postbox":@"📮",
                     @"postal_horn":@"📯",
                     @"newspaper":@"📰",
                     @"iphone":@"📱",
                     @"calling":@"📲",
                     @"vibration_mode":@"📳",
                     @"mobile_phone_off":@"📴",
                     @"no_mobile_phones":@"📵",
                     @"signal_strength":@"📶",
                     @"camera":@"📷",
                     @"camera_with_flash":@"📸",
                     @"video_camera":@"📹",
                     @"tv":@"📺",
                     @"radio":@"📻",
                     @"vhs":@"📼",
                     @"film_projector":@"📽",
                     @"prayer_beads":@"📿",
                     @"twisted_rightwards_arrows":@"🔀",
                     @"repeat":@"🔁",
                     @"repeat_one":@"🔂",
                     @"arrows_clockwise":@"🔃",
                     @"arrows_counterclockwise":@"🔄",
                     @"low_brightness":@"🔅",
                     @"high_brightness":@"🔆",
                     @"mute":@"🔇",
                     @"speaker":@"🔈",
                     @"sound":@"🔉",
                     @"loud_sound":@"🔊",
                     @"battery":@"🔋",
                     @"electric_plug":@"🔌",
                     @"mag":@"🔍",
                     @"mag_right":@"🔎",
                     @"lock_with_ink_pen":@"🔏",
                     @"closed_lock_with_key":@"🔐",
                     @"key":@"🔑",
                     @"lock":@"🔒",
                     @"unlock":@"🔓",
                     @"bell":@"🔔",
                     @"no_bell":@"🔕",
                     @"bookmark":@"🔖",
                     @"link":@"🔗",
                     @"radio_button":@"🔘",
                     @"back":@"🔙",
                     @"end":@"🔚",
                     @"on":@"🔛",
                     @"soon":@"🔜",
                     @"top":@"🔝",
                     @"underage":@"🔞",
                     @"keycap_ten":@"🔟",
                     @"capital_abcd":@"🔠",
                     @"abcd":@"🔡",
                     @"1234":@"🔢",
                     @"symbols":@"🔣",
                     @"abc":@"🔤",
                     @"fire":@"🔥",
                     @"flashlight":@"🔦",
                     @"wrench":@"🔧",
                     @"hammer":@"🔨",
                     @"nut_and_bolt":@"🔩",
                     @"hocho":@"🔪",
                     @"knife":@"🔪",
                     @"gun":@"🔫",
                     @"microscope":@"🔬",
                     @"telescope":@"🔭",
                     @"crystal_ball":@"🔮",
                     @"six_pointed_star":@"🔯",
                     @"beginner":@"🔰",
                     @"trident":@"🔱",
                     @"black_square_button":@"🔲",
                     @"white_square_button":@"🔳",
                     @"red_circle":@"🔴",
                     @"large_blue_circle":@"🔵",
                     @"large_orange_diamond":@"🔶",
                     @"large_blue_diamond":@"🔷",
                     @"small_orange_diamond":@"🔸",
                     @"small_blue_diamond":@"🔹",
                     @"small_red_triangle":@"🔺",
                     @"small_red_triangle_down":@"🔻",
                     @"arrow_up_small":@"🔼",
                     @"arrow_down_small":@"🔽",
                     @"om_symbol":@"🕉",
                     @"dove_of_peace":@"🕊",
                     @"kaaba":@"🕋",
                     @"mosque":@"🕌",
                     @"synagogue":@"🕍",
                     @"menorah_with_nine_branches":@"🕎",
                     @"clock1":@"🕐",
                     @"clock2":@"🕑",
                     @"clock3":@"🕒",
                     @"clock4":@"🕓",
                     @"clock5":@"🕔",
                     @"clock6":@"🕕",
                     @"clock7":@"🕖",
                     @"clock8":@"🕗",
                     @"clock9":@"🕘",
                     @"clock10":@"🕙",
                     @"clock11":@"🕚",
                     @"clock12":@"🕛",
                     @"clock130":@"🕜",
                     @"clock230":@"🕝",
                     @"clock330":@"🕞",
                     @"clock430":@"🕟",
                     @"clock530":@"🕠",
                     @"clock630":@"🕡",
                     @"clock730":@"🕢",
                     @"clock830":@"🕣",
                     @"clock930":@"🕤",
                     @"clock1030":@"🕥",
                     @"clock1130":@"🕦",
                     @"clock1230":@"🕧",
                     @"candle":@"🕯",
                     @"mantelpiece_clock":@"🕰",
                     @"hole":@"🕳",
                     @"man_in_business_suit_levitating":@"🕴",
                     @"sleuth_or_spy":@"🕵",
                     @"dark_sunglasses":@"🕶",
                     @"spider":@"🕷",
                     @"spider_web":@"🕸",
                     @"joystick":@"🕹",
                     @"linked_paperclips":@"🖇",
                     @"lower_left_ballpoint_pen":@"🖊",
                     @"lower_left_fountain_pen":@"🖋",
                     @"lower_left_paintbrush":@"🖌",
                     @"lower_left_crayon":@"🖍",
                     @"raised_hand_with_fingers_splayed":@"🖐",
                     @"middle_finger":@"🖕",
                     @"reversed_hand_with_middle_finger_extended":@"🖕",
                     @"spock-hand":@"🖖",
                     @"desktop_computer":@"🖥",
                     @"printer":@"🖨",
                     @"three_button_mouse":@"🖱",
                     @"trackball":@"🖲",
                     @"frame_with_picture":@"🖼",
                     @"card_index_dividers":@"🗂",
                     @"card_file_box":@"🗃",
                     @"file_cabinet":@"🗄",
                     @"wastebasket":@"🗑",
                     @"spiral_note_pad":@"🗒",
                     @"spiral_calendar_pad":@"🗓",
                     @"compression":@"🗜",
                     @"old_key":@"🗝",
                     @"rolled_up_newspaper":@"🗞",
                     @"dagger_knife":@"🗡",
                     @"speaking_head_in_silhouette":@"🗣",
                     @"left_speech_bubble":@"🗨",
                     @"right_anger_bubble":@"🗯",
                     @"ballot_box_with_ballot":@"🗳",
                     @"world_map":@"🗺",
                     @"mount_fuji":@"🗻",
                     @"tokyo_tower":@"🗼",
                     @"statue_of_liberty":@"🗽",
                     @"japan":@"🗾",
                     @"moyai":@"🗿",
                     @"grinning":@"😀",
                     @"grin":@"😁",
                     @"joy":@"😂",
                     @"smiley":@"😃",
                     @"smile":@"😄",
                     @"sweat_smile":@"😅",
                     @"laughing":@"😆",
                     @"satisfied":@"😆",
                     @"innocent":@"😇",
                     @"smiling_imp":@"😈",
                     @"wink":@"😉",
                     @"blush":@"😊",
                     @"yum":@"😋",
                     @"relieved":@"😌",
                     @"heart_eyes":@"😍",
                     @"sunglasses":@"😎",
                     @"smirk":@"😏",
                     @"neutral_face":@"😐",
                     @"expressionless":@"😑",
                     @"unamused":@"😒",
                     @"sweat":@"😓",
                     @"pensive":@"😔",
                     @"confused":@"😕",
                     @"confounded":@"😖",
                     @"kissing":@"😗",
                     @"kissing_heart":@"😘",
                     @"kissing_smiling_eyes":@"😙",
                     @"kissing_closed_eyes":@"😚",
                     @"stuck_out_tongue":@"😛",
                     @"stuck_out_tongue_winking_eye":@"😜",
                     @"stuck_out_tongue_closed_eyes":@"😝",
                     @"disappointed":@"😞",
                     @"worried":@"😟",
                     @"angry":@"😠",
                     @"rage":@"😡",
                     @"cry":@"😢",
                     @"persevere":@"😣",
                     @"triumph":@"😤",
                     @"disappointed_relieved":@"😥",
                     @"frowning":@"😦",
                     @"anguished":@"😧",
                     @"fearful":@"😨",
                     @"weary":@"😩",
                     @"sleepy":@"😪",
                     @"tired_face":@"😫",
                     @"grimacing":@"😬",
                     @"sob":@"😭",
                     @"open_mouth":@"😮",
                     @"hushed":@"😯",
                     @"cold_sweat":@"😰",
                     @"scream":@"😱",
                     @"astonished":@"😲",
                     @"flushed":@"😳",
                     @"sleeping":@"😴",
                     @"dizzy_face":@"😵",
                     @"no_mouth":@"😶",
                     @"mask":@"😷",
                     @"smile_cat":@"😸",
                     @"joy_cat":@"😹",
                     @"smiley_cat":@"😺",
                     @"heart_eyes_cat":@"😻",
                     @"smirk_cat":@"😼",
                     @"kissing_cat":@"😽",
                     @"pouting_cat":@"😾",
                     @"crying_cat_face":@"😿",
                     @"scream_cat":@"🙀",
                     @"slightly_frowning_face":@"🙁",
                     @"slightly_smiling_face":@"🙂",
                     @"upside_down_face":@"🙃",
                     @"face_with_rolling_eyes":@"🙄",
                     @"no_good":@"🙅",
                     @"ok_woman":@"🙆",
                     @"bow":@"🙇",
                     @"see_no_evil":@"🙈",
                     @"hear_no_evil":@"🙉",
                     @"speak_no_evil":@"🙊",
                     @"raising_hand":@"🙋",
                     @"raised_hands":@"🙌",
                     @"person_frowning":@"🙍",
                     @"person_with_pouting_face":@"🙎",
                     @"pray":@"🙏",
                     @"rocket":@"🚀",
                     @"helicopter":@"🚁",
                     @"steam_locomotive":@"🚂",
                     @"railway_car":@"🚃",
                     @"bullettrain_side":@"🚄",
                     @"bullettrain_front":@"🚅",
                     @"train2":@"🚆",
                     @"metro":@"🚇",
                     @"light_rail":@"🚈",
                     @"station":@"🚉",
                     @"tram":@"🚊",
                     @"train":@"🚋",
                     @"bus":@"🚌",
                     @"oncoming_bus":@"🚍",
                     @"trolleybus":@"🚎",
                     @"busstop":@"🚏",
                     @"minibus":@"🚐",
                     @"ambulance":@"🚑",
                     @"fire_engine":@"🚒",
                     @"police_car":@"🚓",
                     @"oncoming_police_car":@"🚔",
                     @"taxi":@"🚕",
                     @"oncoming_taxi":@"🚖",
                     @"car":@"🚗",
                     @"red_car":@"🚗",
                     @"oncoming_automobile":@"🚘",
                     @"blue_car":@"🚙",
                     @"truck":@"🚚",
                     @"articulated_lorry":@"🚛",
                     @"tractor":@"🚜",
                     @"monorail":@"🚝",
                     @"mountain_railway":@"🚞",
                     @"suspension_railway":@"🚟",
                     @"mountain_cableway":@"🚠",
                     @"aerial_tramway":@"🚡",
                     @"ship":@"🚢",
                     @"rowboat":@"🚣",
                     @"speedboat":@"🚤",
                     @"traffic_light":@"🚥",
                     @"vertical_traffic_light":@"🚦",
                     @"construction":@"🚧",
                     @"rotating_light":@"🚨",
                     @"triangular_flag_on_post":@"🚩",
                     @"door":@"🚪",
                     @"no_entry_sign":@"🚫",
                     @"smoking":@"🚬",
                     @"no_smoking":@"🚭",
                     @"put_litter_in_its_place":@"🚮",
                     @"do_not_litter":@"🚯",
                     @"potable_water":@"🚰",
                     @"non-potable_water":@"🚱",
                     @"bike":@"🚲",
                     @"no_bicycles":@"🚳",
                     @"bicyclist":@"🚴",
                     @"mountain_bicyclist":@"🚵",
                     @"walking":@"🚶",
                     @"no_pedestrians":@"🚷",
                     @"children_crossing":@"🚸",
                     @"mens":@"🚹",
                     @"womens":@"🚺",
                     @"restroom":@"🚻",
                     @"baby_symbol":@"🚼",
                     @"toilet":@"🚽",
                     @"wc":@"🚾",
                     @"shower":@"🚿",
                     @"bath":@"🛀",
                     @"bathtub":@"🛁",
                     @"passport_control":@"🛂",
                     @"customs":@"🛃",
                     @"baggage_claim":@"🛄",
                     @"left_luggage":@"🛅",
                     @"couch_and_lamp":@"🛋",
                     @"sleeping_accommodation":@"🛌",
                     @"shopping_bags":@"🛍",
                     @"bellhop_bell":@"🛎",
                     @"bed":@"🛏",
                     @"place_of_worship":@"🛐",
                     @"hammer_and_wrench":@"🛠",
                     @"shield":@"🛡",
                     @"oil_drum":@"🛢",
                     @"motorway":@"🛣",
                     @"railway_track":@"🛤",
                     @"motor_boat":@"🛥",
                     @"small_airplane":@"🛩",
                     @"airplane_departure":@"🛫",
                     @"airplane_arriving":@"🛬",
                     @"satellite":@"🛰",
                     @"passenger_ship":@"🛳",
                     @"zipper_mouth_face":@"🤐",
                     @"money_mouth_face":@"🤑",
                     @"face_with_thermometer":@"🤒",
                     @"nerd_face":@"🤓",
                     @"thinking_face":@"🤔",
                     @"face_with_head_bandage":@"🤕",
                     @"robot_face":@"🤖",
                     @"hugging_face":@"🤗",
                     @"the_horns":@"🤘",
                     @"sign_of_the_horns":@"🤘",
                     @"crab":@"🦀",
                     @"lion_face":@"🦁",
                     @"scorpion":@"🦂",
                     @"turkey":@"🦃",
                     @"unicorn_face":@"🦄",
                     @"cheese_wedge":@"🧀",
                     @"hash":@"#⃣",
                     @"keycap_star":@"*⃣",
                     @"zero":@"0⃣",
                     @"one":@"1⃣",
                     @"two":@"2⃣",
                     @"three":@"3⃣",
                     @"four":@"4⃣",
                     @"five":@"5⃣",
                     @"six":@"6⃣",
                     @"seven":@"7⃣",
                     @"eight":@"8⃣",
                     @"nine":@"9⃣",
                     @"flag-ac":@"🇦🇨",
                     @"flag-ad":@"🇦🇩",
                     @"flag-ae":@"🇦🇪",
                     @"flag-af":@"🇦🇫",
                     @"flag-ag":@"🇦🇬",
                     @"flag-ai":@"🇦🇮",
                     @"flag-al":@"🇦🇱",
                     @"flag-am":@"🇦🇲",
                     @"flag-ao":@"🇦🇴",
                     @"flag-aq":@"🇦🇶",
                     @"flag-ar":@"🇦🇷",
                     @"flag-as":@"🇦🇸",
                     @"flag-at":@"🇦🇹",
                     @"flag-au":@"🇦🇺",
                     @"flag-aw":@"🇦🇼",
                     @"flag-ax":@"🇦🇽",
                     @"flag-az":@"🇦🇿",
                     @"flag-ba":@"🇧🇦",
                     @"flag-bb":@"🇧🇧",
                     @"flag-bd":@"🇧🇩",
                     @"flag-be":@"🇧🇪",
                     @"flag-bf":@"🇧🇫",
                     @"flag-bg":@"🇧🇬",
                     @"flag-bh":@"🇧🇭",
                     @"flag-bi":@"🇧🇮",
                     @"flag-bj":@"🇧🇯",
                     @"flag-bl":@"🇧🇱",
                     @"flag-bm":@"🇧🇲",
                     @"flag-bn":@"🇧🇳",
                     @"flag-bo":@"🇧🇴",
                     @"flag-bq":@"🇧🇶",
                     @"flag-br":@"🇧🇷",
                     @"flag-bs":@"🇧🇸",
                     @"flag-bt":@"🇧🇹",
                     @"flag-bv":@"🇧🇻",
                     @"flag-bw":@"🇧🇼",
                     @"flag-by":@"🇧🇾",
                     @"flag-bz":@"🇧🇿",
                     @"flag-ca":@"🇨🇦",
                     @"flag-cc":@"🇨🇨",
                     @"flag-cd":@"🇨🇩",
                     @"flag-cf":@"🇨🇫",
                     @"flag-cg":@"🇨🇬",
                     @"flag-ch":@"🇨🇭",
                     @"flag-ci":@"🇨🇮",
                     @"flag-ck":@"🇨🇰",
                     @"flag-cl":@"🇨🇱",
                     @"flag-cm":@"🇨🇲",
                     @"flag-cn":@"🇨🇳",
                     @"cn":@"🇨🇳",
                     @"flag-co":@"🇨🇴",
                     @"flag-cp":@"🇨🇵",
                     @"flag-cr":@"🇨🇷",
                     @"flag-cu":@"🇨🇺",
                     @"flag-cv":@"🇨🇻",
                     @"flag-cw":@"🇨🇼",
                     @"flag-cx":@"🇨🇽",
                     @"flag-cy":@"🇨🇾",
                     @"flag-cz":@"🇨🇿",
                     @"flag-de":@"🇩🇪",
                     @"de":@"🇩🇪",
                     @"flag-dg":@"🇩🇬",
                     @"flag-dj":@"🇩🇯",
                     @"flag-dk":@"🇩🇰",
                     @"flag-dm":@"🇩🇲",
                     @"flag-do":@"🇩🇴",
                     @"flag-dz":@"🇩🇿",
                     @"flag-ea":@"🇪🇦",
                     @"flag-ec":@"🇪🇨",
                     @"flag-ee":@"🇪🇪",
                     @"flag-eg":@"🇪🇬",
                     @"flag-eh":@"🇪🇭",
                     @"flag-er":@"🇪🇷",
                     @"flag-es":@"🇪🇸",
                     @"es":@"🇪🇸",
                     @"flag-et":@"🇪🇹",
                     @"flag-eu":@"🇪🇺",
                     @"flag-fi":@"🇫🇮",
                     @"flag-fj":@"🇫🇯",
                     @"flag-fk":@"🇫🇰",
                     @"flag-fm":@"🇫🇲",
                     @"flag-fo":@"🇫🇴",
                     @"flag-fr":@"🇫🇷",
                     @"fr":@"🇫🇷",
                     @"flag-ga":@"🇬🇦",
                     @"flag-gb":@"🇬🇧",
                     @"gb":@"🇬🇧",
                     @"uk":@"🇬🇧",
                     @"flag-gd":@"🇬🇩",
                     @"flag-ge":@"🇬🇪",
                     @"flag-gf":@"🇬🇫",
                     @"flag-gg":@"🇬🇬",
                     @"flag-gh":@"🇬🇭",
                     @"flag-gi":@"🇬🇮",
                     @"flag-gl":@"🇬🇱",
                     @"flag-gm":@"🇬🇲",
                     @"flag-gn":@"🇬🇳",
                     @"flag-gp":@"🇬🇵",
                     @"flag-gq":@"🇬🇶",
                     @"flag-gr":@"🇬🇷",
                     @"flag-gs":@"🇬🇸",
                     @"flag-gt":@"🇬🇹",
                     @"flag-gu":@"🇬🇺",
                     @"flag-gw":@"🇬🇼",
                     @"flag-gy":@"🇬🇾",
                     @"flag-hk":@"🇭🇰",
                     @"flag-hm":@"🇭🇲",
                     @"flag-hn":@"🇭🇳",
                     @"flag-hr":@"🇭🇷",
                     @"flag-ht":@"🇭🇹",
                     @"flag-hu":@"🇭🇺",
                     @"flag-ic":@"🇮🇨",
                     @"flag-id":@"🇮🇩",
                     @"flag-ie":@"🇮🇪",
                     @"flag-il":@"🇮🇱",
                     @"flag-im":@"🇮🇲",
                     @"flag-in":@"🇮🇳",
                     @"flag-io":@"🇮🇴",
                     @"flag-iq":@"🇮🇶",
                     @"flag-ir":@"🇮🇷",
                     @"flag-is":@"🇮🇸",
                     @"flag-it":@"🇮🇹",
                     @"it":@"🇮🇹",
                     @"flag-je":@"🇯🇪",
                     @"flag-jm":@"🇯🇲",
                     @"flag-jo":@"🇯🇴",
                     @"flag-jp":@"🇯🇵",
                     @"jp":@"🇯🇵",
                     @"flag-ke":@"🇰🇪",
                     @"flag-kg":@"🇰🇬",
                     @"flag-kh":@"🇰🇭",
                     @"flag-ki":@"🇰🇮",
                     @"flag-km":@"🇰🇲",
                     @"flag-kn":@"🇰🇳",
                     @"flag-kp":@"🇰🇵",
                     @"flag-kr":@"🇰🇷",
                     @"kr":@"🇰🇷",
                     @"flag-kw":@"🇰🇼",
                     @"flag-ky":@"🇰🇾",
                     @"flag-kz":@"🇰🇿",
                     @"flag-la":@"🇱🇦",
                     @"flag-lb":@"🇱🇧",
                     @"flag-lc":@"🇱🇨",
                     @"flag-li":@"🇱🇮",
                     @"flag-lk":@"🇱🇰",
                     @"flag-lr":@"🇱🇷",
                     @"flag-ls":@"🇱🇸",
                     @"flag-lt":@"🇱🇹",
                     @"flag-lu":@"🇱🇺",
                     @"flag-lv":@"🇱🇻",
                     @"flag-ly":@"🇱🇾",
                     @"flag-ma":@"🇲🇦",
                     @"flag-mc":@"🇲🇨",
                     @"flag-md":@"🇲🇩",
                     @"flag-me":@"🇲🇪",
                     @"flag-mf":@"🇲🇫",
                     @"flag-mg":@"🇲🇬",
                     @"flag-mh":@"🇲🇭",
                     @"flag-mk":@"🇲🇰",
                     @"flag-ml":@"🇲🇱",
                     @"flag-mm":@"🇲🇲",
                     @"flag-mn":@"🇲🇳",
                     @"flag-mo":@"🇲🇴",
                     @"flag-mp":@"🇲🇵",
                     @"flag-mq":@"🇲🇶",
                     @"flag-mr":@"🇲🇷",
                     @"flag-ms":@"🇲🇸",
                     @"flag-mt":@"🇲🇹",
                     @"flag-mu":@"🇲🇺",
                     @"flag-mv":@"🇲🇻",
                     @"flag-mw":@"🇲🇼",
                     @"flag-mx":@"🇲🇽",
                     @"flag-my":@"🇲🇾",
                     @"flag-mz":@"🇲🇿",
                     @"flag-na":@"🇳🇦",
                     @"flag-nc":@"🇳🇨",
                     @"flag-ne":@"🇳🇪",
                     @"flag-nf":@"🇳🇫",
                     @"flag-ng":@"🇳🇬",
                     @"flag-ni":@"🇳🇮",
                     @"flag-nl":@"🇳🇱",
                     @"flag-no":@"🇳🇴",
                     @"flag-np":@"🇳🇵",
                     @"flag-nr":@"🇳🇷",
                     @"flag-nu":@"🇳🇺",
                     @"flag-nz":@"🇳🇿",
                     @"flag-om":@"🇴🇲",
                     @"flag-pa":@"🇵🇦",
                     @"flag-pe":@"🇵🇪",
                     @"flag-pf":@"🇵🇫",
                     @"flag-pg":@"🇵🇬",
                     @"flag-ph":@"🇵🇭",
                     @"flag-pk":@"🇵🇰",
                     @"flag-pl":@"🇵🇱",
                     @"flag-pm":@"🇵🇲",
                     @"flag-pn":@"🇵🇳",
                     @"flag-pr":@"🇵🇷",
                     @"flag-ps":@"🇵🇸",
                     @"flag-pt":@"🇵🇹",
                     @"flag-pw":@"🇵🇼",
                     @"flag-py":@"🇵🇾",
                     @"flag-qa":@"🇶🇦",
                     @"flag-re":@"🇷🇪",
                     @"flag-ro":@"🇷🇴",
                     @"flag-rs":@"🇷🇸",
                     @"flag-ru":@"🇷🇺",
                     @"ru":@"🇷🇺",
                     @"flag-rw":@"🇷🇼",
                     @"flag-sa":@"🇸🇦",
                     @"flag-sb":@"🇸🇧",
                     @"flag-sc":@"🇸🇨",
                     @"flag-sd":@"🇸🇩",
                     @"flag-se":@"🇸🇪",
                     @"flag-sg":@"🇸🇬",
                     @"flag-sh":@"🇸🇭",
                     @"flag-si":@"🇸🇮",
                     @"flag-sj":@"🇸🇯",
                     @"flag-sk":@"🇸🇰",
                     @"flag-sl":@"🇸🇱",
                     @"flag-sm":@"🇸🇲",
                     @"flag-sn":@"🇸🇳",
                     @"flag-so":@"🇸🇴",
                     @"flag-sr":@"🇸🇷",
                     @"flag-ss":@"🇸🇸",
                     @"flag-st":@"🇸🇹",
                     @"flag-sv":@"🇸🇻",
                     @"flag-sx":@"🇸🇽",
                     @"flag-sy":@"🇸🇾",
                     @"flag-sz":@"🇸🇿",
                     @"flag-ta":@"🇹🇦",
                     @"flag-tc":@"🇹🇨",
                     @"flag-td":@"🇹🇩",
                     @"flag-tf":@"🇹🇫",
                     @"flag-tg":@"🇹🇬",
                     @"flag-th":@"🇹🇭",
                     @"flag-tj":@"🇹🇯",
                     @"flag-tk":@"🇹🇰",
                     @"flag-tl":@"🇹🇱",
                     @"flag-tm":@"🇹🇲",
                     @"flag-tn":@"🇹🇳",
                     @"flag-to":@"🇹🇴",
                     @"flag-tr":@"🇹🇷",
                     @"flag-tt":@"🇹🇹",
                     @"flag-tv":@"🇹🇻",
                     @"flag-tw":@"🇹🇼",
                     @"flag-tz":@"🇹🇿",
                     @"flag-ua":@"🇺🇦",
                     @"flag-ug":@"🇺🇬",
                     @"flag-um":@"🇺🇲",
                     @"flag-us":@"🇺🇸",
                     @"us":@"🇺🇸",
                     @"flag-uy":@"🇺🇾",
                     @"flag-uz":@"🇺🇿",
                     @"flag-va":@"🇻🇦",
                     @"flag-vc":@"🇻🇨",
                     @"flag-ve":@"🇻🇪",
                     @"flag-vg":@"🇻🇬",
                     @"flag-vi":@"🇻🇮",
                     @"flag-vn":@"🇻🇳",
                     @"flag-vu":@"🇻🇺",
                     @"flag-wf":@"🇼🇫",
                     @"flag-ws":@"🇼🇸",
                     @"flag-xk":@"🇽🇰",
                     @"flag-ye":@"🇾🇪",
                     @"flag-yt":@"🇾🇹",
                     @"flag-za":@"🇿🇦",
                     @"flag-zm":@"🇿🇲",
                     @"flag-zw":@"🇿🇼",
                     @"man-man-boy":@"👨‍👨‍👦",
                     @"man-man-boy-boy":@"👨‍👨‍👦‍👦",
                     @"man-man-girl":@"👨‍👨‍👧",
                     @"man-man-girl-boy":@"👨‍👨‍👧‍👦",
                     @"man-man-girl-girl":@"👨‍👨‍👧‍👧",
                     @"man-woman-boy-boy":@"👨‍👩‍👦‍👦",
                     @"man-woman-girl":@"👨‍👩‍👧",
                     @"man-woman-girl-boy":@"👨‍👩‍👧‍👦",
                     @"man-woman-girl-girl":@"👨‍👩‍👧‍👧",
                     @"man-heart-man":@"👨‍❤️‍👨",
                     @"man-kiss-man":@"👨‍❤️‍💋‍👨",
                     @"woman-woman-boy":@"👩‍👩‍👦",
                     @"woman-woman-boy-boy":@"👩‍👩‍👦‍👦",
                     @"woman-woman-girl":@"👩‍👩‍👧",
                     @"woman-woman-girl-boy":@"👩‍👩‍👧‍👦",
                     @"woman-woman-girl-girl":@"👩‍👩‍👧‍👧",
                     @"woman-heart-woman":@"👩‍❤️‍👩",
                     @"woman-kiss-woman":@"👩‍❤️‍💋‍👩",
                     
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
                     @"simple_smile":@":)",
                     @"slightly_smiling_face":@":)"};
    
    static NSRegularExpression *_pattern;
    if(!_pattern) {
        NSError *err;
        NSString *pattern = [NSString stringWithFormat:@"\\B:(%@):\\B", [[[[[emojiMap.allKeys componentsJoinedByString:@"|"] stringByReplacingOccurrencesOfString:@"-" withString:@"\\-"] stringByReplacingOccurrencesOfString:@"+" withString:@"\\+"] stringByReplacingOccurrencesOfString:@"(" withString:@"\\("] stringByReplacingOccurrencesOfString:@")" withString:@"\\)"]];
        _pattern = [NSRegularExpression
                    regularExpressionWithPattern:pattern
                    options:NSRegularExpressionCaseInsensitive
                    error:&err];
    }
    return _pattern;
}

+(NSPredicate *)emojiOnlyPattern {
    if(!emojiMap)
        [self emoji];
    
    static NSPredicate *_pattern;
    if(!_pattern) {
        _pattern = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", [NSString stringWithFormat:@"[%@]+", [emojiMap.allValues componentsJoinedByString:@""]]];
    }
    return _pattern;
}

+(BOOL)emojiOnly:(NSString *)text {
    return [[self emojiOnlyPattern] evaluateWithObject:text];
}

+(NSRegularExpression *)spotify {
    static NSRegularExpression *_pattern = nil;
    if(!_pattern) {
        NSString *pattern = @"spotify:([^<>\"\\s]+)";
        _pattern = [NSRegularExpression
                    regularExpressionWithPattern:pattern
                    options:NSRegularExpressionCaseInsensitive
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
                    options:NSRegularExpressionCaseInsensitive
                    error:nil];
    }
    return _pattern;
}

+(NSRegularExpression *)webURL {
    static NSRegularExpression *_pattern = nil;
    if(!_pattern) {
    //Ported from Android: https://github.com/android/platform_frameworks_base/blob/master/core/java/android/util/Patterns.java
    NSString *TOP_LEVEL_DOMAIN_STR_FOR_WEB_URL = @"(?:\
(?:aaa|aarp|abb|abbott|abbvie|abogado|abudhabi|academy|accenture|accountant|accountants|aco|active|actor|adac|ads|adult|aeg|aero|aetna|afl|agakhan|agency|aig|airbus|airforce|airtel|akdn|alibaba|alipay|allfinanz|ally|alsace|alstom|amica|amsterdam|analytics|android|anquan|apartments|app|apple|aquarelle|aramco|archi|army|arpa|arte|asia|associates|attorney|auction|audi|audible|audio|author|auto|autos|avianca|aws|axa|azure|a[cdefgilmoqrstuwxz])\
|(?:baby|baidu|band|bank|bar|barcelona|barclaycard|barclays|barefoot|bargains|bauhaus|bayern|bbc|bbva|bcg|bcn|beats|beer|bentley|berlin|best|bet|bharti|bible|bid|bike|bing|bingo|bio|biz|black|blackfriday|blog|bloomberg|blue|bms|bmw|bnl|bnpparibas|boats|boehringer|bom|bond|boo|book|boots|bosch|bostik|bot|boutique|bradesco|bridgestone|broadway|broker|brother|brussels|budapest|bugatti|build|builders|business|buy|buzz|bzh|b[abdefghijmnorstvwyz])\
|(?:cab|cafe|cal|call|camera|camp|cancerresearch|canon|capetown|capital|car|caravan|cards|care|career|careers|cars|cartier|casa|cash|casino|cat|catering|cba|cbn|ceb|center|ceo|cern|cfa|cfd|chanel|channel|chase|chat|cheap|chintai|chloe|christmas|chrome|church|cipriani|circle|cisco|citic|city|cityeats|claims|cleaning|click|clinic|clinique|clothing|cloud|club|clubmed|coach|codes|coffee|college|cologne|com|commbank|community|company|compare|computer|comsec|condos|construction|consulting|contact|contractors|cooking|cool|coop|corsica|country|coupon|coupons|courses|credit|creditcard|creditunion|cricket|crown|crs|cruises|csc|cuisinella|cymru|cyou|c[acdfghiklmnoruvwxyz])\
|(?:dabur|dad|dance|date|dating|datsun|day|dclk|dds|deal|dealer|deals|degree|delivery|dell|deloitte|delta|democrat|dental|dentist|desi|design|dev|dhl|diamonds|diet|digital|direct|directory|discount|dnp|docs|dog|doha|domains|dot|download|drive|dtv|dubai|dunlop|dupont|durban|dvag|d[ejkmoz])\
|(?:earth|eat|edeka|edu|education|email|emerck|energy|engineer|engineering|enterprises|epost|epson|equipment|ericsson|erni|esq|estate|eurovision|eus|events|everbank|exchange|expert|exposed|express|extraspace|e[cegrstu])\
|(?:fage|fail|fairwinds|faith|family|fan|fans|farm|fashion|fast|feedback|ferrero|film|final|finance|financial|fire|firestone|firmdale|fish|fishing|fit|fitness|flickr|flights|flir|florist|flowers|flsmidth|fly|foo|football|ford|forex|forsale|forum|foundation|fox|fresenius|frl|frogans|frontier|ftr|fund|furniture|futbol|fyi|f[ijkmor])\
|(?:gal|gallery|gallo|gallup|game|games|garden|gbiz|gdn|gea|gent|genting|ggee|gift|gifts|gives|giving|glass|gle|global|globo|gmail|gmbh|gmo|gmx|gold|goldpoint|golf|goo|goodyear|goog|google|gop|got|gov|grainger|graphics|gratis|green|gripe|group|guardian|gucci|guge|guide|guitars|guru|g[abdefghilmnpqrstuwy])\
|(?:hamburg|hangout|haus|hdfcbank|health|healthcare|help|helsinki|here|hermes|hiphop|hisamitsu|hitachi|hiv|hkt|hockey|holdings|holiday|homedepot|homes|honda|horse|host|hosting|hoteles|hotmail|house|how|hsbc|htc|hyundai|h[kmnrtu])\
|(?:ibm|icbc|ice|icu|ifm|iinet|imamat|imdb|immo|immobilien|industries|infiniti|info|ing|ink|institute|insurance|insure|int|international|investments|ipiranga|irish|iselect|ismaili|ist|istanbul|itau|iwc|i[delmnoqrst])\
|(?:jaguar|java|jcb|jcp|jetzt|jewelry|jlc|jll|jmp|jnj|jobs|joburg|jot|joy|jpmorgan|jprs|juegos|j[emop])\
|(?:kaufen|kddi|kerryhotels|kerrylogistics|kerryproperties|kfh|kia|kim|kinder|kindle|kitchen|kiwi|koeln|komatsu|kosher|kpmg|kpn|krd|kred|kuokgroup|kyoto|k[eghimnprwyz])\
|(?:lacaixa|lamborghini|lamer|lancaster|land|landrover|lanxess|lasalle|lat|latrobe|law|lawyer|lds|lease|leclerc|legal|lexus|lgbt|liaison|lidl|life|lifeinsurance|lifestyle|lighting|like|limited|limo|lincoln|linde|link|lipsy|live|living|lixil|loan|loans|locker|locus|lol|london|lotte|lotto|love|ltd|ltda|lupin|luxe|luxury|l[abcikrstuvy])\
|(?:madrid|maif|maison|makeup|man|management|mango|market|marketing|markets|marriott|mattel|mba|med|media|meet|melbourne|meme|memorial|men|menu|meo|metlife|miami|microsoft|mil|mini|mlb|mls|mma|mobi|mobily|moda|moe|moi|mom|monash|money|montblanc|mormon|mortgage|moscow|motorcycles|mov|movie|movistar|mtn|mtpc|mtr|museum|mutual|mutuelle|m[acdeghklmnopqrstuvwxyz])\
|(?:nadex|nagoya|name|natura|navy|nec|net|netbank|netflix|network|neustar|new|news|next|nextdirect|nexus|ngo|nhk|nico|nikon|ninja|nissan|nissay|nokia|northwesternmutual|norton|now|nowruz|nowtv|nra|nrw|ntt|nyc|n[acefgilopruz])\
|(?:obi|office|okinawa|olayan|olayangroup|ollo|omega|one|ong|onl|online|ooo|oracle|orange|org|organic|origins|osaka|otsuka|ott|ovh|om)\
|(?:page|pamperedchef|panerai|paris|pars|partners|parts|party|passagens|pccw|pet|pharmacy|philips|photo|photography|photos|physio|piaget|pics|pictet|pictures|pid|pin|ping|pink|pioneer|pizza|place|play|playstation|plumbing|plus|pohl|poker|porn|post|praxi|press|prime|pro|prod|productions|prof|progressive|promo|properties|property|protection|pub|pwc|p[aefghklmnrstwy])\
|(?:qpon|quebec|quest|qa)\
|(?:racing|read|realestate|realtor|realty|recipes|red|redstone|redumbrella|rehab|reise|reisen|reit|ren|rent|rentals|repair|report|republican|rest|restaurant|review|reviews|rexroth|rich|richardli|ricoh|rio|rip|rocher|rocks|rodeo|room|rsvp|ruhr|run|rwe|ryukyu|r[eosuw])\
|(?:saarland|safe|safety|sakura|sale|salon|samsung|sandvik|sandvikcoromant|sanofi|sap|sapo|sarl|sas|save|saxo|sbi|sbs|sca|scb|schaeffler|schmidt|scholarships|school|schule|schwarz|science|scor|scot|seat|security|seek|select|sener|services|seven|sew|sex|sexy|sfr|sharp|shaw|shell|shia|shiksha|shoes|shop|shouji|show|shriram|silk|sina|singles|site|ski|skin|sky|skype|smile|sncf|soccer|social|softbank|software|sohu|solar|solutions|song|sony|soy|space|spiegel|spot|spreadbetting|srl|stada|star|starhub|statebank|statefarm|statoil|stc|stcgroup|stockholm|storage|store|stream|studio|study|style|sucks|supplies|supply|support|surf|surgery|suzuki|swatch|swiss|sydney|symantec|systems|s[abcdeghijklmnortuvxyz])\
|(?:tab|taipei|talk|taobao|tatamotors|tatar|tattoo|tax|taxi|tci|tdk|team|tech|technology|tel|telecity|telefonica|temasek|tennis|teva|thd|theater|theatre|tickets|tienda|tiffany|tips|tires|tirol|tmall|today|tokyo|tools|top|toray|toshiba|total|tours|town|toyota|toys|trade|trading|training|travel|travelers|travelersinsurance|trust|trv|tube|tui|tunes|tushu|tvs|t[cdfghjklmnortvwz])\
|(?:ubs|unicom|university|uno|uol|ups|u[agksyz])\
|(?:vacations|vana|vegas|ventures|verisign|versicherung|vet|viajes|video|vig|viking|villas|vin|vip|virgin|vision|vista|vistaprint|viva|vlaanderen|vodka|volkswagen|vote|voting|voto|voyage|vuelos|v[aceginu])\
|(?:wales|walter|wang|wanggou|warman|watch|watches|weather|weatherchannel|webcam|weber|website|wed|wedding|weibo|weir|whoswho|wien|wiki|williamhill|win|windows|wine|wme|wolterskluwer|work|works|world|wtc|wtf|w[fs])\
|(?:\\u03b5\\u03bb|\\u0431\\u0435\\u043b|\\u0434\\u0435\\u0442\\u0438|\\u0435\\u044e|\\u043a\\u043e\\u043c|\\u043c\\u043a\\u0434|\\u043c\\u043e\\u043d|\\u043c\\u043e\\u0441\\u043a\\u0432\\u0430|\\u043e\\u043d\\u043b\\u0430\\u0439\\u043d|\\u043e\\u0440\\u0433|\\u0440\\u0443\\u0441|\\u0440\\u0444|\\u0441\\u0430\\u0439\\u0442|\\u0441\\u0440\\u0431|\\u0443\\u043a\\u0440|\\u049b\\u0430\\u0437|\\u0570\\u0561\\u0575|\\u05e7\\u05d5\\u05dd|\\u0627\\u0628\\u0648\\u0638\\u0628\\u064a|\\u0627\\u0631\\u0627\\u0645\\u0643\\u0648|\\u0627\\u0644\\u0627\\u0631\\u062f\\u0646|\\u0627\\u0644\\u062c\\u0632\\u0627\\u0626\\u0631|\\u0627\\u0644\\u0633\\u0639\\u0648\\u062f\\u064a\\u0629|\\u0627\\u0644\\u0639\\u0644\\u064a\\u0627\\u0646|\\u0627\\u0644\\u0645\\u063a\\u0631\\u0628|\\u0627\\u0645\\u0627\\u0631\\u0627\\u062a|\\u0627\\u06cc\\u0631\\u0627\\u0646|\\u0628\\u0627\\u0632\\u0627\\u0631|\\u0628\\u064a\\u062a\\u0643|\\u0628\\u06be\\u0627\\u0631\\u062a|\\u062a\\u0648\\u0646\\u0633|\\u0633\\u0648\\u062f\\u0627\\u0646|\\u0633\\u0648\\u0631\\u064a\\u0629|\\u0634\\u0628\\u0643\\u0629|\\u0639\\u0631\\u0627\\u0642|\\u0639\\u0645\\u0627\\u0646|\\u0641\\u0644\\u0633\\u0637\\u064a\\u0646|\\u0642\\u0637\\u0631|\\u0643\\u0648\\u0645|\\u0645\\u0635\\u0631|\\u0645\\u0644\\u064a\\u0633\\u064a\\u0627|\\u0645\\u0648\\u0628\\u0627\\u064a\\u0644\\u064a|\\u0645\\u0648\\u0642\\u0639|\\u0647\\u0645\\u0631\\u0627\\u0647|\\u0915\\u0949\\u092e|\\u0928\\u0947\\u091f|\\u092d\\u093e\\u0930\\u0924|\\u0938\\u0902\\u0917\\u0920\\u0928|\\u09ad\\u09be\\u09b0\\u09a4|\\u0a2d\\u0a3e\\u0a30\\u0a24|\\u0aad\\u0abe\\u0ab0\\u0aa4|\\u0b87\\u0ba8\\u0bcd\\u0ba4\\u0bbf\\u0baf\\u0bbe|\\u0b87\\u0bb2\\u0b99\\u0bcd\\u0b95\\u0bc8|\\u0b9a\\u0bbf\\u0b99\\u0bcd\\u0b95\\u0baa\\u0bcd\\u0baa\\u0bc2\\u0bb0\\u0bcd|\\u0c2d\\u0c3e\\u0c30\\u0c24\\u0c4d|\\u0dbd\\u0d82\\u0d9a\\u0dcf|\\u0e04\\u0e2d\\u0e21|\\u0e44\\u0e17\\u0e22|\\u10d2\\u10d4|\\u307f\\u3093\\u306a|\\u30af\\u30e9\\u30a6\\u30c9|\\u30b0\\u30fc\\u30b0\\u30eb|\\u30b3\\u30e0|\\u30b9\\u30c8\\u30a2|\\u30bb\\u30fc\\u30eb|\\u30d5\\u30a1\\u30c3\\u30b7\\u30e7\\u30f3|\\u30dd\\u30a4\\u30f3\\u30c8|\\u4e16\\u754c|\\u4e2d\\u4fe1|\\u4e2d\\u56fd|\\u4e2d\\u570b|\\u4e2d\\u6587\\u7f51|\\u4f01\\u4e1a|\\u4f5b\\u5c71|\\u4fe1\\u606f|\\u5065\\u5eb7|\\u516b\\u5366|\\u516c\\u53f8|\\u516c\\u76ca|\\u53f0\\u6e7e|\\u53f0\\u7063|\\u5546\\u57ce|\\u5546\\u5e97|\\u5546\\u6807|\\u5609\\u91cc|\\u5609\\u91cc\\u5927\\u9152\\u5e97|\\u5728\\u7ebf|\\u5927\\u62ff|\\u5a31\\u4e50|\\u5bb6\\u96fb|\\u5de5\\u884c|\\u5e7f\\u4e1c|\\u5fae\\u535a|\\u6148\\u5584|\\u6211\\u7231\\u4f60|\\u624b\\u673a|\\u624b\\u8868|\\u653f\\u52a1|\\u653f\\u5e9c|\\u65b0\\u52a0\\u5761|\\u65b0\\u95fb|\\u65f6\\u5c1a|\\u66f8\\u7c4d|\\u673a\\u6784|\\u6de1\\u9a6c\\u9521|\\u6e38\\u620f|\\u6fb3\\u9580|\\u70b9\\u770b|\\u73e0\\u5b9d|\\u79fb\\u52a8|\\u7ec4\\u7ec7\\u673a\\u6784|\\u7f51\\u5740|\\u7f51\\u5e97|\\u7f51\\u7ad9|\\u7f51\\u7edc|\\u8054\\u901a|\\u8bfa\\u57fa\\u4e9a|\\u8c37\\u6b4c|\\u8d2d\\u7269|\\u96c6\\u56e2|\\u96fb\\u8a0a\\u76c8\\u79d1|\\u98de\\u5229\\u6d66|\\u98df\\u54c1|\\u9910\\u5385|\\u9999\\u6e2f|\\ub2f7\\ub137|\\ub2f7\\ucef4|\\uc0bc\\uc131|\\ud55c\\uad6d|verm\\xf6gensberater|verm\\xf6gensberatung|xbox|xerox|xihuan|xin|xn\\-\\-11b4c3d|xn\\-\\-1ck2e1b|xn\\-\\-1qqw23a|xn\\-\\-30rr7y|xn\\-\\-3bst00m|xn\\-\\-3ds443g|xn\\-\\-3e0b707e|xn\\-\\-3pxu8k|xn\\-\\-42c2d9a|xn\\-\\-45brj9c|xn\\-\\-45q11c|xn\\-\\-4gbrim|xn\\-\\-55qw42g|xn\\-\\-55qx5d|xn\\-\\-5tzm5g|xn\\-\\-6frz82g|xn\\-\\-6qq986b3xl|xn\\-\\-80adxhks|xn\\-\\-80ao21a|xn\\-\\-80asehdb|xn\\-\\-80aswg|xn\\-\\-8y0a063a|xn\\-\\-90a3ac|xn\\-\\-90ais|xn\\-\\-9dbq2a|xn\\-\\-9et52u|xn\\-\\-9krt00a|xn\\-\\-b4w605ferd|xn\\-\\-bck1b9a5dre4c|xn\\-\\-c1avg|xn\\-\\-c2br7g|xn\\-\\-cck2b3b|xn\\-\\-cg4bki|xn\\-\\-clchc0ea0b2g2a9gcd|xn\\-\\-czr694b|xn\\-\\-czrs0t|xn\\-\\-czru2d|xn\\-\\-d1acj3b|xn\\-\\-d1alf|xn\\-\\-e1a4c|xn\\-\\-eckvdtc9d|xn\\-\\-efvy88h|xn\\-\\-estv75g|xn\\-\\-fct429k|xn\\-\\-fhbei|xn\\-\\-fiq228c5hs|xn\\-\\-fiq64b|xn\\-\\-fiqs8s|xn\\-\\-fiqz9s|xn\\-\\-fjq720a|xn\\-\\-flw351e|xn\\-\\-fpcrj9c3d|xn\\-\\-fzc2c9e2c|xn\\-\\-fzys8d69uvgm|xn\\-\\-g2xx48c|xn\\-\\-gckr3f0f|xn\\-\\-gecrj9c|xn\\-\\-h2brj9c|xn\\-\\-hxt814e|xn\\-\\-i1b6b1a6a2e|xn\\-\\-imr513n|xn\\-\\-io0a7i|xn\\-\\-j1aef|xn\\-\\-j1amh|xn\\-\\-j6w193g|xn\\-\\-jlq61u9w7b|xn\\-\\-jvr189m|xn\\-\\-kcrx77d1x4a|xn\\-\\-kprw13d|xn\\-\\-kpry57d|xn\\-\\-kpu716f|xn\\-\\-kput3i|xn\\-\\-l1acc|xn\\-\\-lgbbat1ad8j|xn\\-\\-mgb9awbf|xn\\-\\-mgba3a3ejt|xn\\-\\-mgba3a4f16a|xn\\-\\-mgba7c0bbn0a|xn\\-\\-mgbaam7a8h|xn\\-\\-mgbab2bd|xn\\-\\-mgbayh7gpa|xn\\-\\-mgbb9fbpob|xn\\-\\-mgbbh1a71e|xn\\-\\-mgbc0a9azcg|xn\\-\\-mgbca7dzdo|xn\\-\\-mgberp4a5d4ar|xn\\-\\-mgbpl2fh|xn\\-\\-mgbt3dhd|xn\\-\\-mgbtx2b|xn\\-\\-mgbx4cd0ab|xn\\-\\-mix891f|xn\\-\\-mk1bu44c|xn\\-\\-mxtq1m|xn\\-\\-ngbc5azd|xn\\-\\-ngbe9e0a|xn\\-\\-node|xn\\-\\-nqv7f|xn\\-\\-nqv7fs00ema|xn\\-\\-nyqy26a|xn\\-\\-o3cw4h|xn\\-\\-ogbpf8fl|xn\\-\\-p1acf|xn\\-\\-p1ai|xn\\-\\-pbt977c|xn\\-\\-pgbs0dh|xn\\-\\-pssy2u|xn\\-\\-q9jyb4c|xn\\-\\-qcka1pmc|xn\\-\\-qxam|xn\\-\\-rhqv96g|xn\\-\\-rovu88b|xn\\-\\-s9brj9c|xn\\-\\-ses554g|xn\\-\\-t60b56a|xn\\-\\-tckwe|xn\\-\\-unup4y|xn\\-\\-vermgensberater\\-ctb|xn\\-\\-vermgensberatung\\-pwb|xn\\-\\-vhquv|xn\\-\\-vuq861b|xn\\-\\-w4r85el8fhu5dnra|xn\\-\\-w4rs40l|xn\\-\\-wgbh1c|xn\\-\\-wgbl6a|xn\\-\\-xhq521b|xn\\-\\-xkc2al3hye2a|xn\\-\\-xkc2dl3a5ee0h|xn\\-\\-y9a3aq|xn\\-\\-yfro4i67o|xn\\-\\-ygbi2ammx|xn\\-\\-zfr164b|xperia|xxx|xyz)\
|(?:yachts|yahoo|yamaxun|yandex|yodobashi|yoga|yokohama|you|youtube|yun|y[et])\
|(?:zappos|zara|zero|zip|zone|zuerich|z[amw])))";
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
\\-\\.\\+\\!\\*\\'\\(\\)\\,\\_\\^\\{\\}\\[\\]\\|])|(?:\\%%[a-fA-F0-9]{2}))*)?\
(?:\\b|$)", GOOD_IRI_CHAR, GOOD_IRI_CHAR, TOP_LEVEL_DOMAIN_STR_FOR_WEB_URL, GOOD_IRI_CHAR];
    _pattern = [NSRegularExpression
            regularExpressionWithPattern:pattern
            options:NSRegularExpressionCaseInsensitive
            error:nil];
    }
    return _pattern;
}

+(NSRegularExpression *)ircChannelRegexForServer:(Server *)s {
    NSString *pattern;
    if(s && s.CHANTYPES.length) {
        pattern = [NSString stringWithFormat:@"(\\s|^)([%@][^\\ufe0e\\ufe0f\\u20e3<>\",\\s\\u0001][^<>\",\\s\\u0001]*)", s.CHANTYPES];
    } else {
        pattern = [NSString stringWithFormat:@"(\\s|^)([#][^\\ufe0e\\ufe0f\\u20e3<>\",\\s\\u0001][^<>\",\\s\\u0001]*)"];
    }
    
    return [NSRegularExpression
            regularExpressionWithPattern:pattern
            options:NSRegularExpressionCaseInsensitive
            error:nil];
}

+(BOOL)unbalanced:(NSString *)input {
    if(!quotes)
        quotes = @{@"\"":@"\"",@"'": @"'",@")": @"(",@"]": @"[",@"}": @"{",@">": @"<",@"”": @"“",@"’": @"‘",@"»": @"«"};
    
    NSString *lastChar = [input substringFromIndex:input.length - 1];
    
    return [quotes objectForKey:lastChar] && [input componentsSeparatedByString:lastChar].count != [input componentsSeparatedByString:[quotes objectForKey:lastChar]].count;
}

+(void)setFont:(id)font start:(int)start length:(int)length attributes:(NSMutableArray *)attributes {
    [attributes addObject:@{NSFontAttributeName:font,
                            @"start":@(start),
                            @"length":@(length)
                            }];
}

+(void)loadFonts {
    monoTimestampFont = [UIFont fontWithName:@"Hack" size:FONT_SIZE - 3];
    timestampFont = [UIFont systemFontOfSize:FONT_SIZE - 2];
    awesomeFont = [UIFont fontWithName:@"FontAwesome" size:FONT_SIZE];
    arrowFont = [UIFont fontWithName:@"SourceSansPro-Regular" size:FONT_SIZE];
    Courier = [UIFont fontWithName:@"Hack" size:FONT_SIZE - 1];
    CourierBold = [UIFont fontWithName:@"Hack-Bold" size:FONT_SIZE - 1];
    CourierOblique = [UIFont fontWithName:@"Hack-Italic" size:FONT_SIZE - 1];
    CourierBoldOblique = [UIFont fontWithName:@"Hack-BoldItalic" size:FONT_SIZE - 1];
    chalkboardFont = [UIFont fontWithName:@"ChalkboardSE-Light" size:FONT_SIZE];
    markerFont = [UIFont fontWithName:@"MarkerFelt-Thin" size:FONT_SIZE];
    largeEmojiFont = [UIFont fontWithName:@"AppleColorEmoji" size:FONT_SIZE * 2];
    UIFontDescriptor *bodyFontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
    UIFontDescriptor *boldBodyFontDescriptor = [bodyFontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
    UIFontDescriptor *italicBodyFontDescriptor = [bodyFontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
    UIFontDescriptor *boldItalicBodyFontDescriptor = [bodyFontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold|UIFontDescriptorTraitItalic];
    Helvetica = [UIFont fontWithDescriptor:bodyFontDescriptor size:FONT_SIZE];
    HelveticaBold = [UIFont fontWithDescriptor:boldBodyFontDescriptor size:FONT_SIZE];
    HelveticaOblique = [UIFont fontWithDescriptor:italicBodyFontDescriptor size:FONT_SIZE];
    HelveticaBoldOblique = [UIFont fontWithDescriptor:boldItalicBodyFontDescriptor size:FONT_SIZE];
    ColorFormatterCachedFontSize = FONT_SIZE;
}

+(void)emojify:(NSMutableString *)text {
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

+(NSAttributedString *)format:(NSString *)input defaultColor:(UIColor *)color mono:(BOOL)mono linkify:(BOOL)linkify server:(Server *)server links:(NSArray **)links {
    return [self format:input defaultColor:color mono:mono linkify:linkify server:server links:links largeEmoji:NO];
}
+(NSAttributedString *)format:(NSString *)input defaultColor:(UIColor *)color mono:(BOOL)mono linkify:(BOOL)linkify server:(Server *)server links:(NSArray **)links largeEmoji:(BOOL)largeEmoji {
    if(!color)
        color = [UIColor messageTextColor];
    
    int bold = -1, italics = -1, underline = -1, fg = -1, bg = -1;
    UIColor *fgColor = nil, *bgColor = nil;
    id font, boldFont, italicFont, boldItalicFont;
    NSMutableArray *matches = [[NSMutableArray alloc] init];
    
    if(!Courier) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self loadFonts];
        });
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
    
    NSMutableString *text = [[NSMutableString alloc] initWithFormat:@"%@%c", [input stringByReplacingOccurrencesOfString:@"  " withString:@"\u00A0 "], CLEAR];
    BOOL disableConvert = [[NetworkConnection sharedInstance] prefs] && [[[[NetworkConnection sharedInstance] prefs] objectForKey:@"emoji-disableconvert"] boolValue];
    if(!disableConvert) {
        [self emojify:text];
    }
    
    for(int i = 0; i < text.length; i++) {
        switch([text characterAtIndex:i]) {
            case 0x2190:
            case 0x2192:
            case 0x2194:
            case 0x21D0:
                if(i < text.length - 1 && [text characterAtIndex:i+1] == 0xFE0E) {
                    [arrowIndex addObject:@(i)];
                }
                break;
            case BOLD:
                if(bold == -1) {
                    bold = i;
                } else {
                    if(italics != -1) {
                        if(italics < bold - 1) {
                            [self setFont:italicFont start:italics length:(bold - italics) attributes:attributes];
                        }
                        [self setFont:boldItalicFont start:bold length:(i - bold) attributes:attributes];
                        italics = i;
                    } else {
                        [self setFont:boldFont start:bold length:(i - bold) attributes:attributes];
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
                            [self setFont:boldFont start:bold length:(italics - bold) attributes:attributes];
                        }
                        [self setFont:boldItalicFont start:italics length:(i - italics) attributes:attributes];
                        bold = i;
                    } else {
                        [self setFont:italicFont start:italics length:(i - italics) attributes:attributes];
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
                     NSUnderlineStyleAttributeName:@1,
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
                         NSForegroundColorAttributeName:fgColor,
                         @"start":@(fg),
                         @"length":@(i - fg)
                         }];
                    fg = -1;
                }
                if(bg != -1) {
                    if(bgColor)
                        [attributes addObject:@{
                         NSBackgroundColorAttributeName:bgColor,
                         @"start":@(bg),
                         @"length":@(i - bg)
                         }];
                    bg = -1;
                }
                BOOL rgb = [text characterAtIndex:i] == COLOR_RGB;
                int count = 0;
                int fg_color = -1;
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
                            fg_color = [[text substringWithRange:NSMakeRange(i, count)] intValue];
                            if(fg_color > 15) {
                                count--;
                                fg_color /= 10;
                            }
                        } else {
                            fgColor = [UIColor colorFromHexString:[text substringWithRange:NSMakeRange(i, count)]];
                            fg_color = -1;
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
                            bgColor = [UIColor mIRCColor:color background:YES];
                        } else {
                            bgColor = [UIColor colorFromHexString:[text substringWithRange:NSMakeRange(i, count)]];
                        }
                        [text deleteCharactersInRange:NSMakeRange(i,count)];
                        bg = i;
                    } else {
                        [text insertString:@"," atIndex:i];
                    }
                }
                if(fg_color != -1)
                    fgColor = [UIColor mIRCColor:fg_color background:bgColor != nil];
                i--;
                continue;
            case CLEAR:
                if(fg != -1) {
                    [attributes addObject:@{
                     NSForegroundColorAttributeName:fgColor,
                     @"start":@(fg),
                     @"length":@(i - fg)
                     }];
                    fg = -1;
                }
                if(bg != -1) {
                    [attributes addObject:@{
                     NSBackgroundColorAttributeName:bgColor,
                     @"start":@(bg),
                     @"length":@(i - bg)
                     }];
                    bg = -1;
                }
                if(bold != -1 && italics != -1) {
                    if(bold < italics) {
                        [self setFont:boldFont start:bold length:(italics - bold) attributes:attributes];
                        [self setFont:boldItalicFont start:italics length:(i - italics) attributes:attributes];
                    } else {
                        [self setFont:italicFont start:italics length:(bold - italics) attributes:attributes];
                        [self setFont:boldItalicFont start:bold length:(i - bold) attributes:attributes];
                    }
                } else if(bold != -1) {
                    [self setFont:boldFont start:bold length:(i - bold) attributes:attributes];
                } else if(italics != -1) {
                    [self setFont:italicFont start:italics length:(i - italics) attributes:attributes];
                } else if(underline != -1) {
                    [attributes addObject:@{
                     NSUnderlineStyleAttributeName:@1,
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
    [output addAttributes:@{NSFontAttributeName:font} range:NSMakeRange(0, text.length)];
    [output addAttributes:@{(NSString *)NSForegroundColorAttributeName:color} range:NSMakeRange(0, text.length)];

    for(NSNumber *i in arrowIndex) {
        [output addAttributes:@{NSFontAttributeName:arrowFont} range:NSMakeRange([i intValue], 2)];
    }
    
    NSMutableParagraphStyle *paragraphStyle = [[NSMutableParagraphStyle alloc] init];
    if(__compact)
        paragraphStyle.lineSpacing = 0;
    else
        paragraphStyle.lineSpacing = MESSAGE_LINE_SPACING;
    paragraphStyle.lineBreakMode = NSLineBreakByWordWrapping;
    [output addAttribute:(NSString*)NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [output length])];
    
    for(NSDictionary *dict in attributes) {
        [output addAttributes:dict range:NSMakeRange([[dict objectForKey:@"start"] intValue], [[dict objectForKey:@"length"] intValue])];
    }
    
    NSRange r = NSMakeRange(0, text.length);
    do {
        r = [text rangeOfString:@"comic sans" options:NSCaseInsensitiveSearch range:r];
        if(r.location != NSNotFound) {
            [output addAttributes:@{NSFontAttributeName:chalkboardFont} range:r];
            r.location++;
            r.length = text.length - r.location;
        }
    } while(r.location != NSNotFound);
    
    r = NSMakeRange(0, text.length);
    do {
        r = [text rangeOfString:@"marker felt" options:NSCaseInsensitiveSearch range:r];
        if(r.location != NSNotFound) {
            [output addAttributes:@{NSFontAttributeName:markerFont} range:r];
            r.location++;
            r.length = text.length - r.location;
        }
    } while(r.location != NSNotFound);
    
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
        NSPredicate *ipAddress = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"[0-9\\.]+"];

        for(NSTextCheckingResult *result in results) {
            BOOL overlap = NO;
            for(NSTextCheckingResult *match in matches) {
                if(result.range.location >= match.range.location && result.range.location <= match.range.location + match.range.length) {
                    overlap = YES;
                    break;
                }
            }
            if(!overlap) {
                NSRange range = result.range;
                if(range.location + range.length < output.length && [[output string] characterAtIndex:range.location + range.length - 1] != '/' && [[output string] characterAtIndex:range.location + range.length] == '/')
                    range.length++;
                NSString *url = [[output string] substringWithRange:result.range];
                if([self unbalanced:url] || [url hasSuffix:@"."] || [url hasSuffix:@"?"] || [url hasSuffix:@"!"] || [url hasSuffix:@","]) {
                    url = [url substringToIndex:url.length - 1];
                    range.length--;
                }

                NSString *scheme = nil;
                NSString *credentials = @"";
                NSString *hostname = @"";
                NSString *rest = @"";
                if([url rangeOfString:@"://"].location != NSNotFound)
                    scheme = [[url componentsSeparatedByString:@"://"] objectAtIndex:0];
                NSInteger start = (scheme.length?(scheme.length + 3):0);
                
                for(NSInteger i = start; i < url.length; i++) {
                    char c = [url characterAtIndex:i];
                    if(c == ':') { //Search for @ credentials
                        for(NSInteger j = i; j < url.length; j++) {
                            char c = [url characterAtIndex:j];
                            if(c == '@') {
                                j++;
                                credentials = [url substringWithRange:NSMakeRange(start, j - start)];
                                i = j;
                                start += credentials.length;
                                break;
                            } else if(c == '/') {
                                break;
                            }
                        }
                        if(credentials.length)
                            continue;
                    }
                    if(c == ':' || c == '/' || i == url.length - 1) {
                        if(i < url.length - 1) {
                            hostname = [NSURL IDNEncodedHostname:[url substringWithRange:NSMakeRange(start, i - start)]];
                            rest = [url substringFromIndex:i];
                        } else {
                            hostname = [NSURL IDNEncodedHostname:[url substringFromIndex:start]];
                        }
                        break;
                    }
                }
                
                if(!scheme) {
                    if([url hasPrefix:@"irc."])
                        scheme = @"irc";
                    else
                        scheme = @"http";
                }
                
                url = [NSString stringWithFormat:@"%@://%@%@%@", scheme, credentials, hostname, rest];
                
                if([ipAddress evaluateWithObject:url]) {
                    continue;
                }
                
                CFStringRef safe_escaped = CFURLCreateStringByAddingPercentEscapes(NULL, (CFStringRef)url, (CFStringRef)@"%#/?.;+", (CFStringRef)@"^", kCFStringEncodingUTF8);

                url = [NSString stringWithString:(__bridge_transfer NSString *)safe_escaped];
                
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
    
    if(largeEmoji) {
        NSUInteger start = 0;
        if(![self emojiOnly:text]) {
            for(; start < text.length; start++)
                if([self emojiOnly:[text substringFromIndex:start]])
                    break;
        }
        
        [output addAttributes:@{NSFontAttributeName:largeEmojiFont} range:NSMakeRange(start, text.length - start)];
    }
    return output;
}
@end

@implementation NSString (ColorFormatter)
-(NSString *)stripIRCFormatting {
    return [[ColorFormatter format:self defaultColor:[UIColor blackColor] mono:NO linkify:NO server:nil links:nil] string];
}
@end
