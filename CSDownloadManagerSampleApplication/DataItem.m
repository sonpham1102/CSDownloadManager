//
//  DataItem.m
//  CSDownloadManager
//
//  Created by Christian Schwarz on 16.09.12.
//  Copyright (c) 2012 Christian Schwarz. All rights reserved.
//

#import "DataItem.h"

@implementation DataItem


//===========================================================
//  Keyed Archiving
//
//===========================================================
- (void)encodeWithCoder:(NSCoder *)encoder
{
    [encoder encodeObject:self.title forKey:@"title"];
}

- (id)initWithCoder:(NSCoder *)decoder
{
    self = [super init];
    if (self) {
        self.title = [decoder decodeObjectForKey:@"title"];
    }
    return self;
}

@end
