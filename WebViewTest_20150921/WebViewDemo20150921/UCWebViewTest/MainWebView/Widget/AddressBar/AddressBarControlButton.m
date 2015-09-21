/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : AddressBarControlButton.m
 *
 * Description   : Implementation file
 *
 * Creation       : 2015/06/25
 * Author          : luyc@ucweb.com
 * History         :
 *                 Creation, 2015/06/25, luyc, Create the file
 ***************************************************************************
 **/

#import "AddressBarControlButton.h"

@implementation AddressBarControlButton

- (void)setCurrentState:(AddressBarState)currentState
{
    _currentState = currentState;
    
    NSString *iconName = nil;  // A string to store the button icon
    switch(currentState)
    {
        case AddressBarStateFinishLoading:
        {
            iconName = @"NavigationBarReload.png";  //******* Would this statement leak some memery, let's test it later!!
        }
            break;
            
        case AddressBarStateNormal:
        {
            iconName = @"ToolBarIcon1.png";
        }
            break;
            
        case AddressBarStateRefreshing:
        {
            iconName = @"NavigationBarStopLoading.png";
        }
            break;
            
        default:
            break;
    }
    
    /* Set the icon */
    UIImage *icon = [UIImage imageNamed:iconName] ;
    [self setImage:icon forState:UIControlStateNormal];
}

@end
