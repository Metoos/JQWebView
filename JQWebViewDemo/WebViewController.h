//
//  WebViewController.h
//  VMProject
//
//  Created by life on 2018/4/16.
//  Copyright © 2018年 hdyg. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController

- (instancetype) initWithURLString:(NSString *)urlString;

- (instancetype) initWithHTMLString:(NSString *)htmlString;

@property (strong, nonatomic) NSString *urlString;

@property (assign, nonatomic) BOOL isHiddenBackItem;


- (void)loadRequest:(NSString *)urlString;


@end
