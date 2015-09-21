/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : DownloadPopupListView.m
 *
 * Description   : Implemetation file
 *
 * Creation      : 2015/06/30
 * Author         : luyc@ucweb.com
 * History        :
 *                 Creation, 2015/06/30, luyc, Create the file
 ***************************************************************************
 **/

#import "DownloadPopupListView.h"

static const CGFloat HorizontalPadding = 40.f;  // To set a margin to the background view
static const CGFloat VerticalPadding = 80.f;

@interface DownloadPopupListView ()

@property (nonatomic, retain, readwrite) UITableView *listView;
@property (nonatomic, retain) UIView *backgroundView;

@end

@implementation DownloadPopupListView

- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {

        [self setBackgroundColor:[UIColor clearColor]];
        
        [self createBackgroundView];
        [self createListView];
    }
    return self;
}

- (void)dealloc
{
    [_backgroundView removeFromSuperview];
    [_backgroundView release];
    _backgroundView = nil;
    
    [_listView setDelegate:nil];
    [_listView setDataSource:nil];
    [_listView removeFromSuperview];
    [_listView release];
    _listView = nil;
    
    [super dealloc];
}


- (void)createListView
{
    if (self.listView != nil)
    {
        return;
    }
    
    CGFloat listViewWidth = CGRectGetWidth(self.bounds) - 2 * HorizontalPadding;
    CGFloat listViewHeight = CGRectGetHeight(self.bounds) - 2 * VerticalPadding;
    
    _listView = [[UITableView alloc] initWithFrame:CGRectMake(HorizontalPadding, VerticalPadding, listViewWidth, listViewHeight)];
    [_listView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    _listView.layer.cornerRadius = 10.f;
    
    CGFloat distace = CGRectGetHeight(self.bounds) - CGRectGetMinY(self.listView.frame);
    CGAffineTransform moveTransform = CGAffineTransformMakeTranslation(0, distace);
    [self.listView setTransform:moveTransform];

    [self addSubview:_listView];
}

- (void)createBackgroundView
{
    _backgroundView = [[UIView alloc] initWithFrame:self.bounds];
    [_backgroundView setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.5]];
    _backgroundView.alpha = 0.f;
    
    [self addSubview:_backgroundView];
    
    UITapGestureRecognizer *tap = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tapOnBackground)];
    [_backgroundView addGestureRecognizer:tap];
    [tap release];
}

- (void)tapOnBackground
{
    [self showListView:NO animated:YES];
}

- (void)showListView:(BOOL)show animated:(BOOL)animated
{
    CGFloat endAlpha = show ? 1.f : 0.f;
    
    if (show)
    {
        UIWindow *keyWindow = [[UIApplication sharedApplication] keyWindow];
        [keyWindow addSubview:self];
    }

    if (animated)
    {
        CGFloat distace = CGRectGetHeight(self.bounds) - CGRectGetMinY(self.listView.frame);
        CGAffineTransform moveTransform = CGAffineTransformMakeTranslation(0, distace);
        CGAffineTransform endTransform = show ? CGAffineTransformIdentity : moveTransform;
        
        [UIView animateWithDuration:0.5 delay:0.f usingSpringWithDamping:0.8 initialSpringVelocity:0.5 options:UIViewAnimationOptionCurveEaseInOut
                         animations:^{self.listView.transform = endTransform; self.backgroundView.alpha = endAlpha;}  completion:^(BOOL finished){
                             if (!show)
                             {
                                 [self removeFromSuperview];
                             }
                         }];
    }
    else
    {
        self.backgroundView.alpha = endAlpha;
        if (!show)
        {
            [self removeFromSuperview];
        }
    }
}

@end
