//
//  JQWebViewController.h
//  DuoMiPay
//
//  Created by life on 2018/1/2.
//  Copyright © 2018年 zjq. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface JQWebViewController : UIViewController


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


- (instancetype) initWithURLString:(NSString *)urlString;

- (instancetype) initWithHTMLString:(NSString *)htmlString;


- (void)loadRequest:(NSString *)urlString;

@end
