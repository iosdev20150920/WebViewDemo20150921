/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : DownloadController.m
 *
 * Description   : A simple wrap to handle the download
 *
 * Creation      : 2015/06/30
 * Author         : luyc@ucweb.com
 * History        :
 *                 Creation, 2015/06/30, luyc, Create the file
 ***************************************************************************
 **/


#import "DownloadController.h"
#import "DownloadOperationManager.h"
#import "DownloadPopupListView.h"
#import "DownloadItemTableViewCell.h"
#import "FilePathManager.h"
#import "File.h"

static NSString *const kDownloadItemInfoKeyName = @"Name";
static NSString *const kDownLoadItemInfoKeySize = @"Size";
static NSString *const kDownLoadItemInfoKeySucc = @"isSucc";

typedef NS_ENUM(NSUInteger, DownloadItemState)
{
    DownloadItemStateReady = 1,
    DownloadItemStateDone,
    DownloadItemStateFailed,
};

typedef struct
{
    unsigned int DelegateRespondsToNavigatioin : 1;
    unsigned int DelegateRespondsToRemoveFile : 1;
    unsigned int DelegateRespondsToRemoveAllFiles : 1;
    
    unsigned int DelegateRespondsToFinishedDownload : 1;
    unsigned int DelegateRespondsToFailedDownload : 1;
    
    unsigned int DelegateRespondsToDownloadProgress : 1;
}DelegateFlags;


@interface DownloadController () <UITableViewDataSource, UITableViewDelegate, DownloadItemTableViewCellDelegate, UIAlertViewDelegate>
{
    DelegateFlags _delegateFlags;
}

@property (nonatomic, retain) NSMutableArray *downloadItems;
@property (nonatomic, retain) DownloadPopupListView *popupListView;
@property (nonatomic, retain) NSLock *lock;

@property (nonatomic, assign) UInt64 totalOfTotalLength;
@property (nonatomic, assign) UInt64 totalOfReceivedLength;

@end


@implementation DownloadController

- (instancetype)init
{
    if ((self = [super init]))
    {
        _lock = [[NSLock alloc] init];
    
        memset(&_delegateFlags, 0, sizeof(DelegateFlags));
    }
    
    return self;
}

- (void)dealloc
{
    [_lock release];
    _lock = nil;
    
    [_downloadItems release];
    _downloadItems = nil;
    
    [_popupListView.listView setDelegate:nil];
    [_popupListView.listView setDataSource:nil];
    
    [_popupListView removeFromSuperview];
    [_popupListView release];
    _popupListView = nil;
    
    [super dealloc];
}

- (void)setDelegate:(id<DownloadControllerDelegate>)delegate
{
    _delegate = delegate;
    memset(&_delegateFlags, 0, sizeof(DelegateFlags));
    
    if ([delegate respondsToSelector:@selector(downloadController:didFinishedDownloadFile:)])
    {
        _delegateFlags.DelegateRespondsToFinishedDownload = YES;
    }
    
    if ([delegate respondsToSelector:@selector(downloadController:didFailedToDownloadFile:error:)])
    {
        _delegateFlags.DelegateRespondsToFailedDownload = YES;
    }
    
    if ([delegate respondsToSelector:@selector(downloadController:didRemoveFile:)])
    {
        _delegateFlags.DelegateRespondsToRemoveFile = YES;
    }
    
    if ([delegate respondsToSelector:@selector(downloadController:needToNavigateToPath:)])
    {
        _delegateFlags.DelegateRespondsToNavigatioin = YES;
    }
    
    if ([delegate respondsToSelector:@selector(downloadControllerDidRemoveAllFiles:)])
    {
        _delegateFlags.DelegateRespondsToRemoveAllFiles = YES;
    }
    
    if ([delegate respondsToSelector:@selector(downloadController:downloadToProgress:)])
    {
        _delegateFlags.DelegateRespondsToDownloadProgress = YES;
    }
}

- (void)createPopupListViewIfNeeded
{
    if (self.popupListView != nil)
    {
        return;
    }
    
    UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
    _popupListView = [[DownloadPopupListView alloc] initWithFrame:keyWindow.bounds];
    
    [_popupListView.listView setDelegate:self];
    [_popupListView.listView setDataSource:self];
    [_popupListView.listView registerClass:[DownloadItemTableViewCell class] forCellReuseIdentifier:@"Cell"];
    [_popupListView setAutoresizesSubviews:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    
    [self.popupListView showListView:NO animated:NO];
    
    /* Load history download record when first time the table view is created */
    NSString *path = [[DownloadOperationManager sharedInstance] defaultPathToDownload];
    FilePathManager *manager = [[FilePathManager alloc] init];
    
    [manager changeToAbsoluteFilePath:path];
    NSArray *fileList = [manager fileList];
    
    for (File *file in fileList)
    {
        if (self.downloadItems == nil)
        {
            self.downloadItems = [NSMutableArray array];
        }
        
        NSMutableDictionary *downloadItem = [NSMutableDictionary dictionary];
        downloadItem[kDownloadItemInfoKeyName] = file.fileName;
        downloadItem[kDownLoadItemInfoKeySucc] = @(DownloadItemStateDone);
        
        [self.downloadItems addObject:downloadItem];
    }
    
    [manager release];
}


- (void)addDownloadToTarget:(NSURL *)downloadUrl
{
    [self createPopupListViewIfNeeded];
    
    NSMutableDictionary *downloadItem = [NSMutableDictionary dictionary];
    NSString *urlString = [downloadUrl absoluteString];
    NSString *targetName = [urlString lastPathComponent];
    
    downloadItem[kDownloadItemInfoKeyName] = targetName;
    downloadItem[kDownLoadItemInfoKeySucc] = @(DownloadItemStateReady);
    
    if (self.downloadItems == nil)
    {
        self.downloadItems = [NSMutableArray array];
    }
    
    [self.downloadItems addObject:downloadItem];
    NSInteger index = self.downloadItems.count - 1;
    
    DownloadOperationManager *downloadManager = [DownloadOperationManager sharedInstance];
    [downloadManager startDownloadFile:downloadUrl toLocalFilePath:nil errorBlock:^(NSError *error) { // Error block
        
        /* Reset the download item's succ flag */
        NSMutableDictionary *itemInfo = self.downloadItems[index];
        itemInfo[kDownLoadItemInfoKeySucc] = @(DownloadItemStateFailed);
        itemInfo[kDownLoadItemInfoKeySize] = @"下载失败";
        
        [self.popupListView.listView reloadData];
        
        /* Notice delegate */
        if (_delegateFlags.DelegateRespondsToFailedDownload)
        {
            NSString *filePath = [[downloadManager defaultPathToDownload] stringByAppendingPathComponent:targetName];
            [self.delegate downloadController:self didFailedToDownloadFile:filePath error:error];
        }
        
    } progressBlock:^(int64_t receivedLength, int64_t totalLength, float progress) { // Progress block
        
        DownloadItemTableViewCell *cell = (DownloadItemTableViewCell*)[self.popupListView.listView
                                                                       cellForRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0]];
        
        /* If the attached cell currentyl is not visible, we do nothing for this progress block */
        if ([[self.popupListView.listView visibleCells] containsObject:cell])
        {
            [cell setProgress:progress];
        }
        
    } completionBlock:^(BOOL isSuccessful, NSString *fileName) { // Completion block
        
        NSMutableDictionary *downloadItem = self.downloadItems[index];
        if (!isSuccessful)
        {
            downloadItem[kDownLoadItemInfoKeySucc] = @(DownloadItemStateFailed);
        }
        else
        {
            downloadItem[kDownLoadItemInfoKeySucc] = @(DownloadItemStateDone);
        }
        
        downloadItem[kDownloadItemInfoKeyName] = fileName;
        [self.popupListView.listView reloadData];
        
        if (_delegateFlags.DelegateRespondsToFinishedDownload)
        {
            NSString *filePath = [[downloadManager defaultPathToDownload] stringByAppendingPathComponent:fileName];
            [self.delegate downloadController:self didFinishedDownloadFile:filePath];
        }
        
    }];
}

- (void)showDownloadListView:(BOOL)show anmiated:(BOOL)animated
{
    [self.popupListView showListView:show animated:animated];
}

#pragma mark - 
#pragma mark UI Table View Delegate And Data Source 
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.downloadItems count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    DownloadItemTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"Cell"];
    if (cell == nil)
    {
        cell = [[DownloadItemTableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"Cell"];
    }
    
    NSDictionary *itemInfo = self.downloadItems[indexPath.row];
    NSString *fileName = itemInfo[kDownloadItemInfoKeyName];
    DownloadItemState itemState = [itemInfo[kDownLoadItemInfoKeySucc] integerValue];
    
    [cell.textLabel setText:fileName];
    [cell setDelegate:self];
    
    if (itemState == DownloadItemStateDone)
    {
        [cell setHint:@"下载完成"];
    }
    else if (itemState == DownloadItemStateFailed)
    {
        [cell setHint:@"下载失败"];
    }
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    [self showDownloadListView:NO anmiated:YES];
    
    NSString *fileName = self.downloadItems[indexPath.row][kDownloadItemInfoKeyName];
    NSString *filePath = [[[DownloadOperationManager sharedInstance] defaultPathToDownload] stringByAppendingPathComponent:fileName];
    
    if (_delegateFlags.DelegateRespondsToNavigatioin)
    {
        [self.delegate downloadController:self needToNavigateToPath:filePath];
    }
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.f;
}


- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        UIView *view = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.popupListView.listView.bounds), 50)] autorelease];
        [view setBackgroundColor:[UIColor colorWithRed:36 / 255.f green:114 / 255.f blue:255/ 255.f alpha:1]];
        
        UILabel *title = [[UILabel alloc] initWithFrame:view.bounds];
        [title setFont:[UIFont systemFontOfSize:15.f]];
        [title setTextColor:[UIColor whiteColor]];
        [title setBackgroundColor:[UIColor clearColor]];
        [title setTextAlignment:NSTextAlignmentCenter];
        [title setText:@"下载列表"];
        
        [view addSubview:title];
        [title release];
        
        return view;
    }

    
    return nil;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    if (section == 0)
    {
        return 50.f;
    }
    
    return 0.1f;
}

#pragma mark - 
#pragma mark Down Load Item Table View Cell Delegate
- (void)removeDownloadItem:(DownloadItemTableViewCell *)itemCell
{
    NSIndexPath *indexPath = [self.popupListView.listView indexPathForCell:itemCell];
    
    UIAlertView *view = [[[UIAlertView alloc] initWithTitle:@"删除下载" message:@"是否同时删除文件" delegate:self cancelButtonTitle:@"是" otherButtonTitles:@"否", nil] autorelease];
    view.tag = indexPath.row;
    [view show];
}

#pragma mark - 
#pragma mark UI Alert View Delegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSIndexPath *indexPath = [NSIndexPath indexPathForRow:alertView.tag inSection:0];
    NSString *fileName = self.downloadItems[indexPath.row][kDownloadItemInfoKeyName];
    
    [self.popupListView.listView beginUpdates];
    [self.popupListView.listView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    [self.downloadItems removeObjectAtIndex:indexPath.row];
    [self.popupListView.listView endUpdates];
    
    NSString *filePath = [[[DownloadOperationManager sharedInstance] defaultPathToDownload] stringByAppendingPathComponent:fileName];

    if (buttonIndex == 0)
    {
        [[NSFileManager defaultManager] removeItemAtPath:filePath error:nil];
    }
    
    if (_delegateFlags.DelegateRespondsToRemoveFile)
    {
        [self.delegate downloadController:self didRemoveFile:filePath];
    }
    
    if (self.downloadItems.count == 0)
    {
        [_downloadItems release];
        _downloadItems = nil;
        
        if (_delegateFlags.DelegateRespondsToRemoveAllFiles)
        {
            [self.delegate downloadControllerDidRemoveAllFiles:self];
        }
    }
}


@end
