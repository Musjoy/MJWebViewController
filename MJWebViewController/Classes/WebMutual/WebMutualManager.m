//
//  WebMutualManager.m
//  Common
//
//  Created by 黄磊 on 16/4/6.
//  Copyright © 2016年 Musjoy. All rights reserved.
//  

#include <objc/message.h>
#import "WebMutualManager.h"
#import "Utils.h"
#import HEADER_CONTROLLER_MANAGER
#import HEADER_NAVIGATION_CONTROLLER

#import "ActionProtocol.h"

#ifdef MODULE_FILE_SOURCE
#import "FileSource.h"
#endif

static WebMutualManager *s_webMutualManager = nil;

@interface WebMutualManager ()

@property (nonatomic, strong) NSDictionary *dicActiveActions;
@property (nonatomic, strong) NSMutableDictionary *dicForRequest;

@end

@implementation WebMutualManager

+ (WebMutualManager *)sharedInstance
{
    if (s_webMutualManager == nil) {
        s_webMutualManager = [[WebMutualManager alloc] init];
    }
    return s_webMutualManager;
}

- (id)init
{
    self = [super init];
    if (self)
    {
        _dicActiveActions = getFileData(FILE_NAME_WEB_MUTUAL);
        _dicForRequest = [[NSMutableDictionary alloc] init];
    }
    return self;
}

- (void)handleThisRequest:(NSURL *)requestURL withDelegate:(id<WebMutualManagerDelegate>)delegate
{
    // 获取请求数据
    WebRequestModel *webRequest = [self getRequestModel:requestURL withWebView:delegate.webView];
    if (webRequest == nil) {
        LogError(@"Cann't get request data with request : %@", requestURL);
        return;
    }
    // 解析数据
    @try {
        
        if (delegate && [delegate respondsToSelector:@selector(canHandleThisRequest:)]) {
            if ([delegate canHandleThisRequest:webRequest]) {
                return;
            }
        }
        
        if (webRequest.callbackId.length > 0) {
            NSMutableDictionary *aDic = [[NSMutableDictionary alloc] init];
            [aDic setObject:webRequest forKey:@"webRequest"];
            [aDic setObject:delegate forKey:@"delegate"];
            [_dicForRequest setObject:aDic forKey:webRequest.callbackId];
        }
        LogInfo(@"Web Request Mode : %d ; Action : %@", webRequest.mode, webRequest.action);
        NSDictionary *dicModel = [_dicActiveActions objectForKey:[NSString stringWithFormat:@"%d", webRequest.mode]];
        NSDictionary *dicHandler = [dicModel objectForKey:webRequest.action];
        if (webRequest.mode <= kWebSendData && dicHandler == nil) {
            // 如果是打开新的网页，这直接处理
            if (webRequest.mode == kWebOpenView && [webRequest.action isEqualToString:@"OpenWebView"]) {
                //
                dicHandler = @{@"displayVC":@"MJWebViewController"};
            } else {
                // 平台未接收该接口
                LogError(@"平台未接收该接口 : %@ ", webRequest.action);
                [self operationFailedWith:webRequest.callbackId message:@"Request Not Accept"];
                return;
            }
        }
        
        switch (webRequest.mode)
        {
            case kWebOpenView:
            {
                // 打开一个界面
                NSString *strDisplayVC = [dicHandler objectForKey:@"displayVC"];
                if ([webRequest.action isEqualToString:@"BackToView"]) {
                    // 返回上一级界面
                    NSDictionary *aDic = [webRequest.jsonData objectFromJSONString];
                    NSNumber *needRefresh = aDic[@"needRefresh"];
                    NSNumber *refreshData = aDic[@"refreshData"];
                    UIViewController *webVC = (UIViewController *)delegate;
                    UIViewController *secondVC = nil;
                    NSArray *arrVCs = webVC.navigationController.viewControllers;
                    if (arrVCs.count > 1) {
                        secondVC = arrVCs[arrVCs.count-2];
                        [webVC.navigationController popViewControllerAnimated:YES];
                    } else {
                        // 最上层只有当前WebViewController
                        secondVC = [arrVCs.lastObject presentingViewController];
                        if (secondVC == nil) {
                            [self operationFailedWith:webRequest.callbackId message:@"Back Error"];
                            return;
                        }
                        if (secondVC) {
                            [webVC dismissViewControllerAnimated:YES completion:nil];
                        }
                    }

                    if (needRefresh && [needRefresh boolValue]) {
                        // 需要刷新返回后的界面
                        while ([secondVC respondsToSelector:@selector(topViewController)]) {
                            UINavigationController *navVC = (UINavigationController *)secondVC;
                            secondVC = navVC.topViewController;
                        }
                        [secondVC refreshWithData:refreshData];
                    }
                    [self operationSucceedWith:webRequest.callbackId];
                    return;
                }

                UIViewController *aVC = [THEControllerManager getViewControllerWithName:strDisplayVC];
                id attachData = [dicHandler objectForKey:@"attachData"];
                NSDictionary *aDic = nil;
                if (webRequest.jsonData.length > 0) {
                    aDic = [webRequest.jsonData objectFromJSONString];
                }
                if (attachData) {
                    [aVC configWithData:aDic andAttach:attachData];
                } else if (aDic) {
                    [aVC configWithData:aDic];
                }
                
                // 打开方式
                NSString *displayMode = [dicHandler objectForKey:@"displayMode"];
                if (displayMode && [displayMode isEqualToString:@"Present"]) {
                    // 使用present的方式
                    NSNumber *withoutNav = [dicHandler objectForKey:@"withoutNav"];
                    if (withoutNav && [withoutNav boolValue]) {
                        [[THEControllerManager topViewController] presentViewController:aVC animated:YES completion:nil];
                    } else {
                        THENavigationController *aNavVC = [[THENavigationController alloc] initWithRootViewController:aVC];
                        [[THEControllerManager topViewController] presentViewController:aNavVC animated:YES completion:nil];
                    }
                } else {
                    [[[THEControllerManager topViewController] navigationController] pushViewController:aVC animated:YES];
                }
                
                if ([aVC respondsToSelector:@selector(setCompleteBlock:)]) {
                    // 如果该VC能处理回调，将回调移交给他
                    UIViewController<ActionCompleteDelegate> *actionVC = (UIViewController<ActionCompleteDelegate> *)aVC;
                    [actionVC setCompleteBlock:^(BOOL isSucceed, NSString *message, id data) {
                        WebResultModel *webResult = [[WebResultModel alloc] init];
                        webResult.isSuccess = isSucceed;
                        webResult.callbackId = webRequest.callbackId;
                        webResult.message = message;
                        webResult.data = [data convertToJsonString];
                        [self callbackWithResult:webResult isFinish:YES];
                    }];
                    return;
                }
                [self operationSucceedWith:webRequest.callbackId];
                break;
            }
            case kWebFetchData:
            {
                // 从平台层获取数据
                NSString *handlerClass = [dicHandler objectForKey:@"handlerClass"];
                Class theClass = NSClassFromString(handlerClass);
                NSObject *theHanlder = [theClass sharedInstance];
                NSString *strAction = [dicHandler objectForKey:@"action"];
                id dataReceive = [self dataByExecute:strAction target:theHanlder data:webRequest.jsonData];
                NSString *returnString = @"";
                if (dataReceive != nil) {
                    // 获取到数据，可立即返回
                    if ([dataReceive isKindOfClass:[NSString class]]) {
                        returnString = (NSString *)dataReceive;
                    } else if ([[dataReceive class] isSubclassOfClass:[DBModel class]]) {
                        returnString = [dataReceive toJSONString];
                    } else if ([dataReceive isKindOfClass:[NSDictionary class]]) {
                        returnString = [dataReceive convertToJsonString];
                    }
                    WebResultModel *webResult = [[WebResultModel alloc] init];
                    webResult.isSuccess = YES;
                    webResult.callbackId = webRequest.callbackId;
                    webResult.message = @"Get Data Successed";
                    webResult.data = returnString;
                    [self callbackWithResult:webResult isFinish:YES];
                } else {
                    // 未获取到数据
                    [self operationFailedWith:webRequest.callbackId message:@"Get Data Failed"];
                }
                break;
            }
            case kWebSendData:
            {
                // 从平台层获取数据
                id dataReceive = nil;
                if ([webRequest.action isEqualToString:@"SendLog"]) {
                    [self printLog:webRequest.jsonData];
                    dataReceive = [NSNumber numberWithBool:YES];
                    if (webRequest.callbackId.length > 0) {
                        [_dicForRequest removeObjectForKey:webRequest.callbackId];
                    }
                    return;
                } else {
                    NSString *handlerClass = [dicHandler objectForKey:@"handlerClass"];
                    Class theClass = NSClassFromString(handlerClass);
                    NSObject *theHanlder = [theClass sharedInstance];
                    NSString *strAction = [dicHandler objectForKey:@"action"];
                    dataReceive = [self dataByExecute:strAction target:theHanlder data:webRequest.jsonData];
                }
                if ([dataReceive intValue] == YES) {
                    [self operationSucceedWith:webRequest.callbackId];
                } else {
                    // 保存失败
                    [self operationFailedWith:webRequest.callbackId message:@"Save Data Failed"];
                }
                break;
            }
            default:
                LogError(@"平台未接收该模式 : %d ", webRequest.mode);
                [self operationFailedWith:webRequest.callbackId message:@"Request Not Accept"];
                break;
        } ;
        
    }
    @catch (NSException *exception)
    {
        LogDebug(@"%@", exception);
        return;
    }
    @finally
    {
        
    }
}

- (WebRequestModel *)getRequestModel:(NSURL *)requestURL withWebView:(UIWebView *)webView
{
    WebRequestModel *webRequest = nil;
    
    NSString *requestId = requestURL.resourceSpecifier;
    NSRange range = [requestId rangeOfString:@"?"];
    if (range.length == 0) {
        NSString *js = [NSString stringWithFormat:@"webMutual.getRequestData(\'%@\')", requestId];
        NSString* requestData = [webView stringByEvaluatingJavaScriptFromString:js];
        webRequest = [[WebRequestModel alloc] initWithString:requestData error:nil];
    } else {
        NSString *modelStr = [requestId substringToIndex:range.location];
        WebActionHandleMode mode = [self actionModeFromString:modelStr];
        if (mode < 0) {
            return nil;
        }
        webRequest = [[WebRequestModel alloc] init];
        webRequest.mode = mode;
        webRequest.action =  [requestURL getUrlParameter:@"action"];
        webRequest.jsonData =  [[requestURL getUrlParameter:@"jsonData"] stringByRemovingPercentEncoding];
    }
    
    return webRequest;
}

- (WebActionHandleMode)actionModeFromString:(NSString *)str
{
    if ([str isEqualToString:@"OpenView"]) {
        return kWebOpenView;
    } else if ([str isEqualToString:@"OpenView"]) {
        return kWebOpenView;
    } else if ([str isEqualToString:@"FetchData"]) {
        return kWebFetchData;
    } else if ([str isEqualToString:@"SendData"]) {
        return kWebSendData;
    } else if ([str isEqualToString:@"RegistAction"]) {
        return kWebRegistAction;
    }
    return kWebUnknown;
}

- (NSDictionary *)webGetOSInfo
{
    NSMutableDictionary *aDic = [[NSMutableDictionary alloc] init];
    [aDic setObject:[[UIDevice currentDevice] systemName] forKey:@"OSName"];
    [aDic setObject:[[UIDevice currentDevice] systemVersion] forKey:@"OSVersion"];
//    [aDic setObject:[DeviceHelper getDeviceID] forKey:@"imei"];
    return aDic;
}

- (NSNumber *)showAlert:(NSString *)message
{
    NSDictionary *aDic = [message objectFromJSONString];
    NSString *title = @"Prompt";
    if (aDic) {
        NSString *aMessage = aDic[@"message"];
        if ([aMessage isKindOfClass:[NSNumber class]]) {
            aMessage = [(NSNumber *)aMessage stringValue];
        }
        if (aMessage.length > 0) {
            message = aMessage;
        }
        NSString *aTitle = aDic[@"title"];
        if (aTitle.length > 0) {
            title = aTitle;
        }
    }
    UIAlertView *alertView = [[UIAlertView alloc] initWithTitle:title
                                                        message:message
                                                       delegate:nil
                                              cancelButtonTitle:@"OK"
                                              otherButtonTitles:nil];
    [alertView show];
    return @YES;
}

- (NSNumber *)showToast:(NSString *)message
{
    [THEControllerManager toast:message];
    return @YES;
}

- (NSNumber *)startLoading:(NSString *)message
{
    [THEControllerManager startLoading:message];
    return @YES;
}

- (NSNumber *)stopLoading
{
    [THEControllerManager stopLoading];
    return @YES;
}

- (NSNumber *)copyText:(NSString *)message
{
    UIPasteboard *pasteboard = [UIPasteboard generalPasteboard];
    [pasteboard setPersistent:YES];
    pasteboard.string = message;
    return @YES;
}

- (NSNumber *)printLog:(NSString *)logInfo
{
    NSDictionary *aDic = [logInfo objectFromJSONString];
    int logType = [aDic[@"logType"] intValue];
    NSString *message = aDic[@"message"];
    if (message.length == 0) {
        return @NO;
    }
    BOOL printSuccess = YES;
    // 0-Debug；1-Info；2-Trace；3-Warn；4-Error
    switch (logType) {
        case 0:
            LogDebug(@"%@", message);
            break;
        case 1:
            LogInfo(@"%@", message);
            break;
        case 2:
            LogTrace(@"%@", message);
            break;
        case 3:
            LogError(@"%@", message);
            break;
        case 4:
            LogError(@"%@", message);
            break;
        default:
            printSuccess = NO;
            break;
    }
    
    return [NSNumber numberWithBool:printSuccess];
}

#pragma mark - Private

- (id)dataByExecute:(NSString *)strAction target:(id)theHanlder data:(NSString *)jsonData
{
    id dataReceive = nil;
    if (strAction.length > 0) {
        SEL selector = NSSelectorFromString(strAction);
        if ([theHanlder respondsToSelector:selector]) {
            if ([strAction hasSuffix:@":"]) {
                IMP imp = [theHanlder methodForSelector:selector];
                id (*func)(id, SEL, id) = (void *)imp;
                dataReceive = func(theHanlder, selector, jsonData);
            } else {
                IMP imp = [theHanlder methodForSelector:selector];
                id (*func)(id, SEL) = (void *)imp;
                dataReceive = func(theHanlder, selector);
            }
        }
    }
    return dataReceive;
}

#pragma mark - Platform Callback

- (void)operationSucceedWith:(NSString *)callbackId
{
    if (callbackId.length == 0) {
        return;
    }
    WebResultModel *webResult = [[WebResultModel alloc] init];
    webResult.isSuccess = YES;
    webResult.callbackId = callbackId;
    webResult.message = @"操作成功";
    webResult.data = @"";
    [self callbackWithResult:webResult isFinish:YES];
}

- (void)operationFailedWith:(NSString *)callbackId message:(NSString *)message
{
    if (callbackId.length == 0) {
        return;
    }
    WebResultModel *webResult = [[WebResultModel alloc] init];
    webResult.isSuccess = NO;
    webResult.callbackId = callbackId;
    webResult.message = message;
    webResult.data = @"";
    [self callbackWithResult:webResult isFinish:YES];
}


- (void)callbackWithResult:(WebResultModel *)result isFinish:(BOOL)isFinish
{
    NSDictionary *aDic = [_dicForRequest objectForKey:result.callbackId];
    if (aDic == nil) {
        return;
    }
    BOOL callResult = [self callbackWithResult:result andDelegate:[aDic objectForKey:@"delegate"]];
    if (!callResult || isFinish) {
        [_dicForRequest removeObjectForKey:result.callbackId];
    }
}

- (BOOL)callbackWithResult:(WebResultModel *)result andDelegate:(id<WebMutualManagerDelegate>)delegate
{
    NSString *resultStr = [result toJSONString];
    resultStr = [resultStr stringByReplacingOccurrencesOfString:@"\"" withString:@"\\\""];
    NSString *js = [NSString stringWithFormat:@"webMutual.platformCallback(\'%@\')", resultStr];
    if (delegate && [delegate respondsToSelector:@selector(webView)]) {
        UIWebView *aWebView = [delegate webView];
        if (aWebView) {
            [aWebView stringByEvaluatingJavaScriptFromString:js];
            return YES;
        } else {
            LogError(@"Can not call webView when WebViewController is dealloc");
        }
    }
    return NO;
}


@end
