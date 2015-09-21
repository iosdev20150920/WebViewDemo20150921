/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : AddressBar.m
 *
 * Description   : Implementation file
 *
 * Creation       : 2015/06/25
 * Author          : luyc@ucweb.com
 * History         :
 *                 Creation, 2015/06/25, luyc, Create the file
 ***************************************************************************
 **/

#import "AddressBar.h"

/* Delegate capabilities */
typedef struct
{
    unsigned int DelegateRespondsToLoadURL : 1;
    unsigned int DelegateRespondsToReload : 1;
    unsigned int DelegateRespondsToStopLoading : 1;
    unsigned int DelegateRespondsToBeginEditing : 1;
}DelegateFlags;

static const CGFloat Padding = 5.f;  // The space between each tool item

NSString *const AddressBarErrorDomain = @"com.ucweb.AddressBarError";  // For error handling;

@interface AddressBar () <UITextFieldDelegate>
{
    DelegateFlags _delegateFlags;
}

@property (nonatomic, retain) AddressBarControlButton *controlButton;
@property (nonatomic, retain) UITextField *linkInputTextField;

@property (nonatomic, retain) NSMutableArray *toolItems; // An array holds the items added to the right of address bar
@property (nonatomic, retain) NSString *fixedUrl;          // We may do some fixing on the user input, and this string holds to fixed result

@property (nonatomic, assign) CGFloat textFieldCurrentWidth;

@end

@implementation AddressBar

- (instancetype)initWithFrame:(CGRect)frame
{
    CGFloat statubarHeight = [[UIApplication sharedApplication] statusBarFrame].size.height;
    frame.size.height = MIN(40 + statubarHeight, frame.size.height);

    self = [super initWithFrame:frame];
    if (self)
    {
        /* Set the initial state of the text field */
        CGFloat textFieldHeight = CGRectGetHeight(frame) - 2 * Padding - statubarHeight;
        
        _linkInputTextField = [[UITextField alloc] initWithFrame:CGRectMake(Padding, Padding + statubarHeight, CGRectGetWidth(frame) - 2 * Padding, textFieldHeight)];
        [_linkInputTextField setBorderStyle:UITextBorderStyleNone];
        [_linkInputTextField setDelegate:self];
        [_linkInputTextField setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        
        [_linkInputTextField setBackgroundColor:[UIColor colorWithWhite:0.9 alpha:1]];
        _linkInputTextField.layer.cornerRadius = 5.f;
        
        /* Set the initial state of the button */
        CGFloat controlButtonSize = CGRectGetHeight(self.linkInputTextField.bounds);
        
        _controlButton = [[AddressBarControlButton alloc] initWithFrame:CGRectMake(0, 0, controlButtonSize, controlButtonSize)];
        [_controlButton setCurrentState:AddressBarStateNormal];
        [_controlButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
        [_controlButton addTarget:self action:@selector(onControlButtonPressed) forControlEvents:UIControlEventTouchUpInside];  // Press on the control button
        
        /* Use it as the right view */
        [_linkInputTextField setRightViewMode:UITextFieldViewModeAlways];
        _linkInputTextField.rightView = _controlButton;
        
        [self addSubview:_linkInputTextField];
        
        /* And set the initial style of self */
        self.layer.borderWidth = 1.f;
        self.layer.borderColor = [UIColor colorWithWhite:0.9f alpha:1].CGColor;
        [self setBackgroundColor:[UIColor colorWithWhite:0.99 alpha:1]];
        
        memset(&_delegateFlags, 0, sizeof(DelegateFlags));
        
        _textFieldCurrentWidth = CGRectGetWidth(self.bounds) - 2 * Padding;
    }
    
    return self;
}

- (void)dealloc
{
    [_controlButton removeTarget:self action:@selector(onControlButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [_controlButton release];
    _controlButton = nil;
    
    [_linkInputTextField setDelegate:nil];
    [_linkInputTextField release];
    _linkInputTextField = nil;
    
    [_fixedUrl release];
    _fixedUrl = nil;

    [super dealloc];
}

- (void)setDelegate:(id<AddressBarDelegate>)delegate
{
    _delegate = delegate;
    memset(&_delegateFlags, 0, sizeof(DelegateFlags));
    
    if ([delegate respondsToSelector:@selector(addressBar:requireToLoadURL:)])
    {
        _delegateFlags.DelegateRespondsToLoadURL = YES;
    }
    
    if ([delegate respondsToSelector:@selector(addressBar:requireToRefreshURL:)])
    {
        _delegateFlags.DelegateRespondsToReload = YES;
    }
    
    if ([delegate respondsToSelector:@selector(addressBarRequireToStopLoading:)])
    {
        _delegateFlags.DelegateRespondsToStopLoading = YES;
    }
    
    if ([delegate respondsToSelector:@selector(addressBarDidStartEditing:)])
    {
        _delegateFlags.DelegateRespondsToBeginEditing = YES;
    }
}

- (void)setAddressBarState:(AddressBarState)barState
{
    [self.controlButton setCurrentState:barState];
}

- (void)setAddressBarText:(NSString *)text
{
    [self.linkInputTextField setText:text];
}

- (void)onControlButtonPressed
{
    /* We will order the delegate to act correctly according to the button's state */
    switch(self.controlButton.currentState)
    {
        case AddressBarStateFinishLoading:
        {
            if (_delegateFlags.DelegateRespondsToReload && self.fixedUrl.length != 0)
            {
                NSURL *targetUrl = [NSURL URLWithString:self.fixedUrl];
                [self.delegate addressBar:self requireToRefreshURL:targetUrl];
                
                [self.controlButton setCurrentState:AddressBarStateRefreshing];
            }
        }
            break;
            
        case AddressBarStateRefreshing:
        {
            if (_delegateFlags.DelegateRespondsToStopLoading)
            {
                [self.delegate addressBarRequireToStopLoading:self];
                [self.controlButton setCurrentState:AddressBarStateFinishLoading];
            }
        }
            break;
            
        case AddressBarStateNormal:
        {
            /* We haven't laod any urls or the textfield is emptied, we should check the url now */
            NSString *userInput = [[self.linkInputTextField text] lowercaseString];
            if (userInput.length == 0)
            {
                break;
            }

            NSString *urlWithoutHttp = [userInput stringByReplacingOccurrencesOfString:@"http://" withString:@""];
            NSString *urlWithout3W = [urlWithoutHttp stringByReplacingOccurrencesOfString:@"www." withString:@""];
            if ([urlWithout3W hasSuffix:@"/"])
            {
                urlWithout3W = [urlWithout3W stringByTrimmingCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@"/"]];
            }
            
            userInput = [NSString stringWithFormat:@"http://www.%@/", urlWithout3W];
            
            /* Do more checking here later  */
            // ...

            if (_delegateFlags.DelegateRespondsToLoadURL && userInput.length != 0)
            {
                self.fixedUrl = userInput;
                
                NSURL *targetUrl = [NSURL URLWithString:self.fixedUrl];
                [self.delegate addressBar:self requireToLoadURL:targetUrl];
                
                [self.controlButton setCurrentState:AddressBarStateRefreshing];
            }
        }
            break;
            
        default:
            break;
    }
}

- (void)moveItemsForward:(CGFloat)distnace animated:(BOOL)animated
{
    NSInteger index = 0;  // For delay animation
    for (UIView *item in self.toolItems)
    {
        /* The altered rect for the previous added items */
        CGRect itemNewFrame = CGRectMake(CGRectGetMinX(item.frame) - distnace, CGRectGetMinY(item.frame), CGRectGetWidth(item.bounds), CGRectGetHeight(item.bounds));
        NSTimeInterval dely =  ++ index * 0.1;
        NSTimeInterval duration = animated ? 0.3f : 0.f;

        [UIView animateWithDuration:duration delay:dely options:UIViewAnimationOptionCurveEaseIn animations:^{
            if (index == self.toolItems.count)
            {
                [item setAlpha:1.f];
            }
            else
            {
                [item setFrame:itemNewFrame];
            }
        } completion:nil];
    }
}

- (BOOL)addToolItem:(UIView *)item animated:(BOOL)animated error:(NSError **)error
{
    if (self.toolItems == nil)
    {
        self.toolItems = [NSMutableArray array];
    }
    
    CGFloat itemWidth = item.bounds.size.width;
    CGFloat itemHeight = item.bounds.size.height;
    
    /* The target rect for the altered inputTextField */
    CGRect inputTextFieldRect = self.linkInputTextField.frame;
    inputTextFieldRect.size.width -= itemWidth + Padding;
    
    /* We should limit the minimum size the textInput */
    if (inputTextFieldRect.size.width < 2 * CGRectGetWidth(self.controlButton.bounds))
    {
        NSDictionary *userInfo = @{NSLocalizedDescriptionKey : @"Too many items added to the address bar"};
        if (error != nil)
        {
            *error = [[[NSError alloc] initWithDomain:AddressBarErrorDomain code:AddressBarErrorCodeTooManyItems userInfo:userInfo] autorelease];
        }
        
        return NO;
    }
    
    [item setAlpha:0.f];
    [item setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
    
    [self addSubview:item];
    [self.toolItems addObject:item];

    /* The target rect for the added item */
    CGFloat addedItemXpos = CGRectGetWidth(self.bounds) - itemWidth - Padding;
    CGRect addedItemRect = CGRectMake(addedItemXpos, CGRectGetMinY(self.linkInputTextField.frame) - 5, itemWidth, itemHeight);
    [item setFrame:addedItemRect];
    
    [UIView animateWithDuration:0.3 animations:^{[self.linkInputTextField setFrame:inputTextFieldRect];}];
    [self moveItemsForward:itemWidth + Padding animated:YES];

    return YES;
}

- (void)removeToolItem:(UIView *)item animated:(BOOL)animatedr
{
    if (self.toolItems == nil ||self.toolItems.count == 0)
    {
        return;
    }
    
    CGFloat itemWidth = CGRectGetWidth(item.bounds);

    NSInteger moveBeforeThisIndex = [self.toolItems indexOfObject:item];  // The items before this index shall be moved backward later
    [self.toolItems removeObject:item];
    
    if (self.toolItems.count == 0)
    {
        [_toolItems release];
        _toolItems = nil;
    }
    
    [UIView animateWithDuration:0.3 animations:^{item.alpha = 0.f;} completion:^(BOOL finished) {
        [item removeFromSuperview];
    }];
    
    if (moveBeforeThisIndex == 0)
    {
        /* Enlarge the inputTextField */
        CGRect textFieldRect = self.linkInputTextField.frame;
        textFieldRect.size.width += itemWidth + Padding;
        
        [UIView animateWithDuration:0.3 animations:^{self.linkInputTextField.frame = textFieldRect;}];
    }
    else
    {
        for (NSInteger index = moveBeforeThisIndex - 1; index >= 0; -- index)
        {
            UIView *addedItem = self.toolItems[index];
            
            /* The final frame of each view */
            CGFloat itemXPos = CGRectGetMinX(addedItem.frame) + itemWidth + Padding;
            CGRect alteredFrame = CGRectMake(itemXPos , CGRectGetMinY(addedItem.frame), CGRectGetWidth(addedItem.bounds), CGRectGetHeight(addedItem.bounds));
            
            NSTimeInterval delay = (moveBeforeThisIndex - index) * 0.1;
            [UIView animateWithDuration:0.3 delay:delay options:UIViewAnimationOptionCurveEaseIn animations:^{addedItem.frame = alteredFrame;} completion:^(BOOL finished){

                if (index == 0)
                {
                    /* Enlarge the inputTextField */
                    CGRect textFieldRect = self.linkInputTextField.frame;
                    textFieldRect.size.width += itemWidth + Padding;
                    
                    [UIView animateWithDuration:0.3 animations:^{self.linkInputTextField.frame = textFieldRect;}];
                }
            }];
        }
    }
    
    return;
}

- (void)hideToolItemsWhenEditing
{
    if (self.toolItems == nil || self.toolItems.count == 0)
    {
        return;
    }
    
    for (UIView *item in self.toolItems)
    {
        [UIView animateWithDuration:0.1 animations:^{item.alpha = 0.f;}];
    }
    
    self.textFieldCurrentWidth = self.linkInputTextField.frame.size.width;
    CGRect textFieldFrame = self.linkInputTextField.frame;
    textFieldFrame.size.width = CGRectGetWidth(self.bounds) - 2 * Padding;
    
    [UIView animateWithDuration:0.2 animations:^{[self.linkInputTextField setFrame:textFieldFrame];}];
}

- (void)showToolItemsWhenEndEditing
{
    if (self.toolItems == nil || self.toolItems.count == 0)
    {
        return;
    }
    
    CGRect textFieldFrame = self.linkInputTextField.frame;
    textFieldFrame.size.width = self.textFieldCurrentWidth;
    [UIView animateWithDuration:0.2 animations:^{[self.linkInputTextField setFrame:textFieldFrame];} completion:^(BOOL finished) {
        for (UIView *item in self.toolItems)
        {
            [UIView animateWithDuration:0.1 animations:^{item.alpha = 1.f;}];
        }
    }];
}


#pragma mark - 
#pragma mark UI Text Field Delegate
- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string
{
    if (self.controlButton.currentState != AddressBarStateNormal)
    {
        [self.controlButton setCurrentState:AddressBarStateNormal];
    }
    
    return YES;
}

- (void)textFieldDidBeginEditing:(UITextField *)textField
{
    /* If there is any tool item on the address bar, enlarge the inputTextField at first */
    [self hideToolItemsWhenEditing];
    
    if (_delegateFlags.DelegateRespondsToBeginEditing)
    {
        [self.delegate addressBarDidStartEditing:self];
    }
}

- (void)textFieldDidEndEditing:(UITextField *)textField
{
    [self showToolItemsWhenEndEditing];
}

@end
