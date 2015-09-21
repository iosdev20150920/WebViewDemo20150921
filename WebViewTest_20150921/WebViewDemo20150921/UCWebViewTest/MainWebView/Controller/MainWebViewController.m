/*
 ***************************************************************************
 * Copyright (C) 2005-2011 UC Mobile Limited. All Rights Reserved
 * File              : MainWebViewController.m
 *
 * Description   : MainWebViewController.m
 *
 * Creation       : 2015/06/25
 * Author          : luyc@ucweb.com
 * History         :
 *                 Creation, 2015/06/25, luyc, Create the file
 ***************************************************************************
 **/

#import "MainWebViewController.h"
#import "AddressBar.h"
#import "BottomToolBar.h"
#import "HistorySaver.h"
#import "HistoryViewController.h"
#import "FileManageViewController.h"
#import "DownloadController.h"
#import "ProgressButton.h"

/* We shall limit the index for all available items */
typedef NS_ENUM(NSUInteger , BottomToolBarItemIndex)
{
    BottomToolBarItemIndexGoBack = 0,
    BottomToolBarItemIndexGoForward,
    BottomToolBarItemIndexFileManagement,
    BottomToolBarItemIndexHistoryList,
    BottomToolBarItemIndexPagination,
    
    BottomToolBarItemIndexMaximum,
};

/* Constants */
static NSString *const kIsFirstLaunchKey = @"isFirstLaunch";
static const CGFloat kBottomToolBarHeight = 40.f;

@interface MainWebViewController () <UIWebViewDelegate, AddressBarDelegate, BottomToolBarDelegate, UINavigationControllerDelegate, HistoryViewControllerDelegate, UIAlertViewDelegate, DownloadControllerDelegate>

@property (nonatomic, retain) BottomToolBar *bottomToolBar;
@property (nonatomic, retain) HistorySaver *historySaver;
@property (nonatomic, retain) AddressBar *addressBar;
@property (nonatomic, retain) ProgressButton *progressButton;

@property (nonatomic, retain) UIWebView *webView;
@property (nonatomic, retain) UIView *keyboardMaskView;  // A view to dismiss the keyboard while inputing the url
@property (nonatomic, retain) NSArray *fileSuffixes;
@property (nonatomic, retain) NSURL *downloadUrl;

@property (nonatomic, assign) BOOL isActivatedAddressBar;
@property (nonatomic, assign) BOOL isLastLoadingSucc;

@property (nonatomic, retain) DownloadController *downloadController;

@end

@implementation MainWebViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.isActivatedAddressBar = NO;
    self.isLastLoadingSucc = NO;
    
    /* Create the main components of the main web view controller */
    [self createAddressBar];
    [self createWebView];
    [self createBottomToolBar];
    
    _historySaver = [[HistorySaver alloc] init];
    if (self.historySaver.histroySectionCount != 0)
    {
        // FIXME: 不允许有注释掉的废弃代码，要删除干净
//        NSString *urlString = [self.historySaver recordAtSection:0 andRow:0][HistoryRecordKeyUrl];
//        NSURL *lastOpenedUrl = [NSURL URLWithString:urlString];
        
//        [self.addressBar setAddressBarText:urlString];
//        [self.addressBar setAddressBarState:AddressBarStateRefreshing];
//        [self.webView loadRequest:[NSURLRequest requestWithURL:lastOpenedUrl]];
    }
    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"test" ofType:@"html"];
    NSString *htmlString = [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil];
    [self.webView loadHTMLString:htmlString baseURL:[NSURL URLWithString:@"http://"]];
    
    // FIXME： 太多method调用，很多地方用点语法更间接优雅。
    [self.navigationController setDelegate:self];
    
    [self copyTestFileToDiskWhenFirstLaunch]; // Copy some test files for file management test
    
    /* Try do download these types of file when we meet them on redirection */
    self.fileSuffixes = @[@".rar", @".zip", @"ipa"];
    
    /* Show mask view to hide the keyboard */
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(onKeyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(savePersistentHistoryData) name:UIApplicationWillResignActiveNotification object:nil];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
    [self.navigationController setDelegate:nil];

    [_webView setDelegate:nil];
    [_webView release];
    _webView = nil;
    
    [_addressBar setDelegate:nil];
    [_addressBar release];
    _addressBar = nil;
    
    [_keyboardMaskView release];
    _keyboardMaskView = nil;

    [_bottomToolBar setDelegate:nil];
    [_bottomToolBar release];
    _bottomToolBar = nil;
    
    [_historySaver release];
    _historySaver = nil;
    
    [_fileSuffixes release];
    _fileSuffixes = nil;
    
    [_downloadUrl release];
    _downloadUrl = nil;
    
    [_progressButton removeTarget:self];
    [_progressButton release];
    _progressButton = nil;
    
    [_downloadController setDelegate:nil];
    [_downloadController release];
    _downloadController = nil;
    
    [super dealloc];
}

- (void)setDetectedFileSuffixes:(NSArray *)fileSuffixes
{
    if (_fileSuffixes != nil)
    {
        [_fileSuffixes release];
    }
    _fileSuffixes = [fileSuffixes retain];
}

- (void)hideKeyboard
{
    [self.view endEditing:YES];
}

- (void)createAddressBar
{
    CGFloat yPos = CGRectGetMaxY([[UIApplication sharedApplication] statusBarFrame]);
    
    /* Position the address bar to the top the view,  and has a height that's 40 point higher than the status bar */
    _addressBar = [[AddressBar alloc] initWithFrame:CGRectMake(0, 0, CGRectGetWidth(self.view.bounds), yPos + 40)];
    [self.addressBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth];
    [self.addressBar setDelegate:self];
    
    [self.view addSubview:self.addressBar];
}

- (void)createWebView
{
    /* Web poses to the bottom of the address bar and covers the rest of the view space */
    CGFloat addressBarBottom = CGRectGetMaxY(self.addressBar.frame);
    CGFloat webViewHeight = CGRectGetHeight(self.view.bounds) - addressBarBottom -  40;
    
    _webView = [[UIWebView alloc] initWithFrame:CGRectMake(0, addressBarBottom, CGRectGetWidth(self.view.bounds), webViewHeight)];
    [self.webView setDelegate:self];
    [self.webView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
    
    [self.view addSubview: self.webView];
    
    // FIXME: 感觉不需要这个代码。没机会执行。
    if (self.bottomToolBar != nil)
    {
        [self.view bringSubviewToFront:self.bottomToolBar];     // To fix the creation sequence problem
    }
}

- (void)createBottomToolBar
{
    /* Bottom tool bar is placed to the bottom of the view */
    _bottomToolBar = [[BottomToolBar alloc] initWithFrame:CGRectMake(0, CGRectGetHeight(self.view.bounds) -  kBottomToolBarHeight, CGRectGetWidth(self.view.bounds), kBottomToolBarHeight)];
    [self.bottomToolBar setDelegate:self];
    [self.bottomToolBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleTopMargin];
    
    NSMutableArray *iconArray = [NSMutableArray array];
    for (NSInteger index = BottomToolBarItemIndexGoBack; index < BottomToolBarItemIndexMaximum; ++ index)
    {
        [iconArray addObject:[NSString stringWithFormat:@"ToolBarIcon%d.png", (int)index]];
    }
    
    [self.bottomToolBar setItemsWithIcons:iconArray titles:nil animated:YES];
    [self.bottomToolBar setEnable:NO forItemAtIndex:BottomToolBarItemIndexGoBack];
    [self.bottomToolBar setEnable:NO forItemAtIndex:BottomToolBarItemIndexGoForward];
    
    [self.view addSubview:self.bottomToolBar];
    
    if (self.webView != nil)
    {
        [self.view bringSubviewToFront:self.bottomToolBar]; // To fix the creation sequence problem
    }
}

- (void)savePersistentHistoryData
{
    [self.historySaver synchronize];
}

// FIXME: 代码耦合，应该和当前controll没啥关系，需要分离出去。
- (void)copyTestFileToDiskWhenFirstLaunch
{
    if ([[NSUserDefaults standardUserDefaults] valueForKey:kIsFirstLaunchKey] == nil)
    {
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0) , ^{
            
            /* This is the application first launch time */
            [[NSUserDefaults standardUserDefaults] setValue:@"NO" forKey:kIsFirstLaunchKey];
            
            /* Copy the test files to the disk */
            NSString *testFilesPathInBundle = [[NSBundle mainBundle] pathForResource:@"TestFiles" ofType:nil];
            
            NSString *documentPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES) lastObject];
            NSString *targetPath = [documentPath stringByAppendingPathComponent:[testFilesPathInBundle lastPathComponent]];
            
            NSError *error = nil;
            NSFileManager *fileManager = [NSFileManager defaultManager];
            if (![fileManager copyItemAtPath:testFilesPathInBundle toPath:targetPath error:&error])
            {
                dispatch_async(dispatch_get_main_queue(), ^{
                    NSString *alertMessage = @"拷贝测试文件出错，文件管理功能测试将没有测试数据";
                    UIAlertView *view = [[[UIAlertView alloc] initWithTitle:@"拷贝测试文件" message:alertMessage delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] autorelease];
                    [view show];
                });
            }
        });
    }
}

- (BOOL)isUrlCanBeDownloaded:(NSString *)urlString
{
    for (NSString *fileType in self.fileSuffixes)
    {
        if ([urlString hasSuffix:fileType])
        {
            return YES;
        }
    }
    
    return NO;
}

- (void)showDownloadListView
{
    [self.downloadController showDownloadListView:YES anmiated:YES];
}

#pragma mark -
#pragma mark Keyboard Event Handlers
- (void)onKeyboardWillShow:(NSNotification*)notify
{
    if (!self.isActivatedAddressBar || self.keyboardMaskView != nil)
    {
        return;
    }
    
    /* Some basic data */
    NSTimeInterval animationDuration = [notify.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    CGFloat addressBarBottom = CGRectGetMaxY(self.addressBar.frame);
    CGFloat maskViewHeight = CGRectGetHeight(self.view.bounds) - addressBarBottom;
    
    /* Create the mask view and add to our view */
    _keyboardMaskView = [[UIView alloc] initWithFrame:CGRectMake(0, addressBarBottom, CGRectGetWidth(self.view.bounds), maskViewHeight)];
    [self.keyboardMaskView setBackgroundColor:[UIColor clearColor]];
    [self.view addSubview:self.keyboardMaskView];
    
    /* Tap on the mask view will cause the keyboard to hide itself */
    UITapGestureRecognizer *tap = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(hideKeyboard)] autorelease];
    [self.keyboardMaskView addGestureRecognizer:tap];
    
    [UIView animateWithDuration:animationDuration animations:^{[self.keyboardMaskView setBackgroundColor:[[UIColor blackColor] colorWithAlphaComponent:0.5]];}];
}

- (void)onKeyboardWillHide:(NSNotification*)notify
{
    if (!self.isActivatedAddressBar)
    {
        return;
    }
    
    NSTimeInterval animatioinDuration = [notify.userInfo[UIKeyboardAnimationDurationUserInfoKey] doubleValue];
    [UIView animateWithDuration:animatioinDuration animations:^{[self.keyboardMaskView setBackgroundColor:[UIColor clearColor]];} completion:^(BOOL finished) {
        
        if (self.keyboardMaskView != nil)
        {
            /* The keyboardMaskView will be removed after the animation is finished */
            [self.keyboardMaskView removeFromSuperview];
            self.keyboardMaskView = nil;
        }
        
        self.isActivatedAddressBar = NO;
    }];
}


#pragma mark -
#pragma mark AddressBarDelegate
- (void)addressBar:(AddressBar *)addressBar requireToLoadURL:(NSURL *)targetUrl
{
    [self hideKeyboard];
    [self.webView loadRequest:[NSURLRequest requestWithURL:targetUrl]];
}

- (void)addressBar:(AddressBar *)addressBar requireToRefreshURL:(NSURL *)targetUrl
{
    [self hideKeyboard];
    
    if (self.isLastLoadingSucc)
    {
        [self.webView reload];  // The webview will only reload the last url that's been loaded successfully by itself
    }
    else
    {
        NSURLRequest *request = [NSURLRequest requestWithURL:targetUrl];
        [self.webView loadRequest:request];
    }
}

- (void)addressBarRequireToStopLoading:(AddressBar *)addressBar
{
    if (![self.webView isLoading])
    {
        return;
    }
    
    [self.webView stopLoading];
}

- (void)addressBarDidStartEditing:(AddressBar *)addressBar
{
    self.isActivatedAddressBar = YES;
}


#pragma mark -
#pragma mark UIWebViewDelegate
- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error
{
    NSLog(@"===didFailLoadWithError===\n%@", error);
    self.isLastLoadingSucc = NO;
    
    UIAlertView *failAlertView = [[[UIAlertView alloc] initWithTitle:@"打开网页" message:@"打开网页时出错了" delegate:nil cancelButtonTitle:@"确定" otherButtonTitles:nil, nil] autorelease];
    [failAlertView show];
    
    [self.addressBar setAddressBarState:AddressBarStateFinishLoading];
}

- (void)webViewDidFinishLoad:(UIWebView *)webView
{
    self.isLastLoadingSucc = YES;
    
    [self.addressBar setAddressBarState: AddressBarStateFinishLoading];
    [self.addressBar setAddressBarText:[webView.request.URL absoluteString]];
    
    [self.bottomToolBar setEnable:[self.webView canGoBack] forItemAtIndex:BottomToolBarItemIndexGoBack];
    [self.bottomToolBar setEnable:[self.webView canGoForward] forItemAtIndex:BottomToolBarItemIndexGoForward];
    
    [self.historySaver saveLinkHistory:webView.request.URL];  // Save the history here

}

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    self.isLastLoadingSucc = NO;
}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    if ([[request.URL absoluteString] isEqualToString:@"abount:blank"])
    {
        return NO;
    }
    
    if ([self isUrlCanBeDownloaded:[request.URL absoluteString]])
    {
        self.downloadUrl = request.URL;
        
//        NSString *message = [NSString stringWithFormat:@"是否下载文件%@", [[request.URL absoluteString] lastPathComponent]];
        UIAlertView *view = [[UIAlertView alloc] initWithTitle:@"下载文件" message:@"TEST" delegate:self cancelButtonTitle:@"确定" otherButtonTitles:@"取消", nil];
        [view show];
        [view release];
        
        return NO;
    }
    
    return  YES;
}


#pragma mark -
#pragma mark Bottom Tool Bar Button Item Actions
- (void)actionGoBack
{
    /* We don't need to check canGoBack again, co'z it's been done when the page is loaded */
    [self.webView goBack];
}

- (void)actionGoForward
{
    [self.webView goForward]; // See comment in actionGoBack
}

- (void)actionFileManagement
{
    FileManageViewController *fileManageViewController = [[[FileManageViewController alloc] init] autorelease];
    [self.navigationController pushViewController:fileManageViewController animated:YES];
}

- (void)actionHistory
{
    HistoryViewController *historyController = [[HistoryViewController alloc] init];
    [historyController setHistorySaver:self.historySaver];
    [historyController setDelegate:self];
    
    [self.navigationController pushViewController:historyController animated:YES];
    [historyController release];
}

- (void)actionPagination
{
    /* No required */
}


- (void)bottomBar:(BottomToolBar *)toolbar didPressButtonAtIndex:(NSInteger)index
{
    switch(index)
    {
        case BottomToolBarItemIndexGoBack:
        {
            [self actionGoBack];
        }
            break;
            
        case BottomToolBarItemIndexGoForward:
        {
            [self actionGoForward];
        }
            break;
            
        case BottomToolBarItemIndexHistoryList:
        {
            [self actionHistory];
        }
            break;
            
        case BottomToolBarItemIndexFileManagement:
        {
            [self actionFileManagement];
        }
            break;
            
        case BottomToolBarItemIndexPagination:
        {
            [self actionPagination];
        }
            break;
            
        default:
            break;
    }
}

#pragma mark - 
#pragma mark HistoryViewControllerDelegate
- (void)loadHistoryURL:(NSURL *)url
{
    [self addressBar:nil requireToLoadURL:url];
}


#pragma mark -
#pragma mark DownLoadControllerDelegate
- (void)downloadController:(DownloadController *)controller needToNavigateToPath:(NSString *)path
{
    FileManageViewController *fileManagerController = [[[FileManageViewController alloc] init] autorelease];
    [fileManagerController setDefaultPathToShow:path];
    
    [self.navigationController pushViewController:fileManagerController animated:YES];
}

- (void)downloadControllerDidRemoveAllFiles:(DownloadController *)controller
{
    [self.downloadController showDownloadListView:NO anmiated:YES];
    [self.addressBar removeToolItem:self.progressButton animated:YES];
    
    [_progressButton release];
    _progressButton = nil;
}

#pragma mark - 
#pragma mark UIAlertViewDelegate
- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex
{
    if (buttonIndex == 0)
    {
        if (self.progressButton == nil)
        {
            _progressButton = [[ProgressButton alloc] initWithFrame:CGRectMake(0, 0, 40, 40)];
            [_progressButton addTarget:self action:@selector(showDownloadListView)];

            [self.addressBar addToolItem:self.progressButton animated:YES error:nil];
        }
        
        
        
        if (self.downloadController == nil)
        {
            _downloadController = [[DownloadController alloc] init];
            [_downloadController setDelegate:self];
        }

        [self.downloadController addDownloadToTarget:self.downloadUrl];
    }
}


#pragma mark - 
#pragma mark UINavigationControllerDelegate
- (void)navigationController:(UINavigationController *)navigationController willShowViewController:(UIViewController *)viewController animated:(BOOL)animated
{
    if ([viewController isEqual:self])
    {
        [navigationController setNavigationBarHidden:YES animated:YES];
    }
    else
    {
        [navigationController setNavigationBarHidden:NO animated:YES];
    }
}


@end