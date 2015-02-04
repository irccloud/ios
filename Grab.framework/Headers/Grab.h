//
//  Grab.h
//
//  Created by Alex Lewis on 10/3/12.
//
//

/**
 * @Grab.h
 * Contains Grab
 */

#import <Foundation/Foundation.h>

// it has to be defined in the plist as part of the build process
// plist hard-coded to be 0.0.0
// but we don't want that, we want the real version
#ifdef GA_SDK_VERSION
#undef GA_SDK_VERSION
#endif
#define GA_SDK_VERSION @"iOS_3.0.5"

#define LOGGING_NONE	0
#define LOGGING_ERROR	1
#define LOGGING_WARNING	2
#define LOGGING_INFO	3
#define LOGGING_DEBUG	4

//#define GA_LOCAL
//#define GA_DEV
//#define GA_STAGING
#define GA_LIVE

#define GA_KEY_STORE_NAME @"Grab_store"
#define GA_USER_TAGS_KEY_STORE_NAME @"Grab_userTags"
#define GA_KEY_REF_CODE @"gaRefCodeId"
#define GA_KEY_POSTINSTALL_ID @"gaPostInstallId"
#define GA_KEY_JSON_POSTINSTALL_ID @"postInstallId"
#define GA_KEY_JSON_REFCODE @"refCode"
#define GA_KEY_ADVERTISING_IDENTIFIER @"gaAdvertisingIdentifier"
#define GA_KEY_IDENTIFIER_FOR_VENDOR @"gaIdentifierForVendor"
#define GA_KEY_ADVERTISING_TRACKING_ENABLED @"gaAdvertisingTrackinEnabled"
#define GA_KEY_UUID @"gaUUID"
#define GA_KEY_QUEUE_COUNT @"gaKeyQueueCount"
#define GA_KEY_QUEUE_JSON @"gaKeyQueueJSON"
#define OFFLINE_SLOTS 500

#define GA_VALUE_ADVERTISING_TRACKING_ENABLED @"1"
#define GA_VALUE_ADVERTISING_TRACKING_DISABLED @"0"
#define GA_VALUE_TEST_REFCODE @"lexRef"
#define GA_VALUE_NO_REFCODE @"empty"
#define GA_VALUE_EMPTY_STRING @""
#define GA_VALUE_TRUE @"TRUE"
#define GA_VALUE_FALSE @"FALSE"
#define GA_VALUE_PLATFORM_IOS @"ios"

#define GA_TARGET_REFERRAL @"referral"
#define GA_TARGET_SETTINGS @"settings"
#define GA_ACTION_REFERRAL_TRACKING @"refTrack"
#define GA_ACTION_POST_INSTALL @"postInstall"

#ifdef GA_LOCAL
#define GA_GATEWAY_URL GA_GATEWAY_URL_LOCAL
#elif defined GA_DEV
#define GA_GATEWAY_URL GA_GATEWAY_URL_DEV
#elif defined GA_STAGING
#define GA_GATEWAY_URL GA_GATEWAY_URL_STAGING
#elif defined GA_LIVE
#define GA_GATEWAY_URL GA_GATEWAY_URL_LIVE
#endif

#define GA_GATEWAY_URL_LOCAL @"http://10.0.11.217:3001"
#define GA_GATEWAY_URL_DEV @"https://dev1.grab-apps.com:3001"
#define GA_GATEWAY_URL_STAGING @"https://amp-stage.grab-apps.com:3001"
#define GA_GATEWAY_URL_LIVE @"https://grabanalytics.grab-apps.com:3001"

#define MIN_BATCH_DELAY 10
#define DEFAULT_BATCH_DELAY 30
#define CONNECTION_TIMEOUT 5.0

@interface Grab : NSObject
{
}

/**
 * Initializes the SDK with the secret provided by Grab and allows for overriding send interval and max storage
 *
 * @param NSString* secret
 *   An NSString of the Grab Secret
 *
 * @param int sendInterval
 *   An integer to specify analytic sending interval in seconds (must be >= 10, default 30)
 *
 * @param long maxStorageBytes
 *   A long integer to specify the maximum amount of offline storage in case of network failure (default 2000000)
 */
+ (void) initWithSecret:(NSString*)sec sendInterval:(int)interval maxStorageBytes:(long)storage;

/**
 * Initializes the SDK with the Secret provided by Grab. This is the default init function.
 *
 * @param NSString* secret
 *   An NSString of the Grab Secret
 *
 */
+ (void) initWithSecret:(NSString*)sec;


/**
 * Initializes the SDK with the secret provided by Grab and allows for overriding the analytics server URL (for Grab internal debug only).
 *
 * @param NSString* secret
 *   An NSString of the Grab Secret
 *
 * @param int sendInterval
 *   An integer to specify analytic sending interval in seconds (must be >= 10, default 30)
 *
 * @param long maxStorageBytes
 *   A long integer to specify the maximum amount of offline storage in case of network failure (default 2000000)
 *
 * @param NSString* url
 *   A url for the Grab gateway that will override the live URL.  Use this init for testing
 *
 */
+ (void) initWithSecret:(NSString *)sec sendInterval:(int)interval maxStorageBytes:(long)storage gatewayURL:(NSString*)url;

/**
 * Used to send in-app purchase analytic in addition to verifying receipt on the server. This is sent automatically be default.
 * 
 * @param NSString* receipt
 *		base64EncodedString transaction receipt (from SKPaymentTransaction) after purchase completion
 *
 * @param NSDecimalNumber* price
 *		Price of the item at purchase, since this cannot be fetched server-side.
 * 
 * @param NSDictionary* data
 *		Other custom data to be tracked along with the in-app purchase analytic. 
 *		e.g. Location in app where purchase took place. 
 */
+ (void) verifyInAppPurchase:(NSString*)receipt productId:(NSString*)pid data:(NSMutableDictionary*)data;

/**
 * Used to report custom analytic data
 *
 * @param NSString* name
 *      The identifying name for the custom event
 *
 * @param NSMutableDictionary* data
 *      A dictionary of key,value pairs related to the custom event. They key 'grabEventName' is reserved and cannot be used.
 **/
+ (void) customEvent:(NSString*)name data:(NSMutableDictionary*)data;

/**
 * Used for reporting specifically the first time a user successfully registers for your app
 *
 * @param _method the registration method (example "Facebook", "Twitter", "e-mail", etc)
 *
 */
+ (void) signUp:(NSString*)method;

/**
 * Used for reporting any time a user successfully logs in to your app
 *
 * @param _method the login method (example "Facebook", "Twitter", "e-mail", etc)
 *
 */
+ (void) login:(NSString*)method;

/**
 * Used for reporting when a user achieves a specific level,
 *
 * @param _level the level achieved (example "5", or "Captain")
 *
 */
+ (void) levelAchieved:(NSString*)level;

/**
 * Used for reporting when a user adds payment info
 *
 */
+ (void) addedPaymentInfo;

/**
 * Used for reporting when a user adds an item to a shopping cart
 *
 * @param _id an id for the item being added
 * @param _type the type of item being added
 * @param _currency the currency of the item's price (example "USD", or "EUR)
 * @param _price the price of the item (example "2.99", or "100")
 *
 */
+ (void) addToCart:(NSString*)contentId type:(NSString*)type currency:(NSString*)currency price:(NSString*)price;

/**
 * Used for reporting when a user adds an item to a wishlist
 *
 * @param _id an id for the item being added
 * @param _type the type of item being added
 * @param _currency the currency of the item's price (example "USD", or "EUR)
 * @param _price the price of the item (example "2.99", or "100")
 *
 */
+ (void) addToWishlist:(NSString*)contentId type:(NSString*)type currency:(NSString*)currency price:(NSString*)price;

/**
 * Used for reporting whenever a user completes a tutorial
 *
 * @param _id an id for the tutorial (example "1" or "Tutorial 1")
 *
 */
+ (void) tutorialComplete:(NSString*)contentId;

/**
 * Used for reporting when a user proceeds to a checkout section of your app
 *
 * @param _id an id for the checkout
 * @param _type a type for the checkout
 * @param _numItems the number of items being purchased
 * @param _currency the currency of the checkouts price (example "USD", or "EUR)
 * @param _paymentInfo a flag to indicate if payment info is available
 *
 */
+ (void) checkoutInitiated:(NSString*)contentId type:(NSString*)type numItems:(NSString*)numItems currency:(NSString*)currency paymentInfo:(bool)paymentInfo;

/**
 * Used for reporting when a user rates your app
 *
 * @param _id an id for the rating
 * @param _type a type for the rating
 * @param _maxRating the maximum rating value
 *
 */
+ (void) rated:(NSString*)contentId type:(NSString*)type maxRating:(NSString*)maxRating;

/**
 * Used for reporting when a user views specific content
 *
 * @param _id an id for the content being viewed
 * @param _type the type of content being viewed
 * @param _currency the currency of the content being viewed (example "USD", or "EUR)
 * @param _price the price of the content being viewed (example "2.99", or "100")
 *
 */
+ (void) contentView:(NSString*)contentId type:(NSString*)type currency:(NSString*)currency price:(NSString*)price;

/**
 * Used for reporting when a user unlocks a specific achievement
 *
 * @param _id an id for the achievement unlocked
 * @param _type the type of achievement unlocked
 * @param _currency the currency of the achievement unlocked (example "USD", or "EUR)
 * @param _desc a description of the achievement unlocked
 *
 */
+ (void) achievementUnlocked:(NSString*)contentId type:(NSString*)type currency:(NSString*)currency desc:(NSString*)desc;

/**
 * Used for reporting when a user spends in-app credits
 *
 * @param _id an id for the spend
 * @param _type a type for the spend
 * @param _value the number of credits spent
 *
 */
+ (void) spentCredits:(NSString*)contentId type:(NSString*)type value:(NSString*)value;

/**
 * Used for reporting when a user searches within your app
 *
 * @param _type a type for the search
 * @param _string the string being searched for
 *
 */
+ (void) search:(NSString*)type string:(NSString*)string;

/**
 * Used for reporting when a user makes a reservation within your app
 *
 * @param _date the date of the reservation
 *
 */
+ (void) reservation:(NSString*)date;

/**
 * Used for reporting when a user shares content from within your app
 *
 * @param _id an id for the share
 * @param _type the type of share
 *
 */
+ (void) share:(NSString*)contentId type:(NSString*)type;

/**
 * Used for reporting when a user sends an invite
 *
 * @param _id an id for the invite
 * @param _type the type of invite
 *
 */
+ (void) invite:(NSString*)contentId type:(NSString*)type;

/**
 * Used to toggle automatic/manual dispatch of verify receipt and analytics for in-app purchases. This is enabled for automatic handling by default. 
 * 
 * @param bool true for automatic receipt verification and analytic tracking of in-app purchases, false otherwise
 */
+ (void) setAutomaticInAppPurchaseTracking:(bool)automatic;

/**
 * Used to pre-fetch data about the given in-app purchase product ID for observing purchases and tracking analytics around that product ID. If the product is purchased, the data will be automatically fetched before receipt verification and analytics reporting is performed. 
 *
 * @param NSString* in-app purchase product ID
 */
+ (void) registerInAppPurchaseProductId:(NSString*)productId;

/**
 * Used to set level of logging output in the console. Default is LOGGING_LEVEL_NONE (0).
 *
 * @param int loggingLevel to correspond to LOGGING_LEVEL_XXX (top of this header file)
 */
+ (void) setLoggingLevel:(int)loggingLevel;

+ (void) appendGAV:(NSString*)append;


@end


// static stuff
/*! @cond PRIVATE */
@interface Grab (Private) // private methods

- (void) connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
- (void) connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
- (void) connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
- (void) connectionDidFinishLoading:(NSURLConnection *)connection;
- (void) receiveSystemEvent:(NSNotification*)event;

+ (NSString*) deviceName;
+ (NSString*) advertisingIdentifier;
+ (NSString*) identifierForVendor;
+ (NSString*) advertisingTrackingEnabled;
+ (NSString*) ODIN;
+ (NSString*) OUDID;
+ (NSString*) UUID;
+ (NSString*) loadString:(NSString*)key defaultValue:(NSString*)val;
+ (NSString*) doSHA1:(NSString*)input;
+ (NSString*) genSigStr:(NSString*)str;
+ (NSString*) genTsStr;
+ (NSMutableDictionary*) getTagsForAnalytics;

+ (void) postInstall;
+ (void) reEngage;
+ (void) saveAnalQueue;
+ (void) loadAnalQueue;
+ (void) flushAnalQueue;
+ (int) loadInt:(NSString*)key defaultValue:(int)val;
+ (void) saveString:(NSString*)key value:(NSString*)val;
+ (void) saveInt:(NSString*)key value:(int)val;
+ (void) cleanup;
+ (void) sendAnalyticWithType:(NSString*)type data:(NSMutableDictionary*)data;
+ (NSString*) char2hex:(char)dec;
+ (NSString*) urlEncode:(NSString*)str;
+ (void) log:(NSString*)toLog forLevel:(int)level;
+ (BOOL) isOnline;
//sessions
+ (void) sessionStart:(NSString*)evt;
+ (void) sessionEnd:(NSString*)evt;

//batching
+ (void) analyticTimerTask:(NSTimer*)timer;

@end
/*! @endcond */
