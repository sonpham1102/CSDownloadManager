//
//  CSDownload.m
//  CSDownloadManager
//
//  Created by Christian Schwarz on 16.09.12.
//  Copyright (c) 2012 Christian Schwarz. All rights reserved.
//

#import "CSFinishedDownload.h"

@implementation CSFinishedDownload
@synthesize userInfo = _userInfo;

- (id)init {
    self = [super init];
    if (self) {
    }
    return self;
}

- (id)initWithUserInfo:(NSDictionary *)userInfo {
    self = [self init];
    if (self) {
        self.userInfo = userInfo;
    }
    return self;
}

- (void)setUserInfo:(NSDictionary *)userInfo {
    NSDictionary* exceptionUserInfo;
    @try {
        if ([NSKeyedArchiver archivedDataWithRootObject:userInfo]) {
            _userInfo = userInfo;
        } else {
            _userInfo = nil;
        }
    }
    @catch (NSException *exception) {
        exceptionUserInfo = exception.userInfo;
        @throw [NSException exceptionWithName:CSFinishedDownloadUserInfoExceptionName reason:@"The provided dictionary is not compliant to the NSCoding protocol." userInfo:exceptionUserInfo];
    }
    @finally {

    }
}

//===========================================================
//  Keyed Archiving
//
//===========================================================
- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.path forKey:@"path"];
    [encoder encodeObject:self.userInfo forKey:@"userInfo"];
    [encoder encodeObject:self.downloadStartDate forKey:@"downloadStartDate"];
    [encoder encodeObject:self.downloadEndDate forKey:@"downloadEndDate"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        self.path = [decoder decodeObjectForKey:@"path"];
        self.userInfo = [decoder decodeObjectForKey:@"userInfo"];
        self.downloadStartDate = [decoder decodeObjectForKey:@"downloadStartDate"];
        self.downloadEndDate = [decoder decodeObjectForKey:@"downloadEndDate"];
    }
    return self;
}

@end
