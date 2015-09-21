/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : AddressBar.h
 *
 * Description   : This widget helps to get the searching target from the user 
 *
 * Creation       : 2015/06/25
 * Author          : luyc@ucweb.com
 * History         :
 *                 Creation, 2015/06/25, luyc, Create the file
 ***************************************************************************
 **/

#import <UIKit/UIKit.h>
#import "AddressBarControlButton.h"  // We need the enum

/* Protocol for address bar to control the loading process */
@class AddressBar;
@protocol  AddressBarDelegate <NSObject>

@optional
- (void)addressBar:(AddressBar *)addressBar requireToLoadURL:(NSURL *)targetUrl;
- (void)addressBar:(AddressBar *)addressBar requireToRefreshURL:(NSURL *)targetUrl;

- (void)addressBarRequireToStopLoading:(AddressBar *)addressBar;
- (void)addressBarDidStartEditing:(AddressBar *)addressBar;

@end

/* Error handle */
typedef NS_ENUM(NSInteger, AddressBarErrorCode)
{
    AddressBarErrorCodeTooManyItems = 1,
};

extern NSString *const AddressBarErrorDomain;
//////////////////

/* Class */
@interface AddressBar : UIView

@property (nonatomic , assign) id<AddressBarDelegate> delegate;

- (void)setAddressBarText:(NSString *)text;
- (void)setAddressBarState:(AddressBarState)barState;

/* We can now add/remove items to the right of the address bar */
- (BOOL)addToolItem:(UIView *)item animated:(BOOL)animated error:(NSError **)error;
- (void)removeToolItem:(UIView *)item animated:(BOOL)animated;

@end
