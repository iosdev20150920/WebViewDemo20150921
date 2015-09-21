/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : HistoryViewController.m
 *
 * Description   : Implementation of HistoryViewController
 *
 * Creation       : 2015/06/26
 * Author          : luyc@ucweb.com
 * History         :
 *                 Creation, 2015/06/26, luyc, Create the file
 ***************************************************************************
 **/

#import "HistoryViewController.h"
#import "HistorySaver.h"

@interface HistoryViewController () <UITableViewDataSource, UITableViewDelegate, UIActionSheetDelegate>

@property (nonatomic, retain) UITableView *historyReocrdListView;
@property (nonatomic, retain) UIButton *clearButton;
@property (nonatomic, retain) UIButton *editButton;

@end

static const CGFloat ButtonWidth = 100.f;
static const CGFloat ButtonHeight = 40.f;

@implementation HistoryViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self.navigationItem setTitle:@"历史"];
}

- (void)viewDidLayoutSubviews
{
    [self createHelperButtons];
    [self createListView];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [_historyReocrdListView setDelegate:nil];
    [_historyReocrdListView setDataSource:nil];
    [_historyReocrdListView release];
    _historyReocrdListView = nil;
    
    [_clearButton removeTarget:self action:@selector(onClearButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [_clearButton release];
    _clearButton = nil;
    
    [_editButton removeTarget:self action:@selector(onEditButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    [_editButton release];
    _editButton = nil;
    
    [_historySaver release];
    _historySaver = nil;
    
    [super dealloc];
}

- (void)createHelperButtons
{
    if (self.clearButton != nil || self.editButton != nil)
    {
        return;
    }
    
    CGFloat padding = (CGRectGetWidth(self.view.bounds) - 2 * ButtonWidth) / 3.f;
    CGFloat yPos = CGRectGetMaxY(self.navigationController.navigationBar.frame);
    
    /* On top left */
    self.editButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.editButton setFrame:CGRectMake(padding, yPos, ButtonWidth, ButtonHeight)];
    [self.editButton setTitle:@"编辑" forState:UIControlStateNormal];
    [self.editButton addTarget:self action:@selector(onEditButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    /* On top right */
    self.clearButton = [UIButton buttonWithType:UIButtonTypeSystem];
    [self.clearButton setFrame:CGRectMake(padding * 2 + ButtonWidth, yPos, ButtonWidth, ButtonHeight)];
    [self.clearButton setTitle:@"清除" forState:UIControlStateNormal];
    [self.clearButton addTarget:self action:@selector(onClearButtonPressed) forControlEvents:UIControlEventTouchUpInside];
    
    [self.view addSubview:self.editButton];
    [self.view addSubview:self.clearButton];
}

- (void)onEditButtonPressed
{
    [self.historyReocrdListView setEditing: !self.historyReocrdListView.editing animated:YES];
}

- (void)onClearButtonPressed
{
    UIActionSheet *actiionSheet = [[[UIActionSheet alloc] initWithTitle:@"清理历史"
                                                                              delegate:self
                                                                              cancelButtonTitle:@"取消"
                                                                              destructiveButtonTitle:nil
                                                                              otherButtonTitles:@"1天内", @"全部", nil] autorelease];
    [actiionSheet showInView:self.view];
}


- (void)createListView
{
    if (self.historyReocrdListView != nil)
    {
        return;
    }
    
    CGFloat listViewHeight = CGRectGetHeight(self.view.bounds) - CGRectGetMaxY(self.clearButton.frame);
    _historyReocrdListView = [[UITableView alloc] initWithFrame:CGRectMake(0, CGRectGetMaxY(self.clearButton.frame), CGRectGetWidth(self.view.bounds), listViewHeight)];
    self.historyReocrdListView.allowsMultipleSelectionDuringEditing = NO;
    
    [self.historyReocrdListView setDelegate:self];
    [self.historyReocrdListView setDataSource:self];
    
    [self.view addSubview:_historyReocrdListView];
}


#pragma mark - 
#pragma mark UI Table View Delegate And Data Source 
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView
{
    return [self.historySaver histroySectionCount];
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    return [self.historySaver numberOfRecordsInSection:section];
}

-(CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section
{
    return 20.f;
}

- (NSString*)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section
{
    return [self.historySaver titleForSection:section];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseIdentifer = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifer];
    
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifer] autorelease];
        [cell.textLabel setTextColor:[UIColor colorWithRed:36 / 255.f green:114 / 255.f blue:255/ 255.f alpha:1]];
        [cell.detailTextLabel setTextColor:[UIColor colorWithRed:25 / 255.f green:25 / 255.f  blue:25 / 255.f alpha:1]];
    }
    
    /* Config the cell */
    NSDictionary *record = [self.historySaver recordAtSection:indexPath.section andRow:indexPath.row];
    [cell.textLabel setText:record[HistoryRecordKeyUrl]];
    [cell.detailTextLabel setText:record[HistoryRecordKeyDate]];
    
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 70.f;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        [self.historySaver removeRecordAtSection:indexPath.section andRow:indexPath.row];
        [self.historyReocrdListView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if ([self.delegate respondsToSelector:@selector(loadHistoryURL:)])
    {
        NSDictionary *historyRecord = [self.historySaver recordAtSection:indexPath.section andRow:indexPath.row];
        NSURL *targetUrl = [NSURL URLWithString:historyRecord[HistoryRecordKeyUrl]];

        [self.delegate loadHistoryURL:targetUrl];
        [self.navigationController popViewControllerAnimated:YES];
    }
}


#pragma mark -
#pragma mark UI Action Sheet Delegate
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex > 1)
    {
        return;
    }
    
    if (buttonIndex == 0)
    {
        [self.historySaver removeAllRecordsInSection:buttonIndex];
    }
    else if (buttonIndex == 1)
    {
        [self.historySaver removeAllRecords];
    }
    
    [self.historyReocrdListView reloadData];
}
@end