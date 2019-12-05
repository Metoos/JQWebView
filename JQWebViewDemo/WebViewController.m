//
//  WebViewController.m
//  VMProject
//
//  Created by life on 2018/4/16.
//  Copyright © 2018年 hdyg. All rights reserved.
//

#import "WebViewController.h"
#import "JQWebView.h"
@interface WebViewController ()<JQWebViewDelegate>
{
    BOOL isLoad;
}

@property (strong, nonatomic) NSString *loadedURL;
@property (strong, nonatomic) JQWebView *webView;

@property (strong, nonatomic) UILabel *errorLab;

@property (strong, nonatomic) UIBarButtonItem *backBtn;
@property (strong, nonatomic) UIBarButtonItem *closeBtn;

//@property (strong, nonatomic) NSString *urlString;
@property (strong, nonatomic) NSString *htmlString;

/** 导航标题 showsPageTitleInNavigationBar = NO 时 有效 */
@property (strong, nonatomic) NSString *navigationTitleString;
/** 显示每个网页的标题 默认 YES*/
@property (nonatomic, assign) BOOL showsPageTitleInNavigationBar;

/** 返回按钮图片 */
@property (nonatomic, strong) UIImage *backButtonImage;
/** 进度条背景颜色 */
@property (nonatomic, strong) UIColor *loadingTrackTintColor;
/** 进度条进度值颜色 */
@property (nonatomic, strong) UIColor *loadingTintColor;
//@property (nonatomic, strong) UIColor *barTintColor;
/** 关闭全部网页按钮是否隐藏 默认显示 */
@property (nonatomic, assign) BOOL closeButtonHidden;
//@property (nonatomic, assign) BOOL showsURLInNavigationBar;


@end

@implementation WebViewController

-(instancetype)initWithURLString:(NSString *)urlString
{
    self = [super init];
    if (self) {
        self.urlString = urlString;
        self.showsPageTitleInNavigationBar = YES;
        self.backButtonImage = [UIImage imageNamed:@"jq_back"];
    }
    
    return self;
}
- (instancetype) initWithHTMLString:(NSString *)htmlString
{
    self = [super init];
    if (self) {
        self.htmlString = htmlString;
        self.showsPageTitleInNavigationBar = YES;
        self.backButtonImage = [UIImage imageNamed:@"jq_back"];
    }
    
    return self;
}

- (void)viewDidLoad {
    
    [super viewDidLoad];
    self.webView.wkWebView.scrollView.showsVerticalScrollIndicator = NO;
    self.webView.wkWebView.scrollView.showsHorizontalScrollIndicator = NO;
    
    self.backBtn = [[UIBarButtonItem alloc]initWithImage:self.backButtonImage style:UIBarButtonItemStylePlain target:self action:@selector(goBackAction)];
    
    self.closeBtn = [[UIBarButtonItem alloc]initWithTitle:@"关闭" style:UIBarButtonItemStylePlain target:self action:@selector(closeAction)];
    self.navigationItem.leftBarButtonItems = @[self.backBtn];
    
    if (@available(iOS 11.0, *)) {
        self.webView.wkWebView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
        self.webView.wkWebView.scrollView.contentInset = UIEdgeInsetsMake((([[UIApplication sharedApplication] statusBarFrame].size.height)>=44)?88.0f:64.0f, 0, 0, 0);
        self.webView.wkWebView.scrollView.scrollIndicatorInsets = self.webView.wkWebView.scrollView.contentInset;
    }
    
    if (self.urlString)
    {   //开始加载网页链接
        [self loadRequest:self.urlString];
        
    }else if (self.htmlString)
    {
        //开始加载网页代码
        [self.webView loadHTMLString:self.htmlString];
    }
    
    if (_isHiddenBackItem) {
        self.navigationItem.leftBarButtonItem = nil;
    }
    
    
    //添加js交互调用原生方法
    [self addScriptMessage];
    // Do any additional setup after loading the view.
}

- (void)addScriptMessage{
    
    [self.webView addScriptMessageWithName:@"ScanAction" handler:^(id data) {
        NSLog(@"ScanAction = %@",data);
    }];
    
    [self.webView addScriptMessageWithName:@"Share" handler:^(id data) {
        NSLog(@"Share = %@",data);
    }];
    [self.webView addScriptMessageWithName:@"Location" handler:^(id data) {
        NSLog(@"Location = %@",data);
    }];
    [self.webView addScriptMessageWithName:@"Color" handler:^(id data) {
        NSLog(@"Color = %@",data);
    }];
    [self.webView addScriptMessageWithName:@"payClick" handler:^(id data) {
        NSLog(@"payClick = %@",data);
    }];
    
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (!self.webView.wkWebView.isLoading) {
        if (self.urlString) {
            [self.webView reload];
        }
    }
}


- (void)setNavigationTitleString:(NSString *)navigationTitleString
{
    _navigationTitleString = navigationTitleString;
    self.title = navigationTitleString;
}

- (void)loadRequest:(NSString *)urlString
{
    self.urlString = urlString;
    //开始加载网页链接
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.urlString]]];
}

- (void)setLoadingTintColor:(UIColor *)loadingTintColor
{
    _loadingTintColor = loadingTintColor;
    
    self.webView.tintColor = loadingTintColor;
    
}
- (void)setLoadingTrackTintColor:(UIColor *)loadingTrackTintColor
{
    _loadingTrackTintColor = loadingTrackTintColor;
    self.webView.trackTintColor = loadingTrackTintColor;
}

- (void)goBackAction
{
    if ([self.webView canGoBack]) {
        [self.webView goBack];
    }
    else
    {
        [self.navigationController popViewControllerAnimated:YES];
    }
    
}

- (void)closeAction
{
    [self.navigationController popViewControllerAnimated:YES];
}

#pragma mark - JQWebViewDelegate
- (void)JQWebView:(JQWebView *)webview didFinishLoadingURL:(NSURL *)URL
{

    
    if (self.showsPageTitleInNavigationBar) {
        NSString *title = [webview getHTMLDocumentTitle];
        if (title.length>0) {
            self.navigationItem.title = title;
        }
    }
    
    if ([self.webView canGoBack] && !self.closeButtonHidden) {
        self.navigationItem.leftBarButtonItems = @[self.backBtn,self.closeBtn];
    }else
    {
        if (!_isHiddenBackItem) {
           self.navigationItem.leftBarButtonItems = @[self.backBtn];
        }
    }
    
}
- (void)JQWebView:(JQWebView *)webview didFailToLoadURL:(NSURL *)URL error:(NSError *)error
{
 
}
- (BOOL)JQWebView:(JQWebView *)webview shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(NSInteger)navigationType
{
    NSURL *URL = request.URL;
//    NSLog(@"urlbaseURL = %@ \n 请求URL = %@",URL.baseURL,URL.absoluteString);
    __block BOOL isreturnNO = NO;
    [self.navigationController.viewControllers enumerateObjectsUsingBlock:^(__kindof UIViewController * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
         //判断网页是否已打开 已打开则返回打开页
        if ([obj isKindOfClass:self.class]) {
            NSLog(@"((WebViewController*)obj).urlString = %@",((WebViewController*)obj).urlString);
             if ([((WebViewController*)obj).urlString isEqualToString:URL.absoluteString] && ![self.urlString isEqualToString:URL.absoluteString]) {
                 [self.navigationController popToViewController:obj animated:YES];
                 
                 isreturnNO = YES;
             }
        }
    }];
    if (isreturnNO) {
        return NO;
    }
    
    
    if (!webview.wkWebView.isLoading) {
        if (![self.urlString isEqualToString:URL.absoluteString]) {
            
            
            if (navigationType == WKNavigationTypeOther) {
                return NO;
            }
            //加载的链接有重定向时，解决中间空界面或多重界面加载问题
           NSURLSessionDataTask *sessionDataTask = [[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
                if (error || ([response respondsToSelector:@selector(statusCode)] && [((NSHTTPURLResponse *)response) statusCode] != 200 && [((NSHTTPURLResponse *)response) statusCode] != 302)) {
                    //Show error message
                    NSLog(@"statusCode = %ld",[((NSHTTPURLResponse *)response) statusCode]);
                }else {
                    
                    dispatch_async(dispatch_get_main_queue(), ^{
                        WebViewController *webViewVC = [[WebViewController alloc]initWithURLString:URL.absoluteString];
                        [self.navigationController pushViewController:webViewVC animated:YES];
                    });
                  
                }
            }];
            [sessionDataTask resume];
            return NO;
        }
    }
    return YES;
}
- (void)JQWebViewDidStartLoad:(JQWebView *)webview
{
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (JQWebView *)webView
{
    if (!_webView) {
        
        _webView = [[JQWebView alloc]initWithFrame:CGRectMake(0, 0, [UIScreen mainScreen].bounds.size.width, [UIScreen mainScreen].bounds.size.height)];
        _webView.delegate = self;
        [self.view addSubview:_webView];
    }
    
    return _webView;
}

@end
