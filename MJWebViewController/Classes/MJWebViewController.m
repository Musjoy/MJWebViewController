//
//  MJWebViewController.m
//  Common
//
//  Created by 黄磊 on 16/4/6.
//  Copyright © 2016年 Musjoy. All rights reserved.
//

#define WEB_REQUEST_TIMEOUT 30

#import "MJWebViewController.h"
#import HEADER_NAVIGATION_CONTROLLER
#import HEADER_SERVER_URL
#import HEADER_JSON_GENERATE
#import HEADER_LOCALIZE
#ifdef  MODULE_URL_MANAGER
#import "URLManager.h"
#endif
#ifdef MODULE_USER_MANAGER
#import "UserManager.h"
#endif
#ifdef MODULE_WEB_SERVICE
#import <MJWebService/MJWebService.h>
#endif

static NSString *s_webMutualConfig = nil;

@interface MJWebViewController ()

@property (nonatomic, strong) NSMutableString *executeStr;
@property (nonatomic, assign) BOOL isWebLoaded;
@property (nonatomic, strong) UIButton *btnBack;

@property (nonatomic, strong) NSString *webMutualConfig;

@property (nonatomic, assign) BOOL needCheckSecurity;               ///< 是否需要检查安全性

@end

@implementation MJWebViewController
@synthesize webUrl =_webUrl;
@synthesize navTitle =_navTitle;

+ (NSString *)webMutualConfig
{
    if (s_webMutualConfig == nil) {
        NSMutableDictionary *dic = [[NSMutableDictionary alloc] init];
        [dic setObject:@"iOS" forKey:@"platform"];
#ifdef kServerBaseHost
        [dic setObject:kServerBaseHost forKey:@"baseHost"];
#endif
#ifdef kServerUrl
        [dic setObject:kServerUrl forKey:@"serverUrl"];
#endif
#ifdef kServerAction
        [dic setObject:kServerAction forKey:@"serverAction"];
#endif
        s_webMutualConfig = jsonStringFromDic(dic);
    }
    return s_webMutualConfig;
}

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
        self.autoLoadUrl = YES;
    }
    return self;
}

- (id)init
{
    self = [super init];
    if (self) {
        self.autoLoadUrl = YES;
    }
    return self;
}

- (WKWebView *)webView
{
    if (_isDealloc) {
        return nil;
    }
    return _webView;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    // Do any additional setup after loading the view from its nib.
    
    if (self.navTitle.length > 0) {
        self.navigationItem.title = self.navTitle;
    }
    
    [self.navController showBackButtonWith:self andAction:@selector(back)];
    
    _isDealloc = NO;
    _isWebLoaded = NO;
    _executeStr = [[NSMutableString alloc] init];
    
    if (_webView == nil) {
        self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds];
        [self.webView setAutoresizingMask:UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth];
        [self.webView setBackgroundColor:[UIColor clearColor]];
        [self.webView setNavigationDelegate:self];
        [self.view addSubview:self.webView];
        [self.view sendSubviewToBack:self.webView];
    } else {
        [self.webView setNavigationDelegate:self];
    }
    
    UIScrollView *aScrollView = (UIScrollView *)[[_webView subviews] objectAtIndex:0];
    [aScrollView setBounces:NO];
    [aScrollView setBackgroundColor:[UIColor clearColor]];
    NSArray *subViews = aScrollView.subviews;
    if (aScrollView.subviews.count > 0) {
        UIView *contentView = [subViews objectAtIndex:0];
        [contentView setBackgroundColor:[UIColor clearColor]];
    }
    
//    if (_hideNav) {
        _btnBack = [[UIButton alloc] initWithFrame:CGRectMake(20, 20, 38, 38)];
        [_btnBack setImage:[UIImage imageNamed:@"btn_back"] forState:UIControlStateNormal];
        [_btnBack addTarget:self action:@selector(back) forControlEvents:UIControlEventTouchUpInside];
        _btnBack.hidden = YES;
        [self.view addSubview:_btnBack];
//    }
    
    if (!self.autoLoadUrl) {
        // 子类负责处理url
        return;
    }
    // 加载网页文件

    LogTrace(@"%@", _webUrl);
    
    [self loadUrl:_webUrl withParameters:[[NSDictionary alloc] init]];
}

- (void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    if (_hideNav) {
        _btnBack.hidden = NO;
        [self.navigationController setNavigationBarHidden:YES animated:YES];
    } else {
        _btnBack.hidden = NO;
        [self.navigationController setNavigationBarHidden:NO animated:YES];
    }
}

- (void)viewWillDisappear:(BOOL)animated
{
    [super viewWillDisappear:animated];
//    [self.navigationController setNavigationBarHidden:NO animated:YES];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


#pragma makr - Public

- (void)configWithData:(id)data
{
    NSDictionary *aDic = nil;
    if ([data isKindOfClass:[NSDictionary class]]) {
        aDic = data;
    } else if ([data isKindOfClass:[NSString class]]) {
        aDic = [data objectFromJSONString];
    }
    if (aDic) {
        NSString *aUrl = [aDic objectForKey:@"url"];
        if (aUrl) {
            self.webUrl = aUrl;
        }
        NSString *aTitle = [aDic objectForKey:@"title"];
        NSString *aTitleKey = [aDic objectForKey:@"titleKey"];
        if (aTitleKey.length > 0) {
            NSString *aTitleTmp = locString(aTitleKey);
            if (![aTitleTmp isEqualToString:aTitleKey]) {
                aTitle = aTitleTmp;
            }
        }
        if (aTitle) {
            self.navigationItem.title = aTitle;
        }
        NSNumber *hideNav = [aDic objectForKey:@"hideNav"];
        if (hideNav && [hideNav boolValue]) {
            _hideNav = [hideNav boolValue];
        }
    }
}

- (void)refreshWithData:(id)data
{
    [self configWithData:data];
    [self refreshWithUrl:self.webUrl];
}

- (BOOL)canSlipOut:(UIGestureRecognizer *)gestureRecognizer
{
    return !_hideNav;
}

#pragma mark - Action

- (void)back
{
    LogTrace(@" {Button Click} ");
    if (_hideNav && _isWebLoaded) {
        [self.webView evaluateJavaScript:@"webMutual.platformCall('IsWebHandleBack')" completionHandler:^(id result, NSError * _Nullable error) {
            if ([result boolValue]) {
                return;
            } else {
                if ([self.navController back]) {
                    _isDealloc = YES;
                }
            }
        }];
        return;
    } else {
        if ([_webView canGoBack]) {
            [_webView goBack];
            return;
        }
    }
    
    if ([self.navController back]) {
        _isDealloc = YES;
    }
}


#pragma mark - Private

- (NSString *)assembleUrl:(NSString *)url parameters:(NSDictionary *)parameters
{
    NSMutableString *requestUrl = [NSMutableString stringWithString:url];
    NSMutableString *parameterStr = [NSMutableString stringWithString:@""];
    NSArray *allkeys = [parameters allKeys];
#ifdef MODULE_USER_MANAGER
    UserManager *theUser = [UserManager sharedInstance];
    NSNumber *userId = [theUser getUserId];
    if (userId) {
        if (![parameters objectForKey:@"userId"]) {
            [parameterStr appendFormat:@"%@=%@&", @"userId", userId];
        }
    }
#endif
#if defined(FUNCTION_WEB_NEED_BASE_HOST) && defined(kServerBaseHost)
    [parameterStr appendFormat:@"%@=%@&", @"baseHost", kServerBaseHost];
#endif
    for (NSString *aKey in allkeys) {
        [parameterStr appendFormat:@"%@=%@&", aKey, [parameters objectForKey:aKey]];
    }
    if (parameterStr.length > 0) {
        [parameterStr deleteCharactersInRange:NSMakeRange(parameterStr.length - 1, 1)];
        if ([requestUrl rangeOfString:@"?"].length == 0) {
            [requestUrl appendString:@"\?"];
        } else {
            if (![requestUrl hasSuffix:@"&"]) {
                [requestUrl appendString:@"&"];
            }
        }
        [requestUrl appendString:parameterStr];
    }
    return requestUrl;
}

- (void)loadUrl:(NSString *)url withParameters:(NSDictionary *)parameters
{
    if (url.length == 0) {
        LogError(@"Cannot Load an empty url");
        return;
    }
    if ([url hasPrefix:@"http"]) {
        [self refreshWithUrl:[self assembleUrl:url parameters:parameters]];
    } else {
        // 本地网页
        NSString *filePath = url;
        if (![filePath hasPrefix:@"file"]) {
            filePath = [[[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"Web"] stringByAppendingPathComponent:url];
        }
#ifdef kServerUrl
        if (![[NSFileManager defaultManager] fileExistsAtPath:filePath]) {
            // 本地不存在，默认为服务器路径，这里可能会有些问题
            // 防止服务器路径泄露
            _needCheckSecurity = YES;
            NSString *remoteUrl = [kServerUrl stringByAppendingString:url];
            [self refreshWithUrl:[self assembleUrl:remoteUrl parameters:parameters]];
            return;
        }
#endif
        NSString *content = [NSString stringWithContentsOfFile:filePath encoding:NSUTF8StringEncoding error:nil];
        NSString *aUrl = [self assembleUrl:filePath parameters:parameters];
        NSURL *theUrl = [NSURL fileURLWithPath:aUrl];
        LogTrace(@"Load Url : {%@}", theUrl);
        [self startInnerLoading:sLoading];
        [_webView loadHTMLString:content baseURL:theUrl];
    }
    
}

- (void)refreshWithUrl:(NSString *)url
{
    _isWebLoaded = NO;
    _executeStr = [[NSMutableString alloc] init];
    NSURLRequestCachePolicy cachePolicy = NSURLRequestReloadIgnoringLocalCacheData;
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] initWithURL:[NSURL URLWithString:url] cachePolicy:cachePolicy timeoutInterval:WEB_REQUEST_TIMEOUT];
    [self refreshWithRequest:request];
}

- (void)refreshWithRequest:(NSMutableURLRequest *)request
{
    
    _isWebLoaded = NO;
    _executeStr = [[NSMutableString alloc] init];
    LogTrace(@"Load Url : {%@}", request);
    
    // 暂时注视掉缓存，等待添加清楚缓存功能后再加上
//    [request setValue:@"needCache" forHTTPHeaderField:@"X-Cache"];
    [self startInnerLoading:sLoading];
#if defined(MODULE_WEB_SERVICE) && defined(FUN_NEED_SECURITY_REQUEST)
    if (_needCheckSecurity) {
        [MJWebService checkRequestSecurity:[request.URL absoluteString] completion:^(MJRequestSecurityState requestSecurityState, NSError *err) {
            if (requestSecurityState != MJRequestSecurityStateUnknown) {
                // 该请求安全性已确认，可以直接回调
                if (requestSecurityState == MJRequestSecurityStateUnsafe) {
                    [self failedWithError:err];
                } else {
                    [self->_webView loadRequest:request];
                }
                return;
            }
            // 这里的unknown, 也是直接失败
            [self failedWithError:err];
        }];
        return;
    }
#elif defined(MODULE_WEB_SERVICE) && defined(FUN_NEED_IP_AUTO_CHOOSE)
    [MJWebService autoChooseIpWith:[request.URL absoluteString] completion:^(NSString *useIp, NSError *err) {
        if (useIp.length == 0) {
            [self webView:self->_webView didFailLoadWithError:err];
            return;
        }
        [self updateReqeust:request withIp:useIp];
        [self->_webView loadRequest:request];
    }];
#endif
    
    [_webView loadRequest:request];
}

- (void)executeThisJS:(NSString *)jsSentence
{
    if (_isWebLoaded == NO) {
        [_executeStr appendString:@";"];
        [_executeStr appendString:jsSentence];
        return;
    }
    [self.webView evaluateJavaScript:jsSentence completionHandler:NULL];
//    [self.webView stringByEvaluatingJavaScriptFromString:jsSentence];
}

- (void)executeThisModel:(WebExecuteModel *)executeModel
{
    NSString *str = [executeModel toJSONString];
    NSMutableString *jsStr = [NSMutableString stringWithString:@"webMutual.platformExecute({0})"];
    str = [jsStr stringByReplacingOccurrencesOfString:@"{0}" withString:str];
    [self executeThisJS:str];
}

- (void)updateReqeust:(NSMutableURLRequest *)request withIp:(NSString *)useIp
{
    if (useIp.length == 0) {
        return;
    }
    NSURL *url = request.URL;
    NSString *urlStr = url.absoluteString;
    NSRange range = [urlStr rangeOfString:url.host];
    NSURL *newUrl = [NSURL URLWithString:[urlStr stringByReplacingCharactersInRange:range withString:useIp]];
    [request setURL:newUrl];
    [request.allHTTPHeaderFields setValue:url.host forKey:@"Host"];
}

#pragma mark - Loading

- (NSInteger)startInnerLoading:(NSString *)loadingText
{
#ifdef MODULE_LOADING_VIEW
    return [super startInnerLoading:loadingText];
#else
    return [self startLoading:loadingText];
#endif
}

- (void)stopInnerLoading
{
#ifdef MODULE_LOADING_VIEW
    return [super stopInnerLoading];
#else
    return [self stopLoading];
#endif
}


- (void)failedWithError:(NSError *)error
{
    if (error.code == -1009 || error.code == -1003) {
        
    } else {
        
    }
    [self toast:locString(@"Network Error")];
    [self stopInnerLoading];
    _webView.hidden = YES;
}


#pragma mark - WKNavigationDelegate

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation
{
    _webView.hidden = NO;
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation
{
    if (_isWebLoaded) {
        return;
    }
    _isWebLoaded = YES;
    _needCheckSecurity = NO;
    [self stopInnerLoading];
    // 这里需要主动激活网页交互
    NSString *config = [self.class webMutualConfig];
    NSString *js = [NSString stringWithFormat:@"webMutual.activePlatform(%@)", config];
    [webView evaluateJavaScript:js completionHandler:NULL];
    
    if (_executeStr.length > 0) {
        [self executeThisJS:_executeStr];
        _executeStr = [[NSMutableString alloc] init];
    }
}

-(void)webView:(WKWebView *)webView didFailProvisionalNavigation:(null_unspecified WKNavigation *)navigation withError:(nonnull NSError *)error
{
    [self failedWithError:error];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler
{
    NSURL *url =  navigationAction.request.URL;
    if ([[url scheme] isEqualToString:kWebMutualUrlScheme]) {
        LogInfo(@"%@", [url resourceSpecifier]);
        [[WebMutualManager sharedInstance] handleThisRequest:url withDelegate:self];
        decisionHandler(WKNavigationActionPolicyCancel);
#ifdef MODULE_URL_MANAGER
    } else if ([[url scheme] isEqualToString:kReceiveUrlScheme]) {
        BOOL result = [URLManager openURL:url];
        if (result) {
            decisionHandler(WKNavigationActionPolicyCancel);
        } else {
            decisionHandler(WKNavigationActionPolicyAllow);
        }
#endif
    }
    LogTrace(@"Load URL : %@ ", url);
    decisionHandler(WKNavigationActionPolicyAllow);
}

#pragma mark - WebMutualManagerDelegate

- (BOOL)canHandleThisRequest:(WebRequestModel *)request
{
    return NO;
}

@end
