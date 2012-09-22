//
//  CSActiveDownload.h
//  CSDownloadManager
//
//  Created by Christian Schwarz on 16.09.12.
//  Copyright (c) 2012 Christian Schwarz. All rights reserved.
//

#import "CSFinishedDownload.h"

@interface CSActiveDownload : CSFinishedDownload

@property (nonatomic, strong) NSURLConnection* connection;

@property (nonatomic, strong) NSHTTPURLResponse* response;

@property (nonatomic, strong) NSFileHandle* fileHandle;

@property (readonly) float process;

@property (readwrite) long long loadedBytes;

@end
