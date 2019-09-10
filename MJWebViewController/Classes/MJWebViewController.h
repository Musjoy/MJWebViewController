//
//  MJWebViewController.h
//  Common
//
//  Created by 黄磊 on 16/4/6.
//  Copyright © 2016年 Musjoy. All rights reserved.
//

#import <ModuleCapability/ModuleCapability.h>
#import <WebKit/WebKit.h>
#import HEADER_BASE_VIEW_CONTROLLER
#import "WebMutualManager.h"
#import "WebExecuteModel.h"


#ifndef kWebMutualUrlScheme
#define kWebMutualUrlScheme @"webmutual"
#endif

@interface MJWebViewController : THEBaseViewController <WKNavigationDelegate, WebMutualManagerDelegate>

@property (nonatomic, strong) WebMutualManager *webManager;
@property (strong, nonatomic) IBOutlet WKWebView *webView;
@property (nonatomic, strong) NSString *webUrl;
@property (nonatomic, strong) NSString *navTitle;
@property (nonatomic, assign) BOOL hideNav;
@property (nonatomic, assign) BOOL autoLoadUrl;         // 是否自动加载url, 默认为YES
@property (nonatomic, assign) BOOL isDealloc;           // 是否已被销毁


- (NSString *)assembleUrl:(NSString *)url parameters:(NSDictionary *)parameters;

- (void)loadUrl:(NSString *)url withParameters:(NSDictionary *)parameters;

- (void)refreshWithUrl:(NSString *)url;

- (void)refreshWithRequest:(NSURLRequest *)request;

// 直接执行js语句
- (void)executeThisJS:(NSString *)jsSentence;

// 执行WebExecuteModel对应的方法
- (void)executeThisModel:(WebExecuteModel *)executeModel;

@end
