//
//  JQWebView.h
//  DuoMiPay
//
//  Created by life on 2018/1/2.
//  Copyright © 2018年 zjq. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <WebKit/WebKit.h>

@class JQWebView;
@protocol JQWebViewDelegate <NSObject>
@optional
- (void)JQWebView:(JQWebView *)webview didFinishLoadingURL:(NSURL *)URL;
- (void)JQWebView:(JQWebView *)webview didFailToLoadURL:(NSURL *)URL error:(NSError *)error;
- (BOOL)JQWebView:(JQWebView *)webview shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(NSInteger)navigationType;
- (void)JQWebViewDidStartLoad:(JQWebView *)webview;
@end



typedef void(^ScriptMessageHandler)(id data);
@interface JQWebView : UIView<WKNavigationDelegate, WKUIDelegate>


#pragma mark - Public Properties

//JQdelegate
@property (nonatomic, weak) id <JQWebViewDelegate> delegate;

// add js function (window.webkit.messageHandlers.<name>.postMessage(<data>);)
- (void)addScriptMessageWithName:(NSString *)name handler:(ScriptMessageHandler)handler;

// The main and only UIProgressView
@property (nonatomic, strong) UIProgressView *progressView;
// The web views
// Depending on the version of iOS, one of these will be set
@property (nonatomic, strong) WKWebView *wkWebView;

@property (nonatomic, assign) BOOL scrollEnabled;

#pragma mark - Initializers view
- (instancetype)initWithFrame:(CGRect)frame;


#pragma mark - Static Initializers
//UIProgressView tintColor
@property (nonatomic, strong) UIColor *tintColor;
//UIProgressView trackTintColor
@property (nonatomic, strong) UIColor *trackTintColor;



//Allow for custom activities in the browser by populating this optional array
@property (nonatomic, strong) NSArray *customActivityItems;

#pragma mark - Public Interface


// Load a NSURLURLRequest to web view
// Can be called any time after initialization
- (void)loadRequest:(NSURLRequest *)request;

// Load a NSURL to web view
// Can be called any time after initialization
- (void)loadURL:(NSURL *)URL;

// Loads a URL as NSString to web view
// Can be called any time after initialization
- (void)loadURLString:(NSString *)URLString;


// Loads an string containing HTML to web view
// Can be called any time after initialization
- (void)loadHTMLString:(NSString *)HTMLString;

// web html document title
- (NSString *)getHTMLDocumentTitle;

// web html Content scrollHeight
- (CGFloat)getHTMLScrollHeight;

/*! @abstract A Boolean value indicating whether there is a back item in
 the back-forward list that can be navigated to.
 for this property.
 @seealso backForwardList.
 */
- (BOOL)canGoBack;

/*! @abstract Navigates to the back item in the back-forward list.
 item in the back-forward list.
 */
- (void)goBack;

/*! @abstract A Boolean value indicating whether there is a forward item in
 the back-forward list that can be navigated to.
 for this property.
 @seealso backForwardList.
 */
- (BOOL)canGoForward;

/*! @abstract Navigates to the forward item in the back-forward list.
 forward item in the back-forward list.
 */
- (void)goForward;
/*! @abstract Reloads the current page.
 */
- (void)reload;


/* 清除全部缓存 */
+ (void)deleteAllWebCache;

/*
   自定义清除缓存
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
+ (void)deleteWebCacheOfWebsiteDataTypes:(NSArray *)types completionHandler:(void (^)(void))completionHandler;

@end
