//
//  CSActiveDownload.m
//  CSDownloadManager
//
//  Created by Christian Schwarz on 16.09.12.
//  Copyright (c) 2012 Christian Schwarz. All rights reserved.
//

#import "CSActiveDownload.h"

@interface CSActiveDownload ()

@end

@implementation CSActiveDownload
@dynamic process;

- (id)init {
    self = [super init];
    if (self) {
        self.loadedBytes = 0;
    }
    return self;
}

- (float)process {
    
    long long expectedLength = self.response.expectedContentLength > 0 ? self.response.expectedContentLength : [[[self.response allHeaderFields] valueForKey:@"Content-Length"] longLongValue];
    
    float process = expectedLength != 0 ? (float)self.loadedBytes / (float)expectedLength : 0;
    
    return process;
}

@end
