//
//  CSDownloadManager.h
//  CSDownloadManager
//
//  Created by Christian Schwarz on 16.09.12.
//  Copyright (c) 2012 Christian Schwarz. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSActiveDownload.h"
#import "CSFinishedDownload.h"

#pragma mark - constants

typedef enum {
    CSDownloadManagerFileSystemError,
    CSDownloadManagerConnectionError,
    CSDownloadManagerNoDiskSpaceError
} CSDownloadManagerErrorCode;

static NSString* const CSDownloadManagerInternalInconsistencyException = @"CSDownloadManagerInternalInconsistencyException";

#pragma mark - delegate

@class CSDownloadManager;

@protocol CSDownloadManagerDelegate <NSObject>

/**
 * @exception CSDownloadManagerInternalInconsistencyException Thrown if an error occures with the provided path
 */
- (NSString*)pathForFinishedDownloadsOfDownloadManager:(CSDownloadManager*)dm;


@optional

- (void)downloadManager:(CSDownloadManager*)dm didFinishDownload:(CSActiveDownload*)finishedDownload;

- (void)downloadManager:(CSDownloadManager*)dm download:(CSActiveDownload*)activeDownload didProceed:(float)process;

- (void)downloadManager:(CSDownloadManager*)dm download:(CSActiveDownload*)activeDownload didFailWithError:(NSError*)error;

- (void)downloadManager:(CSDownloadManager*)dm internalError:(NSError*)error;

@end

#pragma mark - interface

@interface CSDownloadManager : NSObject

- (id)initWithDelegate:(id<CSDownloadManagerDelegate>)delegate;

@property (nonatomic, strong) id<CSDownloadManagerDelegate> delegate;

@property (readonly) NSArray* activeDownloads;
@property (readonly) NSArray* finishedDownloads;

- (void)addDownloadFromURL:(NSURL*)url withUserInfo:(NSDictionary*)dictionary callback:(void(^)(CSActiveDownload*activeDownload))callback;

- (void)cancelDownload:(CSActiveDownload*)activeDownload callback:(void(^)(NSError* error, NSInteger formerIndex))callback;

- (void)deleteDownload:(CSFinishedDownload*)finishedDownload callback:(void(^)(NSError* error, NSInteger formerIndex))callback;

- (void)processFinishedDownload:(CSActiveDownload*)finishedDownload callback:(void(^)(NSInteger formerIndex, NSInteger newIndex))callback;


@end
