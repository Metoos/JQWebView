//
//  JQWebView.m
//  DuoMiPay
//
//  Created by life on 2018/1/2.
//  Copyright © 2018年 zjq. All rights reserved.
//

#import "JQWebView.h"
#import "JQWKScriptMessageDelegate.h"

#define isiOS8 [[[UIDevice currentDevice] systemVersion] floatValue]>=8.0
static void *JQWebBrowserContext = &JQWebBrowserContext;


@interface JQWebView ()<UIAlertViewDelegate,WKScriptMessageHandler>
@property (nonatomic, strong) NSTimer *fakeProgressTimer;
@property (nonatomic, assign) BOOL uiWebViewIsLoading;
@property (nonatomic, strong) NSURL *uiWebViewCurrentURL;
@property (nonatomic, strong) NSURL *URLToLaunchWithPermission;
@property (nonatomic, strong) UIAlertView *externalAppPermissionAlertView;

@property (nonatomic, strong) NSString *webViewTitle;

@property (nonatomic, strong) NSMutableArray *scriptMessageHandlers;

@end

@implementation JQWebView

#pragma mark --Initializers
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
     
        if(isiOS8) {
            
            //初始化一个WKWebViewConfiguration对象
            WKWebViewConfiguration *config = [WKWebViewConfiguration new];
            //初始化偏好设置属性：preferences
            config.preferences = [WKPreferences new];
            //The minimum font size in points default is 0;
            config.preferences.minimumFontSize = 0;
            //是否支持JavaScript
            config.preferences.javaScriptEnabled = YES;
            //不通过用户交互，是否可以打开窗口
            config.preferences.javaScriptCanOpenWindowsAutomatically = YES;
            self.wkWebView = [[WKWebView alloc] initWithFrame:frame configuration:config];
            
        }
        else {
            
            self.uiWebView = [[UIWebView alloc] init];
            
        }
        
        
        self.backgroundColor = [UIColor colorWithRed:240.0f/255.0f green:245.0/255.0 blue:245.0/255.0 alpha:1];
        if(self.wkWebView) {
            [self.wkWebView setNavigationDelegate:self];
            [self.wkWebView setUIDelegate:self];
            [self.wkWebView setMultipleTouchEnabled:YES];
            [self.wkWebView setAutoresizesSubviews:YES];
            [self.wkWebView.scrollView setAlwaysBounceVertical:YES];
            // 标识是否支持左、右swipe手势是否可以前进、后退
            self.wkWebView.allowsBackForwardNavigationGestures = YES;
            [self addSubview:self.wkWebView];
            self.wkWebView.scrollView.bounces = NO;
            [self.wkWebView addObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress)) options:0 context:JQWebBrowserContext];
             [self.wkWebView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:JQWebBrowserContext];
            
            if (@available(iOS 11.0, *)) {
                self.wkWebView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
                self.wkWebView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
                self.wkWebView.scrollView.scrollIndicatorInsets = self.wkWebView.scrollView.contentInset;
            }
 
        }
        else  {
            [self.uiWebView setFrame:frame];
            [self.uiWebView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
            [self.uiWebView setDelegate:self];
            [self.uiWebView setMultipleTouchEnabled:YES];
            [self.uiWebView setAutoresizesSubviews:YES];
            [self.uiWebView setScalesPageToFit:YES];
            [self.uiWebView.scrollView setAlwaysBounceVertical:YES];
            self.uiWebView.scrollView.bounces = NO;
            
            [self addSubview:self.uiWebView];
        }

        self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        [self.progressView setFrame:CGRectMake(0, (([[UIApplication sharedApplication] statusBarFrame].size.height)>=44)?88.0f:64.0f, self.frame.size.width, self.progressView.frame.size.height)];
        [self setTrackTintColor:[UIColor colorWithWhite:1.0f alpha:0.0f]];
        //设置进度条颜色
        [self setTintColor:[UIColor colorWithRed:0.400 green:0.863 blue:0.133 alpha:1.000]];
        [self addSubview:self.progressView];
        
        
    }
    return self;
}


- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    
    if(self.wkWebView) {
        [self.wkWebView setFrame:self.bounds];
    }
    else  {
        [self.uiWebView setFrame:self.bounds];
        
        
    }
}

- (void)addScriptMessageWithName:(NSString *)name handler:(ScriptMessageHandler)handler
{
    if (name == nil || [name isEqualToString:@""]) {
        return;
    }
    
    [self.wkWebView.configuration.userContentController addScriptMessageHandler:[[JQWKScriptMessageDelegate alloc]initWithDelegate:self] name:name];
    
    NSMutableDictionary *dic = [[NSMutableDictionary alloc]init];
    [dic setValue:name forKey:@"name"];
    if (handler) {
        [dic setValue:handler forKey:@"handler"];
    }
    [self.scriptMessageHandlers addObject:dic];
    
}

- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    
    [self.scriptMessageHandlers enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if ([message.name isEqualToString:obj[@"name"]]) {
            if (obj[@"handler"]) {
                ScriptMessageHandler handler = obj[@"handler"];
                handler(message.body);
            }
        }
    }];
}




#pragma mark - Public Interface
- (void)loadRequest:(NSURLRequest *)request {
    if(self.wkWebView) {
        [self.wkWebView loadRequest:request];
    }
    else  {
        [self.uiWebView loadRequest:request];
        
        
    }
}

- (void)setScrollEnabled:(BOOL)scrollEnabled
{
    _scrollEnabled = scrollEnabled;
    if(self.wkWebView) {
        self.wkWebView.scrollView.scrollEnabled = _scrollEnabled;
    }else  {
        self.uiWebView.scrollView.scrollEnabled = _scrollEnabled;
    }
    
}

- (void)loadURL:(NSURL *)URL {
    [self loadRequest:[NSURLRequest requestWithURL:URL]];
}

- (void)loadURLString:(NSString *)URLString {
    NSURL *URL = [NSURL URLWithString:URLString];
    [self loadURL:URL];
}

- (void)loadHTMLString:(NSString *)HTMLString {
    if(self.wkWebView) {
        [self.wkWebView loadHTMLString:HTMLString baseURL:nil];
    }
    else if(self.uiWebView) {
        [self.uiWebView loadHTMLString:HTMLString baseURL:nil];
    }
}

// web html document title
- (NSString *)getHTMLDocumentTitle
{
    if (self.wkWebView) {
        return self.webViewTitle;
    }else
    {
        self.webViewTitle = [self.uiWebView stringByEvaluatingJavaScriptFromString:@"document.title"];
        return self.webViewTitle;
    }
}

// web html Content scrollHeight
- (CGFloat)getHTMLScrollHeight
{
    if (self.wkWebView) {
        [self.wkWebView sizeToFit];
        return self.wkWebView.scrollView.contentSize.height;
    }else
    {
        CGFloat height = [[self.uiWebView stringByEvaluatingJavaScriptFromString:@"document.body.offsetHeight"] floatValue];
        return height;
    }
}

- (BOOL)canGoBack
{
    if(self.wkWebView) {
       return [self.wkWebView canGoBack];
    }
    else {
       return [self.uiWebView canGoBack];
    }

}
- (void)goBack
{
    if(self.wkWebView) {
        [self.wkWebView goBack];
    }
    else{
        [self.uiWebView goBack];
    }
}
- (BOOL)canGoForward
{
    if(self.wkWebView) {
       return [self.wkWebView canGoForward];
    }
    else {
       return [self.uiWebView canGoForward];
    }
}
- (void)goForward
{
    if(self.wkWebView) {
        [self.wkWebView goForward];
    }
    else {
        [self.uiWebView goForward];
    }
}
- (void)reload
{
    if(self.wkWebView) {
        [self.wkWebView reload];
    }
    else {
        [self.uiWebView reload];
    }
}


- (void)setTintColor:(UIColor *)tintColor {
    _tintColor = tintColor;
    [self.progressView setTintColor:tintColor];
}

- (void)setTrackTintColor:(UIColor *)trackTintColor {
    _trackTintColor = trackTintColor;
    
    [self.progressView setTrackTintColor:trackTintColor];
}



#pragma mark - UIWebViewDelegate

- (void)webViewDidStartLoad:(UIWebView *)webView
{
    if(webView == self.uiWebView) {
        [self.delegate JQWebViewDidStartLoad:self];
        
    }
}

//监视请求
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType {
    
    if(webView == self.uiWebView) {
        if(![self externalAppRequiredToOpenURL:request.URL]) {
            self.uiWebViewCurrentURL = request.URL;
            self.uiWebViewIsLoading = YES;
            
            [self fakeProgressViewStartLoading];

            //back delegate
            if (self.delegate && [self.delegate respondsToSelector:@selector(JQWebView:shouldStartLoadWithRequest:navigationType:)]) {
                return [self.delegate JQWebView:self shouldStartLoadWithRequest:request navigationType:navigationType];
            }else
            {
                return YES;
            }
          
        }
        else {
            [self launchExternalAppWithURL:request.URL];
            return NO;
        }
    }
    return NO;
}

/* WKWebView默认禁止了一些跳转
 
 UIWebView
 打开ituns.apple.com跳转到appStore, 拨打电话, 唤起邮箱等一系列操作UIWebView默认支持的.
 WKWebView
 默认禁止了以上行为,除此之外,js端通过alert()`弹窗的动作也被禁掉了.
 这边做处理*/

// 警告框
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
    }])];
    [[self getCurrentViewController] presentViewController:alertController animated:YES completion:nil];
    
}
// 确认框
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler{
    //    DLOG(@"msg = %@ frmae = %@",message,frame);
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
    }])];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
    }])];
    [[self getCurrentViewController] presentViewController:alertController animated:YES completion:nil];
}
// 输入框
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler{
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:@"" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = defaultText;
    }];
    [alertController addAction:([UIAlertAction actionWithTitle:@"完成" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(alertController.textFields[0].text?:@"");
    }])];
    
    
    
    [[self getCurrentViewController] presentViewController:alertController animated:YES completion:nil];
    
}


- (void)webViewDidFinishLoad:(UIWebView *)webView {
    
    
    if(webView == self.uiWebView) {
        if(!self.uiWebView.isLoading) {
            self.uiWebViewIsLoading = NO;
            
            [self fakeProgressBarStopLoading];
        }
        
        //back delegate
        [self.delegate JQWebView:self didFinishLoadingURL:self.uiWebView.request.URL];
        
    }
}

- (void)webView:(UIWebView *)webView didFailLoadWithError:(NSError *)error {
    
    if(webView == self.uiWebView) {
        if(!self.uiWebView.isLoading) {
            self.uiWebViewIsLoading = NO;
            
            [self fakeProgressBarStopLoading];
        }
        
        //back delegate
        [self.delegate JQWebView:self didFailToLoadURL:self.uiWebView.request.URL error:error];
    }
}




#pragma mark - WKNavigationDelegate


- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    if(webView == self.wkWebView) {
        
        
        
        
        //back delegate
        [self.delegate JQWebViewDidStartLoad:self];
        
        
        //        WKNavigationActionPolicy(WKNavigationActionPolicyAllow);
        
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    
    if(webView == self.wkWebView) {
        
        //back delegate
        [self.delegate JQWebView:self didFinishLoadingURL:self.wkWebView.URL];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation
      withError:(NSError *)error {
    if(webView == self.wkWebView) {
        //back delegate
        [self.delegate JQWebView:self didFailToLoadURL:self.wkWebView.URL error:error];
    }
    
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation
      withError:(NSError *)error {
    if(webView == self.wkWebView) {
        //back delegate
        [self.delegate JQWebView:self didFailToLoadURL:self.wkWebView.URL error:error];
    }
}

//访问不受信任的https
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(NSURLAuthenticationChallenge *)challenge completionHandler:(void (^)(NSURLSessionAuthChallengeDisposition disposition, NSURLCredential * _Nullable credential))completionHandler{
    
    if ([challenge.protectionSpace.authenticationMethod isEqualToString:NSURLAuthenticationMethodServerTrust]) {
        
        NSURLCredential *card = [[NSURLCredential alloc]initWithTrust:challenge.protectionSpace.serverTrust];
        
        completionHandler(NSURLSessionAuthChallengeUseCredential,card);
        
    }
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    

    if(webView == self.wkWebView) {
        
        /* WKWebView默认禁止了一些跳转
         
         UIWebView
         打开ituns.apple.com跳转到appStore, 拨打电话, 唤起邮箱等一系列操作UIWebView默认支持的.
         WKWebView
         默认禁止了以上行为,除此之外,js端通过alert()`弹窗的动作也被禁掉了.
         这边做处理*/
        
        NSURL *URL = navigationAction.request.URL;
        
        NSString *scheme = [URL scheme];
        UIApplication *app = [UIApplication sharedApplication];
        // 打电话
        if ([scheme isEqualToString:@"tel"]) {
            if ([app canOpenURL:URL]) {
                [app openURL:URL];
                // 一定要加上这句,否则会打开新页面
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
        }
        // 打开appstore
        if ([URL.absoluteString containsString:@"ituns.apple.com"]) {
            if ([app canOpenURL:URL]) {
                [app openURL:URL];
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
        }
        if ([self isWirelessDownloadManifestForURL:URL]) {
            //当前加载链接为苹果企业APP无线安装清单文件，则打开外部浏览器进行展示
            [app openURL:URL];
             decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
        
        if(![self externalAppRequiredToOpenURL:URL]) {
            if(!navigationAction.targetFrame) {
                [self loadURL:URL];
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
            BOOL decision = [self callback_webViewShouldStartLoadWithRequest:navigationAction.request navigationType:navigationAction.navigationType];
            if (decision) {
                decisionHandler(WKNavigationActionPolicyAllow);
                return;
            } else
            {
                decisionHandler(WKNavigationActionPolicyCancel);
                return;
            }
            
        }
        else if([[UIApplication sharedApplication] canOpenURL:URL]) {
            [self launchExternalAppWithURL:URL];
            decisionHandler(WKNavigationActionPolicyCancel);
            return;
        }
    }
    decisionHandler(WKNavigationActionPolicyAllow);

}

- (BOOL)isWirelessDownloadManifestForURL:(NSURL*)url
{
//    DLog(@"url.absoluteString = %@ ",url.absoluteString);
    if (!url.absoluteString) {
        return NO;
    }
    
    NSString *urlString = url.absoluteString;
    if ([urlString hasPrefix:@"itms-services://?action=download-manifest&url="]) {
        return YES;
    }
    return NO;
}

-(BOOL)callback_webViewShouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(NSInteger)navigationType
{
    //back delegate
    if (self.delegate && [self.delegate respondsToSelector:@selector(JQWebView:shouldStartLoadWithRequest:navigationType:)]) {
        return [self.delegate JQWebView:self shouldStartLoadWithRequest:request navigationType:navigationType];
    }else
    {
        return YES;
    }

}


#pragma mark - WKUIDelegate

- (WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures{
    if (!navigationAction.targetFrame.isMainFrame) {
        [webView loadRequest:navigationAction.request];
    }
    return nil;
}
#pragma mark - Estimated Progress KVO (WKWebView)

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context {
    if ([keyPath isEqualToString:NSStringFromSelector(@selector(estimatedProgress))] && object == self.wkWebView) {
        [self.progressView setAlpha:1.0f];
        BOOL animated = self.wkWebView.estimatedProgress > self.progressView.progress;
        [self.progressView setProgress:self.wkWebView.estimatedProgress animated:animated];
        
        // Once complete, fade out UIProgressView
        if(self.wkWebView.estimatedProgress >= 1.0f) {
            [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
                [self.progressView setAlpha:0.0f];
            } completion:^(BOOL finished) {
                [self.progressView setProgress:0.0f animated:NO];
            }];
        }
    }else if ([keyPath isEqualToString:@"title"]){//网页title
        if (object == self.wkWebView){
            self.webViewTitle = self.wkWebView.title;
        }else{
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }
    else {
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - Fake Progress Bar Control (UIWebView)

- (void)fakeProgressViewStartLoading {
    [self.progressView setProgress:0.0f animated:NO];
    [self.progressView setAlpha:1.0f];
    
    if(!self.fakeProgressTimer) {
        self.fakeProgressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0f/60.0f target:self selector:@selector(fakeProgressTimerDidFire:) userInfo:nil repeats:YES];
    }
}

- (void)fakeProgressBarStopLoading {
    if(self.fakeProgressTimer) {
        [self.fakeProgressTimer invalidate];
    }
    
    if(self.progressView) {
        [self.progressView setProgress:1.0f animated:YES];
        [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
            [self.progressView setAlpha:0.0f];
        } completion:^(BOOL finished) {
            [self.progressView setProgress:0.0f animated:NO];
        }];
    }
}

- (void)fakeProgressTimerDidFire:(id)sender {
    CGFloat increment = 0.005/(self.progressView.progress + 0.2);
    if([self.uiWebView isLoading]) {
        CGFloat progress = (self.progressView.progress < 0.75f) ? self.progressView.progress + increment : self.progressView.progress + 0.0005;
        if(self.progressView.progress < 0.95) {
            [self.progressView setProgress:progress animated:YES];
        }
    }
}

#pragma mark - External App Support
- (BOOL)externalAppRequiredToOpenURL:(NSURL *)URL {
    
    //若需要限制只允许某些前缀的scheme通过请求，则取消下述注释，并在数组内添加自己需要放行的前缀
    //    NSSet *validSchemes = [NSSet setWithArray:@[@"http", @"https",@"file"]];
    //    return ![validSchemes containsObject:URL.scheme];
    
    return !URL;
}

- (void)launchExternalAppWithURL:(NSURL *)URL {
    self.URLToLaunchWithPermission = URL;
    if (![self.externalAppPermissionAlertView isVisible]) {
        [self.externalAppPermissionAlertView show];
    }
    
}

#pragma mark - UIAlertViewDelegate

- (void)alertView:(UIAlertView *)alertView didDismissWithButtonIndex:(NSInteger)buttonIndex {
    if(alertView == self.externalAppPermissionAlertView) {
        if(buttonIndex != alertView.cancelButtonIndex) {
            [[UIApplication sharedApplication] openURL:self.URLToLaunchWithPermission];
        }
        self.URLToLaunchWithPermission = nil;
    }
}


#pragma mark -获取当前屏幕显示的viewcontroller
- (UIViewController *)getCurrentViewController
{

    UIWindow * window = [[UIApplication sharedApplication] keyWindow];
    
    if (window.windowLevel != UIWindowLevelNormal){
        
        NSArray *windows = [[UIApplication sharedApplication] windows];
        
        for(UIWindow * tmpWin in windows){
            
            if (tmpWin.windowLevel == UIWindowLevelNormal){
                
                window = tmpWin;
                
                break;
                
            }
            
        }
        
    }
    
    UIViewController *result = window.rootViewController;
    
    while (result.presentedViewController) {
        
        result = result.presentedViewController;
        
    }
    
    if ([result isKindOfClass:[UITabBarController class]]) {
        
        result = [(UITabBarController *)result selectedViewController];
        
    }
    
    if ([result isKindOfClass:[UINavigationController class]]) {
        
        result = [(UINavigationController *)result topViewController];
        
    }
    
    return result;
    
    
}

- (NSMutableArray *)scriptMessageHandlers
{
    if (_scriptMessageHandlers == nil) {
        _scriptMessageHandlers = [[NSMutableArray alloc]init];
    }
    return _scriptMessageHandlers;
}

#pragma mark - Dealloc

- (void)dealloc {
    NSLog(@"JQWebView dealloc");
    [self.uiWebView setDelegate:nil];
    [self.wkWebView setNavigationDelegate:nil];
    [self.wkWebView setUIDelegate:nil];
    [self.wkWebView removeObserver:self forKeyPath:NSStringFromSelector(@selector(estimatedProgress))];
    [self.wkWebView removeObserver:self forKeyPath:@"title"];
    
    [self.scriptMessageHandlers enumerateObjectsUsingBlock:^(NSDictionary *obj, NSUInteger idx, BOOL * _Nonnull stop) {
        NSString *name  = obj[@"name"];
        [self.wkWebView.configuration.userContentController removeScriptMessageHandlerForName:name];
    }];
    [self.scriptMessageHandlers removeAllObjects];
    self.scriptMessageHandlers = nil;
    
}

@end

