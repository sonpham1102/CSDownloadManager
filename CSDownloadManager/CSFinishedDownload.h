//
//  CSDownload.h
//  CSDownloadManager
//
//  Created by Christian Schwarz on 16.09.12.
//  Copyright (c) 2012 Christian Schwarz. All rights reserved.
//

#import <Foundation/Foundation.h>

static NSString* const CSFinishedDownloadUserInfoExceptionName = @"CSFinishedDownloadUserInfoExceptionName";

@interface CSFinishedDownload : NSObject <NSCoding>

@property (nonatomic, strong) NSString* path;

/**
 * User info may contain any data as long as it is compliant to the NSCoding protocol
 * @exception CSFinishedDownloadUserInfoException Thrown if userInfo cannot be serialized. Sets userInfo to nil
 */
@property (nonatomic, strong) NSDictionary* userInfo;

@property (nonatomic, strong) NSDate* downloadStartDate;
@property (nonatomic, strong) NSDate* downloadEndDate;

- (id)initWithUserInfo:(NSDictionary*)userInfo;

@end
