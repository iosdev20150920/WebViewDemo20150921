//
//  FileManageViewController.m
//  UCWebViewTest
//
//  Created by Sooyo on 15/6/27.
//  Copyright (c) 2015年 Sooyo. All rights reserved.
//

#import "FileManageViewController.h"
#import "FilePathManager.h"
#import "File.h"
#import "BottomToolBar.h"


typedef NS_ENUM(NSUInteger, OperationIndex)
{
    OperationIndexCreate = 0,
    OperationIndexSelect,
    
    OperationIndexDelete = 0,
    OperationIndexCancel,
};

typedef NS_ENUM(NSInteger, AlertViewContent)
{
    AlertViewContentCreateFile = 1,
    AlertViewContentCreateDirectory,
    AlertViewContentRemoveItems,
};


@interface FileManageViewController () <UITableViewDataSource, UITableViewDelegate, BottomToolBarDelegate, UIActionSheetDelegate, UIAlertViewDelegate>

@property (nonatomic, retain) FilePathManager *filePathManager;
@property (nonatomic, retain) UITableView *tableView;
@property (nonatomic, retain) UIBarButtonItem *operationItem;
@property (nonatomic, retain) BottomToolBar *toolBar;

@property (nonatomic, copy) NSString *defaultFileToShow;

@property (nonatomic, retain) NSMutableArray *selections;
@property (nonatomic, assign, getter = isSelectonModeOn) BOOL selectionModeOn;

@end

@implementation FileManageViewController

- (void)viewDidLoad
{
    [super viewDidLoad];

    _selectionModeOn = NO;
    
    _filePathManager = [[FilePathManager alloc] init];
    [_filePathManager setWorkDirectory:NSDocumentDirectory];
    
    if (self.defaultPathToShow != nil)
    {
        self.defaultFileToShow = [self.defaultPathToShow lastPathComponent];
        NSString *filePath = [self.defaultPathToShow stringByDeletingLastPathComponent];
        
        [_filePathManager changeToAbsoluteFilePath:filePath];
    }
    
    /* Create teh table view for showing file contents */
    _tableView = [[UITableView alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), CGRectGetHeight(self.view.bounds) - 40)];
    [_tableView setDelegate:self];
    [_tableView setDataSource:self];
    [_tableView setAllowsMultipleSelectionDuringEditing:NO];
    
    [self.view addSubview:_tableView];
    [self setAutomaticallyAdjustsScrollViewInsets:YES];
    
    /* Create the bottom tool bar for file operatoins */
    _toolBar = [[BottomToolBar alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds) - 40, CGRectGetWidth(self.view.bounds), 40)];
    [_toolBar setDelegate:self];
    [_toolBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
    [_toolBar setItemsWithIcons:nil titles:@[@"新建", @"选择"] animated:YES];    // We simply have two items with title only
    
    [self.view addSubview:_toolBar];
    
    [self.navigationItem setTitle:@"文件管理"];
}

- (void)dealloc
{
    [_filePathManager release];
    _filePathManager = nil;
    
    [_tableView setDelegate:nil];
    [_tableView setDataSource:nil];
    [_tableView release];
    _tableView = nil;
    
    [_operationItem setTarget:nil];
    [_operationItem release];
    _operationItem = nil;
    
    
    [_toolBar setDelegate:nil];
    [_toolBar release];
    _toolBar = nil;
    
    [_selections release];
    _selections = nil;
    
    [super dealloc];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)setSelectionModeOn:(BOOL)selectionModeOn
{
    _selectionModeOn = selectionModeOn;
    
    if (selectionModeOn)
    {
        [self.toolBar setItemsWithIcons:nil titles:@[] animated:YES]; // Change the tool bar interface
    }
    else
    {
        [self.toolBar setItemsWithIcons:nil titles:@[] animated:YES]; // Change to normal status
    }
}

#pragma mark -
#pragma mark Bottom Tool Bar Delegate
- (void)bottomBar:(BottomToolBar *)toolbar didPressButtonAtIndex:(NSInteger)index
{
    if (!self.isSelectonModeOn)
    {
        switch (index)
        {
            case OperationIndexCreate:
            {
                UIActionSheet *createActionSheet = [[[UIActionSheet alloc] initWithTitle:@"创建文件或文件夹" delegate:self cancelButtonTitle:@"取消" destructiveButtonTitle:nil otherButtonTitles:@"创建文件夹", @"创建文件", nil] autorelease];
                [createActionSheet showInView:self.view];
            }
                break;
                
            case OperationIndexSelect:
            {
                self.selections = [NSMutableArray array];
                
                [self setSelectionModeOn:YES];
                [self.tableView reloadData];
            }
                
            default:
                break;
        }
    }
    else
    {
        switch (index)
        {
            case OperationIndexCancel:
            {
                if (self.selections != nil)
                {
                    [_selections release];
                    _selections = nil;
                }
                
                [self setSelectionModeOn:NO];
                [self.tableView reloadData];
            }
                break;
                
            case OperationIndexDelete:
            {
                NSString *message = [NSString stringWithFormat:@"是否确定删除选中的%d个项目?", (int)self.selections.count];
                
                /* Show an alert view for user to make the final decision */
                UIAlertView *view = [[[UIAlertView alloc] initWithTitle:@"删除文件" message:message delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil] autorelease];
                
                view.tag = AlertViewContentRemoveItems;
                [view show];
            }
                
            default:
                break;
        }
    }
 
}


#pragma mark - 
#pragma mark UI Table View Delegate And Data Source 
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section
{
    if ([self.filePathManager canGoBack])  // If can go back,  we add a dotdot item at the top
    {
        return [[self.filePathManager fileList] count] + 1;
    }
    
    return [[self.filePathManager fileList] count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath
{
    static NSString *reuseIdentifer = @"Cell";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:reuseIdentifer];
    
    if (cell == nil)
    {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:reuseIdentifer] autorelease];
        [cell.textLabel setFont:[UIFont systemFontOfSize:15.f]];
    }
    
    do
    {
        if (indexPath.row == 0 && [self.filePathManager canGoBack])
        {
            /* Leave a place from where user can go back to parent directory */
            [cell.imageView setImage:[UIImage imageNamed:@"Floder.png"]];
            [cell.textLabel setText:@".."];
            
            break;
        }
        
        /* When the current directory has a parent directory, we add a dotdot item at the begining */
        NSInteger index = [self.filePathManager canGoBack] ? indexPath.row - 1: indexPath.row;
        File *file = [self.filePathManager fileList][index];
        
        [cell.textLabel setText:file.fileName];
        
        NSString *iconName = nil;
        switch(file.fileType)
        {
            case FileTypeDirectory:
            {
                iconName = @"Floder.png";
            }
                break;
                
            case FileTypeRegular:
            {
                iconName = @"File.png";
            }
                break;
                
            default:
                break;
        }
        
        if (self.isSelectonModeOn)
        {
            [cell setSelectionStyle:UITableViewCellSelectionStyleNone];
            [cell setAccessoryType:UITableViewCellAccessoryCheckmark];
            [cell setTintColor:[UIColor grayColor]];
        }
        else
        {
            [cell setSelectionStyle:UITableViewCellSelectionStyleDefault];

            if (file.fileType == FileTypeDirectory)
            {
                [cell setAccessoryType:UITableViewCellAccessoryDisclosureIndicator];
            }
            else
            {
                [cell setAccessoryType:UITableViewCellAccessoryNone];
            }
        }
  
        [cell.imageView setImage:[UIImage imageNamed:iconName]];
        
    } while(false);

    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.isSelectonModeOn)
    {
        if (indexPath.row == 0 && [self.filePathManager canGoBack])
        {
            return ;
        }
        
        UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];

        if ([self.selections containsObject:indexPath])
        {
            [cell setTintColor:[UIColor grayColor]];
            [self.selections removeObject:indexPath];
        }
        else
        {
            [cell setTintColor:[UIColor redColor]];
            [self.selections addObject:indexPath];
        }
    }
    else
    {
        if (indexPath.row == 0 && [self.filePathManager canGoBack])
        {
            [self.filePathManager changeToParentDirectory];
            [tableView reloadData];
        }
        else
        {
            NSInteger index = [self.filePathManager canGoBack] ? indexPath.row - 1: indexPath.row; // Don't forget the dotdot~
            File *fileAtIndex = [self.filePathManager fileList][index];
            if (fileAtIndex.fileType == FileTypeDirectory)
            {
                [self.filePathManager changeToSubDirectory:fileAtIndex.fileName];
                [tableView reloadData];
            }
        }
    }
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (self.defaultFileToShow == nil)
    {
        return;
    }
    

    NSInteger index = 0;
    for (File *file in [self.filePathManager fileList])
    {
        if ([file.fileName isEqualToString:self.defaultFileToShow])
        {
            [tableView scrollToRowAtIndexPath:[NSIndexPath indexPathForRow:index inSection:0] atScrollPosition:UITableViewScrollPositionMiddle animated:YES];
            break;
        }
        
        ++ index;
    }

    [_defaultPathToShow release];
    _defaultPathToShow = nil;
    
    [_defaultFileToShow release];
    _defaultFileToShow = nil;
}

- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (editingStyle == UITableViewCellEditingStyleDelete)
    {
        NSInteger index = [self.filePathManager canGoBack] ? indexPath.row - 1 : indexPath.row;
        NSString *fileName = [[self.filePathManager fileList][index] fileName];

        [self.filePathManager removeItem:fileName];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationAutomatic];
    }
}


- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    return 50.f;
}


#pragma mark - 
#pragma mark UI Action Sheet Delegate 
- (void)actionSheet:(UIActionSheet *)actionSheet didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    NSString *alertTitle = nil;
    NSInteger typeTag = 0;
    
    switch (buttonIndex) {
        case 0:
        {
            typeTag = AlertViewContentCreateDirectory;
            alertTitle = @"请输入文件夹名称";
        }
            break;
            
        case 1:
        {
            typeTag = AlertViewContentCreateFile;
            alertTitle = @"请输入文件名称";
        }
            break;
            
        default:
            break;
    }
    
    UIAlertView *view = [[[UIAlertView alloc] initWithTitle:alertTitle message:nil delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil] autorelease];
    
    [view setAlertViewStyle:UIAlertViewStylePlainTextInput];
    [view setTag:typeTag];
    [view show];
}

#pragma mark - 
#pragma mark UI Alert View Delegate 
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex != 0 )
    {
        return;
    }
    
    switch (alertView.tag)
    {
        case AlertViewContentRemoveItems:
        {
            NSMutableArray *fileNames = [NSMutableArray array];
             for (NSIndexPath *indexPath in self.selections)
             {
                 NSInteger index = [self.filePathManager canGoBack] ? indexPath.row - 1 : indexPath.row;
                 File *file = [self.filePathManager fileList][index];
                
                 [fileNames addObject:file.fileName];
             }
            
            for (NSString *fileName in fileNames)
            {
                [self.filePathManager removeItem:fileName];
            }
            
            [self setSelectionModeOn:NO];
            
            [_selections release];
            _selections = nil;
            
            [self.tableView reloadData];
        }
            break;
            
        case AlertViewContentCreateDirectory:
        case AlertViewContentCreateFile:
        {
            NSString *inputContent = [[alertView textFieldAtIndex:0] text];
            
            if (alertView.tag == AlertViewContentCreateDirectory)
            {
                /* Create a directory */
                [self.filePathManager createDirectory:inputContent];
                
            }
            else if (alertView.tag == AlertViewContentCreateFile)
            {
                /* Create a file */
                [self.filePathManager createFile:inputContent];
            }
            
            [self.tableView reloadData];
        }
            break;
            
        default:
            break;
    }
}
@end
