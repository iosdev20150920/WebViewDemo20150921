/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : AddressBarControlButton.h
 *
 * Description   : This widget shows on the right of the AddressBar to descript the state of the AddressBar and do some controlling 
 *                      such as refresh the webview or stop loading a page
 *
 * Creation       : 2015/06/25
 * Author          : luyc@ucweb.com
 * History         :
 *                 Creation, 2015/06/25, luyc, Create the file
 ***************************************************************************
 **/

#import <UIKit/UIKit.h>

/* An enum to indicate all possible state  of this button */
typedef NS_ENUM(NSUInteger, AddressBarState)
{
    AddressBarStateNormal = 0,
    AddressBarStateRefreshing,
    AddressBarStateFinishLoading,
};

@interface AddressBarControlButton : UIButton

@property (nonatomic, assign) AddressBarState currentState;  // Change the icon according to this property

@end
