/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : BottomToolBar.m
 *
 * Description   : Implementation of BottomToolBar
 *
 * Creation       : 2015/06/26
 * Author          : luyc@ucweb.com
 * History         :
 *                 Creation, 2015/06/26, luyc, Create the file
 ***************************************************************************
 **/

#import "BottomToolBar.h"

@interface BottomToolBar ()

@property (nonatomic, retain) UIToolbar *toolbar;
@property (nonatomic, assign) BOOL canDelegateRepondsToButtonPressed;

@end

@implementation BottomToolBar

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        _canDelegateRepondsToButtonPressed = NO;
        
        /* Put the heavy constructing tasks here may not be very suitable */
        _toolbar = [[UIToolbar alloc] initWithFrame:self.bounds];
        [_toolbar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [_toolbar setTranslucent:NO];
        
        [self addSubview:_toolbar];
    }
    
    return self ;
}

- (void)dealloc
{
    for (UIBarButtonItem *barButton in [self.toolbar items])
    {
        [barButton setTarget:nil];
    }
    
    
    [_toolbar release];
    _toolbar = nil;
    
    [super dealloc];
}

- (void)setDelegate:(id<BottomToolBarDelegate>)delegate
{
    _delegate = delegate;
    self.canDelegateRepondsToButtonPressed = [delegate respondsToSelector:@selector(bottomBar:didPressButtonAtIndex:)];
}

- (void)setItemsWithIcons:(NSArray *)iconArray titles:(NSArray*)titleArray animated:(BOOL)animated
{
    if (iconArray == nil && titleArray == nil)
    {
        // It seems the user wants to create an empty tool bar
        return;
    }
    
    if (iconArray.count == 0 && titleArray.count == 0)
    {
        // It seems the user wants to create an empty tool bar
        return ;
    }
    
    NSInteger maximumIndex = MAX(iconArray.count, titleArray.count); // User may put a @[ ] into this function
    
    NSMutableArray *itemsArray = [NSMutableArray array];
    for (NSInteger index = 0; index < maximumIndex; ++ index)
    {
        UIBarButtonItem *barButton = nil;
        if (iconArray != nil && iconArray.count != 0)  // Add icons
        {
            UIImage *icon = [UIImage imageNamed:iconArray[index]];
            barButton = [[UIBarButtonItem alloc] initWithImage:icon style:UIBarButtonItemStyleBordered target:self action:@selector(onBarButtonItemPressed:)];
        }
        
        if (titleArray != nil && titleArray.count != 0) // Add titles
        {
            if (barButton != nil)
            {
                [barButton setTitle:titleArray[index]];
            }
            else
            {
                barButton = [[UIBarButtonItem alloc] initWithTitle:titleArray[index] style:UIBarButtonItemStylePlain target:self action:@selector(onBarButtonItemPressed:)];
            }
        }
    
        if (barButton == nil)
        {
            continue;
        }
        
        barButton.tag = index;
        [itemsArray addObject:barButton];
        [barButton release];
        
        if (index != maximumIndex - 1)
        {
            /* Add a space item after each item except the last one to make it tidy */
            UIBarButtonItem *spaceItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
            [itemsArray addObject:spaceItem];
            [spaceItem release];
        }
    }
    
    [self.toolbar setItems:itemsArray animated:animated];
}

- (void)setItems:(NSArray *)barButtonItemArray animated:(BOOL)animated
{
    
}


- (void)onBarButtonItemPressed:(UIBarButtonItem *)barButton
{
    if (self.canDelegateRepondsToButtonPressed)
    {
        [self.delegate bottomBar:self didPressButtonAtIndex:barButton.tag];
    }
}

- (void)setEnable:(BOOL)enable forItemAtIndex:(NSInteger)index
{
    for (UIBarButtonItem *barButton in self.toolbar.items)
    {
        if (barButton.tag == index)
        {
            [barButton setEnabled:enable];
            break;  // Only the first item with tag 0 will be hit when index is equal to 0
        }
    }
}
@end
