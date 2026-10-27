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
#import "LinkTextView.h"
#import "UIColor+IRCCloud.h"
#import "NSURL+IDN.h"
#import "NetworkConnection.h"

id Courier = NULL, CourierBold, CourierOblique,CourierBoldOblique;
id Helvetica, HelveticaBold, HelveticaOblique,HelveticaBoldOblique;
id arrowFont, chalkboardFont, markerFont, awesomeFont, largeEmojiFont, replyThreadFont;
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
    timestampFont = monoTimestampFont = awesomeFont = replyThreadFont = NULL;
}

+(UIFont *)timestampFont {
    @synchronized (self) {
        if(!timestampFont) {
            timestampFont = [UIFont systemFontOfSize:FONT_SIZE - 2];
        }
        return timestampFont;
    }
}

+(UIFont *)monoTimestampFont {
    @synchronized (self) {
        if(!monoTimestampFont) {
            monoTimestampFont = [UIFont fontWithName:@"Courier" size:FONT_SIZE - 2];
        }
        return monoTimestampFont;
    }
}

+(UIFont *)awesomeFont {
    @synchronized (self) {
        if(!awesomeFont) {
            awesomeFont = [UIFont fontWithName:@"FontAwesome" size:FONT_SIZE];
        }
        return awesomeFont;
    }
}

+(UIFont *)replyThreadFont {
    @synchronized (self) {
        if(!replyThreadFont) {
            replyThreadFont = [UIFont fontWithName:@"FontAwesome" size:12];
        }
        return replyThreadFont;
    }
}

+(UIFont *)messageFont:(BOOL)mono {
    return mono?Courier:Helvetica;
}

+(NSRegularExpression *)emoji {
    @synchronized (self) {
        if(!emojiMap)
            emojiMap = @{
                @"umbrella_with_rain_drops":@"☔",
                @"coffee":@"☕",
                @"aries":@"♈",
                @"taurus":@"♉",
                @"sagittarius":@"♐",
                @"capricorn":@"♑",
                @"aquarius":@"♒",
                @"pisces":@"♓",
                @"anchor":@"⚓",
                @"white_check_mark":@"✅",
                @"sparkles":@"✨",
                @"question":@"❓",
                @"grey_question":@"❔",
                @"grey_exclamation":@"❕",
                @"exclamation":@"❗",
                @"heavy_exclamation_mark":@"❗",
                @"heavy_plus_sign":@"➕",
                @"heavy_minus_sign":@"➖",
                @"heavy_division_sign":@"➗",
                @"hash":@"#️⃣",
                @"keycap_star":@"*️⃣",
                @"zero":@"0️⃣",
                @"one":@"1️⃣",
                @"two":@"2️⃣",
                @"three":@"3️⃣",
                @"four":@"4️⃣",
                @"five":@"5️⃣",
                @"six":@"6️⃣",
                @"seven":@"7️⃣",
                @"eight":@"8️⃣",
                @"nine":@"9️⃣",
                @"copyright":@"©️",
                @"registered":@"®️",
                @"mahjong":@"🀄",
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
                @"cn":@"🇨🇳",
                @"flag-cn":@"🇨🇳",
                @"flag-co":@"🇨🇴",
                @"flag-cp":@"🇨🇵",
                @"flag-sark":@"🇨🇶",
                @"flag-cr":@"🇨🇷",
                @"flag-cu":@"🇨🇺",
                @"flag-cv":@"🇨🇻",
                @"flag-cw":@"🇨🇼",
                @"flag-cx":@"🇨🇽",
                @"flag-cy":@"🇨🇾",
                @"flag-cz":@"🇨🇿",
                @"de":@"🇩🇪",
                @"flag-de":@"🇩🇪",
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
                @"es":@"🇪🇸",
                @"flag-es":@"🇪🇸",
                @"flag-et":@"🇪🇹",
                @"flag-eu":@"🇪🇺",
                @"flag-fi":@"🇫🇮",
                @"flag-fj":@"🇫🇯",
                @"flag-fk":@"🇫🇰",
                @"flag-fm":@"🇫🇲",
                @"flag-fo":@"🇫🇴",
                @"fr":@"🇫🇷",
                @"flag-fr":@"🇫🇷",
                @"flag-ga":@"🇬🇦",
                @"gb":@"🇬🇧",
                @"uk":@"🇬🇧",
                @"flag-gb":@"🇬🇧",
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
                @"it":@"🇮🇹",
                @"flag-it":@"🇮🇹",
                @"flag-je":@"🇯🇪",
                @"flag-jm":@"🇯🇲",
                @"flag-jo":@"🇯🇴",
                @"jp":@"🇯🇵",
                @"flag-jp":@"🇯🇵",
                @"flag-ke":@"🇰🇪",
                @"flag-kg":@"🇰🇬",
                @"flag-kh":@"🇰🇭",
                @"flag-ki":@"🇰🇮",
                @"flag-km":@"🇰🇲",
                @"flag-kn":@"🇰🇳",
                @"flag-kp":@"🇰🇵",
                @"kr":@"🇰🇷",
                @"flag-kr":@"🇰🇷",
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
                @"ru":@"🇷🇺",
                @"flag-ru":@"🇷🇺",
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
                @"flag-un":@"🇺🇳",
                @"us":@"🇺🇸",
                @"flag-us":@"🇺🇸",
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
                @"koko":@"🈁",
                @"sa":@"🈂️",
                @"u7121":@"🈚",
                @"u6307":@"🈯",
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
                @"thermometer":@"🌡️",
                @"mostly_sunny":@"🌤️",
                @"sun_small_cloud":@"🌤️",
                @"barely_sunny":@"🌥️",
                @"sun_behind_cloud":@"🌥️",
                @"partly_sunny_rain":@"🌦️",
                @"sun_behind_rain_cloud":@"🌦️",
                @"rain_cloud":@"🌧️",
                @"snow_cloud":@"🌨️",
                @"lightning":@"🌩️",
                @"lightning_cloud":@"🌩️",
                @"tornado":@"🌪️",
                @"tornado_cloud":@"🌪️",
                @"fog":@"🌫️",
                @"wind_blowing_face":@"🌬️",
                @"hotdog":@"🌭",
                @"taco":@"🌮",
                @"burrito":@"🌯",
                @"chestnut":@"🌰",
                @"seedling":@"🌱",
                @"evergreen_tree":@"🌲",
                @"deciduous_tree":@"🌳",
                @"palm_tree":@"🌴",
                @"cactus":@"🌵",
                @"hot_pepper":@"🌶️",
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
                @"brown_mushroom":@"🍄‍🟫",
                @"mushroom":@"🍄",
                @"tomato":@"🍅",
                @"eggplant":@"🍆",
                @"grapes":@"🍇",
                @"melon":@"🍈",
                @"watermelon":@"🍉",
                @"tangerine":@"🍊",
                @"lime":@"🍋‍🟩",
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
                @"fried_egg":@"🍳",
                @"cooking":@"🍳",
                @"fork_and_knife":@"🍴",
                @"tea":@"🍵",
                @"sake":@"🍶",
                @"wine_glass":@"🍷",
                @"cocktail":@"🍸",
                @"tropical_drink":@"🍹",
                @"beer":@"🍺",
                @"beers":@"🍻",
                @"baby_bottle":@"🍼",
                @"knife_fork_plate":@"🍽️",
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
                @"medal":@"🎖️",
                @"reminder_ribbon":@"🎗️",
                @"studio_microphone":@"🎙️",
                @"level_slider":@"🎚️",
                @"control_knobs":@"🎛️",
                @"film_frames":@"🎞️",
                @"admission_tickets":@"🎟️",
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
                @"woman-running":@"🏃‍♀️",
                @"woman_running_facing_right":@"🏃‍♀️‍➡️",
                @"man-running":@"🏃‍♂️",
                @"man_running_facing_right":@"🏃‍♂️‍➡️",
                @"person_running_facing_right":@"🏃‍➡️",
                @"runner":@"🏃",
                @"running":@"🏃",
                @"woman-surfing":@"🏄‍♀️",
                @"man-surfing":@"🏄‍♂️",
                @"surfer":@"🏄",
                @"sports_medal":@"🏅",
                @"trophy":@"🏆",
                @"horse_racing":@"🏇",
                @"football":@"🏈",
                @"rugby_football":@"🏉",
                @"woman-swimming":@"🏊‍♀️",
                @"man-swimming":@"🏊‍♂️",
                @"swimmer":@"🏊",
                @"woman-lifting-weights":@"🏋️‍♀️",
                @"man-lifting-weights":@"🏋️‍♂️",
                @"weight_lifter":@"🏋️",
                @"woman-golfing":@"🏌️‍♀️",
                @"man-golfing":@"🏌️‍♂️",
                @"golfer":@"🏌️",
                @"racing_motorcycle":@"🏍️",
                @"racing_car":@"🏎️",
                @"cricket_bat_and_ball":@"🏏",
                @"volleyball":@"🏐",
                @"field_hockey_stick_and_ball":@"🏑",
                @"ice_hockey_stick_and_puck":@"🏒",
                @"table_tennis_paddle_and_ball":@"🏓",
                @"snow_capped_mountain":@"🏔️",
                @"camping":@"🏕️",
                @"beach_with_umbrella":@"🏖️",
                @"building_construction":@"🏗️",
                @"house_buildings":@"🏘️",
                @"cityscape":@"🏙️",
                @"derelict_house_building":@"🏚️",
                @"classical_building":@"🏛️",
                @"desert":@"🏜️",
                @"desert_island":@"🏝️",
                @"national_park":@"🏞️",
                @"stadium":@"🏟️",
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
                @"rainbow-flag":@"🏳️‍🌈",
                @"transgender_flag":@"🏳️‍⚧️",
                @"waving_white_flag":@"🏳️",
                @"pirate_flag":@"🏴‍☠️",
                @"flag-england":@"🏴󠁧󠁢󠁥󠁮󠁧󠁿",
                @"flag-scotland":@"🏴󠁧󠁢󠁳󠁣󠁴󠁿",
                @"flag-wales":@"🏴󠁧󠁢󠁷󠁬󠁳󠁿",
                @"waving_black_flag":@"🏴",
                @"rosette":@"🏵️",
                @"label":@"🏷️",
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
                @"black_cat":@"🐈‍⬛",
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
                @"service_dog":@"🐕‍🦺",
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
                @"ladybug":@"🐞",
                @"lady_beetle":@"🐞",
                @"fish":@"🐟",
                @"tropical_fish":@"🐠",
                @"blowfish":@"🐡",
                @"turtle":@"🐢",
                @"hatching_chick":@"🐣",
                @"baby_chick":@"🐤",
                @"hatched_chick":@"🐥",
                @"phoenix":@"🐦‍🔥",
                @"black_bird":@"🐦‍⬛",
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
                @"polar_bear":@"🐻‍❄️",
                @"bear":@"🐻",
                @"panda_face":@"🐼",
                @"pig_nose":@"🐽",
                @"feet":@"🐾",
                @"paw_prints":@"🐾",
                @"chipmunk":@"🐿️",
                @"eyes":@"👀",
                @"eye-in-speech-bubble":@"👁️‍🗨️",
                @"eye":@"👁️",
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
                @"male-farmer":@"👨‍🌾",
                @"male-cook":@"👨‍🍳",
                @"man_feeding_baby":@"👨‍🍼",
                @"male-student":@"👨‍🎓",
                @"male-singer":@"👨‍🎤",
                @"male-artist":@"👨‍🎨",
                @"male-teacher":@"👨‍🏫",
                @"male-factory-worker":@"👨‍🏭",
                @"man-boy-boy":@"👨‍👦‍👦",
                @"man-boy":@"👨‍👦",
                @"man-girl-boy":@"👨‍👧‍👦",
                @"man-girl-girl":@"👨‍👧‍👧",
                @"man-girl":@"👨‍👧",
                @"man-man-boy":@"👨‍👨‍👦",
                @"man-man-boy-boy":@"👨‍👨‍👦‍👦",
                @"man-man-girl":@"👨‍👨‍👧",
                @"man-man-girl-boy":@"👨‍👨‍👧‍👦",
                @"man-man-girl-girl":@"👨‍👨‍👧‍👧",
                @"man-woman-boy":@"👨‍👩‍👦",
                @"man-woman-boy-boy":@"👨‍👩‍👦‍👦",
                @"man-woman-girl":@"👨‍👩‍👧",
                @"man-woman-girl-boy":@"👨‍👩‍👧‍👦",
                @"man-woman-girl-girl":@"👨‍👩‍👧‍👧",
                @"male-technologist":@"👨‍💻",
                @"male-office-worker":@"👨‍💼",
                @"male-mechanic":@"👨‍🔧",
                @"male-scientist":@"👨‍🔬",
                @"male-astronaut":@"👨‍🚀",
                @"male-firefighter":@"👨‍🚒",
                @"man_with_white_cane_facing_right":@"👨‍🦯‍➡️",
                @"man_with_probing_cane":@"👨‍🦯",
                @"red_haired_man":@"👨‍🦰",
                @"curly_haired_man":@"👨‍🦱",
                @"bald_man":@"👨‍🦲",
                @"white_haired_man":@"👨‍🦳",
                @"man_in_motorized_wheelchair_facing_right":@"👨‍🦼‍➡️",
                @"man_in_motorized_wheelchair":@"👨‍🦼",
                @"man_in_manual_wheelchair_facing_right":@"👨‍🦽‍➡️",
                @"man_in_manual_wheelchair":@"👨‍🦽",
                @"male-doctor":@"👨‍⚕️",
                @"male-judge":@"👨‍⚖️",
                @"male-pilot":@"👨‍✈️",
                @"man-heart-man":@"👨‍❤️‍👨",
                @"man-kiss-man":@"👨‍❤️‍💋‍👨",
                @"man":@"👨",
                @"female-farmer":@"👩‍🌾",
                @"female-cook":@"👩‍🍳",
                @"woman_feeding_baby":@"👩‍🍼",
                @"female-student":@"👩‍🎓",
                @"female-singer":@"👩‍🎤",
                @"female-artist":@"👩‍🎨",
                @"female-teacher":@"👩‍🏫",
                @"female-factory-worker":@"👩‍🏭",
                @"woman-boy-boy":@"👩‍👦‍👦",
                @"woman-boy":@"👩‍👦",
                @"woman-girl-boy":@"👩‍👧‍👦",
                @"woman-girl-girl":@"👩‍👧‍👧",
                @"woman-girl":@"👩‍👧",
                @"woman-woman-boy":@"👩‍👩‍👦",
                @"woman-woman-boy-boy":@"👩‍👩‍👦‍👦",
                @"woman-woman-girl":@"👩‍👩‍👧",
                @"woman-woman-girl-boy":@"👩‍👩‍👧‍👦",
                @"woman-woman-girl-girl":@"👩‍👩‍👧‍👧",
                @"female-technologist":@"👩‍💻",
                @"female-office-worker":@"👩‍💼",
                @"female-mechanic":@"👩‍🔧",
                @"female-scientist":@"👩‍🔬",
                @"female-astronaut":@"👩‍🚀",
                @"female-firefighter":@"👩‍🚒",
                @"woman_with_white_cane_facing_right":@"👩‍🦯‍➡️",
                @"woman_with_probing_cane":@"👩‍🦯",
                @"red_haired_woman":@"👩‍🦰",
                @"curly_haired_woman":@"👩‍🦱",
                @"bald_woman":@"👩‍🦲",
                @"white_haired_woman":@"👩‍🦳",
                @"woman_in_motorized_wheelchair_facing_right":@"👩‍🦼‍➡️",
                @"woman_in_motorized_wheelchair":@"👩‍🦼",
                @"woman_in_manual_wheelchair_facing_right":@"👩‍🦽‍➡️",
                @"woman_in_manual_wheelchair":@"👩‍🦽",
                @"female-doctor":@"👩‍⚕️",
                @"female-judge":@"👩‍⚖️",
                @"female-pilot":@"👩‍✈️",
                @"woman-heart-man":@"👩‍❤️‍👨",
                @"woman-heart-woman":@"👩‍❤️‍👩",
                @"woman-kiss-man":@"👩‍❤️‍💋‍👨",
                @"woman-kiss-woman":@"👩‍❤️‍💋‍👩",
                @"woman":@"👩",
                @"family":@"👪",
                @"man_and_woman_holding_hands":@"👫",
                @"woman_and_man_holding_hands":@"👫",
                @"couple":@"👫",
                @"two_men_holding_hands":@"👬",
                @"men_holding_hands":@"👬",
                @"two_women_holding_hands":@"👭",
                @"women_holding_hands":@"👭",
                @"female-police-officer":@"👮‍♀️",
                @"male-police-officer":@"👮‍♂️",
                @"cop":@"👮",
                @"women-with-bunny-ears-partying":@"👯‍♀️",
                @"woman-with-bunny-ears-partying":@"👯‍♀️",
                @"men-with-bunny-ears-partying":@"👯‍♂️",
                @"man-with-bunny-ears-partying":@"👯‍♂️",
                @"dancers":@"👯",
                @"woman_with_veil":@"👰‍♀️",
                @"man_with_veil":@"👰‍♂️",
                @"bride_with_veil":@"👰",
                @"blond-haired-woman":@"👱‍♀️",
                @"blond-haired-man":@"👱‍♂️",
                @"person_with_blond_hair":@"👱",
                @"man_with_gua_pi_mao":@"👲",
                @"woman-wearing-turban":@"👳‍♀️",
                @"man-wearing-turban":@"👳‍♂️",
                @"man_with_turban":@"👳",
                @"older_man":@"👴",
                @"older_woman":@"👵",
                @"baby":@"👶",
                @"female-construction-worker":@"👷‍♀️",
                @"male-construction-worker":@"👷‍♂️",
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
                @"woman-tipping-hand":@"💁‍♀️",
                @"man-tipping-hand":@"💁‍♂️",
                @"information_desk_person":@"💁",
                @"female-guard":@"💂‍♀️",
                @"male-guard":@"💂‍♂️",
                @"guardsman":@"💂",
                @"dancer":@"💃",
                @"lipstick":@"💄",
                @"nail_care":@"💅",
                @"woman-getting-massage":@"💆‍♀️",
                @"man-getting-massage":@"💆‍♂️",
                @"massage":@"💆",
                @"woman-getting-haircut":@"💇‍♀️",
                @"man-getting-haircut":@"💇‍♂️",
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
                @"pile_of_poo":@"💩",
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
                @"film_projector":@"📽️",
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
                @"om_symbol":@"🕉️",
                @"dove_of_peace":@"🕊️",
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
                @"candle":@"🕯️",
                @"mantelpiece_clock":@"🕰️",
                @"hole":@"🕳️",
                @"man_in_business_suit_levitating":@"🕴️",
                @"female-detective":@"🕵️‍♀️",
                @"male-detective":@"🕵️‍♂️",
                @"sleuth_or_spy":@"🕵️",
                @"dark_sunglasses":@"🕶️",
                @"spider":@"🕷️",
                @"spider_web":@"🕸️",
                @"joystick":@"🕹️",
                @"man_dancing":@"🕺",
                @"linked_paperclips":@"🖇️",
                @"lower_left_ballpoint_pen":@"🖊️",
                @"lower_left_fountain_pen":@"🖋️",
                @"lower_left_paintbrush":@"🖌️",
                @"lower_left_crayon":@"🖍️",
                @"raised_hand_with_fingers_splayed":@"🖐️",
                @"middle_finger":@"🖕",
                @"reversed_hand_with_middle_finger_extended":@"🖕",
                @"spock-hand":@"🖖",
                @"black_heart":@"🖤",
                @"desktop_computer":@"🖥️",
                @"printer":@"🖨️",
                @"three_button_mouse":@"🖱️",
                @"trackball":@"🖲️",
                @"frame_with_picture":@"🖼️",
                @"card_index_dividers":@"🗂️",
                @"card_file_box":@"🗃️",
                @"file_cabinet":@"🗄️",
                @"wastebasket":@"🗑️",
                @"spiral_note_pad":@"🗒️",
                @"spiral_calendar_pad":@"🗓️",
                @"compression":@"🗜️",
                @"old_key":@"🗝️",
                @"rolled_up_newspaper":@"🗞️",
                @"dagger_knife":@"🗡️",
                @"speaking_head_in_silhouette":@"🗣️",
                @"left_speech_bubble":@"🗨️",
                @"right_anger_bubble":@"🗯️",
                @"ballot_box_with_ballot":@"🗳️",
                @"world_map":@"🗺️",
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
                @"face_exhaling":@"😮‍💨",
                @"open_mouth":@"😮",
                @"hushed":@"😯",
                @"cold_sweat":@"😰",
                @"scream":@"😱",
                @"astonished":@"😲",
                @"flushed":@"😳",
                @"sleeping":@"😴",
                @"face_with_spiral_eyes":@"😵‍💫",
                @"dizzy_face":@"😵",
                @"face_in_clouds":@"😶‍🌫️",
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
                @"head_shaking_horizontally":@"🙂‍↔️",
                @"head_shaking_vertically":@"🙂‍↕️",
                @"slightly_smiling_face":@"🙂",
                @"upside_down_face":@"🙃",
                @"face_with_rolling_eyes":@"🙄",
                @"woman-gesturing-no":@"🙅‍♀️",
                @"man-gesturing-no":@"🙅‍♂️",
                @"no_good":@"🙅",
                @"woman-gesturing-ok":@"🙆‍♀️",
                @"man-gesturing-ok":@"🙆‍♂️",
                @"ok_woman":@"🙆",
                @"woman-bowing":@"🙇‍♀️",
                @"man-bowing":@"🙇‍♂️",
                @"bow":@"🙇",
                @"see_no_evil":@"🙈",
                @"hear_no_evil":@"🙉",
                @"speak_no_evil":@"🙊",
                @"woman-raising-hand":@"🙋‍♀️",
                @"man-raising-hand":@"🙋‍♂️",
                @"raising_hand":@"🙋",
                @"raised_hands":@"🙌",
                @"woman-frowning":@"🙍‍♀️",
                @"man-frowning":@"🙍‍♂️",
                @"person_frowning":@"🙍",
                @"woman-pouting":@"🙎‍♀️",
                @"man-pouting":@"🙎‍♂️",
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
                @"woman-rowing-boat":@"🚣‍♀️",
                @"man-rowing-boat":@"🚣‍♂️",
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
                @"woman-biking":@"🚴‍♀️",
                @"man-biking":@"🚴‍♂️",
                @"bicyclist":@"🚴",
                @"woman-mountain-biking":@"🚵‍♀️",
                @"man-mountain-biking":@"🚵‍♂️",
                @"mountain_bicyclist":@"🚵",
                @"woman-walking":@"🚶‍♀️",
                @"woman_walking_facing_right":@"🚶‍♀️‍➡️",
                @"man-walking":@"🚶‍♂️",
                @"man_walking_facing_right":@"🚶‍♂️‍➡️",
                @"person_walking_facing_right":@"🚶‍➡️",
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
                @"couch_and_lamp":@"🛋️",
                @"sleeping_accommodation":@"🛌",
                @"shopping_bags":@"🛍️",
                @"bellhop_bell":@"🛎️",
                @"bed":@"🛏️",
                @"place_of_worship":@"🛐",
                @"octagonal_sign":@"🛑",
                @"shopping_trolley":@"🛒",
                @"hindu_temple":@"🛕",
                @"hut":@"🛖",
                @"elevator":@"🛗",
                @"landslide":@"🛘",
                @"wireless":@"🛜",
                @"playground_slide":@"🛝",
                @"wheel":@"🛞",
                @"ring_buoy":@"🛟",
                @"hammer_and_wrench":@"🛠️",
                @"shield":@"🛡️",
                @"oil_drum":@"🛢️",
                @"motorway":@"🛣️",
                @"railway_track":@"🛤️",
                @"motor_boat":@"🛥️",
                @"small_airplane":@"🛩️",
                @"airplane_departure":@"🛫",
                @"airplane_arriving":@"🛬",
                @"satellite":@"🛰️",
                @"passenger_ship":@"🛳️",
                @"scooter":@"🛴",
                @"motor_scooter":@"🛵",
                @"canoe":@"🛶",
                @"sled":@"🛷",
                @"flying_saucer":@"🛸",
                @"skateboard":@"🛹",
                @"auto_rickshaw":@"🛺",
                @"pickup_truck":@"🛻",
                @"roller_skate":@"🛼",
                @"large_orange_circle":@"🟠",
                @"large_yellow_circle":@"🟡",
                @"large_green_circle":@"🟢",
                @"large_purple_circle":@"🟣",
                @"large_brown_circle":@"🟤",
                @"large_red_square":@"🟥",
                @"large_blue_square":@"🟦",
                @"large_orange_square":@"🟧",
                @"large_yellow_square":@"🟨",
                @"large_green_square":@"🟩",
                @"large_purple_square":@"🟪",
                @"large_brown_square":@"🟫",
                @"heavy_equals_sign":@"🟰",
                @"pinched_fingers":@"🤌",
                @"white_heart":@"🤍",
                @"brown_heart":@"🤎",
                @"pinching_hand":@"🤏",
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
                @"call_me_hand":@"🤙",
                @"raised_back_of_hand":@"🤚",
                @"left-facing_fist":@"🤛",
                @"right-facing_fist":@"🤜",
                @"handshake":@"🤝",
                @"crossed_fingers":@"🤞",
                @"hand_with_index_and_middle_fingers_crossed":@"🤞",
                @"i_love_you_hand_sign":@"🤟",
                @"face_with_cowboy_hat":@"🤠",
                @"clown_face":@"🤡",
                @"nauseated_face":@"🤢",
                @"rolling_on_the_floor_laughing":@"🤣",
                @"drooling_face":@"🤤",
                @"lying_face":@"🤥",
                @"woman-facepalming":@"🤦‍♀️",
                @"man-facepalming":@"🤦‍♂️",
                @"face_palm":@"🤦",
                @"sneezing_face":@"🤧",
                @"face_with_raised_eyebrow":@"🤨",
                @"face_with_one_eyebrow_raised":@"🤨",
                @"star-struck":@"🤩",
                @"grinning_face_with_star_eyes":@"🤩",
                @"zany_face":@"🤪",
                @"grinning_face_with_one_large_and_one_small_eye":@"🤪",
                @"shushing_face":@"🤫",
                @"face_with_finger_covering_closed_lips":@"🤫",
                @"face_with_symbols_on_mouth":@"🤬",
                @"serious_face_with_symbols_covering_mouth":@"🤬",
                @"face_with_hand_over_mouth":@"🤭",
                @"smiling_face_with_smiling_eyes_and_hand_covering_mouth":@"🤭",
                @"face_vomiting":@"🤮",
                @"face_with_open_mouth_vomiting":@"🤮",
                @"exploding_head":@"🤯",
                @"shocked_face_with_exploding_head":@"🤯",
                @"pregnant_woman":@"🤰",
                @"breast-feeding":@"🤱",
                @"palms_up_together":@"🤲",
                @"selfie":@"🤳",
                @"prince":@"🤴",
                @"woman_in_tuxedo":@"🤵‍♀️",
                @"man_in_tuxedo":@"🤵‍♂️",
                @"person_in_tuxedo":@"🤵",
                @"mrs_claus":@"🤶",
                @"mother_christmas":@"🤶",
                @"woman-shrugging":@"🤷‍♀️",
                @"man-shrugging":@"🤷‍♂️",
                @"shrug":@"🤷",
                @"woman-cartwheeling":@"🤸‍♀️",
                @"man-cartwheeling":@"🤸‍♂️",
                @"person_doing_cartwheel":@"🤸",
                @"woman-juggling":@"🤹‍♀️",
                @"man-juggling":@"🤹‍♂️",
                @"juggling":@"🤹",
                @"fencer":@"🤺",
                @"woman-wrestling":@"🤼‍♀️",
                @"man-wrestling":@"🤼‍♂️",
                @"wrestlers":@"🤼",
                @"woman-playing-water-polo":@"🤽‍♀️",
                @"man-playing-water-polo":@"🤽‍♂️",
                @"water_polo":@"🤽",
                @"woman-playing-handball":@"🤾‍♀️",
                @"man-playing-handball":@"🤾‍♂️",
                @"handball":@"🤾",
                @"diving_mask":@"🤿",
                @"wilted_flower":@"🥀",
                @"drum_with_drumsticks":@"🥁",
                @"clinking_glasses":@"🥂",
                @"tumbler_glass":@"🥃",
                @"spoon":@"🥄",
                @"goal_net":@"🥅",
                @"first_place_medal":@"🥇",
                @"second_place_medal":@"🥈",
                @"third_place_medal":@"🥉",
                @"boxing_glove":@"🥊",
                @"martial_arts_uniform":@"🥋",
                @"curling_stone":@"🥌",
                @"lacrosse":@"🥍",
                @"softball":@"🥎",
                @"flying_disc":@"🥏",
                @"croissant":@"🥐",
                @"avocado":@"🥑",
                @"cucumber":@"🥒",
                @"bacon":@"🥓",
                @"potato":@"🥔",
                @"carrot":@"🥕",
                @"baguette_bread":@"🥖",
                @"green_salad":@"🥗",
                @"shallow_pan_of_food":@"🥘",
                @"stuffed_flatbread":@"🥙",
                @"egg":@"🥚",
                @"glass_of_milk":@"🥛",
                @"peanuts":@"🥜",
                @"kiwifruit":@"🥝",
                @"pancakes":@"🥞",
                @"dumpling":@"🥟",
                @"fortune_cookie":@"🥠",
                @"takeout_box":@"🥡",
                @"chopsticks":@"🥢",
                @"bowl_with_spoon":@"🥣",
                @"cup_with_straw":@"🥤",
                @"coconut":@"🥥",
                @"broccoli":@"🥦",
                @"pie":@"🥧",
                @"pretzel":@"🥨",
                @"cut_of_meat":@"🥩",
                @"sandwich":@"🥪",
                @"canned_food":@"🥫",
                @"leafy_green":@"🥬",
                @"mango":@"🥭",
                @"moon_cake":@"🥮",
                @"bagel":@"🥯",
                @"smiling_face_with_3_hearts":@"🥰",
                @"yawning_face":@"🥱",
                @"smiling_face_with_tear":@"🥲",
                @"partying_face":@"🥳",
                @"woozy_face":@"🥴",
                @"hot_face":@"🥵",
                @"cold_face":@"🥶",
                @"ninja":@"🥷",
                @"disguised_face":@"🥸",
                @"face_holding_back_tears":@"🥹",
                @"pleading_face":@"🥺",
                @"sari":@"🥻",
                @"lab_coat":@"🥼",
                @"goggles":@"🥽",
                @"hiking_boot":@"🥾",
                @"womans_flat_shoe":@"🥿",
                @"crab":@"🦀",
                @"lion_face":@"🦁",
                @"scorpion":@"🦂",
                @"turkey":@"🦃",
                @"unicorn_face":@"🦄",
                @"eagle":@"🦅",
                @"duck":@"🦆",
                @"bat":@"🦇",
                @"shark":@"🦈",
                @"owl":@"🦉",
                @"fox_face":@"🦊",
                @"butterfly":@"🦋",
                @"deer":@"🦌",
                @"gorilla":@"🦍",
                @"lizard":@"🦎",
                @"rhinoceros":@"🦏",
                @"shrimp":@"🦐",
                @"squid":@"🦑",
                @"giraffe_face":@"🦒",
                @"zebra_face":@"🦓",
                @"hedgehog":@"🦔",
                @"sauropod":@"🦕",
                @"t-rex":@"🦖",
                @"cricket":@"🦗",
                @"kangaroo":@"🦘",
                @"llama":@"🦙",
                @"peacock":@"🦚",
                @"hippopotamus":@"🦛",
                @"parrot":@"🦜",
                @"raccoon":@"🦝",
                @"lobster":@"🦞",
                @"mosquito":@"🦟",
                @"microbe":@"🦠",
                @"badger":@"🦡",
                @"swan":@"🦢",
                @"mammoth":@"🦣",
                @"dodo":@"🦤",
                @"sloth":@"🦥",
                @"otter":@"🦦",
                @"orangutan":@"🦧",
                @"skunk":@"🦨",
                @"flamingo":@"🦩",
                @"oyster":@"🦪",
                @"beaver":@"🦫",
                @"bison":@"🦬",
                @"seal":@"🦭",
                @"guide_dog":@"🦮",
                @"probing_cane":@"🦯",
                @"bone":@"🦴",
                @"leg":@"🦵",
                @"foot":@"🦶",
                @"tooth":@"🦷",
                @"female_superhero":@"🦸‍♀️",
                @"male_superhero":@"🦸‍♂️",
                @"superhero":@"🦸",
                @"female_supervillain":@"🦹‍♀️",
                @"male_supervillain":@"🦹‍♂️",
                @"supervillain":@"🦹",
                @"safety_vest":@"🦺",
                @"ear_with_hearing_aid":@"🦻",
                @"motorized_wheelchair":@"🦼",
                @"manual_wheelchair":@"🦽",
                @"mechanical_arm":@"🦾",
                @"mechanical_leg":@"🦿",
                @"cheese_wedge":@"🧀",
                @"cupcake":@"🧁",
                @"salt":@"🧂",
                @"beverage_box":@"🧃",
                @"garlic":@"🧄",
                @"onion":@"🧅",
                @"falafel":@"🧆",
                @"waffle":@"🧇",
                @"butter":@"🧈",
                @"mate_drink":@"🧉",
                @"ice_cube":@"🧊",
                @"bubble_tea":@"🧋",
                @"troll":@"🧌",
                @"woman_standing":@"🧍‍♀️",
                @"man_standing":@"🧍‍♂️",
                @"standing_person":@"🧍",
                @"woman_kneeling":@"🧎‍♀️",
                @"woman_kneeling_facing_right":@"🧎‍♀️‍➡️",
                @"man_kneeling":@"🧎‍♂️",
                @"man_kneeling_facing_right":@"🧎‍♂️‍➡️",
                @"person_kneeling_facing_right":@"🧎‍➡️",
                @"kneeling_person":@"🧎",
                @"deaf_woman":@"🧏‍♀️",
                @"deaf_man":@"🧏‍♂️",
                @"deaf_person":@"🧏",
                @"face_with_monocle":@"🧐",
                @"farmer":@"🧑‍🌾",
                @"cook":@"🧑‍🍳",
                @"person_feeding_baby":@"🧑‍🍼",
                @"mx_claus":@"🧑‍🎄",
                @"student":@"🧑‍🎓",
                @"singer":@"🧑‍🎤",
                @"artist":@"🧑‍🎨",
                @"teacher":@"🧑‍🏫",
                @"factory_worker":@"🧑‍🏭",
                @"technologist":@"🧑‍💻",
                @"office_worker":@"🧑‍💼",
                @"mechanic":@"🧑‍🔧",
                @"scientist":@"🧑‍🔬",
                @"astronaut":@"🧑‍🚀",
                @"firefighter":@"🧑‍🚒",
                @"people_holding_hands":@"🧑‍🤝‍🧑",
                @"person_with_white_cane_facing_right":@"🧑‍🦯‍➡️",
                @"person_with_probing_cane":@"🧑‍🦯",
                @"red_haired_person":@"🧑‍🦰",
                @"curly_haired_person":@"🧑‍🦱",
                @"bald_person":@"🧑‍🦲",
                @"white_haired_person":@"🧑‍🦳",
                @"person_in_motorized_wheelchair_facing_right":@"🧑‍🦼‍➡️",
                @"person_in_motorized_wheelchair":@"🧑‍🦼",
                @"person_in_manual_wheelchair_facing_right":@"🧑‍🦽‍➡️",
                @"person_in_manual_wheelchair":@"🧑‍🦽",
                @"family_adult_adult_child":@"🧑‍🧑‍🧒",
                @"family_adult_adult_child_child":@"🧑‍🧑‍🧒‍🧒",
                @"family_adult_child_child":@"🧑‍🧒‍🧒",
                @"family_adult_child":@"🧑‍🧒",
                @"ballet_dancer":@"🧑‍🩰",
                @"health_worker":@"🧑‍⚕️",
                @"judge":@"🧑‍⚖️",
                @"pilot":@"🧑‍✈️",
                @"adult":@"🧑",
                @"child":@"🧒",
                @"older_adult":@"🧓",
                @"woman_with_beard":@"🧔‍♀️",
                @"man_with_beard":@"🧔‍♂️",
                @"bearded_person":@"🧔",
                @"person_with_headscarf":@"🧕",
                @"woman_in_steamy_room":@"🧖‍♀️",
                @"man_in_steamy_room":@"🧖‍♂️",
                @"person_in_steamy_room":@"🧖",
                @"woman_climbing":@"🧗‍♀️",
                @"man_climbing":@"🧗‍♂️",
                @"person_climbing":@"🧗",
                @"woman_in_lotus_position":@"🧘‍♀️",
                @"man_in_lotus_position":@"🧘‍♂️",
                @"person_in_lotus_position":@"🧘",
                @"female_mage":@"🧙‍♀️",
                @"male_mage":@"🧙‍♂️",
                @"mage":@"🧙",
                @"female_fairy":@"🧚‍♀️",
                @"male_fairy":@"🧚‍♂️",
                @"fairy":@"🧚",
                @"female_vampire":@"🧛‍♀️",
                @"male_vampire":@"🧛‍♂️",
                @"vampire":@"🧛",
                @"mermaid":@"🧜‍♀️",
                @"merman":@"🧜‍♂️",
                @"merperson":@"🧜",
                @"female_elf":@"🧝‍♀️",
                @"male_elf":@"🧝‍♂️",
                @"elf":@"🧝",
                @"female_genie":@"🧞‍♀️",
                @"male_genie":@"🧞‍♂️",
                @"genie":@"🧞",
                @"female_zombie":@"🧟‍♀️",
                @"male_zombie":@"🧟‍♂️",
                @"zombie":@"🧟",
                @"brain":@"🧠",
                @"orange_heart":@"🧡",
                @"billed_cap":@"🧢",
                @"scarf":@"🧣",
                @"gloves":@"🧤",
                @"coat":@"🧥",
                @"socks":@"🧦",
                @"red_envelope":@"🧧",
                @"firecracker":@"🧨",
                @"jigsaw":@"🧩",
                @"test_tube":@"🧪",
                @"petri_dish":@"🧫",
                @"dna":@"🧬",
                @"compass":@"🧭",
                @"abacus":@"🧮",
                @"fire_extinguisher":@"🧯",
                @"toolbox":@"🧰",
                @"bricks":@"🧱",
                @"magnet":@"🧲",
                @"luggage":@"🧳",
                @"lotion_bottle":@"🧴",
                @"thread":@"🧵",
                @"yarn":@"🧶",
                @"safety_pin":@"🧷",
                @"teddy_bear":@"🧸",
                @"broom":@"🧹",
                @"basket":@"🧺",
                @"roll_of_paper":@"🧻",
                @"soap":@"🧼",
                @"sponge":@"🧽",
                @"receipt":@"🧾",
                @"nazar_amulet":@"🧿",
                @"ballet_shoes":@"🩰",
                @"one-piece_swimsuit":@"🩱",
                @"briefs":@"🩲",
                @"shorts":@"🩳",
                @"thong_sandal":@"🩴",
                @"light_blue_heart":@"🩵",
                @"grey_heart":@"🩶",
                @"pink_heart":@"🩷",
                @"drop_of_blood":@"🩸",
                @"adhesive_bandage":@"🩹",
                @"stethoscope":@"🩺",
                @"x-ray":@"🩻",
                @"crutch":@"🩼",
                @"yo-yo":@"🪀",
                @"kite":@"🪁",
                @"parachute":@"🪂",
                @"boomerang":@"🪃",
                @"magic_wand":@"🪄",
                @"pinata":@"🪅",
                @"nesting_dolls":@"🪆",
                @"maracas":@"🪇",
                @"flute":@"🪈",
                @"harp":@"🪉",
                @"trombone":@"🪊",
                @"treasure_chest":@"🪎",
                @"shovel":@"🪏",
                @"ringed_planet":@"🪐",
                @"chair":@"🪑",
                @"razor":@"🪒",
                @"axe":@"🪓",
                @"diya_lamp":@"🪔",
                @"banjo":@"🪕",
                @"military_helmet":@"🪖",
                @"accordion":@"🪗",
                @"long_drum":@"🪘",
                @"coin":@"🪙",
                @"carpentry_saw":@"🪚",
                @"screwdriver":@"🪛",
                @"ladder":@"🪜",
                @"hook":@"🪝",
                @"mirror":@"🪞",
                @"window":@"🪟",
                @"plunger":@"🪠",
                @"sewing_needle":@"🪡",
                @"knot":@"🪢",
                @"bucket":@"🪣",
                @"mouse_trap":@"🪤",
                @"toothbrush":@"🪥",
                @"headstone":@"🪦",
                @"placard":@"🪧",
                @"rock":@"🪨",
                @"mirror_ball":@"🪩",
                @"identification_card":@"🪪",
                @"low_battery":@"🪫",
                @"hamsa":@"🪬",
                @"folding_hand_fan":@"🪭",
                @"hair_pick":@"🪮",
                @"khanda":@"🪯",
                @"fly":@"🪰",
                @"worm":@"🪱",
                @"beetle":@"🪲",
                @"cockroach":@"🪳",
                @"potted_plant":@"🪴",
                @"wood":@"🪵",
                @"feather":@"🪶",
                @"lotus":@"🪷",
                @"coral":@"🪸",
                @"empty_nest":@"🪹",
                @"nest_with_eggs":@"🪺",
                @"hyacinth":@"🪻",
                @"jellyfish":@"🪼",
                @"wing":@"🪽",
                @"leafless_tree":@"🪾",
                @"goose":@"🪿",
                @"anatomical_heart":@"🫀",
                @"lungs":@"🫁",
                @"people_hugging":@"🫂",
                @"pregnant_man":@"🫃",
                @"pregnant_person":@"🫄",
                @"person_with_crown":@"🫅",
                @"fingerprint":@"🫆",
                @"hairy_creature":@"🫈",
                @"orca":@"🫍",
                @"moose":@"🫎",
                @"donkey":@"🫏",
                @"blueberries":@"🫐",
                @"bell_pepper":@"🫑",
                @"olive":@"🫒",
                @"flatbread":@"🫓",
                @"tamale":@"🫔",
                @"fondue":@"🫕",
                @"teapot":@"🫖",
                @"pouring_liquid":@"🫗",
                @"beans":@"🫘",
                @"jar":@"🫙",
                @"ginger_root":@"🫚",
                @"pea_pod":@"🫛",
                @"root_vegetable":@"🫜",
                @"splatter":@"🫟",
                @"melting_face":@"🫠",
                @"saluting_face":@"🫡",
                @"face_with_open_eyes_and_hand_over_mouth":@"🫢",
                @"face_with_peeking_eye":@"🫣",
                @"face_with_diagonal_mouth":@"🫤",
                @"dotted_line_face":@"🫥",
                @"biting_lip":@"🫦",
                @"bubbles":@"🫧",
                @"shaking_face":@"🫨",
                @"face_with_bags_under_eyes":@"🫩",
                @"distorted_face":@"🫪",
                @"fight_cloud":@"🫯",
                @"hand_with_index_finger_and_thumb_crossed":@"🫰",
                @"rightwards_hand":@"🫱",
                @"leftwards_hand":@"🫲",
                @"palm_down_hand":@"🫳",
                @"palm_up_hand":@"🫴",
                @"index_pointing_at_the_viewer":@"🫵",
                @"heart_hands":@"🫶",
                @"leftwards_pushing_hand":@"🫷",
                @"rightwards_pushing_hand":@"🫸",
                @"bangbang":@"‼️",
                @"interrobang":@"⁉️",
                @"tm":@"™️",
                @"information_source":@"ℹ️",
                @"left_right_arrow":@"↔️",
                @"arrow_up_down":@"↕️",
                @"arrow_upper_left":@"↖️",
                @"arrow_upper_right":@"↗️",
                @"arrow_lower_right":@"↘️",
                @"arrow_lower_left":@"↙️",
                @"leftwards_arrow_with_hook":@"↩️",
                @"arrow_right_hook":@"↪️",
                @"watch":@"⌚",
                @"hourglass":@"⌛",
                @"keyboard":@"⌨️",
                @"eject":@"⏏️",
                @"fast_forward":@"⏩",
                @"rewind":@"⏪",
                @"arrow_double_up":@"⏫",
                @"arrow_double_down":@"⏬",
                @"black_right_pointing_double_triangle_with_vertical_bar":@"⏭️",
                @"black_left_pointing_double_triangle_with_vertical_bar":@"⏮️",
                @"black_right_pointing_triangle_with_double_vertical_bar":@"⏯️",
                @"alarm_clock":@"⏰",
                @"stopwatch":@"⏱️",
                @"timer_clock":@"⏲️",
                @"hourglass_flowing_sand":@"⏳",
                @"double_vertical_bar":@"⏸️",
                @"black_square_for_stop":@"⏹️",
                @"black_circle_for_record":@"⏺️",
                @"m":@"Ⓜ️",
                @"black_small_square":@"▪️",
                @"white_small_square":@"▫️",
                @"arrow_forward":@"▶️",
                @"arrow_backward":@"◀️",
                @"white_medium_square":@"◻️",
                @"black_medium_square":@"◼️",
                @"white_medium_small_square":@"◽",
                @"black_medium_small_square":@"◾",
                @"sunny":@"☀️",
                @"cloud":@"☁️",
                @"umbrella":@"☂️",
                @"snowman":@"☃️",
                @"comet":@"☄️",
                @"phone":@"☎️",
                @"telephone":@"☎️",
                @"ballot_box_with_check":@"☑️",
                @"shamrock":@"☘️",
                @"point_up":@"☝️",
                @"skull_and_crossbones":@"☠️",
                @"radioactive_sign":@"☢️",
                @"biohazard_sign":@"☣️",
                @"orthodox_cross":@"☦️",
                @"star_and_crescent":@"☪️",
                @"peace_symbol":@"☮️",
                @"yin_yang":@"☯️",
                @"wheel_of_dharma":@"☸️",
                @"white_frowning_face":@"☹️",
                @"relaxed":@"☺️",
                @"female_sign":@"♀️",
                @"male_sign":@"♂️",
                @"gemini":@"♊",
                @"cancer":@"♋",
                @"leo":@"♌",
                @"virgo":@"♍",
                @"libra":@"♎",
                @"scorpius":@"♏",
                @"chess_pawn":@"♟️",
                @"spades":@"♠️",
                @"clubs":@"♣️",
                @"hearts":@"♥️",
                @"diamonds":@"♦️",
                @"hotsprings":@"♨️",
                @"recycle":@"♻️",
                @"infinity":@"♾️",
                @"wheelchair":@"♿",
                @"hammer_and_pick":@"⚒️",
                @"crossed_swords":@"⚔️",
                @"medical_symbol":@"⚕️",
                @"staff_of_aesculapius":@"⚕️",
                @"scales":@"⚖️",
                @"alembic":@"⚗️",
                @"gear":@"⚙️",
                @"atom_symbol":@"⚛️",
                @"fleur_de_lis":@"⚜️",
                @"warning":@"⚠️",
                @"zap":@"⚡",
                @"transgender_symbol":@"⚧️",
                @"white_circle":@"⚪",
                @"black_circle":@"⚫",
                @"coffin":@"⚰️",
                @"funeral_urn":@"⚱️",
                @"soccer":@"⚽",
                @"baseball":@"⚾",
                @"snowman_without_snow":@"⛄",
                @"partly_sunny":@"⛅",
                @"thunder_cloud_and_rain":@"⛈️",
                @"ophiuchus":@"⛎",
                @"pick":@"⛏️",
                @"helmet_with_white_cross":@"⛑️",
                @"broken_chain":@"⛓️‍💥",
                @"chains":@"⛓️",
                @"no_entry":@"⛔",
                @"shinto_shrine":@"⛩️",
                @"church":@"⛪",
                @"mountain":@"⛰️",
                @"umbrella_on_ground":@"⛱️",
                @"fountain":@"⛲",
                @"golf":@"⛳",
                @"ferry":@"⛴️",
                @"boat":@"⛵",
                @"sailboat":@"⛵",
                @"skier":@"⛷️",
                @"ice_skate":@"⛸️",
                @"woman-bouncing-ball":@"⛹️‍♀️",
                @"man-bouncing-ball":@"⛹️‍♂️",
                @"person_with_ball":@"⛹️",
                @"tent":@"⛺",
                @"fuelpump":@"⛽",
                @"scissors":@"✂️",
                @"airplane":@"✈️",
                @"email":@"✉️",
                @"envelope":@"✉️",
                @"fist":@"✊",
                @"hand":@"✋",
                @"raised_hand":@"✋",
                @"v":@"✌️",
                @"writing_hand":@"✍️",
                @"pencil2":@"✏️",
                @"black_nib":@"✒️",
                @"heavy_check_mark":@"✔️",
                @"heavy_multiplication_x":@"✖️",
                @"latin_cross":@"✝️",
                @"star_of_david":@"✡️",
                @"eight_spoked_asterisk":@"✳️",
                @"eight_pointed_black_star":@"✴️",
                @"snowflake":@"❄️",
                @"sparkle":@"❇️",
                @"x":@"❌",
                @"negative_squared_cross_mark":@"❎",
                @"heavy_heart_exclamation_mark_ornament":@"❣️",
                @"heart_on_fire":@"❤️‍🔥",
                @"mending_heart":@"❤️‍🩹",
                @"heart":@"❤️",
                @"arrow_right":@"➡️",
                @"curly_loop":@"➰",
                @"loop":@"➿",
                @"arrow_heading_up":@"⤴️",
                @"arrow_heading_down":@"⤵️",
                @"arrow_left":@"⬅️",
                @"arrow_up":@"⬆️",
                @"arrow_down":@"⬇️",
                @"black_large_square":@"⬛",
                @"white_large_square":@"⬜",
                @"star":@"⭐",
                @"o":@"⭕",
                @"wavy_dash":@"〰️",
                @"part_alternation_mark":@"〽️",
                @"congratulations":@"㊗️",
                @"secret":@"㊙️",

                @"like":@"👍",
                @"thumbs_up":@"👍",
                @"dislike":@"👎",
                @"thumbs_down":@"👎",
                @"doge":@"🐕",
                @"aubergine":@"🍆",
                @"gust_of_wind":@"💨",
                @"party_popper":@"🎉",
                @"shock":@"😱",
                @"atom":@"⚛️",
                @"<3":@"❤️",
                @"</3":@"💔",
                @"simple_smile":@"🙂",
                @":)":@"🙂",
                @":-)":@"🙂",
                @")":@"🙂",
                @"-)":@"🙂",
                @"=D":@"😃",
                @":D":@"😀",
                @"D":@"😀",
                @":(":@"😞",
                @"(":@"😞",
                @":'(":@"😢",
                @"'(":@"😢",
                @":_(":@"😭",
                @"_(":@"😭",
                @"loudly_crying_face":@"😭",
                @"sad_tears":@"😭",
                @"bawl":@"😭",
                @";)":@"😉",
                @";p":@"😜",
                @"XD":@"😆",
                @"^_^":@"😄",
                @"^_^;":@"😅",
                @"rofl":@"🤣",
                @":|":@"😐",
                @"|":@"😐",
                @">.<":@"😣",
                @"ufo":@"🛸",
                @"female_wizard":@"🧙‍♀️",
                @"male_wizard":@"🧙‍♂️",
                @"brontosaurus":@"🦕",
                @"diplodocus":@"🦕",
                @"tyrannosaurus":@"🦖",
                @"steak":@"🥩",
                @"soup_tin":@"🥫",
                @"baseball_cap":@"🧢",
                @"female_yoga":@"🧘‍♀️",
                @"male_yoga":@"🧘‍♂️",
                @"female_sauna":@"🧖‍♀️",
                @"male_sauna":@"🧖‍♂️",
                @"hijab":@"🧕",
                @"ladybird":@"🐞",
                @"ladybeetle":@"🐞",
                @"coccinellid":@"🐞",
                @"diamond":@"💎",
                @"angel_face":@"😇",
                @"smiling_devil":@"😈",
                @"frowning_devil":@"👿",
                @"mad_rage":@"😡",
                @"angry_rage":@"😡",
                @"mad":@"😠",
                @"steam_train":@"🚂",
                @"graduation_cap":@"🎓",
                @"lightbulb":@"💡",
                @"cool_dude":@"😎",
                @"deal_with_it":@"😎",
                @"liar":@"🤥",
                @"bunny":@"🐰",
                @"bunny2":@"🐇",
                @"cigarette":@"🚬",
                @"fag":@"🚬",
                @"water_wave":@"🌊",
                @"crazy_face":@"🤪",
                @"sh":@"🤫",
                @"angry_swearing":@"🤬",
                @"mad_swearing":@"🤬",
                @"cursing":@"🤬",
                @"swearing":@"🤬",
                @"pissed_off":@"🤬",
                @"fuck":@"🤬",
                @"oops":@"🤭",
                @"throwing_up":@"🤮",
                @"being_sick":@"🤮",
                @"mind_blown":@"🤯",
                @"lightning_bolt":@"⚡",
                @"confetti":@"🎊",
                @"rubbish":@"🗑️",
                @"trash":@"🗑️",
                @"garbage":@"🗑️",
                @"bin":@"🗑️",
                @"wastepaper_basket":@"🗑️",
            };
        
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
}

+(NSRegularExpression *)emojiOnlyPattern {
    @synchronized (self) {
        if(!emojiMap)
            [self emoji];
        
        static NSRegularExpression *_pattern;
        if(!_pattern) {
            NSString *pattern = [[NSString stringWithFormat:@"(?:%@|\xE2\x80\x8D|\xEF\xB8\x8F)", [emojiMap.allValues componentsJoinedByString:@"|"]] stringByReplacingOccurrencesOfString:@"|:)" withString:@""];
            NSMutableString *pattern_escaped = [@"" mutableCopy];
            
            NSScanner *scanner = [NSScanner scannerWithString:pattern];
            while (![scanner isAtEnd]) {
                NSString *tempString;
                [scanner scanUpToCharactersFromSet:[NSCharacterSet characterSetWithCharactersInString:@"*"] intoString:&tempString];
                if([scanner isAtEnd]){
                    [pattern_escaped appendString:tempString];
                }
                else {
                    [pattern_escaped appendFormat:@"%@\\%@", tempString, [pattern substringWithRange:NSMakeRange([scanner scanLocation], 1)]];
                    [scanner setScanLocation:[scanner scanLocation]+1];
                }
            }
            _pattern = [NSRegularExpression regularExpressionWithPattern:pattern_escaped options:NSRegularExpressionCaseInsensitive error:nil];
        }
        return _pattern;
    }
}

+(NSRegularExpression *)spotify {
    @synchronized (self) {
        static NSRegularExpression *_pattern = nil;
        if(!_pattern) {
            NSString *pattern = @"spotify:([^<>()\"\\s]+)";
            _pattern = [NSRegularExpression
                        regularExpressionWithPattern:pattern
                        options:NSRegularExpressionCaseInsensitive
                        error:nil];
        }
        return _pattern;
    }
}

+(NSRegularExpression *)geo {
    @synchronized (self) {
        static NSRegularExpression *_pattern = nil;
        if(!_pattern) {
            NSString *pattern = @"geo:([^<>()\"\\s]+)";
            _pattern = [NSRegularExpression
                        regularExpressionWithPattern:pattern
                        options:NSRegularExpressionCaseInsensitive
                        error:nil];
        }
        return _pattern;
    }
}

+(NSRegularExpression *)email {
    @synchronized (self) {
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
}

+(NSRegularExpression *)webURL {
    @synchronized (self) {
        static NSRegularExpression *_pattern = nil;
        if(!_pattern) {
            //Ported from Android: https://github.com/android/platform_frameworks_base/blob/master/core/java/android/util/Patterns.java
            NSString *IANA_TOP_LEVEL_DOMAINS = @"(?:\
(?:aaa|aarp|abarth|abb|abbott|abbvie|abc|able|abogado|abudhabi|academy|accenture|accountant|accountants|aco|actor|adac|ads|adult|aeg|aero|aetna|afamilycompany|afl|africa|agakhan|agency|aig|aigo|airbus|airforce|airtel|akdn|alfaromeo|alibaba|alipay|allfinanz|allstate|ally|alsace|alstom|americanexpress|americanfamily|amex|amfam|amica|amsterdam|analytics|android|anquan|anz|aol|apartments|app|apple|aquarelle|arab|aramco|archi|army|arpa|art|arte|asda|asia|associates|athleta|attorney|auction|audi|audible|audio|auspost|author|auto|autos|avianca|aws|axa|azure|a[cdefgilmoqrstuwxz])\
|(?:baby|baidu|banamex|bananarepublic|band|bank|bar|barcelona|barclaycard|barclays|barefoot|bargains|baseball|basketball|bauhaus|bayern|bbc|bbt|bbva|bcg|bcn|beats|beauty|beer|bentley|berlin|best|bestbuy|bet|bharti|bible|bid|bike|bing|bingo|bio|biz|black|blackfriday|blockbuster|blog|bloomberg|blue|bms|bmw|bnpparibas|boats|boehringer|bofa|bom|bond|boo|book|booking|bosch|bostik|boston|bot|boutique|box|bradesco|bridgestone|broadway|broker|brother|brussels|budapest|bugatti|build|builders|business|buy|buzz|bzh|b[abdefghijmnorstvwyz])\
|(?:cab|cafe|cal|call|calvinklein|cam|camera|camp|cancerresearch|canon|capetown|capital|capitalone|car|caravan|cards|care|career|careers|cars|cartier|casa|case|caseih|cash|casino|cat|catering|catholic|cba|cbn|cbre|cbs|ceb|center|ceo|cern|cfa|cfd|chanel|channel|charity|chase|chat|cheap|chintai|christmas|chrome|chrysler|church|cipriani|circle|cisco|citadel|citi|citic|city|cityeats|claims|cleaning|click|clinic|clinique|clothing|cloud|club|clubmed|coach|codes|coffee|college|cologne|com|comcast|commbank|community|company|compare|computer|comsec|condos|construction|consulting|contact|contractors|cooking|cookingchannel|cool|coop|corsica|country|coupon|coupons|courses|cpa|credit|creditcard|creditunion|cricket|crown|crs|cruise|cruises|csc|cuisinella|cymru|cyou|c[acdfghiklmnoruvwxyz])\
|(?:dabur|dad|dance|data|date|dating|datsun|day|dclk|dds|deal|dealer|deals|degree|delivery|dell|deloitte|delta|democrat|dental|dentist|desi|design|dev|dhl|diamonds|diet|digital|direct|directory|discount|discover|dish|diy|dnp|docs|doctor|dodge|dog|domains|dot|download|drive|dtv|dubai|duck|dunlop|dupont|durban|dvag|dvr|d[ejkmoz])\
|(?:earth|eat|eco|edeka|edu|education|email|emerck|energy|engineer|engineering|enterprises|epson|equipment|ericsson|erni|esq|estate|esurance|etisalat|eurovision|eus|events|everbank|exchange|expert|exposed|express|extraspace|e[cegrstu])\
|(?:fage|fail|fairwinds|faith|family|fan|fans|farm|farmers|fashion|fast|fedex|feedback|ferrari|ferrero|fiat|fidelity|fido|film|final|finance|financial|fire|firestone|firmdale|fish|fishing|fit|fitness|flickr|flights|flir|florist|flowers|fly|foo|food|foodnetwork|football|ford|forex|forsale|forum|foundation|fox|free|fresenius|frl|frogans|frontdoor|frontier|ftr|fujitsu|fujixerox|fun|fund|furniture|futbol|fyi|f[ijkmor])\
|(?:gal|gallery|gallo|gallup|game|games|gap|garden|gay|gbiz|gdn|gea|gent|genting|george|ggee|gift|gifts|gives|giving|glade|glass|gle|global|globo|gmail|gmbh|gmo|gmx|godaddy|gold|goldpoint|golf|goo|goodyear|goog|google|gop|got|gov|grainger|graphics|gratis|green|gripe|grocery|group|guardian|gucci|guge|guide|guitars|guru|g[abdefghilmnpqrstuwy])\
|(?:hair|hamburg|hangout|haus|hbo|hdfc|hdfcbank|health|healthcare|help|helsinki|here|hermes|hgtv|hiphop|hisamitsu|hitachi|hiv|hkt|hockey|holdings|holiday|homedepot|homegoods|homes|homesense|honda|horse|hospital|host|hosting|hot|hoteles|hotels|hotmail|house|how|hsbc|hughes|hyatt|hyundai|h[kmnrtu])\
|(?:ibm|icbc|ice|icu|ieee|ifm|ikano|imamat|imdb|immo|immobilien|inc|industries|infiniti|info|ing|ink|institute|insurance|insure|int|intel|international|intuit|investments|ipiranga|irish|ismaili|ist|istanbul|itau|itv|iveco|i[delmnoqrst])\
|(?:jaguar|java|jcb|jcp|jeep|jetzt|jewelry|jio|jll|jmp|jnj|jobs|joburg|jot|joy|jpmorgan|jprs|juegos|juniper|j[emop])\
|(?:kaufen|kddi|kerryhotels|kerrylogistics|kerryproperties|kfh|kia|kim|kinder|kindle|kitchen|kiwi|koeln|komatsu|kosher|kpmg|kpn|krd|kred|kuokgroup|kyoto|k[eghimnprwyz])\
|(?:lacaixa|ladbrokes|lamborghini|lamer|lancaster|lancia|lancome|land|landrover|lanxess|lasalle|lat|latino|latrobe|law|lawyer|lds|lease|leclerc|lefrak|legal|lego|lexus|lgbt|liaison|lidl|life|lifeinsurance|lifestyle|lighting|like|lilly|limited|limo|lincoln|linde|link|lipsy|live|living|lixil|llc|loan|loans|locker|locus|loft|lol|london|lotte|lotto|love|lpl|lplfinancial|ltd|ltda|lundbeck|lupin|luxe|luxury|l[abcikrstuvy])\
|(?:macys|madrid|maif|maison|makeup|man|management|mango|map|market|marketing|markets|marriott|marshalls|maserati|mattel|mba|mckinsey|med|media|meet|melbourne|meme|memorial|men|menu|merckmsd|metlife|miami|microsoft|mil|mini|mint|mit|mitsubishi|mlb|mls|mma|mobi|mobile|moda|moe|moi|mom|monash|money|monster|mopar|mormon|mortgage|moscow|moto|motorcycles|mov|movie|movistar|msd|mtn|mtr|museum|mutual|m[acdeghklmnopqrstuvwxyz])\
|(?:nab|nadex|nagoya|name|nationwide|natura|navy|nba|nec|net|netbank|netflix|network|neustar|new|newholland|news|next|nextdirect|nexus|nfl|ngo|nhk|nico|nike|nikon|ninja|nissan|nissay|nokia|northwesternmutual|norton|now|nowruz|nowtv|nra|nrw|ntt|nyc|n[acefgilopruz])\
|(?:obi|observer|off|office|okinawa|olayan|olayangroup|oldnavy|ollo|omega|one|ong|onl|online|onyourside|ooo|open|oracle|orange|org|organic|origins|osaka|otsuka|ott|ovh|om)\
|(?:page|panasonic|paris|pars|partners|parts|party|passagens|pay|pccw|pet|pfizer|pharmacy|phd|philips|phone|photo|photography|photos|physio|piaget|pics|pictet|pictures|pid|pin|ping|pink|pioneer|pizza|place|play|playstation|plumbing|plus|pnc|pohl|poker|politie|porn|post|pramerica|praxi|press|prime|pro|prod|productions|prof|progressive|promo|properties|property|protection|pru|prudential|pub|pwc|p[aefghklmnrstwy])\
|(?:qpon|quebec|quest|qvc|qa)\
|(?:racing|radio|raid|read|realestate|realtor|realty|recipes|red|redstone|redumbrella|rehab|reise|reisen|reit|reliance|ren|rent|rentals|repair|report|republican|rest|restaurant|review|reviews|rexroth|rich|richardli|ricoh|rightathome|ril|rio|rip|rmit|rocher|rocks|rodeo|rogers|room|rsvp|rugby|ruhr|run|rwe|ryukyu|r[eosuw])\
|(?:saarland|safe|safety|sakura|sale|salon|samsclub|samsung|sandvik|sandvikcoromant|sanofi|sap|sarl|sas|save|saxo|sbi|sbs|sca|scb|schaeffler|schmidt|scholarships|school|schule|schwarz|science|scjohnson|scor|scot|search|seat|secure|security|seek|select|sener|services|ses|seven|sew|sex|sexy|sfr|shangrila|sharp|shaw|shell|shia|shiksha|shoes|shop|shopping|shouji|show|showtime|shriram|silk|sina|singles|site|ski|skin|sky|skype|sling|smart|smile|sncf|soccer|social|softbank|software|sohu|solar|solutions|song|sony|soy|space|sport|spot|spreadbetting|srl|srt|stada|staples|star|statebank|statefarm|stc|stcgroup|stockholm|storage|store|stream|studio|study|style|sucks|supplies|supply|support|surf|surgery|suzuki|swatch|swiftcover|swiss|sydney|symantec|systems|s[abcdeghijklmnorstuvxyz])\
|(?:tab|taipei|talk|taobao|target|tatamotors|tatar|tattoo|tax|taxi|tci|tdk|team|tech|technology|tel|telefonica|temasek|tennis|teva|thd|theater|theatre|tiaa|tickets|tienda|tiffany|tips|tires|tirol|tjmaxx|tjx|tkmaxx|tmall|today|tokyo|tools|top|toray|toshiba|total|tours|town|toyota|toys|trade|trading|training|travel|travelchannel|travelers|travelersinsurance|trust|trv|tube|tui|tunes|tushu|tvs|t[cdfghjklmnortvwz])\
|(?:ubank|ubs|uconnect|unicom|university|uno|uol|ups|u[agksyz])\
|(?:vacations|vana|vanguard|vegas|ventures|verisign|versicherung|vet|viajes|video|vig|viking|villas|vin|vip|virgin|visa|vision|vistaprint|viva|vivo|vlaanderen|vodka|volkswagen|volvo|vote|voting|voto|voyage|vuelos|v[aceginu])\
|(?:wales|walmart|walter|wang|wanggou|warman|watch|watches|weather|weatherchannel|webcam|weber|website|wed|wedding|weibo|weir|whoswho|wien|wiki|williamhill|win|windows|wine|winners|wme|wolterskluwer|woodside|work|works|world|wow|wtc|wtf|w[fs])\
|(?:\\u03b5\\u03bb|\\u03b5\\u03c5|\\u0431\\u0433|\\u0431\\u0435\\u043b|\\u0434\\u0435\\u0442\\u0438|\\u0435\\u044e|\\u043a\\u0430\\u0442\\u043e\\u043b\\u0438\\u043a|\\u043a\\u043e\\u043c|\\u043c\\u043a\\u0434|\\u043c\\u043e\\u043d|\\u043c\\u043e\\u0441\\u043a\\u0432\\u0430|\\u043e\\u043d\\u043b\\u0430\\u0439\\u043d|\\u043e\\u0440\\u0433|\\u0440\\u0443\\u0441|\\u0440\\u0444|\\u0441\\u0430\\u0439\\u0442|\\u0441\\u0440\\u0431|\\u0443\\u043a\\u0440|\\u049b\\u0430\\u0437|\\u0570\\u0561\\u0575|\\u05e7\\u05d5\\u05dd|\\u0627\\u0628\\u0648\\u0638\\u0628\\u064a|\\u0627\\u062a\\u0635\\u0627\\u0644\\u0627\\u062a|\\u0627\\u0631\\u0627\\u0645\\u0643\\u0648|\\u0627\\u0644\\u0627\\u0631\\u062f\\u0646|\\u0627\\u0644\\u062c\\u0632\\u0627\\u0626\\u0631|\\u0627\\u0644\\u0633\\u0639\\u0648\\u062f\\u064a\\u0629|\\u0627\\u0644\\u0639\\u0644\\u064a\\u0627\\u0646|\\u0627\\u0644\\u0645\\u063a\\u0631\\u0628|\\u0627\\u0645\\u0627\\u0631\\u0627\\u062a|\\u0627\\u06cc\\u0631\\u0627\\u0646|\\u0628\\u0627\\u0631\\u062a|\\u0628\\u0627\\u0632\\u0627\\u0631|\\u0628\\u064a\\u062a\\u0643|\\u0628\\u06be\\u0627\\u0631\\u062a|\\u062a\\u0648\\u0646\\u0633|\\u0633\\u0648\\u062f\\u0627\\u0646|\\u0633\\u0648\\u0631\\u064a\\u0629|\\u0634\\u0628\\u0643\\u0629|\\u0639\\u0631\\u0627\\u0642|\\u0639\\u0631\\u0628|\\u0639\\u0645\\u0627\\u0646|\\u0641\\u0644\\u0633\\u0637\\u064a\\u0646|\\u0642\\u0637\\u0631|\\u0643\\u0627\\u062b\\u0648\\u0644\\u064a\\u0643|\\u0643\\u0648\\u0645|\\u0645\\u0635\\u0631|\\u0645\\u0644\\u064a\\u0633\\u064a\\u0627|\\u0645\\u0648\\u0631\\u064a\\u062a\\u0627\\u0646\\u064a\\u0627|\\u0645\\u0648\\u0642\\u0639|\\u0647\\u0645\\u0631\\u0627\\u0647|\\u067e\\u0627\\u06a9\\u0633\\u062a\\u0627\\u0646|\\u0680\\u0627\\u0631\\u062a|\\u0915\\u0949\\u092e|\\u0928\\u0947\\u091f|\\u092d\\u093e\\u0930\\u0924|\\u092d\\u093e\\u0930\\u0924\\u092e\\u094d|\\u092d\\u093e\\u0930\\u094b\\u0924|\\u0938\\u0902\\u0917\\u0920\\u0928|\\u09ac\\u09be\\u0982\\u09b2\\u09be|\\u09ad\\u09be\\u09b0\\u09a4|\\u09ad\\u09be\\u09f0\\u09a4|\\u0a2d\\u0a3e\\u0a30\\u0a24|\\u0aad\\u0abe\\u0ab0\\u0aa4|\\u0b2d\\u0b3e\\u0b30\\u0b24|\\u0b87\\u0ba8\\u0bcd\\u0ba4\\u0bbf\\u0baf\\u0bbe|\\u0b87\\u0bb2\\u0b99\\u0bcd\\u0b95\\u0bc8|\\u0b9a\\u0bbf\\u0b99\\u0bcd\\u0b95\\u0baa\\u0bcd\\u0baa\\u0bc2\\u0bb0\\u0bcd|\\u0c2d\\u0c3e\\u0c30\\u0c24\\u0c4d|\\u0cad\\u0cbe\\u0cb0\\u0ca4|\\u0d2d\\u0d3e\\u0d30\\u0d24\\u0d02|\\u0dbd\\u0d82\\u0d9a\\u0dcf|\\u0e04\\u0e2d\\u0e21|\\u0e44\\u0e17\\u0e22|\\u10d2\\u10d4|\\u307f\\u3093\\u306a|\\u30af\\u30e9\\u30a6\\u30c9|\\u30b0\\u30fc\\u30b0\\u30eb|\\u30b3\\u30e0|\\u30b9\\u30c8\\u30a2|\\u30bb\\u30fc\\u30eb|\\u30d5\\u30a1\\u30c3\\u30b7\\u30e7\\u30f3|\\u30dd\\u30a4\\u30f3\\u30c8|\\u4e16\\u754c|\\u4e2d\\u4fe1|\\u4e2d\\u56fd|\\u4e2d\\u570b|\\u4e2d\\u6587\\u7f51|\\u4f01\\u4e1a|\\u4f5b\\u5c71|\\u4fe1\\u606f|\\u5065\\u5eb7|\\u516b\\u5366|\\u516c\\u53f8|\\u516c\\u76ca|\\u53f0\\u6e7e|\\u53f0\\u7063|\\u5546\\u57ce|\\u5546\\u5e97|\\u5546\\u6807|\\u5609\\u91cc|\\u5609\\u91cc\\u5927\\u9152\\u5e97|\\u5728\\u7ebf|\\u5927\\u4f17\\u6c7d\\u8f66|\\u5927\\u62ff|\\u5929\\u4e3b\\u6559|\\u5a31\\u4e50|\\u5bb6\\u96fb|\\u5de5\\u884c|\\u5e7f\\u4e1c|\\u5fae\\u535a|\\u6148\\u5584|\\u6211\\u7231\\u4f60|\\u624b\\u673a|\\u624b\\u8868|\\u62db\\u8058|\\u653f\\u52a1|\\u653f\\u5e9c|\\u65b0\\u52a0\\u5761|\\u65b0\\u95fb|\\u65f6\\u5c1a|\\u66f8\\u7c4d|\\u673a\\u6784|\\u6de1\\u9a6c\\u9521|\\u6e38\\u620f|\\u6fb3\\u9580|\\u70b9\\u770b|\\u73e0\\u5b9d|\\u79fb\\u52a8|\\u7ec4\\u7ec7\\u673a\\u6784|\\u7f51\\u5740|\\u7f51\\u5e97|\\u7f51\\u7ad9|\\u7f51\\u7edc|\\u8054\\u901a|\\u8bfa\\u57fa\\u4e9a|\\u8c37\\u6b4c|\\u8d2d\\u7269|\\u901a\\u8ca9|\\u96c6\\u56e2|\\u96fb\\u8a0a\\u76c8\\u79d1|\\u98de\\u5229\\u6d66|\\u98df\\u54c1|\\u9910\\u5385|\\u9999\\u683c\\u91cc\\u62c9|\\u9999\\u6e2f|\\ub2f7\\ub137|\\ub2f7\\ucef4|\\uc0bc\\uc131|\\ud55c\\uad6d|verm\\xf6gensberater|verm\\xf6gensberatung|xbox|xerox|xfinity|xihuan|xin|xn\\-\\-11b4c3d|xn\\-\\-1ck2e1b|xn\\-\\-1qqw23a|xn\\-\\-2scrj9c|xn\\-\\-30rr7y|xn\\-\\-3bst00m|xn\\-\\-3ds443g|xn\\-\\-3e0b707e|xn\\-\\-3hcrj9c|xn\\-\\-3oq18vl8pn36a|xn\\-\\-3pxu8k|xn\\-\\-42c2d9a|xn\\-\\-45br5cyl|xn\\-\\-45brj9c|xn\\-\\-45q11c|xn\\-\\-4gbrim|xn\\-\\-54b7fta0cc|xn\\-\\-55qw42g|xn\\-\\-55qx5d|xn\\-\\-5su34j936bgsg|xn\\-\\-5tzm5g|xn\\-\\-6frz82g|xn\\-\\-6qq986b3xl|xn\\-\\-80adxhks|xn\\-\\-80ao21a|xn\\-\\-80aqecdr1a|xn\\-\\-80asehdb|xn\\-\\-80aswg|xn\\-\\-8y0a063a|xn\\-\\-90a3ac|xn\\-\\-90ae|xn\\-\\-90ais|xn\\-\\-9dbq2a|xn\\-\\-9et52u|xn\\-\\-9krt00a|xn\\-\\-b4w605ferd|xn\\-\\-bck1b9a5dre4c|xn\\-\\-c1avg|xn\\-\\-c2br7g|xn\\-\\-cck2b3b|xn\\-\\-cg4bki|xn\\-\\-clchc0ea0b2g2a9gcd|xn\\-\\-czr694b|xn\\-\\-czrs0t|xn\\-\\-czru2d|xn\\-\\-d1acj3b|xn\\-\\-d1alf|xn\\-\\-e1a4c|xn\\-\\-eckvdtc9d|xn\\-\\-efvy88h|xn\\-\\-estv75g|xn\\-\\-fct429k|xn\\-\\-fhbei|xn\\-\\-fiq228c5hs|xn\\-\\-fiq64b|xn\\-\\-fiqs8s|xn\\-\\-fiqz9s|xn\\-\\-fjq720a|xn\\-\\-flw351e|xn\\-\\-fpcrj9c3d|xn\\-\\-fzc2c9e2c|xn\\-\\-fzys8d69uvgm|xn\\-\\-g2xx48c|xn\\-\\-gckr3f0f|xn\\-\\-gecrj9c|xn\\-\\-gk3at1e|xn\\-\\-h2breg3eve|xn\\-\\-h2brj9c|xn\\-\\-h2brj9c8c|xn\\-\\-hxt814e|xn\\-\\-i1b6b1a6a2e|xn\\-\\-imr513n|xn\\-\\-io0a7i|xn\\-\\-j1aef|xn\\-\\-j1amh|xn\\-\\-j6w193g|xn\\-\\-jlq61u9w7b|xn\\-\\-jvr189m|xn\\-\\-kcrx77d1x4a|xn\\-\\-kprw13d|xn\\-\\-kpry57d|xn\\-\\-kpu716f|xn\\-\\-kput3i|xn\\-\\-l1acc|xn\\-\\-lgbbat1ad8j|xn\\-\\-mgb9awbf|xn\\-\\-mgba3a3ejt|xn\\-\\-mgba3a4f16a|xn\\-\\-mgba7c0bbn0a|xn\\-\\-mgbaakc7dvf|xn\\-\\-mgbaam7a8h|xn\\-\\-mgbab2bd|xn\\-\\-mgbah1a3hjkrd|xn\\-\\-mgbai9azgqp6j|xn\\-\\-mgbayh7gpa|xn\\-\\-mgbbh1a|xn\\-\\-mgbbh1a71e|xn\\-\\-mgbc0a9azcg|xn\\-\\-mgbca7dzdo|xn\\-\\-mgberp4a5d4ar|xn\\-\\-mgbgu82a|xn\\-\\-mgbi4ecexp|xn\\-\\-mgbpl2fh|xn\\-\\-mgbt3dhd|xn\\-\\-mgbtx2b|xn\\-\\-mgbx4cd0ab|xn\\-\\-mix891f|xn\\-\\-mk1bu44c|xn\\-\\-mxtq1m|xn\\-\\-ngbc5azd|xn\\-\\-ngbe9e0a|xn\\-\\-ngbrx|xn\\-\\-node|xn\\-\\-nqv7f|xn\\-\\-nqv7fs00ema|xn\\-\\-nyqy26a|xn\\-\\-o3cw4h|xn\\-\\-ogbpf8fl|xn\\-\\-otu796d|xn\\-\\-p1acf|xn\\-\\-p1ai|xn\\-\\-pbt977c|xn\\-\\-pgbs0dh|xn\\-\\-pssy2u|xn\\-\\-q9jyb4c|xn\\-\\-qcka1pmc|xn\\-\\-qxa6a|xn\\-\\-qxam|xn\\-\\-rhqv96g|xn\\-\\-rovu88b|xn\\-\\-rvc1e0am3e|xn\\-\\-s9brj9c|xn\\-\\-ses554g|xn\\-\\-t60b56a|xn\\-\\-tckwe|xn\\-\\-tiq49xqyj|xn\\-\\-unup4y|xn\\-\\-vermgensberater\\-ctb|xn\\-\\-vermgensberatung\\-pwb|xn\\-\\-vhquv|xn\\-\\-vuq861b|xn\\-\\-w4r85el8fhu5dnra|xn\\-\\-w4rs40l|xn\\-\\-wgbh1c|xn\\-\\-wgbl6a|xn\\-\\-xhq521b|xn\\-\\-xkc2al3hye2a|xn\\-\\-xkc2dl3a5ee0h|xn\\-\\-y9a3aq|xn\\-\\-yfro4i67o|xn\\-\\-ygbi2ammx|xn\\-\\-zfr164b|xxx|xyz)\
|(?:yachts|yahoo|yamaxun|yandex|yodobashi|yoga|yokohama|you|youtube|yun|y[et])\
|(?:zappos|zara|zero|zip|zone|zuerich|z[amw]))";
            NSString *IP_ADDRESS_STRING = @"((25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9])\\.(25[0-5]|2[0-4]\
[0-9]|[0-1][0-9]{2}|[1-9][0-9]|[1-9]|0)\\.(25[0-5]|2[0-4][0-9]|[0-1]\
[0-9]{2}|[1-9][0-9]|[1-9]|0)\\.(25[0-5]|2[0-4][0-9]|[0-1][0-9]{2}\
|[1-9][0-9]|[0-9]))";
            NSString *UCS_CHAR = @"[\
\u00A0-\uD7FF\
\uF900-\uFDCF\
\uFDF0-\uFFEF\
&&[^\u00A0[\u2000-\u200A]\u2028\u2029\u202F\u3000]]";

            NSString *LABEL_CHAR = [NSString stringWithFormat:@"a-zA-Z0-9%@", UCS_CHAR];
            NSString *IRI_LABEL = [NSString stringWithFormat:@"[%@](?:[%@_\\-]{0,61}[%@]){0,1}", LABEL_CHAR, LABEL_CHAR, LABEL_CHAR];
            NSString *PUNYCODE_TLD = @"xn\\-\\-[\\w\\-]{0,58}\\w";
            NSString *PROTOCOL = @"[a-z_-]+://";
            NSString *WORD_BOUNDARY = @"(?=\\b|$|^)";
            NSString *USER_INFO = @"(?:[a-zA-Z0-9\\$\\-\\_\\.\\+\\!\\*\\'\\(\\)\
\\,\\;\\?\\&\\=]|(?:\\%[a-fA-F0-9]{2})){1,64}(?:\\:(?:[a-zA-Z0-9\\$\\-\\_\
\\.\\+\\!\\*\\'\\(\\)\\,\\;\\?\\&\\=]|(?:\\%[a-fA-F0-9]{2})){1,25})?\\@";
            NSString *PORT_NUMBER = @"\\:\\d{1,5}";
            NSString *PATH_AND_QUERY = [NSString stringWithFormat:@"[/\\?](?:(?:[%@;/\\?:@&=#~\\-\\.\\+!\\*'\\(\\),_\\$])|(?:%%[a-fA-F0-9]{2}))*", LABEL_CHAR];
            NSString *STRICT_TLD = [NSString stringWithFormat:@"(?:%@|%@)", IANA_TOP_LEVEL_DOMAINS, PUNYCODE_TLD];
            NSString *STRICT_HOST_NAME = [NSString stringWithFormat:@"(?:(?:%@\\.)+%@)", IRI_LABEL, STRICT_TLD];
            NSString *STRICT_DOMAIN_NAME = [NSString stringWithFormat:@"(?:%@|%@)", STRICT_HOST_NAME, IP_ADDRESS_STRING];
            NSString *RELAXED_DOMAIN_NAME = [NSString stringWithFormat:@"(?:(?:%@(?:\\.(?=\\S))?)+|%@)", IRI_LABEL, IP_ADDRESS_STRING];

            NSString *WEB_URL_WITHOUT_PROTOCOL = [NSString stringWithFormat:@"(\
%@\
(?<!:\\/\\/)\
(\
(?:%@)\
(?:%@)?\
)\
(?:%@)?\
%@\
)", WORD_BOUNDARY, STRICT_DOMAIN_NAME, PORT_NUMBER, PATH_AND_QUERY, WORD_BOUNDARY];
            
            NSString *WEB_URL_WITH_PROTOCOL = [NSString stringWithFormat:@"(\
%@\
(?:\
(?:%@(?:%@)?)\
(?:%@)?\
(?:%@)?\
)\
(?:%@)?\
%@\
)", WORD_BOUNDARY, PROTOCOL, USER_INFO, RELAXED_DOMAIN_NAME, PORT_NUMBER, PATH_AND_QUERY, WORD_BOUNDARY];
            
            NSString *pattern = [NSString stringWithFormat:@"(%@|%@)", WEB_URL_WITH_PROTOCOL, WEB_URL_WITHOUT_PROTOCOL];
            _pattern = [NSRegularExpression
                regularExpressionWithPattern:pattern
                options:NSRegularExpressionCaseInsensitive|NSRegularExpressionUseUnicodeWordBoundaries
                error:nil];
        }
        return _pattern;
    }
}

+(NSRegularExpression *)ircChannelRegexForServer:(Server *)s {
    @synchronized (self) {
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
    @synchronized (self) {
        monoTimestampFont = [UIFont fontWithName:@"Hack" size:FONT_SIZE - 3];
        timestampFont = [UIFont systemFontOfSize:FONT_SIZE - 2];
        arrowFont = nil;
        awesomeFont = [UIFont fontWithName:@"FontAwesome" size:FONT_SIZE];
        Courier = [UIFont fontWithName:@"Hack" size:FONT_SIZE - 1];
        CourierBold = [UIFont fontWithName:@"Hack-Bold" size:FONT_SIZE - 1];
        CourierOblique = [UIFont fontWithName:@"Hack-Italic" size:FONT_SIZE - 1];
        CourierBoldOblique = [UIFont fontWithName:@"Hack-BoldItalic" size:FONT_SIZE - 1];
        chalkboardFont = [UIFont fontWithName:@"ChalkboardSE-Light" size:FONT_SIZE];
        markerFont = [UIFont fontWithName:@"MarkerFelt-Thin" size:FONT_SIZE];
        UIFontDescriptor *bodyFontDescriptor = [UIFontDescriptor preferredFontDescriptorWithTextStyle:UIFontTextStyleBody];
        UIFontDescriptor *boldBodyFontDescriptor = [bodyFontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold];
        UIFontDescriptor *italicBodyFontDescriptor = [bodyFontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitItalic];
        UIFontDescriptor *boldItalicBodyFontDescriptor = [bodyFontDescriptor fontDescriptorWithSymbolicTraits:UIFontDescriptorTraitBold|UIFontDescriptorTraitItalic];
        Helvetica = [UIFont fontWithDescriptor:bodyFontDescriptor size:FONT_SIZE];
        HelveticaBold = [UIFont fontWithDescriptor:boldBodyFontDescriptor size:FONT_SIZE];
        HelveticaOblique = [UIFont fontWithDescriptor:italicBodyFontDescriptor size:FONT_SIZE];
        HelveticaBoldOblique = [UIFont fontWithDescriptor:boldItalicBodyFontDescriptor size:FONT_SIZE];
        largeEmojiFont = [UIFont fontWithDescriptor:bodyFontDescriptor size:FONT_SIZE * 2];
        ColorFormatterCachedFontSize = FONT_SIZE;
    }
}

+(void)emojify:(NSMutableString *)text {
    [self _emojify:text mentions:nil];
}

+(void)_emojify:(NSMutableString *)text mentions:(NSMutableDictionary *)mentions {
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
                if(mentions) {
                    [self _offsetMentions:mentions start:range.location offset:range.length - emoji.length + 2];
                }
            }
        }
    }
}

+(NSAttributedString *)format:(NSString *)input defaultColor:(UIColor *)color mono:(BOOL)mono linkify:(BOOL)linkify server:(Server *)server links:(NSArray **)links {
    return [self format:input defaultColor:color mono:mono linkify:linkify server:server links:links largeEmoji:NO mentions:nil colorizeMentions:NO mentionOffset:0 mentionData:nil];
}
+(void)_offsetMentions:(NSMutableDictionary *)mentions start:(NSInteger)start offset:(NSInteger)offset {
    for(NSString *key in mentions.allKeys) {
        NSArray *mention = [mentions objectForKey:key];
        NSMutableArray *new_mention = [[NSMutableArray alloc] initWithCapacity:mention.count];
        for(NSArray *position in mention) {
            if([[position objectAtIndex:0] intValue] >= start) {
                [new_mention addObject:@[@([[position objectAtIndex:0] intValue] - offset),
                                         @([[position objectAtIndex:1] intValue])]];
            } else {
                [new_mention addObject:position];
            }
        }
        [mentions setObject:new_mention forKey:key];
    }
}

+(NSAttributedString *)format:(NSString *)input defaultColor:(UIColor *)color mono:(BOOL)monospace linkify:(BOOL)linkify server:(Server *)server links:(NSArray **)links largeEmoji:(BOOL)largeEmoji mentions:(NSDictionary *)m colorizeMentions:(BOOL)colorizeMentions mentionOffset:(NSInteger)mentionOffset mentionData:(NSDictionary *)mentionData {
    return [self format:input defaultColor:color mono:monospace linkify:linkify server:server links:links largeEmoji:largeEmoji mentions:m colorizeMentions:colorizeMentions mentionOffset:mentionOffset mentionData:mentionData stripColors:NO];
}

+(NSAttributedString *)format:(NSString *)input defaultColor:(UIColor *)color mono:(BOOL)monospace linkify:(BOOL)linkify server:(Server *)server links:(NSArray **)links largeEmoji:(BOOL)largeEmoji mentions:(NSDictionary *)m colorizeMentions:(BOOL)colorizeMentions mentionOffset:(NSInteger)mentionOffset mentionData:(NSDictionary *)mentionData stripColors:(BOOL)stripColors {
    int bold = -1, italics = -1, underline = -1, fg = -1, bg = -1, mono = -1, strike = -1;
    UIColor *fgColor = nil, *bgColor = nil, *oldFgColor = nil, *oldBgColor = nil;
    id font, boldFont, italicFont, boldItalicFont;
    NSMutableArray *matches = [[NSMutableArray alloc] init];
    NSMutableDictionary *mentions = m.mutableCopy;
    
    if(!Courier) {
        dispatch_sync(dispatch_get_main_queue(), ^{
            [self loadFonts];
        });
    }
    
    if(monospace) {
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
    NSMutableArray *thinSpaceIndex = [[NSMutableArray alloc] init];

    NSMutableString *text = [[NSMutableString alloc] initWithFormat:@"%@%c", [input stringByReplacingOccurrencesOfString:@"  " withString:@"\u00A0 "], CLEAR];
    
    if(mentions) {
        [self _offsetMentions:mentions start:0 offset:-mentionOffset];
        
        for(NSUInteger i = 0; i < text.length; i++) {
            NSRange r = [text rangeOfComposedCharacterSequenceAtIndex:i];
            if(r.length > 1) {
                //iOS uses UTF-16 internally, if the combined character length differs between the two encodings then we need to adjust our offsets by 1 byte
                NSString *c = [text substringWithRange:r];
                NSData *utf8 = [c dataUsingEncoding:NSUTF8StringEncoding];
                NSData *utf16 = [c dataUsingEncoding:NSUTF16StringEncoding];
                if(utf8.length != utf16.length) {
                    [self _offsetMentions:mentions start:i offset:-1];
                    i++;
                }
            }
        }
        
        for(NSString *key in mentions.allKeys) {
            NSArray *mention = [mentions objectForKey:key];
            for(NSArray *old_position in mention) {
                NSMutableArray *position = old_position.mutableCopy;
                if([[position objectAtIndex:0] intValue] >= 0 && [[position objectAtIndex:0] intValue] + [[position objectAtIndex:1] intValue] <= input.length) {
                    [text replaceCharactersInRange:NSMakeRange([[position objectAtIndex:0] intValue], [[position objectAtIndex:1] intValue]) withString:[@"" stringByPaddingToLength:[[position objectAtIndex:1] intValue] withString:@"A" startingAtIndex:0]];
                }
            }
        }
    }
    
    BOOL disableConvert = [[NetworkConnection sharedInstance] prefs] && [[[[NetworkConnection sharedInstance] prefs] objectForKey:@"emoji-disableconvert"] boolValue];
    if(!disableConvert) {
        [self _emojify:text mentions:mentions];
    }
    
    NSUInteger oldLength = 0;
    for(int i = 0; i < text.length; i++) {
        if(oldLength) {
            NSInteger delta = oldLength - text.length;
            if(mentions && delta) {
                [self _offsetMentions:mentions start:i offset:delta];
            }
        }
        oldLength = text.length;
        switch([text characterAtIndex:i]) {
            case 0x2190:
            case 0x2192:
            case 0x2194:
            case 0x21D0:
                if(arrowFont && i < text.length - 1 && [text characterAtIndex:i+1] == 0xFE0E) {
                    [arrowIndex addObject:@(i)];
                }
                break;
            case 0x202f:
                [thinSpaceIndex addObject:@(i)];
                break;
            case BOLD:
                if(bold == -1) {
                    bold = i;
                } else {
                    if(mono != -1) {
                        [self setFont:Courier start:mono length:(bold - mono) attributes:attributes];
                        mono = i;
                    }
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
                if(italics == -1) {
                    italics = i;
                } else {
                    if(mono != -1) {
                        [self setFont:Courier start:mono length:(italics - mono) attributes:attributes];
                        mono = i;
                    }
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
            case MONO:
                if(mono == -1) {
                    mono = i;
                    boldFont = CourierBold;
                    italicFont = CourierOblique;
                    boldItalicFont = CourierBoldOblique;
                    if(!fgColor && !bgColor) {
                        fg = bg = i;
                        fgColor = [UIColor codeSpanForegroundColor];
                        bgColor = [UIColor codeSpanBackgroundColor];
                    }
                } else {
                    [self setFont:Courier start:mono length:(i - mono) attributes:attributes];
                    if(!monospace) {
                        boldFont = HelveticaBold;
                        italicFont = HelveticaOblique;
                        boldItalicFont = HelveticaBoldOblique;
                    }
                    if(fg >= mono || bg >= mono) {
                        if(fgColor)
                            [attributes addObject:@{
                                                NSBackgroundColorAttributeName:fgColor,
                                                @"start":@(fg),
                                                @"length":@(i - fg)
                                                }];
                        if(bgColor)
                            [attributes addObject:@{
                                                NSBackgroundColorAttributeName:bgColor,
                                                @"start":@(bg),
                                                @"length":@(i - bg)
                                                }];
                        fgColor = bgColor = nil;
                        fg = bg = -1;
                    }
                    mono = -1;
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
            case STRIKETHROUGH:
                if(strike == -1) {
                    strike = i;
                } else {
                    [attributes addObject:@{
                                            NSStrikethroughStyleAttributeName:@1,
                                            @"start":@(strike),
                                            @"length":@(i - strike)
                                            }];
                    strike = -1;
                }
                [text deleteCharactersInRange:NSMakeRange(i,1)];
                i--;
                continue;
            case REVERSE:
            case 0x12:
                if(fg != -1 && fgColor)
                        [attributes addObject:@{
                                                NSForegroundColorAttributeName:fgColor,
                                                @"start":@(fg),
                                                @"length":@(i - fg)
                                                }];
                if(bg != -1 && bgColor)
                        [attributes addObject:@{
                                                NSBackgroundColorAttributeName:bgColor,
                                                @"start":@(bg),
                                                @"length":@(i - bg)
                                                }];
                
                fg = bg = i;
                oldFgColor = fgColor;
                fgColor = bgColor;
                bgColor = oldFgColor;
                if(!fgColor)
                    fgColor = [UIColor mIRCColor:[UIColor isDarkTheme]?1:0 background:NO];
                if(!bgColor)
                    bgColor = [UIColor mIRCColor:[UIColor isDarkTheme]?0:1 background:YES];
                [text deleteCharactersInRange:NSMakeRange(i,1)];
                i--;
                continue;
            case COLOR_MIRC:
            case COLOR_RGB:
                oldFgColor = fgColor;
                oldBgColor = bgColor;
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
                            if(fg_color > IRC_COLOR_COUNT) {
                                count--;
                                fg_color /= 10;
                            } else if(fg_color == 99) {
                                fg_color = -1;
                                fgColor = nil;
                            }
                        } else {
                            fgColor = [UIColor colorFromHexString:[text substringWithRange:NSMakeRange(i, count)]];
                            fg_color = -1;
                        }
                        if(fg != -1 && !stripColors) {
                            if(oldFgColor)
                                [attributes addObject:@{
                                                        NSForegroundColorAttributeName:oldFgColor,
                                                        @"start":@(fg),
                                                        @"length":@(i - fg)
                                                        }];
                        }
                        [text deleteCharactersInRange:NSMakeRange(i,count)];
                        fg = i;
                    } else {
                        fgColor = nil;
                        bgColor = nil;
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
                            if(color > IRC_COLOR_COUNT) {
                                count--;
                                color /= 10;
                            }
                            if(color == 99) {
                                bgColor = nil;
                            } else {
                                bgColor = [UIColor mIRCColor:color background:YES];
                            }
                        } else {
                            bgColor = [UIColor colorFromHexString:[text substringWithRange:NSMakeRange(i, count)]];
                        }
                        if(bg != -1) {
                            if(oldBgColor && !stripColors)
                                [attributes addObject:@{
                                                        NSBackgroundColorAttributeName:oldBgColor,
                                                        @"start":@(bg),
                                                        @"length":@(i - bg)
                                                        }];
                        }
                        [text deleteCharactersInRange:NSMakeRange(i,count)];
                        bg = i;
                    } else {
                        [text insertString:@"," atIndex:i];
                    }
                }
                if(fg_color != -1)
                    fgColor = [UIColor mIRCColor:fg_color background:bgColor != nil];
                if(fg != -1 && fgColor == nil) {
                    if(oldFgColor && !stripColors)
                        [attributes addObject:@{
                                                NSForegroundColorAttributeName:oldFgColor,
                                                @"start":@(fg),
                                                @"length":@(i - fg)
                                                }];
                    fg = -1;
                }
                if(bg != -1 && bgColor == nil) {
                    if(oldBgColor && !stripColors)
                        [attributes addObject:@{
                                                NSBackgroundColorAttributeName:oldBgColor,
                                                @"start":@(bg),
                                                @"length":@(i - bg)
                                                }];
                    bg = -1;
                }
                i--;
                continue;
            case CLEAR:
                if(fg != -1 && !stripColors) {
                    [attributes addObject:@{
                     NSForegroundColorAttributeName:fgColor,
                     @"start":@(fg),
                     @"length":@(i - fg)
                     }];
                }
                fg = -1;
                if(bg != -1 && !stripColors) {
                    [attributes addObject:@{
                     NSBackgroundColorAttributeName:bgColor,
                     @"start":@(bg),
                     @"length":@(i - bg)
                     }];
                }
                bg = -1;
                if(mono != -1) {
                    [self setFont:Courier start:mono length:(i - mono) attributes:attributes];
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
                }
                if(underline != -1) {
                    [attributes addObject:@{
                     NSUnderlineStyleAttributeName:@1,
                     @"start":@(underline),
                     @"length":@(i - underline)
                     }];
                }
                if(strike != -1) {
                    [attributes addObject:@{
                                            NSStrikethroughStyleAttributeName:@1,
                                            @"start":@(strike),
                                            @"length":@(i - strike)
                                            }];
                }
                bold = italics = underline = mono = strike = -1;
                if(!monospace) {
                    boldFont = HelveticaBold;
                    italicFont = HelveticaOblique;
                    boldItalicFont = HelveticaBoldOblique;
                }
                [text deleteCharactersInRange:NSMakeRange(i,1)];
                i--;
                continue;
        }
    }
    
    NSMutableAttributedString *output = [[NSMutableAttributedString alloc] initWithString:text];
    [output addAttributes:@{NSFontAttributeName:font} range:NSMakeRange(0, text.length)];
    if(color)
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
    [output addAttribute:NSParagraphStyleAttributeName value:paragraphStyle range:NSMakeRange(0, [output length])];
    
    for(NSDictionary *dict in attributes) {
        if([[dict objectForKey:@"start"] intValue] >= 0 && [[dict objectForKey:@"length"] intValue] > 0)
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
        results = [[self geo] matchesInString:[[output string] lowercaseString] options:0 range:NSMakeRange(0, [output length])];
        for(NSTextCheckingResult *result in results) {
            NSString *url = [NSString stringWithFormat:@"http://maps.apple.com/?ll=%@",[[output string] substringWithRange:NSMakeRange(result.range.location+4, result.range.length-4)]];
            [matches addObject:[NSTextCheckingResult linkCheckingResultWithRange:result.range URL:[NSURL URLWithString:url]]];
        }
        if(server) {
            results = [[self ircChannelRegexForServer:server] matchesInString:[[output string] lowercaseString] options:0 range:NSMakeRange(0, [output length])];
            if(results.count) {
                for(NSTextCheckingResult *match in results) {
                    NSRange matchRange = [match rangeAtIndex:2];
                    unichar lastChar = [[output string] characterAtIndex:matchRange.location + matchRange.length - 1];
                    if([self unbalanced:[output.string substringWithRange:matchRange]] || lastChar == '.' || lastChar == '?' || lastChar == '!' || lastChar == ',' || lastChar == ':' || lastChar == ';') {
                        matchRange.length--;
                    }
                    if(matchRange.length > 1) {
                        NSRange ranges[1] = {NSMakeRange(matchRange.location, matchRange.length)};
                        [matches addObject:[NSTextCheckingResult regularExpressionCheckingResultWithRanges:ranges count:1 regularExpression:match.regularExpression]];
                    }
                }
            }
        }
        [matches addObjectsFromArray:[self webURLs:output.string]];
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
        if(![text isEmojiOnly]) {
            for(; start < text.length; start++)
                if([[text substringFromIndex:start] isEmojiOnly])
                    break;
        }
        
        [output addAttributes:@{NSFontAttributeName:largeEmojiFont} range:NSMakeRange(start, text.length - start)];
    }
    
    for(NSNumber *i in thinSpaceIndex) {
        [output addAttributes:@{NSFontAttributeName:Helvetica} range:NSMakeRange([i intValue], 1)];
    }
    
    if(mentions) {
        for(NSString *nick in mentions.allKeys) {
            NSArray *mention = [mentions objectForKey:nick];
            for(int i = 0; i < mention.count; i++) {
                int start = [[[mention objectAtIndex:i] objectAtIndex:0] intValue];
                int length = [[[mention objectAtIndex:i] objectAtIndex:1] intValue];
                NSString *name = nick;
                if(start > 0 && start < output.string.length && [output.string characterAtIndex:start-1] == '@') {
                    if([mentionData objectForKey:nick])
                        name = [[mentionData objectForKey:nick] objectForKey:@"display_name"];
                    else if(server.isSlack)
                        name = [[UsersDataSource sharedInstance] getDisplayName:nick cid:server.cid];
                    if(!name)
                        name = nick;
                }
                if(!name || start < 0 || start + length >= (output.length + 1))
                    continue;
                [output replaceCharactersInRange:NSMakeRange(start, length) withString:name];
                if(colorizeMentions && ![nick.lowercaseString isEqualToString:server.nick.lowercaseString]) {
                    [output addAttribute:NSForegroundColorAttributeName value:[UIColor colorFromHexString:[UIColor colorForNick:nick]] range:NSMakeRange(start, name.length)];
                } else {
                    [output addAttribute:NSForegroundColorAttributeName value:[UIColor collapsedRowNickColor] range:NSMakeRange(start, name.length)];
                }
                NSInteger delta = nick.length - name.length;
                if(delta) {
                    [self _offsetMentions:mentions start:start offset:delta];
                }
            }
        }
    }

    return output;
}

+(NSString *)toIRC:(NSAttributedString *)string {
    NSString *text = string.string;
    NSMutableString *formattedMsg = [[NSMutableString alloc] init];
    
    int index = 0;
    NSRange range;
    while(index < string.length) {
        BOOL shouldClear = NO;
        for(NSString *key in [string attributesAtIndex:index effectiveRange:&range]) {
            NSString *fgColor = nil;
            NSString *bgColor = nil;
            int fgColormIRC = -1;
            int bgColormIRC = -1;
            if([key isEqualToString:NSFontAttributeName]) {
                UIFont *font = [string attribute:key atIndex:index effectiveRange:nil];
                if(font.fontDescriptor.symbolicTraits & UIFontDescriptorTraitBold && ![[font.fontDescriptor objectForKey:@"NSCTFontUIUsageAttribute"] isEqualToString:@"CTFontRegularUsage"] && ![[font.fontDescriptor objectForKey:@"NSCTFontUIUsageAttribute"] isEqualToString:@"UICTFontTextStyleBody"]) {
                    [formattedMsg appendFormat:@"%c", BOLD];
                    shouldClear = YES;
                }
                if(font.fontDescriptor.symbolicTraits & UIFontDescriptorTraitItalic) {
                    [formattedMsg appendFormat:@"%c", ITALICS];
                    shouldClear = YES;
                }
            } else if([key isEqualToString:NSUnderlineStyleAttributeName]) {
                NSNumber *style = [string attribute:key atIndex:index effectiveRange:nil];
                if(style.integerValue != NSUnderlineStyleNone)
                    [formattedMsg appendFormat:@"%c", UNDERLINE];
                shouldClear = YES;
            } else if([key isEqualToString:NSStrikethroughStyleAttributeName]) {
                [formattedMsg appendFormat:@"%c", STRIKETHROUGH];
                shouldClear = YES;
            } else if([key isEqualToString:NSForegroundColorAttributeName]) {
                UIColor *c = [string attribute:key atIndex:index effectiveRange:nil];
                if(![c isEqual:[UIColor textareaTextColor]]) {
                    fgColor = [c toHexString];
                    fgColormIRC = [UIColor mIRCColor:c];
                }
            } else if([key isEqualToString:NSBackgroundColorAttributeName]) {
                UIColor *c = [string attribute:key atIndex:index effectiveRange:nil];
                if(![c isEqual:[UIColor textareaTextColor]]) {
                    bgColor = [c toHexString];
                    bgColormIRC = [UIColor mIRCColor:c];
                }
            }
            
            if(fgColor || bgColor) {
                if((fgColormIRC != -1 && (!bgColor || bgColormIRC != -1)) || (!fgColor && bgColormIRC != -1)) {
                    [formattedMsg appendFormat:@"%c", COLOR_MIRC];
                    if(fgColormIRC != -1)
                        [formattedMsg appendFormat:@"%i",fgColormIRC];
                    if(bgColormIRC != -1)
                        [formattedMsg appendFormat:@",%i",bgColormIRC];
                } else {
                    [formattedMsg appendFormat:@"%c", COLOR_RGB];
                    if(fgColor)
                        [formattedMsg appendString:fgColor];
                    if(bgColor)
                        [formattedMsg appendFormat:@",%@",bgColor];
                }
                shouldClear = YES;
            }
        }
        
        if(shouldClear)
            [formattedMsg appendFormat:@"%@%c", [text substringWithRange:range], CLEAR];
        else
            [formattedMsg appendString:[text substringWithRange:range]];

        index += range.length;
    }
    
    return formattedMsg;
}

+(NSAttributedString *)stripUnsupportedAttributes:(NSAttributedString *)input fontSize:(CGFloat)fontSize {
    NSMutableAttributedString *output = [[NSMutableAttributedString alloc] initWithString:input.string];
    [output addAttribute:NSForegroundColorAttributeName value:[UIColor messageTextColor] range:NSMakeRange(0, input.length)];
    
    int index = 0;
    NSRange range;
    while(index < input.length) {
        for(NSString *key in [input attributesAtIndex:index effectiveRange:&range]) {
            if([key isEqualToString:NSFontAttributeName]) {
                UIFont *font = [input attribute:key atIndex:index effectiveRange:nil];
                [output addAttribute:key value:[UIFont fontWithDescriptor:font.fontDescriptor size:fontSize] range:range];
            } else if([key isEqualToString:NSForegroundColorAttributeName] || [key isEqualToString:NSBackgroundColorAttributeName]) {
                UIColor *c = [input attribute:key atIndex:index effectiveRange:nil];
                CGFloat r,g,b,a;
                [c getRed:&r green:&g blue:&b alpha:&a];
                if([key isEqualToString:NSForegroundColorAttributeName] && (r > 0 || g > 0 || b > 0)) {
                    [output addAttribute:key value:c range:range];
                }
                if([key isEqualToString:NSBackgroundColorAttributeName] && !(r == 1 && g == 1 && b == 1)) {
                    [output addAttribute:key value:c range:range];
                }
            } else if([key isEqualToString:NSUnderlineStyleAttributeName] || [key isEqualToString:NSStrikethroughStyleAttributeName]) {
                [output addAttribute:key value:[input attribute:key atIndex:index effectiveRange:nil] range:range];
            }
        }
        index += range.length;
    }
    
    return output;
}

+(NSArray *)webURLs:(NSString *)string {
    NSMutableArray *matches = [[NSMutableArray alloc] init];
    static NSMutableCharacterSet *urlSet = nil;
    @synchronized (self) {
        if(!urlSet) {
            urlSet = NSCharacterSet.URLQueryAllowedCharacterSet.mutableCopy;
            [urlSet addCharactersInString:@"#%"];
        }
    }
    
    if(string.length) {
        NSArray *results = [[self webURL] matchesInString:string.lowercaseString options:0 range:NSMakeRange(0, string.length)];
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
                if(range.location + range.length < string.length && [string characterAtIndex:range.location + range.length - 1] != '/' && [string characterAtIndex:range.location + range.length] == '/')
                    range.length++;
                NSString *url = [string substringWithRange:result.range];
                if([url hasSuffix:@"."] || [url hasSuffix:@"?"] || [url hasSuffix:@"!"] || [url hasSuffix:@","] || [url hasSuffix:@":"] || [url hasSuffix:@";"]) {
                    url = [url substringToIndex:url.length - 1];
                    range.length--;
                }
                if([self unbalanced:url]) {
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
                
                url = [[NSString stringWithFormat:@"%@://%@%@%@", scheme, credentials, hostname, rest] stringByAddingPercentEncodingWithAllowedCharacters:urlSet];
                
                if([ipAddress evaluateWithObject:url]) {
                    continue;
                }
                
                [matches addObject:[NSTextCheckingResult linkCheckingResultWithRange:range URL:[NSURL URLWithString:url]]];
            }
        }
        
        results = [[NSDataDetector dataDetectorWithTypes:NSTextCheckingTypePhoneNumber|NSTextCheckingTypeAddress error:nil] matchesInString:string options:0 range:NSMakeRange(0, string.length)];
        for(NSTextCheckingResult *result in results) {
            NSString *url = nil;
            switch (result.resultType) {
                case NSTextCheckingTypePhoneNumber:
                    url = [NSString stringWithFormat:@"telprompt:%@", [result.phoneNumber stringByReplacingOccurrencesOfString:@" " withString:@""]];
                    break;
                case NSTextCheckingTypeAddress:
                    url = [NSString stringWithFormat:@"https://maps.apple.com/?address=%@", [result.addressComponents.allValues componentsJoinedByString:@","]];
                    break;
                default:
                    break;
            }
            
            if(url) {
                url = [url stringByAddingPercentEncodingWithAllowedCharacters:urlSet];
                [matches addObject:[NSTextCheckingResult linkCheckingResultWithRange:result.range URL:[NSURL URLWithString:url]]];
                url = nil;
            }
        }

    }
    return matches;
}
@end

@implementation NSString (ColorFormatter)
-(NSString *)stripIRCFormatting {
    return [[ColorFormatter format:self defaultColor:[UIColor blackColor] mono:NO linkify:NO server:nil links:nil] string];
}
-(NSString *)stripIRCColors {
    NSMutableString *text = self.mutableCopy;
    BOOL rgb;
    int fg_color;
    
    for(int i = 0; i < text.length; i++) {
        switch([text characterAtIndex:i]) {
            case COLOR_MIRC:
            case COLOR_RGB:
                rgb = [text characterAtIndex:i] == COLOR_RGB;
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
                            fg_color = [[text substringWithRange:NSMakeRange(i, count)] intValue];
                            if(fg_color > IRC_COLOR_COUNT) {
                                count--;
                            }
                        }
                        [text deleteCharactersInRange:NSMakeRange(i,count)];
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
                            if(color > IRC_COLOR_COUNT) {
                                count--;
                            }
                        }
                        [text deleteCharactersInRange:NSMakeRange(i,count)];
                    } else {
                        [text insertString:@"," atIndex:i];
                    }
                }
                i--;
                continue;
        }
    }
    return text;
}
-(BOOL)isEmojiOnly {
    if(!self || !self.length)
        return NO;
    
    return [[ColorFormatter emojiOnlyPattern] stringByReplacingMatchesInString:self options:0 range:NSMakeRange(0, self.length) withTemplate:@""].length == 0;
}
-(BOOL)isBlockQuote {
    @synchronized (self) {
        static NSPredicate *_pattern;
        if(!_pattern) {
            _pattern = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"(^|\\n)>(?![<>]|[\\W_](?:[<>/OoDpb|\\\\{}()\\[\\]](?=\\s|$)))([^\\n]+)"];
        }
        return [_pattern evaluateWithObject:self];
    }
}
-(NSString *)insertCodeSpans {
    static NSRegularExpression *_pattern = nil;
    @synchronized (self) {
        if(!_pattern) {
            NSString *pattern = @"`([^`\\n]+?)`";
            _pattern = [NSRegularExpression
                        regularExpressionWithPattern:pattern
                        options:NSRegularExpressionCaseInsensitive
                        error:nil];
        }
    }
    NSMutableString *output = self.mutableCopy;
    NSArray *result = [_pattern matchesInString:self options:0 range:NSMakeRange(0, self.length)];
    while(result.count) {
        NSRange range = [[result objectAtIndex:0] range];
        [output replaceCharactersInRange:NSMakeRange(range.location, 1) withString:[NSString stringWithFormat:@"%c", MONO]];
        [output replaceCharactersInRange:NSMakeRange(range.location + range.length - 1, 1) withString:[NSString stringWithFormat:@"%c", MONO]];
        result = [_pattern matchesInString:self options:0 range:NSMakeRange(range.location + range.length, self.length - range.location - range.length)];
    }
    return output;
}
@end
