/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : MainWebViewController.h
 *
 * Description   : This is the main interface contorller of this project, it contains the UIWebview to display network contents on it.
 *
 * Creation       : 2015/06/25
 * Author          : luyc@ucweb.com
 * History         :
 *                 Creation, 2015/06/25, luyc, Create the file
 ***************************************************************************
 **/

#import <UIKit/UIKit.h>

@interface MainWebViewController : UIViewController

- (void)setDetectedFileSuffixes:(NSArray *)fileSuffixes;  // What types of file do we want to download 

@end

