//
//  JQWebViewController.m
//  DuoMiPay
//
//  Created by life on 2018/1/2.
//  Copyright © 2018年 zjq. All rights reserved.
//

#import "JQWebViewController.h"
#import "JQWebView.h"
@interface JQWebViewController ()<JQWebViewDelegate>

@property (strong, nonatomic) JQWebView *webView;

@property (strong, nonatomic) UILabel *errorLab;

@property (strong, nonatomic) UIBarButtonItem *backBtn;
@property (strong, nonatomic) UIBarButtonItem *closeBtn;

@property (strong, nonatomic) NSString *urlString;
@property (strong, nonatomic) NSString *htmlString;

@end

@implementation JQWebViewController

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
        [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:self.urlString]]];
        
    }else if (self.htmlString)
    {
        //开始加载网页代码
        [self.webView loadHTMLString:self.htmlString];
    }
    

    
    // Do any additional setup after loading the view.
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
            self.title = title;
        }
    }

    if ([self.webView canGoBack] && !self.closeButtonHidden) {
        self.navigationItem.leftBarButtonItems = @[self.backBtn,self.closeBtn];
    }else
    {
        self.navigationItem.leftBarButtonItems = @[self.backBtn];
    }
}
- (void)JQWebView:(JQWebView *)webview didFailToLoadURL:(NSURL *)URL error:(NSError *)error
{
    
}
- (BOOL)JQWebView:(JQWebView *)webview shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(NSInteger)navigationType
{
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
