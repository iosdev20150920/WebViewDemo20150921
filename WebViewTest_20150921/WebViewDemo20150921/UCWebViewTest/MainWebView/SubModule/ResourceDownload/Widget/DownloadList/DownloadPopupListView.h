/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : DownloadPopupListView.h
 *
 * Description   : DownloadPopupListView is a view to display special table view cells, it animates itself when show and hide
 *
 * Creation      : 2015/06/30
 * Author         : luyc@ucweb.com
 * History        :
 *                 Creation, 2015/06/30, luyc, Create the file
 ***************************************************************************
 **/
#import <UIKit/UIKit.h>

@interface DownloadPopupListView : UIView

@property (nonatomic, retain, readonly) UITableView *listView;

- (void)showListView:(BOOL)show animated:(BOOL)animated;

@end
