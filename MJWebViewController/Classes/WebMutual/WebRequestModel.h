//
//  WebRequestModel.h
//  Common
//
//  Created by 黄磊 on 16/4/6.
//  Copyright © 2016年 Musjoy. All rights reserved.
//  网页发给平台层的请求

#import "DBModel.h"

@interface WebRequestModel : DBModel

@property (nonatomic, assign) int mode;
@property (nonatomic, strong) NSString *action;
@property (nonatomic, strong) NSString *jsonData;
@property (nonatomic, strong) NSString *callbackId;

@end
