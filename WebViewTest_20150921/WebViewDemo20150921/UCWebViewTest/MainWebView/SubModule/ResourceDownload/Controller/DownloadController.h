/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : DownloadController.h
 *
 * Description   : A simple wrap to handle the download
 *
 * Creation      : 2015/06/30
 * Author         : luyc@ucweb.com
 * History        :
 *                 Creation, 2015/06/30, luyc, Create the file
 ***************************************************************************
 **/

#import <Foundation/Foundation.h>

@protocol DownloadControllerDelegate;

@interface DownloadController : NSObject

@property (nonatomic, assign) id<DownloadControllerDelegate> delegate;

- (void)showDownloadListView:(BOOL)show anmiated:(BOOL)animated;
- (void)addDownloadToTarget:(NSURL *)donwloadUrl;

@end


@protocol DownloadControllerDelegate <NSObject>

@optional
- (void)downloadController:(DownloadController *)controller needToNavigateToPath:(NSString *)path;
- (void)downloadController:(DownloadController *)controller didRemoveFile:(NSString *)filePath;
- (void)downloadControllerDidRemoveAllFiles:(DownloadController *)controller;

- (void)downloadController:(DownloadController *)controller didFinishedDownloadFile:(NSString *)filePath;
- (void)downloadController:(DownloadController *)controller didFailedToDownloadFile:(NSString *)filePath error:(NSError *)error;

- (void)downloadController:(DownloadController *)controller downloadToProgress:(float)progress;

@end