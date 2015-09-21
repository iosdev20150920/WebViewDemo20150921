/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : DownloadItemTableViewCell.m
 *
 * Description   : DownlaodItemTableViewCell provides an special interface to display the download progress and download item name,
 *                    it also provides a simple deleting button
 *
 * Creation      : 2015/06/30
 * Author         : luyc@ucweb.com
 * History        :
 *                 Creation, 2015/06/30, luyc, Create the file
 ***************************************************************************
 **/

#import "DownloadItemTableViewCell.h"

static const CGFloat HintLabelOccupation = 0.2;
static const CGFloat ProgressViewHeight = 2.f;
static const CGFloat CloseButtonOccupation = 0.5;

@interface DownloadItemTableViewCell ()

@property (nonatomic, retain) UIProgressView *progressView;
@property (nonatomic, retain) UILabel *hintLabel;
@property (nonatomic, retain) UIButton *closeButton;

@end

@implementation DownloadItemTableViewCell

- (void)awakeFromNib {
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier
{
    self = [super initWithStyle:style reuseIdentifier:reuseIdentifier];
    
    if (self)
    {
        CGRect contentViewFrame = self.contentView.bounds;
        
        /* Add some custome views to decorate the cell */
        _progressView = [[UIProgressView alloc] initWithFrame:CGRectMake(5, CGRectGetHeight(contentViewFrame) - ProgressViewHeight, CGRectGetWidth(contentViewFrame) - 2 * 5, ProgressViewHeight)];
        [_progressView setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        
        [self.contentView addSubview:_progressView];
        
        // Hint label
        CGFloat hintLabelYPos = (1 - HintLabelOccupation) * CGRectGetHeight(contentViewFrame);
        CGFloat hintLabelHeight =  HintLabelOccupation * CGRectGetHeight(contentViewFrame);
        
        _hintLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, hintLabelYPos, CGRectGetWidth(contentViewFrame) - 2 * 10, hintLabelHeight)];
        [_hintLabel setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
        [_hintLabel setFont:[UIFont systemFontOfSize:12.f]];
        
        [self.contentView addSubview:_hintLabel];
        
        // Close button
        CGFloat closeButtonSize = CloseButtonOccupation * CGRectGetHeight(contentViewFrame);
        CGFloat closeButtonYPos = 0.5 * (CGRectGetHeight(contentViewFrame) - closeButtonSize);
        
        _closeButton = [[UIButton alloc] initWithFrame:CGRectMake(CGRectGetWidth(contentViewFrame) - closeButtonSize - 5, closeButtonYPos, closeButtonSize, closeButtonSize)];
        [_closeButton setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
        [_closeButton setTitleColor:[UIColor redColor] forState:UIControlStateNormal];
        [_closeButton setTitle:@"x" forState:UIControlStateNormal];
        [_closeButton addTarget:self action:@selector(removeItem) forControlEvents:UIControlEventTouchUpInside];
        
        [self.contentView addSubview:_closeButton];
    }
   
    return self;
}

- (void)dealloc
{
    [_closeButton removeTarget:self action:@selector(removeItem) forControlEvents:UIControlEventTouchUpInside];
    [_closeButton removeFromSuperview];
    [_closeButton release];
    _closeButton = nil;
    
    [_hintLabel removeFromSuperview];
    [_hintLabel release];
    _hintLabel = nil;
    
    [_progressView removeFromSuperview];
    [_progressView release];
    _progressView = nil;
    
    [super dealloc];
}

- (void)removeItem
{
    if ([self.delegate respondsToSelector:@selector(removeDownloadItem:)])
    {
        [self.delegate removeDownloadItem:self];
    }
}

- (void)completionAnimation
{
    CABasicAnimation *backgroundColorAnimation = [CABasicAnimation animationWithKeyPath:@"backgroundColor"];
    backgroundColorAnimation.fromValue = (id)[UIColor whiteColor].CGColor;
    backgroundColorAnimation.toValue = (id)[UIColor greenColor].CGColor;
    backgroundColorAnimation.autoreverses = YES;
    backgroundColorAnimation.repeatCount = 5;
    backgroundColorAnimation.duration = 0.7;
    
    [self.contentView.layer addAnimation:backgroundColorAnimation forKey:@"TwinkleTwinleLittleStart"];
}

- (void)setProgress:(CGFloat)progress
{
    if (progress == 1.f)
    {
        [self.hintLabel setHidden:NO];
        [self.closeButton setHidden:NO];
        
        [self completionAnimation];
    }
    
    [self.progressView setProgress:progress animated:YES];
}

- (void)setHint:(NSString *)hint
{
    /* Whe we set hint, we've already finished the download */
    [self.progressView setHidden:YES];
    
    [self.closeButton setHidden:NO];
    [self.hintLabel setHidden:NO];
    [self.hintLabel setText:hint];
}

@end
