//
//  JQWKScriptMessageDelegate.h
//  JQWebViewDemo
//
//  Created by life on 2018/10/22.
//  Copyright © 2018年 zjq. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WebKit/WebKit.h>

@interface JQWKScriptMessageDelegate : NSObject<WKScriptMessageHandler>

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)delegate;

@end

