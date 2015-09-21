/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : DownloadOperation.h
 *
 * Description   : DownloadOperation is a subclass of NSOperation, We override it for the purpose to get the progress and 
 *                    store some information about the file we're downloading, writting data to disk and ofcause, do some logic
 *                    checking also
 *
 * Creation      : 2015/06/29
 * Author         : luyc@ucweb.com
 * History        :
 *                 Creation, 2015/06/29, luyc, Create the file
 ***************************************************************************
 **/

#import <Foundation/Foundation.h>

/* Error domain */
extern NSString *const kDownloadOperationErrorDomain;

/* Some error codes */
typedef NS_ENUM(NSInteger, DownloadOperationErrorCode)
{
    DownloadOperationErrorCodeInvalidUrl = 1,
    DownloadOperationErrorCodeCannotOpenFileToWrite,
    DownloadOperationErrorCodeDiskSpaceNotEnough,
    DownloadOperationErrorCodeCannotCreateFile,
};

/* A list to indicate the download status */
typedef NS_ENUM(NSUInteger, DownloadOperationState)
{
    DownloadOperationStateReady = 0,      // The operation is fully initialized, but has not started yet
    DownloadOperationStateDownloading,
    DownloadOperationStateDone,           // Finished successfully
    DownloadOperationStateCancelled,     // Cancel by user
    DownloadOperationStateFailed,
};

@protocol DownloadOpearationDelegate;

/* Block types */
typedef void (^OperationErrorBlock) (NSError *error);
typedef void (^OperationCompletionBlock) (BOOL isSuccessful, NSString *filePath);
typedef void (^OperationReceiveDataBlock) (int64_t receivedLength, int64_t totalLength, float progress);

/* Class */
@interface DownloadOperation : NSOperation <NSURLConnectionDelegate, NSURLConnectionDataDelegate>

@property (nonatomic, assign) id<DownloadOpearationDelegate> delegate;

@property (nonatomic, assign, readonly) DownloadOperationState state;  // The state is determined by the internal statu of the operation

/* Some property to search the donwnload target */
@property (nonatomic, copy, readonly) NSString *fileName;
@property (nonatomic, copy, readonly) NSString *pathToDownload;  // The directory not including the file name
@property (nonatomic, copy, readonly) NSString *downloadUrl;       // In a string type may not be very suitable

/* Designate initializers */
- (instancetype)initWithDownloadUrl:(NSURL *)targetUrl pathToStore:(NSString *)pathToStoreFile andDelegate:(id<DownloadOpearationDelegate>)delegate;

- (instancetype)initWithDownloadUrl:(NSURL *)targetUrl
                              pathToStore:(NSString *)pathToStoreFile
                                     error:(OperationErrorBlock)errorBlock
                                 progress:(OperationReceiveDataBlock)progressBlock
                           andCompletion:(OperationCompletionBlock)completionBlock;
@end

@protocol DownloadOpearationDelegate <NSObject>

@optional

/* Notify the delegate that something went wrong during the download */
- (void)downloadOperation:(DownloadOperation *)operation didStopWithError:(NSError *)error;

/* The isSuccessful param will be set according to the download statu, and delegate will also get the full file path for the downloaded file */
- (void)downloadOperation:(DownloadOperation *)operation finished:(BOOL)isSuccessful forFileAtPath:(NSString *)filePath;

/* You may care about the progress in this interface only */
- (void)downloadOperation:(DownloadOperation *)operation didReceviceData:(int64_t)receivedLength toTotal:(int64_t)totalLength progress:(float)progress;

@end
