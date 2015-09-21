/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : HistoryViewController.h
 *
 * Description   : This view controller is used to display the user's surfing history, it provides user ways to delete any amout of history
 *                      reocrds.
 *                  
 *                      It share the records with MainWebViewController, so you need to give it HistorySaver instance to access the data
 *
 * Creation       : 2015/06/26
 * Author          : luyc@ucweb.com
 * History         :
 *                 Creation, 2015/06/26, luyc, Create the file
 ***************************************************************************
 **/


#import <UIKit/UIKit.h>

@protocol HistoryViewControllerDelegate <NSObject>

@optional
- (void)loadHistoryURL:(NSURL *)url;

@end

@class  HistorySaver;
@interface HistoryViewController : UIViewController

@property (nonatomic, assign) id<HistoryViewControllerDelegate> delegate;
@property (nonatomic, retain) HistorySaver* historySaver;

@end
