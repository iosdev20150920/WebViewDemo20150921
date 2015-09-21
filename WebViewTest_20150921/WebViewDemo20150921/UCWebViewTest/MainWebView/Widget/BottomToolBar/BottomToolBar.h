/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : BottomToolBar.h
 *
 * Description   : This tool bar locate to the bottom of the main view, and provide an interface to enable/disable. It just acts like any other
 *                      tool bars. Instead of linking the items' action to your class, please register you class instance as the delegate and handle
 *                      the tool bar item actions in that delegate function.
 *
 * Creation       : 2015/06/26
 * Author          : luyc@ucweb.com
 * History         :
 *                 Creation, 2015/06/26, luyc, Create the file
 ***************************************************************************
 **/


#import <UIKit/UIKit.h>


@class BottomToolBar;
@protocol BottomToolBarDelegate <NSObject>

@optional
- (void)bottomBar:(BottomToolBar *)toolbar didPressButtonAtIndex:(NSInteger)index;  // Response according to the index

@end

@interface BottomToolBar : UIView

@property (nonatomic, assign) id<BottomToolBarDelegate> delegate;

//- (void)setItems:(NSArray *)barButtonItemArray animated:(BOOL)animated;
- (void)setItemsWithIcons:(NSArray *)iconArray titles:(NSArray*)titleArray animated:(BOOL)animated;

- (void)setEnable:(BOOL)enable forItemAtIndex:(NSInteger)index;  // You may need this interface to alter the toolbar correctly

@end
