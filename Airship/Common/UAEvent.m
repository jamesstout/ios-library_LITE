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

#import "UAEvent.h"
#import "UAirship.h"
#import "UAUser.h"
#import "UAUtils.h"
#import "UA_Reachability.h"
#import "UA_SBJsonWriter.h"

@implementation UAEvent

@synthesize time, data, event_id;

- (id)init {
    if (self=[super init]) {
        event_id = [[UAUtils UUID] retain];
        data = [NSMutableDictionary new];
        return self;
    }
    return nil;
}

+ (id)event {
    id obj = [[self alloc] init];
    return [obj autorelease];
}

- (id)initWithContext:(NSDictionary*)context {
    if (self=[self init]) {
        [self gatherData:context];
        return self;
    }
    return nil;
}

+ (id)eventWithContext:(NSDictionary*)context {
    id obj = [[self alloc] initWithContext:context];
    return [obj autorelease];
}

- (NSString*)getType {
    return @"base";
}

- (int)getEstimatedSize {
    NSMutableDictionary *eventDictionary = [NSMutableDictionary dictionary];
    [eventDictionary setObject:[self getType] forKey:@"type"];
    [eventDictionary setObject:self.time forKey:@"time"];
    [eventDictionary setObject:self.event_id forKey:@"event_id"];
    [eventDictionary setObject:self.data forKey:@"data"];
    UA_SBJsonWriter *writer = [UA_SBJsonWriter new];
    writer.humanReadable = NO;//strip whitespace
    NSString *jsonString = [writer stringWithObject:eventDictionary];
    NSData *jsonData = [jsonString dataUsingEncoding:NSUTF8StringEncoding];
    [writer release];
    
    UALOG(@"Estimated event size: %d", [jsonData length]);
    
    return [jsonData length];
}





- (void)gatherIndividualData:(NSDictionary*)context{}

- (void)gatherData:(NSDictionary*)context {
    // in case we re-use a event object
    RELEASE_SAFELY(time);
    time = [[NSString stringWithFormat:@"%f",[[NSDate date] timeIntervalSince1970]] retain];
    [data removeAllObjects];

    // add shared values

    // gather individual data
    [self gatherIndividualData:context];
}

- (void)dealloc {
    RELEASE_SAFELY(event_id);
    RELEASE_SAFELY(time);
    RELEASE_SAFELY(data);
    [super dealloc];
}

@end

@implementation UAEventCustom

- (id)initWithType:(NSString*)aType {
    if (self=[super init]) {
        type = [aType retain];
        return self;
    }
    return nil;
}

+ (id)eventWithType:(NSString*)aType {
    id obj = [[self alloc] initWithType:aType];
    return [obj autorelease];
}

- (id)initWithType:(NSString*)aType andContext:(NSDictionary*)context {
    if (self=[super initWithContext:context]) {
        type = [aType retain];
        return self;
    }
    return nil;
}

+ (id)eventWithType:(NSString*)aType andContext:(NSDictionary*)context {
    id obj = [[self alloc] initWithType:aType andContext:context];
    return [obj autorelease];
}

- (NSString*)getType {
    return type;
}

- (void)gatherIndividualData:(NSDictionary*)context {
    [data addEntriesFromDictionary:context];
}

- (void)dealloc {
    RELEASE_SAFELY(type);
    [super dealloc];
}

@end


@implementation UAEventAppInit

- (NSString*)getType {
    return @"app_init";
}

- (void)gatherIndividualData:(NSDictionary*)context {

    
}

- (int)getEstimatedSize {
    return kEventAppInitSize;
}

@end

@implementation UAEventAppForeground

- (NSString*)getType {
    return @"app_foreground";
}

- (void)gatherIndividualData:(NSDictionary*)context {
    [super gatherIndividualData:context];
    
    [data removeObjectForKey:@"foreground"];//not necessary - even is an explicit foreground
}

@end

@implementation UAEventAppExit

- (NSString*)getType {
    return @"app_exit";
}

- (void)gatherIndividualData:(NSDictionary*)context {
}

- (int)getEstimatedSize {
    return kEventAppExitSize;
}

@end

@implementation UAEventAppBackground

- (NSString*)getType {
    return @"app_background";
}

@end

@implementation UAEventAppActive

- (NSString *)getType {
    return @"activity_started";
}

- (void)gatherIndividualData:(NSDictionary*)context {
    [data setValue:@"" forKey:@"class_name"];
}

- (int)getEstimatedSize {
    return kEventAppActiveSize;
}

@end

@implementation UAEventAppInactive
 
- (NSString *)getType {
    return @"activity_stopped";
}

- (void)gatherIndividualData:(NSDictionary*)context {
    [data setValue:@"" forKey:@"class_name"];
}

- (int)getEstimatedSize {
    return kEventAppInactiveSize;
}

@end

@implementation UAEventDeviceRegistration

- (NSString*)getType {
    return @"device_registration";
}

- (void)gatherIndividualData:(NSDictionary*)context {

}

- (int)getEstimatedSize {
    return kEventDeviceRegistrationSize;
}

@end

@implementation UAEventPushReceived

- (NSString*)getType {
    return @"push_received";
}

- (void)gatherIndividualData:(NSDictionary*)context {
    
    // Get the rich push ID, which can be sent as a one-element array or a string
    NSString *richPushId = nil;
    NSObject *richPushValue = [context objectForKey:@"_uamid"];
    if ([richPushValue isKindOfClass:[NSArray class]]) {
        NSArray *richPushIds = (NSArray *)richPushValue;
        if (richPushIds.count > 0) {
            richPushId = [richPushIds objectAtIndex:0];
        }
    } else if ([richPushValue isKindOfClass:[NSString class]]) {
        richPushId = (NSString *)richPushValue;
    }
    
    //Add the rich push id, if present
    if (richPushId) {
    }
    
    //Add the std push id, if present, else create a UUID
    NSString *pushId = [context objectForKey:@"_"];
    if (pushId) {
    } else {
    }
}

- (int)getEstimatedSize {
    return kEventPushReceivedSize;
}

@end




