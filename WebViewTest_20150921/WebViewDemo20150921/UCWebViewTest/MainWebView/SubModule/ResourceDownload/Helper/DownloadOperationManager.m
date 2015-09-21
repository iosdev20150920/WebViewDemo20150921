/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : DownloadOperationManager.m
 *
 * Description   : DownloadOperationManager is something acts like a NSOperationQueue, it provides convenient interfaces to create
 *                    download task and other interfaces to access the internal status of the manager
 *
 * Creation      : 2015/06/29
 * Author         : luyc@ucweb.com
 * History        :
 *                 Creation, 2015/06/29, luyc, Create the file
 ***************************************************************************
 **/

#import "DownloadOperationManager.h"

static NSString *const kDefaultPathToStoreFile = @"Download";

@interface DownloadOperationManager ()

@property (nonatomic, retain) NSOperationQueue *operationQueue;

@end


static DownloadOperationManager *instance = nil;

@implementation DownloadOperationManager


+ (instancetype)sharedInstance
{
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        instance = [[DownloadOperationManager alloc] init];
    });
    
    return instance;
}

- (instancetype)init
{
    if ((self = [super init]))
    {
        _operationQueue = [[NSOperationQueue alloc] init];
    
        NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        self.defaultPathToDownload = [documentPath stringByAppendingPathComponent:kDefaultPathToStoreFile];
    }
    
    return self;
}

- (void)dealloc
{
    [_operationQueue release];
    
    [super dealloc];
}

- (DownloadOperation *)startDownloadFile:(NSURL *)targetUrl toLocalFilePath:(NSString *)pathToDownload delegate:(id<DownloadOpearationDelegate>)delegate
{
    NSString *storePath = (pathToDownload == nil ? self.defaultPathToDownload : pathToDownload);
    DownloadOperation *operation = [[[DownloadOperation alloc] initWithDownloadUrl:targetUrl pathToStore:storePath andDelegate:delegate] autorelease];
    
    [self.operationQueue addOperation:operation];
    
    return operation;
}

- (DownloadOperation *)startDownloadFile:(NSURL *)targetUrl
                         toLocalFilePath:(NSString *)pathToDownload
                              errorBlock:(OperationErrorBlock)errorCallback
                           progressBlock:(OperationReceiveDataBlock)progressCallback
                         completionBlock:(OperationCompletionBlock)completionCallback
{
    NSString *storePath = (pathToDownload == nil ? self.defaultPathToDownload : pathToDownload);
    
    DownloadOperation *operation = [[DownloadOperation alloc] initWithDownloadUrl:targetUrl
                                                                            pathToStore:storePath
                                                                            error:errorCallback
                                                                            progress:progressCallback
                                                                            andCompletion:completionCallback];
    
    [self.operationQueue addOperation:operation];
    
    return [operation autorelease];
}

- (void)startDownloadOperation:(DownloadOperation *)operation
{
    [self.operationQueue addOperation:operation];
}

- (void)setCocurrentOperationCount:(NSInteger)cocurrentCount
{
    [self.operationQueue setMaxConcurrentOperationCount:cocurrentCount];
}

- (BOOL)setDefaultPathToDownload:(NSString *)defaultPath error:(NSError **)error
{
    
    NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
    NSString *targetPath = [documentPath stringByAppendingPathComponent:kDefaultPathToStoreFile];
    
    if ([[NSFileManager defaultManager] createDirectoryAtPath:targetPath withIntermediateDirectories:YES attributes:nil error:error])
    {
        _defaultPathToDownload = targetPath;
        return YES;
    }
    
    return NO;
}

- (NSInteger)operationCount
{
    return [self.operationQueue operationCount];
}

- (NSInteger)downloadingOperationCount
{
    NSInteger result = 0;
    for (DownloadOperation *operation in self.operationQueue.operations)
    {
        if (operation.state == DownloadOperationStateDownloading)
        {
            ++ result;
        }
    }
    
    return result;
}


@end
