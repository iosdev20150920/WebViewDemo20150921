/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : ProgressButton.h
 *
 * Description   : A small wrap widget for user to show the download items list view and also, notice the user with 
 *                   the total download progress
 *
 * Creation      : 2015/07/01
 * Author         : luyc@ucweb.com
 * History        :
 *                 Creation, 2015/07/01, luyc, Create the file
 ***************************************************************************
 **/

#import <UIKit/UIKit.h>

@interface ProgressButton : UIView

- (void)setProgress:(CGFloat)progress;

- (void)addTarget:(id)target action:(SEL)action;
- (void)removeTarget:(id)target;

@end
