//
//  WebMutualManager.h
//  Common
//
//  Created by 黄磊 on 16/4/6.
//  Copyright © 2016年 Musjoy. All rights reserved.
//  用于处理与网页之间的交互

#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/message.h>
//#import "Utils.h"
#import "WebRequestModel.h"
#import "WebResultModel.h"
#import <WebKit/WebKit.h>

#ifndef FILE_NAME_WEB_MUTUAL
#define FILE_NAME_WEB_MUTUAL    @"web_mutual"
#endif

// web事件处理方式
typedef enum {
    kWebUnknown   = -1,                 // 未知模式
    kWebOpenView  = 0,                  // 在平台层打开对应界面
    kWebFetchData,                      // 从平台层获取数据
    kWebSendData,                       // 向平台层发送数据
    kWebRegistAction                    // 向平台层注册方法
} WebActionHandleMode;

// 显示商户详情
@protocol WebMutualManagerDelegate <NSObject>

@required
- (WKWebView *)webView;

@optional
- (BOOL)canHandleThisRequest:(WebRequestModel *)request;

@end


@interface WebMutualManager : NSObject

+ (WebMutualManager *)sharedInstance;

- (NSNumber *)printLog:(NSString *)logInfo;

- (void)handleThisRequest:(NSURL *)requestURL withDelegate:(id<WebMutualManagerDelegate>)delegate;

// 网页交互，平台层的回调
- (void)callbackWithResult:(WebResultModel *)result isFinish:(BOOL)isFinish;

@end
