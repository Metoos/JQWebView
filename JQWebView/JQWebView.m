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


@interface JQWebView ()<UIAlertViewDelegate,WKScriptMessageHandler,UIScrollViewDelegate>
{
    CGPoint keyboardWillShowPoint;
    BOOL keyboardWillShow;
}
@property (nonatomic, strong) NSTimer *fakeProgressTimer;
@property (nonatomic, strong) NSURL *URLToLaunchWithPermission;
@property (nonatomic, strong) UIAlertView *externalAppPermissionAlertView;

@property (nonatomic, strong) NSString *webViewTitle;

@property (nonatomic, strong) NSMutableArray *scriptMessageHandlers;

@end

@implementation JQWebView

+ (WKProcessPool*)singleWkProcessPool{
    
    static WKProcessPool *sharedPool;
    
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        sharedPool = [[WKProcessPool alloc]init];
        
    });
    
    return sharedPool;
}

#pragma mark --Initializers
- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        
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
        
        //ProcessPool改成单例可实现多webview缓存同步
        config.processPool = [JQWebView singleWkProcessPool];
        
        /*
        //禁止长按弹出 UIMenuController 相关
        
        //禁止选择 css 配置相关
        
        NSString*css = @"body{-webkit-user-select:none;-webkit-user-drag:none;}";
        
        //css 选中样式取消
        
        NSMutableString *javascript = [NSMutableString string];
        
        [javascript appendString:@"var style = document.createElement('style');"];
        
        [javascript appendString:@"style.type = 'text/css';"];
        
        [javascript appendFormat:@"var cssContent = document.createTextNode('%@');", css];
        
        [javascript appendString:@"style.appendChild(cssContent);"];
        
        [javascript appendString:@"document.body.appendChild(style);"];
        
        [javascript appendString:@"document.documentElement.style.webkitUserSelect='none';"];//禁止选择
        
        [javascript appendString:@"document.documentElement.style.webkitTouchCallout='none';"];//禁止长按
        
        //javascript 注入
        
        WKUserScript *noneSelectScript = [[WKUserScript alloc] initWithSource:javascript
                                          
                                                                injectionTime:WKUserScriptInjectionTimeAtDocumentEnd
                                          
                                                             forMainFrameOnly:YES];
        
        WKUserContentController*userContentController = [[WKUserContentController alloc] init];
        
        [userContentController addUserScript:noneSelectScript];
        
        config.userContentController = userContentController;
        
        */
        self.wkWebView = [[WKWebView alloc] initWithFrame:self.bounds configuration:config];
        
    
        self.backgroundColor = [UIColor colorWithRed:240.0f/255.0f green:245.0/255.0 blue:245.0/255.0 alpha:1];
        
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
        self.wkWebView.scrollView.delegate = self;
        if (@available(iOS 11.0, *)) {
            self.wkWebView.scrollView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
            self.wkWebView.scrollView.contentInset = UIEdgeInsetsMake(0, 0, 0, 0);
            self.wkWebView.scrollView.scrollIndicatorInsets = self.wkWebView.scrollView.contentInset;
        }
        
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillShow:) name:UIKeyboardWillShowNotification object:nil];
        
        [[NSNotificationCenter defaultCenter]addObserver:self selector:@selector(keyboardWillHide:) name:UIKeyboardWillHideNotification object:nil];
        
        
        self.progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleDefault];
        [self.progressView setFrame:CGRectMake(0, (([[UIApplication sharedApplication] statusBarFrame].size.height)>=44)?88.0f:64.0f, self.frame.size.width, self.progressView.frame.size.height)];
        [self setTrackTintColor:[UIColor colorWithWhite:1.0f alpha:0.0f]];
        //设置进度条颜色
        [self setTintColor:[UIColor colorWithRed:0.400 green:0.863 blue:0.133 alpha:1.000]];
        [self addSubview:self.progressView];
        
        
    }
    return self;
}

- (void)keyboardWillShow:(NSNotification *)notification
{
    if (!keyboardWillShow) {//避免第三方多出调用keyboardWillShow:
        keyboardWillShowPoint = self.wkWebView.scrollView.contentOffset;
        keyboardWillShow = YES;

    }
}

- (void)keyboardWillHide:(NSNotification *)notification
{
    //延迟调整滚动 避免切换键盘出现界面跳动问题
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.01 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        [self.wkWebView.scrollView setContentOffset:self->keyboardWillShowPoint animated:YES];
    });
    keyboardWillShow = NO;
        
}

- (void)setFrame:(CGRect)frame
{
    [super setFrame:frame];
    [self.wkWebView setFrame:self.bounds];
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
    [self.wkWebView loadRequest:request];
}

- (void)setScrollEnabled:(BOOL)scrollEnabled
{
    _scrollEnabled = scrollEnabled;
    self.wkWebView.scrollView.scrollEnabled = _scrollEnabled;
}

- (void)loadURL:(NSURL *)URL {
    [self loadRequest:[NSURLRequest requestWithURL:URL]];
}

- (void)loadURLString:(NSString *)URLString {
    NSURL *URL = [NSURL URLWithString:URLString];
    [self loadURL:URL];
}

- (void)loadHTMLString:(NSString *)HTMLString {
    
    [self.wkWebView loadHTMLString:HTMLString baseURL:nil];
}

// web html document title
- (NSString *)getHTMLDocumentTitle
{
    return self.webViewTitle;
    
}

// web html Content scrollHeight
- (CGFloat)getHTMLScrollHeight
{
    [self.wkWebView sizeToFit];
    return self.wkWebView.scrollView.contentSize.height;
    
}

- (BOOL)canGoBack
{
    return [self.wkWebView canGoBack];
    
}
- (void)goBack
{
    
    [self.wkWebView goBack];
    
}
- (BOOL)canGoForward
{
    
    return [self.wkWebView canGoForward];
    
}
- (void)goForward
{
    
    [self.wkWebView goForward];
    
    
}
- (void)reload
{
    
    [self.wkWebView reload];
    
}


- (void)setTintColor:(UIColor *)tintColor {
    _tintColor = tintColor;
    [self.progressView setTintColor:tintColor];
}

- (void)setTrackTintColor:(UIColor *)trackTintColor {
    _trackTintColor = trackTintColor;
    
    [self.progressView setTrackTintColor:trackTintColor];
}


/* WKWebView默认禁止了一些跳转

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

#pragma mark - WKNavigationDelegate


- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    if(self.delegate && [self.delegate respondsToSelector:@selector(JQWebViewDidStartLoad:)]) {
        
        //back delegate
        [self.delegate JQWebViewDidStartLoad:self];
        
        
        //        WKNavigationActionPolicy(WKNavigationActionPolicyAllow);
        
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    
    if(self.delegate && [self.delegate respondsToSelector:@selector(JQWebView:didFinishLoadingURL:)]) {
        
        //back delegate
        [self.delegate JQWebView:self didFinishLoadingURL:self.wkWebView.URL];
    }
}

- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation
      withError:(NSError *)error {
    if(self.delegate && [self.delegate respondsToSelector:@selector(JQWebView:didFailToLoadURL:error:)]) {
        //back delegate
        [self.delegate JQWebView:self didFailToLoadURL:self.wkWebView.URL error:error];
    }
    
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation
      withError:(NSError *)error {
    if(self.delegate && [self.delegate respondsToSelector:@selector(JQWebView:didFailToLoadURL:error:)]) {
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
    
    
    
    /* WKWebView默认禁止了一些跳转
     
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
    decisionHandler(WKNavigationActionPolicyAllow);
    
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

/* 清除全部缓存 */
+ (void)deleteAllWebCache
{
    if (@available(iOS 9.0, *)) {
        //allWebsiteDataTypes清除所有缓存
        NSSet *websiteDataTypes = [WKWebsiteDataStore allWebsiteDataTypes];
        NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
        [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:^{
            
        }];
    }else
    {
        NSString *libraryDir = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory,
                                                                   NSUserDomainMask, YES)[0];
        NSString *bundleId  =  [[[NSBundle mainBundle] infoDictionary]
                                objectForKey:@"CFBundleIdentifier"];
        NSString *webkitFolderInLib = [NSString stringWithFormat:@"%@/WebKit",libraryDir];
        NSString *webKitFolderInCaches = [NSString
                                          stringWithFormat:@"%@/Caches/%@/WebKit",libraryDir,bundleId];
        NSString *webKitFolderInCachesfs = [NSString
                                            stringWithFormat:@"%@/Caches/%@/fsCachedData",libraryDir,bundleId];
        
        NSError *error;
        /* iOS8.0 WebView Cache的存放路径 */
        [[NSFileManager defaultManager] removeItemAtPath:webKitFolderInCaches error:&error];
        [[NSFileManager defaultManager] removeItemAtPath:webkitFolderInLib error:nil];
        
        /* iOS7.0 WebView Cache的存放路径 */
        [[NSFileManager defaultManager] removeItemAtPath:webKitFolderInCachesfs error:&error];
    }
    
}

/* 自定义清除缓存 */
+ (void)deleteWebCacheOfWebsiteDataTypes:(NSArray *)types completionHandler:(void (^)(void))completionHandler {
    /*
     在磁盘缓存上。
     WKWebsiteDataTypeDiskCache,
     
     html离线Web应用程序缓存。
     WKWebsiteDataTypeOfflineWebApplicationCache,
     
     内存缓存。
     WKWebsiteDataTypeMemoryCache,
     
     本地存储。
     WKWebsiteDataTypeLocalStorage,
     
     Cookies
     WKWebsiteDataTypeCookies,
     
     会话存储
     WKWebsiteDataTypeSessionStorage,
     
     IndexedDB数据库。
     WKWebsiteDataTypeIndexedDBDatabases,
     
     查询数据库。
     WKWebsiteDataTypeWebSQLDatabases
     */
    
    NSSet *websiteDataTypes = [NSSet setWithArray:types];
    NSDate *dateFrom = [NSDate dateWithTimeIntervalSince1970:0];
    
    if (@available(iOS 9.0, *)) {
        [[WKWebsiteDataStore defaultDataStore] removeDataOfTypes:websiteDataTypes modifiedSince:dateFrom completionHandler:completionHandler];
    }
    
}


#pragma mark - Dealloc

- (void)dealloc {
    NSLog(@"JQWebView dealloc");
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
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    
}

@end

