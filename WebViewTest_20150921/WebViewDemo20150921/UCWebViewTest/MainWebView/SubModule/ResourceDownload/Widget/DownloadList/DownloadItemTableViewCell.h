/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : DownloadItemTableViewCell.h
 *
 * Description   : DownlaodItemTableViewCell provides an special interface to display the download progress and download item name,
 *                    it also provides a simple deleting button
 *
 * Creation      : 2015/06/30
 * Author         : luyc@ucweb.com
 * History        :
 *                 Creation, 2015/06/30, luyc, Create the file
 ***************************************************************************
 **/

#import <UIKit/UIKit.h>

@class DownloadItemTableViewCell;
@protocol DownloadItemTableViewCellDelegate <NSObject>

@optional
- (void)removeDownloadItem:(DownloadItemTableViewCell *)itemCell;

@end

@interface DownloadItemTableViewCell : UITableViewCell

@property (nonatomic, assign) id<DownloadItemTableViewCellDelegate> delegate;

- (void)setHint:(NSString *)hint;
- (void)setProgress:(CGFloat)progress;

@end
