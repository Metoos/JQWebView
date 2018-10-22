//
//  JQWKScriptMessageDelegate.m
//  JQWebViewDemo
//
//  Created by life on 2018/10/22.
//  Copyright © 2018年 zjq. All rights reserved.
//

#import "JQWKScriptMessageDelegate.h"

@interface JQWKScriptMessageDelegate()

@property (weak, nonatomic) id<WKScriptMessageHandler> delegate;

@end

@implementation JQWKScriptMessageDelegate

- (instancetype)initWithDelegate:(id<WKScriptMessageHandler>)delegate
{
    self = [super init];
    if (self) {
        self.delegate = delegate;
    }
    return self;
}

- (void)userContentController:(nonnull WKUserContentController *)userContentController didReceiveScriptMessage:(nonnull WKScriptMessage *)message {
    
    [self.delegate userContentController:userContentController didReceiveScriptMessage:message];
}

@end
