//
//  ViewController.m
//  JQWebViewDemo
//
//  Created by life on 2018/4/11.
//  Copyright © 2018年 zjq. All rights reserved.
//

#import "ViewController.h"
#import "JQWebViewController.h"
#import "WebViewController.h"
@interface ViewController ()



@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    
    
    // Do any additional setup after loading the view, typically from a nib.
}
- (IBAction)showWebViewAction:(UIButton *)sender {
    
    JQWebViewController *webView = [[JQWebViewController alloc]initWithURLString:@"https://m.fliggy.com"];
    webView.loadingTrackTintColor = [UIColor whiteColor];
    webView.loadingTintColor = [UIColor redColor];
    [self.navigationController pushViewController:webView animated:YES];
    
}


- (IBAction)showCustomController:(UIButton *)sender {
    
    WebViewController *webView = [[WebViewController alloc]initWithURLString:@"https://m.vmall.com"];
    [self.navigationController pushViewController:webView animated:YES];
    
    
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
