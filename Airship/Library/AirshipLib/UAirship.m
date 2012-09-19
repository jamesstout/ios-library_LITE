/*
Copyright 2009-2012 Urban Airship Inc. All rights reserved.

Redistribution and use in source and binary forms, with or without
modification, are permitted provided that the following conditions are met:

1. Redistributions of source code must retain the above copyright notice, this
list of conditions and the following disclaimer.

2. Redistributions in binaryform must reproduce the above copyright notice,
this list of conditions and the following disclaimer in the documentation
and/or other materials provided withthe distribution.

THIS SOFTWARE IS PROVIDED BY THE URBAN AIRSHIP INC``AS IS'' AND ANY EXPRESS OR
IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO
EVENT SHALL URBAN AIRSHIP INC OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT,
INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF
LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE
OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#import "UAirship.h"
#import "UAirship+Internal.h"

#import "UA_ASIHTTPRequest.h"
#import "UA_SBJSON.h"

#import "UAUser.h"
#import "UAEvent.h"
#import "UAUtils.h"
#import "UAKeychainUtils.h"
#import "UAGlobal.h"
#import "UAPush.h"

UA_VERSION_IMPLEMENTATION(AirshipVersion, UA_VERSION)
NSString * const UAirshipTakeOffOptionsAirshipConfigKey = @"UAirshipTakeOffOptionsAirshipConfigKey";
NSString * const UAirshipTakeOffOptionsLaunchOptionsKey = @"UAirshipTakeOffOptionsLaunchOptionsKey";
NSString * const UAirshipTakeOffOptionsDefaultUsernameKey = @"UAirshipTakeOffOptionsDefaultUsernameKey";
NSString * const UAirshipTakeOffOptionsDefaultPasswordKey = @"UAirshipTakeOffOptionsDefaultPasswordKey";

//Exceptions
NSString * const UAirshipTakeOffBackgroundThreadException = @"UAirshipTakeOffBackgroundThreadException";

static UAirship *_sharedAirship;
BOOL logging = false;

@implementation UAirship

@synthesize server;
@synthesize appId;
@synthesize appSecret;
@synthesize deviceTokenHasChanged;
@synthesize ready;

#pragma mark -
#pragma mark Logging
+ (void)setLogging:(BOOL)value {
    logging = value;
}



#pragma mark -
#pragma mark Object Lifecycle
- (void)dealloc {
    RELEASE_SAFELY(appId);
    RELEASE_SAFELY(appSecret);
    RELEASE_SAFELY(server);
    // before dealloc
    [super dealloc];
}

- (id)initWithId:(NSString *)appkey identifiedBy:(NSString *)secret {
    if (self = [super init]) {
        self.appId = appkey;
        self.appSecret = secret;
    }
    return self;
}

+ (void)takeOff:(NSDictionary *)options {
    // UAirship needs to be run on the main thread
    if(![[NSThread currentThread] isMainThread]){
        NSException *mainThreadException = [NSException exceptionWithName:UAirshipTakeOffBackgroundThreadException
                                                                   reason:@"UAirship takeOff must be called on the main thread."
                                                                 userInfo:nil];
        [mainThreadException raise];
    }
    //Airships only take off once!
    if (_sharedAirship) {
        return;
    }
    //Application launch options
    //NSDictionary *launchOptions = [options objectForKey:UAirshipTakeOffOptionsLaunchOptionsKey];
    
    // I don't want any UA requests to set the network activity indicator
    [UA_ASIHTTPRequest setShouldUpdateNetworkActivityIndicator:NO];
    
    
    // Load configuration
    // Primary configuration comes from the UAirshipTakeOffOptionsAirshipConfig dictionary and will
    // override any options defined in AirshipConfig.plist
    NSMutableDictionary *config;
    NSString *configPath = [[NSBundle mainBundle] pathForResource:@"AirshipConfig" ofType:@"plist"];
    
    if (configPath) {
        config = [[[NSMutableDictionary alloc] initWithContentsOfFile:configPath] autorelease];
        [config addEntriesFromDictionary:[options objectForKey:UAirshipTakeOffOptionsAirshipConfigKey]];
    } else {
        config = [NSMutableDictionary dictionaryWithDictionary:[options objectForKey:UAirshipTakeOffOptionsAirshipConfigKey]];
    }

    if ([config count] > 0) {
        
        BOOL inProduction = [[config objectForKey:@"APP_STORE_OR_AD_HOC_BUILD"] boolValue];
        
        NSString *loggingOptions = [config objectForKey:@"LOGGING_ENABLED"];
        
        if (loggingOptions != nil) {
            // If it is present, use it
            [UAirship setLogging:[[config objectForKey:@"LOGGING_ENABLED"] boolValue]];
        } else {
            // If it is missing
            if (inProduction) {
                [UAirship setLogging:NO];
            } else {
                [UAirship setLogging:YES];
            }
        }
        
        NSString *configAppKey;
        NSString *configAppSecret;
        
        if (inProduction) {
            configAppKey = [config objectForKey:@"PRODUCTION_APP_KEY"];
            configAppSecret = [config objectForKey:@"PRODUCTION_APP_SECRET"];
        } else {
            configAppKey = [config objectForKey:@"DEVELOPMENT_APP_KEY"];
            configAppSecret = [config objectForKey:@"DEVELOPMENT_APP_SECRET"];
            
            //set release logging to yes because static lib is built in release mode
            //[UAirship setLogging:YES];
        }
        
        // strip leading and trailing whitespace
        configAppKey = [configAppKey stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        configAppSecret = [configAppSecret stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
        
        //Check for a custom UA server value
        NSString *airshipServer = [config objectForKey:@"AIRSHIP_SERVER"];
        if (airshipServer == nil) {
            airshipServer = kAirshipProductionServer;
        }
        
        _sharedAirship = [[UAirship alloc] initWithId:configAppKey identifiedBy:configAppSecret];
        _sharedAirship.server = airshipServer;
        
        
        //For testing, set this value in AirshipConfig to clear out
        //the keychain credentials, as they will otherwise be persisted
        //even when the application is uninstalled.
        if ([[config objectForKey:@"DELETE_KEYCHAIN_CREDENTIALS"] boolValue]) {
            
            UALOG(@"Deleting the keychain credentials");
            [UAKeychainUtils deleteKeychainValue:[[UAirship shared] appId]];
            
            UALOG(@"Deleting the UA device ID");
            [UAKeychainUtils deleteKeychainValue:kUAKeychainDeviceIDKey];
        }
        
    } else {
        NSString* okStr = @"OK";
        NSString* errorMessage = @"The AirshipConfig.plist file is missing.";
        NSString *errorTitle = @"Error";
        UIAlertView *someError = [[UIAlertView alloc] initWithTitle:errorTitle
                                                            message:errorMessage
                                                           delegate:nil
                                                  cancelButtonTitle:okStr
                                                  otherButtonTitles:nil];
        
        [someError show];
        [someError release];
        
        //Use blank credentials to prevent app from crashing while error msg
        //is displayed
        _sharedAirship = [[UAirship alloc] initWithId:@"" identifiedBy:@""];
        
        return;

    }
    
    UALOG(@"App Key: %@", _sharedAirship.appId);
    UALOG(@"App Secret: %@", _sharedAirship.appSecret);
    UALOG(@"Server: %@", _sharedAirship.server);
    
    
    //Check the format of the app key and password.
    //If they're missing or malformed, stop takeoff
    //and prevent the app from connecting to UA.
    NSPredicate *matchPred = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", @"^\\S{22}+$"];
    BOOL match = [matchPred evaluateWithObject:_sharedAirship.appId] 
                    && [matchPred evaluateWithObject:_sharedAirship.appSecret];  
    
    if (!match) {
        NSString* okStr = @"OK";
        NSString* errorMessage =
            @"Application KEY and/or SECRET not set properly, please"
            " insert your application key from http://go.urbanairship.com into"
            " your AirshipConfig.plist file";
        NSString *errorTitle = @"Error";
        UIAlertView *someError = [[UIAlertView alloc] initWithTitle:errorTitle
                                                            message:errorMessage
                                                           delegate:nil
                                                  cancelButtonTitle:okStr
                                                  otherButtonTitles:nil];
        
        [someError show];
        [someError release];
        return;
        
    }
    
    [_sharedAirship configureUserAgent];
    
    _sharedAirship.ready = true;
    
    //init first event
    
    //Handle custom options
    if (options != nil) {
        
        NSString *defaultUsername = [options valueForKey:UAirshipTakeOffOptionsDefaultUsernameKey];
        NSString *defaultPassword = [options valueForKey:UAirshipTakeOffOptionsDefaultPasswordKey];
        if (defaultUsername != nil && defaultPassword != nil) {
            [UAUser setDefaultUsername:defaultUsername withPassword:defaultPassword];
        }
        
    }
    
    //create/setup user (begin listening for device token changes)
    [[UAUser defaultUser] initializeUser];
}

+ (void)land {

    [[UA_ASIHTTPRequest sharedQueue] cancelAllOperations];
    
	// add app_exit event
	
    //Land the modular libaries first
    [NSClassFromString(@"UAPush") land];
    
    //Land common classes
    [UAUser land];
    
    //Finally, release the airship!
    [_sharedAirship release];
    _sharedAirship = nil;
}

+ (UAirship *)shared {
    if (_sharedAirship == nil) {
        [NSException raise:@"InstanceNotExists"
                    format:@"Attempted to access instance before initializaion. Please call takeOff: first."];
    }
    return _sharedAirship;
}

#pragma mark -
#pragma mark DeviceToken get/set/utils

- (NSString*)deviceToken {
    return [[UAPush shared] deviceToken];
}

- (BOOL)deviceTokenHasChanged {
    return [[UAPush shared] deviceTokenHasChanged];
}

- (void)configureUserAgent
{
    /*
     * [LIB-101] User agent string should be:
     * App 1.0 (iPad; iPhone OS 5.0.1; UALib 1.1.2; <app key>; en_US)
     */
    
    UIDevice *device = [UIDevice currentDevice];
    
    NSBundle *bundle = [NSBundle mainBundle];
    NSDictionary *info = [bundle infoDictionary];
    
    NSString *appName = [info objectForKey:(NSString*)kCFBundleNameKey];
    NSString *appVersion = [info objectForKey:(NSString*)kCFBundleVersionKey];
    
    NSString *deviceModel = [device model];
    NSString *osName = [device systemName];
    NSString *osVersion = [device systemVersion];
    
    NSString *libVersion = [AirshipVersion get];
    NSString *locale = [[NSLocale currentLocale] localeIdentifier];
    
    NSString *userAgent = [NSString stringWithFormat:@"%@ %@ (%@; %@ %@; UALib %@; %@; %@)",
                           appName, appVersion, deviceModel, osName, osVersion, libVersion, appId, locale];
    
    UALOG(@"Setting User-Agent for UA requests to %@", userAgent);
    [UA_ASIHTTPRequest setDefaultUserAgentString:userAgent];
}

#pragma mark -
#pragma mark UAPush Methods


- (void)registerDeviceToken:(NSData *)token {
    [[UAPush shared] registerDeviceToken:token withExtraInfo:nil];
}

- (void)registerDeviceToken:(NSData *)token withAlias:(NSString *)alias {
    [[UAPush shared] registerDeviceToken:token withAlias:alias];
}

- (void)registerDeviceToken:(NSData *)token withExtraInfo:(NSDictionary *)info {
    [[UAPush shared] registerDeviceToken:token withExtraInfo:info];
}

- (void)registerDeviceTokenWithExtraInfo:(NSDictionary *)info {
    [[UAPush shared] registerDeviceTokenWithExtraInfo:info];
}

- (void)unRegisterDeviceToken {
    [[UAPush shared] unRegisterDeviceToken];
}

@end
