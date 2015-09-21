/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : ProgressButton.m
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
#import "ProgressButton.h"

static const CGFloat Padding = 4.f;

@interface ProgressButton ()

@property (nonatomic, retain) UIImageView *iconView;
@property (nonatomic, retain) UIProgressView *progressBar;

@property (nonatomic, retain) UITapGestureRecognizer *tap;

@end

@implementation ProgressButton

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        CGFloat iconViewSize = MIN(CGRectGetWidth(frame), CGRectGetHeight(frame)) - Padding * 2;
        
        /* If the icon is too small, we'll just simply make a button with a progress view in the center */
        if (iconViewSize >= 10.f)
        {
            _iconView = [[UIImageView alloc] initWithFrame:CGRectMake(0, 0, iconViewSize, iconViewSize)];
            [_iconView setCenter:CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))];
            [_iconView setContentMode:UIViewContentModeScaleAspectFit];
            [_iconView setImage:[UIImage imageNamed:@"Download.png"]];
            [_iconView setUserInteractionEnabled:YES];
            
            [self addSubview:_iconView];
        }
        
        CGFloat progressViewWidth = CGRectGetWidth(frame) - 2 * Padding;
        _progressBar = [[UIProgressView alloc] initWithFrame:CGRectMake(Padding, 0, progressViewWidth, 3)];
        
        if (_iconView == nil)
        {
            [_progressBar setCenter:CGPointMake(CGRectGetMidX(self.bounds), CGRectGetMidY(self.bounds))];
        }
        else
        {
            CGRect progressViewRect = _progressBar.frame;
            progressViewRect.origin.y = CGRectGetMaxY(_iconView.frame) + 2;
            
            [_progressBar setFrame:progressViewRect];
        }
        
        [self addSubview:_progressBar];
    }
    
    return self;
}

- (void)dealloc
{
    [_iconView release];
    _iconView = nil;
    
    [_progressBar release];
    _progressBar = nil;
    
    [self removeGestureRecognizer:_tap];
    [_tap release];
    _tap = nil;
    
    [super dealloc];
}


- (void)addTarget:(id)target action:(SEL)action
{
    [self removeGestureRecognizer:_tap];
    [_tap release];
    _tap = nil;
    
    _tap = [[UITapGestureRecognizer alloc] initWithTarget:target action:action];
    [self addGestureRecognizer:_tap];
}

- (void)removeTarget:(id)target
{
    [self.tap removeTarget:target action:nil];
    
    [self removeGestureRecognizer:_tap];
    [_tap release];
    _tap = nil;
}

- (void)setProgress:(CGFloat)progress
{
    [self.progressBar setProgress:progress];
}


@end
