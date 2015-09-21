/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : DownloadOperation.m
 *
 * Description   : The implementation of DownloadOperation
 *
 *
 * Creation      : 2015/06/29
 * Author         : luyc@ucweb.com
 * History        :
 *                 Creation, 2015/06/29, luyc, Create the file
 ***************************************************************************
 **/

#import "DownloadOperation.h"

static const NSTimeInterval kDefaultRequestTimeout = 30;
static const NSUInteger kMaximumCachedDataLength = 1024 * 10;

NSString *const kDownloadOperationErrorDomain = @"com.ucweb.DownloadOperation";

@interface DownloadOperation ()

@property (nonatomic, retain) NSURLConnection *connection;
@property (nonatomic, retain) NSMutableURLRequest *downloadRequest;
@property (nonatomic, retain) NSFileHandle *fileWriter;
@property (nonatomic, retain) NSMutableData *receivedDataBuffer;

/* Statu list */
@property (nonatomic, copy, readwrite) NSString *fileName;
@property (nonatomic, copy, readwrite) NSString *pathToDownload;
@property (nonatomic, copy, readwrite) NSString *downloadUrl;

@property (nonatomic, assign, readwrite) DownloadOperationState state;

/* Call back blocks */
@property (nonatomic, copy) OperationErrorBlock errorCallBack;
@property (nonatomic, copy) OperationReceiveDataBlock progressCallBack;
@property (nonatomic, copy) OperationCompletionBlock completionCallBack;  // CompletionCallBack can easily be written wrong as completionBlock, attention!

/* properties used to calculate the progress */
@property (nonatomic, assign) UInt64 expectedLength; // How many to be received
@property (nonatomic, assign) UInt64 receivedLength; // How many received

@end

@implementation DownloadOperation

- (instancetype)initWithDownloadUrl:(NSURL *)targetUrl pathToStore:(NSString *)pathToStoreFile andDelegate:(id<DownloadOpearationDelegate>)delegate
{
    if ((self = [super init]))
    {
        _expectedLength = -1;
        _receivedDataBuffer = 0;
        
        _delegate = delegate;

        _downloadUrl = [[NSString alloc] initWithFormat:@"%@", [targetUrl absoluteString]];
        _fileName = [[NSString alloc] initWithFormat:@"%@", [targetUrl lastPathComponent]];  // Use the last part of the url as the file name..
        _pathToDownload = [pathToStoreFile copy];
        _state = DownloadOperationStateReady;  // The operation is ready, not hasn't started yet
        
        _downloadRequest = [[NSMutableURLRequest alloc] initWithURL:targetUrl cachePolicy:NSURLRequestUseProtocolCachePolicy timeoutInterval:kDefaultRequestTimeout];
    }
    
    return self;
}

- (instancetype)initWithDownloadUrl:(NSURL *)targetUrl
                        pathToStore:(NSString *)pathToStoreFile
                              error:(OperationErrorBlock)errorBlock
                           progress:(OperationReceiveDataBlock)progressBlock
                      andCompletion:(OperationCompletionBlock)completionBlock
{
    self = [self initWithDownloadUrl:targetUrl pathToStore:pathToStoreFile andDelegate:nil];
    
    self.errorCallBack = errorBlock;
    self.progressCallBack = progressBlock;
    self.completionCallBack = completionBlock;
    
    return self;
}

- (void)dealloc
{
    [_connection unscheduleFromRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    [_connection cancel];
    [_connection release];
    _connection = nil;
    
    [_downloadRequest release];
    _downloadRequest = nil;
    
    [_fileWriter closeFile];
    [_fileWriter release];
    _fileWriter = nil;
    
    [_receivedDataBuffer setData:nil];
    [_receivedDataBuffer release];
    _receivedDataBuffer = nil;
    
    [_downloadUrl release];
    _downloadUrl = nil;
    
    self.errorCallBack = nil;
    self.progressCallBack = nil;
    self.completionCallBack = nil;

    [super dealloc];
}


- (void)notifyCompletionWithError:(NSError *)error pathToFile:(NSString *)filePath
{
    if (error != nil)
    {
        /* If there's something wrong with the download, notice delegate and call error block */
        dispatch_async(dispatch_get_main_queue(), ^{
            
            /* Invoke the call back block */
            if (self.errorCallBack != nil)
            {
                self.errorCallBack(error);
            }
            
            /* Nofity the delegate */
            if ([self.delegate respondsToSelector:@selector(downloadOperation:didStopWithError:)])
            {
                [self.delegate downloadOperation:self didStopWithError:error];
            }
        });
    }
    
    BOOL success = (error == nil);
    
    /* Completion notification and block invoked */
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.completionCallBack != nil)
        {
            self.completionCallBack(success, filePath);
        }
        
        if ([self.delegate respondsToSelector:@selector(downloadOperation:finished:forFileAtPath:)])
        {
            [self.delegate downloadOperation:self finished:success forFileAtPath:filePath];
        }
    });
    
    
    /* Finished this operation */
    DownloadOperationState state = success ? DownloadOperationStateDone : DownloadOperationStateFailed;
    [self finisheOperationWithState:state];
}

- (void)finisheOperationWithState:(DownloadOperationState)state
{
    /* Release resource */
    [self.connection cancel];
    [self.fileWriter closeFile];
    
    /* Set status */
    [self willChangeValueForKey:@"isExecuting"];
    [self willChangeValueForKey:@"isFinished"];
    
    self.state = state;
    
    [self didChangeValueForKey:@"isExecuting"];
    [self didChangeValueForKey:@"isFinished"];
}

#pragma mark -
#pragma mark Functions To Override
- (void)start
{
    if (![NSURLConnection canHandleRequest:self.downloadRequest])
    {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Invalid url %@", self.downloadRequest.URL]};
        NSError *error = [NSError errorWithDomain:kDownloadOperationErrorDomain code:DownloadOperationErrorCodeInvalidUrl userInfo:userInfo];
        [self notifyCompletionWithError:error pathToFile:nil];  // The operation is cancelled by now
        
        return;
    }
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    
    /* Prepare the directory to store the file to be downloaded */
    if (![fileManager fileExistsAtPath:self.pathToDownload])
    {
        NSError *error = nil;
        if ([fileManager createDirectoryAtPath:self.pathToDownload withIntermediateDirectories:YES attributes:nil error:&error])
        {
            [self notifyCompletionWithError:error pathToFile:nil];
            
            return;
        }
    }
    
    NSString *filePath = [self.pathToDownload stringByAppendingPathComponent:self.fileName];
    if ([fileManager fileExistsAtPath:filePath])
    {
        NSInteger fileCount = 0;
        NSArray *content = [fileManager contentsOfDirectoryAtPath:self.pathToDownload error:nil];
        for (NSString *fileName in content)
        {
            if ([fileName hasPrefix:self.fileName])
            {
                ++ fileCount;
            }
        }
        
        NSString *newFileName = [NSString stringWithFormat:@"%@(%d)", self.fileName, (int)fileCount];
        filePath = [self.pathToDownload stringByAppendingPathComponent:newFileName];
        self.fileName = newFileName;
    }
    
    /* Create en empty file to recevie date from network */
    if (![fileManager createFileAtPath:filePath contents:nil attributes:nil])
    {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Can not create file %@",  self.fileName]};
        NSError *error = [NSError errorWithDomain:kDownloadOperationErrorDomain code:DownloadOperationErrorCodeCannotCreateFile userInfo:userInfo];
        [self notifyCompletionWithError:error pathToFile:nil];
        
        return;
    }

    /* Bind a file handle to the file we're going to write data into */
    _fileWriter = [[NSFileHandle fileHandleForWritingAtPath:filePath] retain];
    if (self.fileWriter == nil)
    {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Can not open file to write %@",  self.fileName]};
        NSError *error = [NSError errorWithDomain:kDownloadOperationErrorDomain code:DownloadOperationErrorCodeCannotOpenFileToWrite userInfo:userInfo];
        [self notifyCompletionWithError:error pathToFile:nil];
     
        return;
    }
    
    _receivedDataBuffer = [[NSMutableData alloc] init];
    _connection = [[NSURLConnection alloc] initWithRequest:self.downloadRequest delegate:self startImmediately:NO];
 
    if (self.connection != nil && !self.isCancelled)
    {
        /* Okay, let's start rolling~ */
        [self willChangeValueForKey:@"isExecuting"];
        [self setState:DownloadOperationStateDownloading];
        [self didChangeValueForKey:@"isExecuting"];
        
        NSRunLoop *currentRunLoop = [NSRunLoop currentRunLoop];
        [self.connection scheduleInRunLoop:currentRunLoop forMode:NSDefaultRunLoopMode];
        
        [self.connection start];
        [currentRunLoop run];
    }
}

- (BOOL)isCancelled
{
    return _state == DownloadOperationStateCancelled;
}

- (BOOL)isFinished
{
    return _state == DownloadOperationStateCancelled ||_state == DownloadOperationStateDone || _state == DownloadOperationStateFailed;
}

- (BOOL)isExecuting
{
    return _state = DownloadOperationStateDownloading;
}

- (void)cancel
{
    [self willChangeValueForKey:@"isCancelled"];
    [self setState:DownloadOperationStateCancelled];
    [self didChangeValueForKey:@"isCancelled"];
}


#pragma mark - 
#pragma mark NSURL Connection Delegate
- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error
{
    [self notifyCompletionWithError:error pathToFile:self.fileName];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data
{
    [self.receivedDataBuffer appendData:data];
    if (self.receivedDataBuffer.length > kMaximumCachedDataLength && !self.isCancelled)
    {
        /* Time to move some data out of memery and write them to the disk */
        [self.fileWriter writeData:self.receivedDataBuffer];
        [self.receivedDataBuffer setData:nil];
    }
    
    /* Calculate the progress here */
    self.receivedLength += [data length];
    float progress = (float)self.receivedLength / (float)self.expectedLength; // 0.0 ~ 1.0
    
    dispatch_async(dispatch_get_main_queue(), ^{
        if (self.progressCallBack != nil)
        {
            self.progressCallBack(self.receivedLength, self.expectedLength, progress);
        }
        
        if ([self.delegate respondsToSelector:@selector(downloadOperation:didReceviceData:toTotal:progress:)])
        {
            [self.delegate downloadOperation:self didReceviceData:self.receivedLength toTotal:self.expectedLength progress:progress];
        }
    });
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response
{

    if (![response isKindOfClass:[NSHTTPURLResponse class]])
    {
        return ;
    }
    
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    if (httpResponse.statusCode / 100 != 2)  // Only status code begin with 2 will be regarded as successful response, is this correct ??
    {
        return;
    }
    
    /* Do disk space checking only when first time we get the item's size who's going to be donwloaded */
    if (self.expectedLength == -1)
    {
        self.expectedLength = httpResponse.expectedContentLength;
        
        /* Get the free space of the document directory */
        NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
        NSDictionary *fileSystemAttribute = [[NSFileManager defaultManager] attributesOfFileSystemForPath:documentPath error:nil];
        
        UInt64 freeSpace = [fileSystemAttribute[NSFileSystemFreeSize] longLongValue];
        if (freeSpace < self.expectedLength && self.expectedLength != -1)   // Sometimes we get a negative expected length
        {
            NSDictionary *userInfo = @{NSLocalizedDescriptionKey : [NSString stringWithFormat:@"Disk free space is not enough to store file %@", self.fileName]};
            NSError *error = [NSError errorWithDomain:kDownloadOperationErrorDomain code:DownloadOperationErrorCodeDiskSpaceNotEnough userInfo:userInfo];
            
            [self notifyCompletionWithError:error pathToFile:self.fileName];
        }
    }
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection
{
    if (self.isExecuting)
    {
        [self.fileWriter writeData:self.receivedDataBuffer];
        [self.receivedDataBuffer setData:nil];
        
        [self notifyCompletionWithError:nil pathToFile:self.fileName];
    }
}
@end
