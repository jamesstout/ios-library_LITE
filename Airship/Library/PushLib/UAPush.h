/*
 Copyright 2009-2012 Urban Airship Inc. All rights reserved.

 Redistribution and use in source and binary forms, with or without
 modification, are permitted provided that the following conditions are met:

 1. Redistributions of source code must retain the above copyright notice, this
 list of conditions and the following disclaimer.

 2. Redistributions in binary form must reproduce the above copyright notice,
 this list of conditions and the following disclaimer in the documentation
 and/or other materials provided with the distribution.

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

#import "UAGlobal.h"
#import "UAObservable.h"


@class UA_ASIHTTPRequest;

UA_VERSION_INTERFACE(UAPushVersion)


/**
 * Implement this protocol and register with the UAirship shared instance to receive
 * device token registration success and failure callbacks.
 */
@protocol UARegistrationObserver
@optional
- (void)registerDeviceTokenSucceeded;
- (void)registerDeviceTokenFailed:(UA_ASIHTTPRequest *)request;
- (void)unRegisterDeviceTokenSucceeded;
- (void)unRegisterDeviceTokenFailed:(UA_ASIHTTPRequest *)request;
- (void)addTagToDeviceSucceeded;
- (void)addTagToDeviceFailed:(UA_ASIHTTPRequest *)request;
- (void)removeTagFromDeviceSucceeded;
- (void)removeTagFromDeviceFailed:(UA_ASIHTTPRequest *)request;
@end

/**
 * This singleton provides an interface to the functionality provided by the Urban Airship client Push API.
 */
@interface UAPush : UAObservable 


SINGLETON_INTERFACE(UAPush);



///---------------------------------------------------------------------------------------
/// @name UAPush
///---------------------------------------------------------------------------------------

/** 
 * Set a delegate that implements the UAPushNotificationDelegate protocol. If not
 * set, a default implementation is provided (UAPushNotificationHandler).
 */
//@property (nonatomic, assign) id<UAPushNotificationDelegate> delegate;

/** Notification types this app will request from APNS. */
@property (nonatomic, readonly) UIRemoteNotificationType notificationTypes;

/**
 * Clean up when app is terminated. You should not ordinarily call this method as it is called
 * during [UAirship land].
 */
+ (void)land;

///---------------------------------------------------------------------------------------
/// @name Push Notifications
///---------------------------------------------------------------------------------------


/** Enables/disables push notifications on this device through Urban Airship. */
@property (nonatomic) BOOL pushEnabled; /* getter = pushEnabled, setter = setPushEnabled: */


/** The device token for this device, as a string. */
@property (nonatomic, copy, readonly) NSString *deviceToken; 

/*
 * Returns `YES` if the device token has changed. This method is scheduled for removal 
 * in the short term, it is recommended that you do not use it.
 */
@property (nonatomic, assign, readonly) BOOL deviceTokenHasChanged UA_DEPRECATED(__UA_LIB_1_3_0__);


///---------------------------------------------------------------------------------------
/// @name Autobadge
///---------------------------------------------------------------------------------------

/**
 * Toggle the Urban Airship auto-badge feature. If enabled, this will update the badge number
 * stored by UA every time the app is started or foregrounded.
 */
@property (nonatomic, assign) BOOL autobadgeEnabled; /* getter = autobadgeEnabled, setter = setAutobadgeEnabled: */

/**
 * Sets the badge number on the device and on the Urban Airship server.
 * 
 * @param badgeNumber The new badge number
 */
- (void)setBadgeNumber:(NSInteger)badgeNumber;

/**
 * Resets the badge to zero (0) on both the device and on Urban Airships servers. This is a
 * convenience method for `setBadgeNumber:0`.
 */
- (void)resetBadge;

/*
 * Enable the Urban Airship autobadge feature. This will update the badge number stored by UA
 * every time the app is started or foregrounded.
 * 
 * @param enabled New value
 * @warning *Deprecated* Use the setAutobadgeEnabled: method instead
 */
- (void)enableAutobadge:(BOOL)enabled UA_DEPRECATED(__UA_LIB_1_3_0__);


///---------------------------------------------------------------------------------------
/// @name Alias
///---------------------------------------------------------------------------------------
 
/** Alias for this device */
@property (nonatomic, copy) NSString *alias; /* getter = alias, setter = setAlias: */

///---------------------------------------------------------------------------------------
/// @name Tags
///---------------------------------------------------------------------------------------

/** Tags for this device. */
@property (nonatomic, copy) NSArray *tags; /* getter = tags, setter = setTags: */

/**
 * Allows tag editing from device. Set this to `NO` to prevent the device from sending any tag
 * information to the server when using server side tagging. Defaults to `YES`.
 */
@property (nonatomic, assign) BOOL canEditTagsFromDevice; /* getter = canEditTagsFromDevice, setter = setCanEditTagsFromDevice: */

/**
 * Adds a tag to the list of tags for the device.
 * To update the server, make all of you changes, then call
 * [[UAPush shared] updateRegisration] to update the UA server.
 * 
 * @param tag Tag to be added
 * @warning *Warning* When updating multiple 
 * server side values (tags, alias, time zone, quiet time) set the values first, then
 * call the updateRegistration method. Batching these calls improves API and client performance.
 */
- (void)addTagToCurrentDevice:(NSString *)tag;

/**
 * Adds a group of tags to the current list of device tags. To update the server, make all of your
 * changes, then call `updateRegistration`.
 * 
 * @param tags Array of new tags
 * @warning *Warning* When updating multiple 
 * server side values (tags, alias, time zone, quiet time) set the values first, then
 * call the updateRegistration method. Batching these calls improves API and client performance.
 */

- (void)addTagsToCurrentDevice:(NSArray *)tags;

/**
 * Removes a tag from the current tag list. To update the server, make all of you changes, then call
 * updateRegistration.
 * 
 * @param tag Tag to be removed
 * @warning *Warning* When updating multiple 
 * server side values (tags, alias, time zone, quiet time) set the values first, then
 * call the updateRegistration method. Batching these calls improves API and client performance.
 */
- (void)removeTagFromCurrentDevice:(NSString *)tag;

/**
 * Removes a group of tags from a device. To update the server, make all of you changes, then call
 * updateRegisration.
 * 
 * @param tags Array of tags to be removed
 * @warning *Warning* When updating multiple 
 * server side values (tags, alias, time zone, quiet time) set the values first, then
 * call updateRegistration. Batching these calls improves API and client performance.
 */
- (void)removeTagsFromCurrentDevice:(NSArray*)tags;

/*
 * Updates the tag list on the device and on Urban Airship. Use setTags:
 * instead. This method updates the server after setting the tags. Use
 * the other tag manipulation methods instead, and update the server
 * when appropriate.
 *
 * @param values The new tag values
 */
- (void)updateTags:(NSMutableArray *)values UA_DEPRECATED(__UA_LIB_1_3_0__);

///---------------------------------------------------------------------------------------
/// @name Alias
///---------------------------------------------------------------------------------------


/*
 * Updates the alias on the device and on Urban Airship. Use only 
 * when the alias is the only value that needs to be updated. 
 *
 * @param value New alias
 */
- (void)updateAlias:(NSString *)value UA_DEPRECATED(__UA_LIB_1_3_0__);

///---------------------------------------------------------------------------------------
/// @name Quiet Time
///---------------------------------------------------------------------------------------

/**
 * Quiet time settings for this device.
 */
@property (nonatomic, copy, readonly) NSDictionary *quietTime; /* getter = quietTime */

/**
 * Time Zone for quiet time.
 */
@property (nonatomic, retain) NSTimeZone *timeZone; /* getter = timeZone, setter = setTimeZone: */

/**
 * Enables/Disables quiet time
 */
@property (nonatomic, assign) BOOL quietTimeEnabled;

/**
 * Change quiet time for current device token, only take hh:mm into account. Update the server
 * after making changes to the quiet time with the updateRegistration call. 
 * Batching these calls improves API and client performance.
 * 
 * @warning *Important* The behavior of this method has changed in as of 1.3.0
 * This method no longer automatically enables quiet time, and does not automatically update
 * the server. Please refer to quietTimeEnabled and updateRegistration methods for
 * more information
 * 
 * @param from Date for start of quiet time
 * @param to Date for end of quiet time
 * @param tz Time zone the dates are in reference to
 */
- (void)setQuietTimeFrom:(NSDate *)from to:(NSDate *)to withTimeZone:(NSTimeZone *)tz;

/**
 * Disables quiet time settings. This call updates the server with an API call.
 * This call is deprecated. Set quietTimeEnabled to NO instead;
 */
- (void)disableQuietTime UA_DEPRECATED(__UA_LIB_1_3_0__);

/*
 * The current time zone setting for quiet time.
 *
 * @return The time zone name
 */
- (NSString *)tz UA_DEPRECATED(__UA_LIB_1_3_0__);

/*
 * Set a new time zone for quiet time.
 *
 * @param tz NSString representing the new time zone name. If the name does not resolve to an actual NSTimeZone,
 * the default time zone [NSTimeZone localTimeZone] is used
 */
- (void)setTz:(NSString *)tz UA_DEPRECATED(__UA_LIB_1_3_0__);


///---------------------------------------------------------------------------------------
/// @name Registration
///---------------------------------------------------------------------------------------


/*
 * This registers the device token and all current associated Urban Airship custom
 * features that are currently set. You should not ordinarily call this method.
 * 
 * Features set with this call if available:
 *  
 * - tags
 * - alias
 * - time zone
 * - autobadge
 * 
 * Add a UARegistrationObserver to UAPush to receive success or failure callbacks.
 *
 * @param token The device token to register.
 */
- (void)registerDeviceToken:(NSData *)token;

/*
 * Register the current device token with UA. You should not ordinarily call this method.
 * 
 * @param info An NSDictionary containing registration keys and values. See
 * https://docs.urbanairship.com/display/DOCS/Server%3A+iOS+Push+API#ServeriOSPushAPI-Registration
 * for details.
 * 
 * Add a UARegistrationObserver to UAPush to receive success or failure callbacks.
 */
- (void)registerDeviceTokenWithExtraInfo:(NSDictionary *)info UA_DEPRECATED(__UA_LIB_1_3_0__);

/*
 * Register a device token and alias with UA. You should not ordinarily call this method. Use
 * the `alias` property instead.
 *
 * An alias should only have a small
 * number (< 10) of device tokens associated with it. Use the tags API for arbitrary
 * groupings.
 * 
 * Add a UARegistrationObserver to UAPush to receive success or failure callbacks.
 *
 * @param token The device token to register.
 * @param alias The alias to register for this device token.
 */
- (void)registerDeviceToken:(NSData *)token withAlias:(NSString *)alias UA_DEPRECATED(__UA_LIB_1_3_0__);

/*
 * Register a device token with a custom API payload. You should not ordinarily call this method.
 * 
 * Add a UARegistrationObserver to UAPush to receive success or failure callbacks.
 * 
 * @param token The device token to register.
 * @param info An NSDictionary containing registration keys and values. See
 * https://docs.urbanairship.com/display/DOCS/Server%3A+iOS+Push+API for details.
 */
- (void)registerDeviceToken:(NSData *)token withExtraInfo:(NSDictionary *)info UA_DEPRECATED(__UA_LIB_1_3_0__);

/*
 * Remove this device token's registration from the server. You should not ordinarily call this method.
 * This call is equivalent to an API DELETE call, as described here:
 * https://docs.urbanairship.com/display/DOCS/Server%3A+iOS+Push+API#ServeriOSPushAPI-Registration
 *  
 * Add a UARegistrationObserver to UAPush to receive success or failure callbacks.
 *
 * @warning Deprecated: Use the pushEnabled property on UAPush instead
 */
- (void)unRegisterDeviceToken UA_DEPRECATED(__UA_LIB_1_3_2__);

/**
 * Register the device for remote notifications (see Apple documentation for more
 * detail).
 *
 * @param types Bitmask of notification types
 */
- (void)registerForRemoteNotificationTypes:(UIRemoteNotificationType)types;

/**
 * Registers or updates the current registration with an API call. If push notifications are
 * not enabled, this unregisters the device token.
 *
 * Register an implementation of UARegistrationObserver to UAPush to receive success and failure callbacks.
 */
- (void)updateRegistration;

/** 
 * Automatically retry on errors. If the UA reports an error in the 500 range, or there is a 
 * 
 */
@property (nonatomic, assign) BOOL retryOnConnectionError;

///---------------------------------------------------------------------------------------
/// @name Receiving Notifications
///---------------------------------------------------------------------------------------

/**
 * Handle incoming push notifications. This method will record push conversions, parse the notification
 * and call the appropriate methods on your delegate.
 *
 * @param notification The notification payload, as passed to your application delegate.
 * @param applicationState The application state at the time the notification was received.
 */
//- (void)handleNotification:(NSDictionary *)notification applicationState:(UIApplicationState)state;


///---------------------------------------------------------------------------------------
/// @name Push Notification UI Methods
///---------------------------------------------------------------------------------------

/*
 * Returns a human-readable (English-language), comma-separated list of the push notification types.
 *
 * @param types The notification types to include in the list.
 *
 * @return A stringified list of the types.
 */
+ (NSString *)pushTypeString:(UIRemoteNotificationType)types;

@end
