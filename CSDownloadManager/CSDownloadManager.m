//
//  CSDownloadManager.m
//  CSDownloadManager
//
//  Created by Christian Schwarz on 16.09.12.
//  Copyright (c) 2012 Christian Schwarz. All rights reserved.
//

#import "CSDownloadManager.h"

static NSString* const kReverseUrlIdentifier = @"com.cschwarz.CSDownloadManager";

@interface CSDownloadManager () <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, strong) NSMutableArray* _activeDownloads;
@property (nonatomic, strong) NSMutableArray* _finishedDownloads;

@property (nonatomic, strong) NSFileManager* fileManager;

@end

@implementation CSDownloadManager
@synthesize _activeDownloads;
@synthesize _finishedDownloads;
@synthesize fileManager;

- (id)initWithDelegate:(id<CSDownloadManagerDelegate>)delegate {
    self = [self init];
    if (self) {
        self.delegate = delegate;
        
        self._activeDownloads = [NSMutableArray array];
        self._finishedDownloads = [self loadFinishedDownloads];
        
        self.fileManager = [[NSFileManager alloc] init];
        
    }
    return self;
}

#pragma mark - public properties

- (NSArray *)activeDownloads {
    return self._activeDownloads;
}

- (NSArray *)finishedDownloads {
    return self._finishedDownloads;
}


#pragma mark - public methods

- (void)addDownloadFromURL:(NSURL*)url withUserInfo:(NSDictionary*)dictionary callback:(void(^)(CSActiveDownload*activeDownload))callback {
    
    CSActiveDownload* newActiveDownload = [[CSActiveDownload alloc] initWithUserInfo:dictionary];
    
    newActiveDownload.downloadStartDate = [NSDate date];
    
    NSURLRequest* request = [NSURLRequest requestWithURL:url];
    
    newActiveDownload.connection = [[NSURLConnection alloc] initWithRequest:request delegate:self startImmediately:YES];
    
    [self._activeDownloads addObject:newActiveDownload];

    dispatch_async(dispatch_get_main_queue(), ^{
        callback(newActiveDownload);
    });
    
}


- (void)cancelDownload:(CSActiveDownload*)activeDownload callback:(void(^)(NSError* error, NSInteger formerIndex))callback {
    [activeDownload.connection cancel];
    
    [activeDownload.fileHandle closeFile];
    
    NSError* removalError;
    if (![self.fileManager removeItemAtPath:activeDownload.path error:&removalError]) {
        NSError* error = [NSError errorWithDomain:kReverseUrlIdentifier code:CSDownloadManagerFileSystemError userInfo:removalError.userInfo];
        callback(error, NSNotFound);
    }
    
    NSInteger formerIndex = [self._activeDownloads indexOfObject:activeDownload];
    [self._activeDownloads removeObject:activeDownload];
    
    dispatch_async(dispatch_get_main_queue(), ^{
        callback(nil, formerIndex);
    });

    
}

- (void)deleteDownload:(CSFinishedDownload*)finishedDownload callback:(void(^)(NSError* error, NSInteger formerIndex))callback {
    
    NSError* removalError;
    
    if ([self.fileManager removeItemAtPath:finishedDownload.path error:&removalError]) {
        NSInteger formerIndex = [self._finishedDownloads indexOfObject:finishedDownload];
        [self._finishedDownloads removeObject:finishedDownload];
        [self saveFinishedDownloads];
        dispatch_async(dispatch_get_main_queue(), ^{
            callback(nil, formerIndex);
        });
    } else {
        NSError* error = [NSError errorWithDomain:kReverseUrlIdentifier code:CSDownloadManagerFileSystemError userInfo:removalError.userInfo];
        callback(error, NSNotFound);
    }
    
}

- (void)processFinishedDownload:(CSActiveDownload*)finishedDownload callback:(void(^)(NSInteger formerIndex, NSInteger newIndex))callback {
    
    NSInteger formerIndex = [self._activeDownloads indexOfObject:finishedDownload];
    [self._finishedDownloads addObject:finishedDownload];
    [self._activeDownloads removeObject:finishedDownload];
    NSInteger newIndex = [self._finishedDownloads indexOfObject:finishedDownload];
    [self saveFinishedDownloads];
    dispatch_async(dispatch_get_main_queue(), ^{
        callback(formerIndex, newIndex);
    });
    
}

- (void)resetDownloadManager {
    
    [self.fileManager removeItemAtPath:finishedIndexFilePath() error:NULL];
    
    self._finishedDownloads = [NSMutableArray array];
    for (CSActiveDownload* activeDownload in self.activeDownloads) {
        [activeDownload.connection cancel];
    }
    self._activeDownloads = [NSMutableArray array];

    [self indexCorruptionCheck];

}

#pragma mark - file system methods

- (NSString*)finDir {
    NSString* finDir = [self.delegate pathForFinishedDownloadsOfDownloadManager:self];
    NSString* downloadsDir = [finDir stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", kReverseUrlIdentifier]];
    
    NSError* creationError;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:downloadsDir withIntermediateDirectories:YES attributes:nil error:&creationError]) {
        @throw [NSException exceptionWithName:CSDownloadManagerInternalInconsistencyException reason:@"Can not create directory at the provided path" userInfo:nil];
    }
    
    return downloadsDir;
}

- (NSString*)actDir {
    
    NSString* actDir = [NSTemporaryDirectory() stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", kReverseUrlIdentifier]];
    
    NSError* creationError;
    if (![[NSFileManager defaultManager] createDirectoryAtPath:actDir withIntermediateDirectories:YES attributes:nil error:&creationError]) {
        @throw [NSException exceptionWithName:CSDownloadManagerInternalInconsistencyException reason:@"Can not create directory at the provided path" userInfo:nil];
    }
    
    return actDir;
}


NSString* finishedIndexFilePath() {
   
    NSArray *searchPaths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentPath = [searchPaths objectAtIndex:0];

    NSString* finishedIndexFilePath = [[documentPath stringByAppendingPathComponent:[NSString stringWithFormat:@"/%@", kReverseUrlIdentifier]] stringByAppendingPathExtension:@"finishedDownloads"];
    
    return finishedIndexFilePath;
    
}

- (void)indexCorruptionCheck {
 
    NSMutableArray* corruptedDownloads = [NSMutableArray array];
    NSMutableArray* filePaths = [NSMutableArray array];
    for (CSFinishedDownload* finishedDownload in self._finishedDownloads) {
        
        //Corrupcy check
        if (![self.fileManager fileExistsAtPath:finishedDownload.path]) {
            [corruptedDownloads addObject:finishedDownload];
        } else {
            [filePaths addObject:finishedDownload.path];
        }
        
    }
    [self._finishedDownloads removeObjectsInArray:corruptedDownloads];
    [self saveFinishedDownloads];
    
    //Orphaned files
    NSError* readingError;
    NSArray* contents = [self.fileManager contentsOfDirectoryAtPath:[self finDir] error:&readingError];
    if (contents) {
        
        //Remove files that are no download paths
        for (NSString* item in contents) {
            
            BOOL hasFoundFile = NO;
            for (NSString* filePath in filePaths) {
                hasFoundFile |= [item isEqualToString:filePath];
            }
            
            if (!hasFoundFile) {
                NSError* deletionError;
                if (![self.fileManager removeItemAtPath:[[self finDir] stringByAppendingPathComponent:item] error:&deletionError]) {
                    NSError* error = [NSError errorWithDomain:kReverseUrlIdentifier code:CSDownloadManagerFileSystemError userInfo:deletionError.userInfo];
                    if ([self.delegate respondsToSelector:@selector(downloadManager:internalError:)]) {
                        [self.delegate downloadManager:self internalError:error];
                    }
                }
            }
            
        }
        
    } else {
        NSError* error = [NSError errorWithDomain:kReverseUrlIdentifier code:CSDownloadManagerFileSystemError userInfo:readingError.userInfo];
        if ([self.delegate respondsToSelector:@selector(downloadManager:internalError:)]) {
            [self.delegate downloadManager:self internalError:error];
        }
    }
    
    NSError* actDirCleanError;
    if (![self.fileManager removeItemAtPath:[self actDir] error:&actDirCleanError]){
        NSError* error = [NSError errorWithDomain:kReverseUrlIdentifier code:CSDownloadManagerFileSystemError userInfo:actDirCleanError.userInfo];
        if ([self.delegate respondsToSelector:@selector(downloadManager:internalError:)]) {
            [self.delegate downloadManager:self internalError:error];
        }
    }
    
}

- (NSMutableArray*)loadFinishedDownloads {
    
    NSMutableArray* savedFinishedDownloads = [NSKeyedUnarchiver unarchiveObjectWithFile:finishedIndexFilePath()];
    
    [self indexCorruptionCheck];
    
    return savedFinishedDownloads ? savedFinishedDownloads : [NSMutableArray array];
    
}


- (BOOL)saveFinishedDownloads {
 
    NSString* path = finishedIndexFilePath();

    if ([self.fileManager createFileAtPath:path contents:nil attributes:nil] || [self.fileManager fileExistsAtPath:path]) {
        
        NSError* error;
        
        NSData* serialized = [NSKeyedArchiver archivedDataWithRootObject:self._finishedDownloads];
        NSError* writingError;
        if([serialized writeToFile:path options:NSDataWritingAtomic error:&writingError]) {
            return YES;
        } else {
            error = [NSError errorWithDomain:kReverseUrlIdentifier code:CSDownloadManagerFileSystemError userInfo:writingError.userInfo];
            return NO;
        }
                
        if ([self.delegate respondsToSelector:@selector(downloadManager:internalError:)] && error) {
            [self.delegate downloadManager:self internalError:error];
        }

        
    } else {
        return NO;
    }
}

- (NSString*)pathForDownload:(CSActiveDownload*)download directory:(NSString*)directory {
    
    NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
    formatter.dateFormat = @"dd-MM-yyy-HH-mm-ss";
    
    NSString* subpath = [NSString stringWithFormat:@"/%@_%@", [formatter stringFromDate:download.downloadStartDate], download.response.suggestedFilename];
    
    NSString* fullPath = [directory stringByAppendingPathComponent:subpath];
    
    return fullPath;
}


#pragma mark - networking methods

- (CSActiveDownload*)activeDownloadForConnection:(NSURLConnection*)connection {
    
    for (CSActiveDownload* currentActiveDownload in self._activeDownloads) {
        if ([currentActiveDownload.connection isEqual:connection]) {
            return currentActiveDownload;
        }
    }
    
    return nil;
    
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response {
    
    //Check if response is ok
    if ([response isKindOfClass:[NSHTTPURLResponse class]]) {
        NSHTTPURLResponse* httpresponse = (NSHTTPURLResponse*)response;
        if (httpresponse.statusCode >= 400) {
            [connection cancel];
            NSDictionary *errorInfo = [NSDictionary dictionaryWithObject:[NSString stringWithFormat: NSLocalizedString(@"Server returned status code %d",@""), httpresponse.statusCode] forKey:NSLocalizedDescriptionKey];
            NSError *statusError = [NSError errorWithDomain:kReverseUrlIdentifier code:CSDownloadManagerConnectionError userInfo:errorInfo];
            [self connection:connection didFailWithError:statusError];
        }
    }
    
    
    CSActiveDownload* currentActiveDownload = [self activeDownloadForConnection:connection];
    
    currentActiveDownload.response = [response copy];
    
    currentActiveDownload.path = [self pathForDownload:currentActiveDownload directory:[self actDir]];
    
    [self.fileManager createFileAtPath:currentActiveDownload.path contents:nil attributes:nil];
    
    currentActiveDownload.fileHandle = [NSFileHandle fileHandleForWritingAtPath:currentActiveDownload.path];
    
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data {
    
    CSActiveDownload* download = [self activeDownloadForConnection:connection];
    
    [download.fileHandle writeData:data];
    
    download.loadedBytes += [data length];
    
    if ([self.delegate respondsToSelector:@selector(downloadManager:download:didProceed:)]) {
        dispatch_async(dispatch_get_main_queue(), ^{
           [self.delegate downloadManager:self download:download didProceed:[download process]];
        });
    }
    
    
}


- (void)connectionDidFinishLoading:(NSURLConnection *)connection {
    
    
    CSActiveDownload* download = [self activeDownloadForConnection:connection];
    [download.fileHandle closeFile];
    
    NSString* oldPath = [self pathForDownload:download directory:[self actDir]];
    NSString* newPath = [self pathForDownload:download directory:[self finDir]];
    
    NSError* moveError;
    BOOL success = [self.fileManager moveItemAtPath:oldPath toPath:newPath error:&moveError];
    
    if (success) {
        
        download.path = newPath;
        download.downloadEndDate = [NSDate date];
                
        if ([self.delegate respondsToSelector:@selector(downloadManager:didFinishDownload:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate downloadManager:self didFinishDownload:download]; 
            });
        }
                
    } else {
        
        NSError* error = [NSError errorWithDomain:kReverseUrlIdentifier code:CSDownloadManagerFileSystemError userInfo:moveError.userInfo];
        
        if ([self.delegate respondsToSelector:@selector(downloadManager:download:didFailWithError:)]) {
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.delegate downloadManager:self download:download didFailWithError:error];
            });
        }
        
    }
    
}

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)connectionError {
    
    CSActiveDownload* activeDownload = [self activeDownloadForConnection:connection];
    
    if ([self.delegate respondsToSelector:@selector(downloadManager:download:didFailWithError:)]) {
        
        NSError* error = [NSError errorWithDomain:kReverseUrlIdentifier code:CSDownloadManagerConnectionError userInfo:connectionError.userInfo];
        
        dispatch_async(dispatch_get_main_queue(), ^{
            [self.delegate downloadManager:self download:activeDownload didFailWithError:error];
        });
    }
    
}


@end
