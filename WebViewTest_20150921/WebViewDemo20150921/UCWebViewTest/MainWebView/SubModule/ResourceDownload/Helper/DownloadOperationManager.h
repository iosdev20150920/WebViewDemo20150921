/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : DownloadOperationManager.h
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

#import <Foundation/Foundation.h>

#import "DownloadOperation.h"

@interface DownloadOperationManager : NSObject

@property (nonatomic, copy) NSString *defaultPathToDownload;   // The default path for user downlaod

@property (nonatomic, assign, readonly) NSInteger operationCount;               // The number of operations in the queue
@property (nonatomic, assign, readonly) NSInteger downloadingOperationCount; // The number of operations that are running currently

+ (instancetype)sharedInstance;   // Try to make it a singleton now!

/* Create and start a DownloadOperation */
- (DownloadOperation *)startDownloadFile:(NSURL *)targetUrl
                         toLocalFilePath:(NSString *)pathToDownload
                              errorBlock:(OperationErrorBlock)errorCallback
                           progressBlock:(OperationReceiveDataBlock)progressCallback
                         completionBlock:(OperationCompletionBlock)completionCallback;

- (DownloadOperation *)startDownloadFile:(NSURL *)targetUrl toLocalFilePath:(NSString *)pathToDownload delegate:(id<DownloadOpearationDelegate>)delegate;

/* You may use this interface to add your DownloadOperation to the queue also */
- (void)startDownloadOperation:(DownloadOperation *)operation;

/* Other utility interfaces */
- (void)setCocurrentOperationCount:(NSInteger)cocurrentCount;
- (BOOL)setDefaultPathToDownload:(NSString *)defaultPath error:(NSError **)error;

@end
