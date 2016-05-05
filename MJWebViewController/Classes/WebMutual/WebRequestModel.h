//
//  WebRequestModel.h
//  Common
//
//  Created by 黄磊 on 16/4/6.
//  Copyright © 2016年 Musjoy. All rights reserved.
//  网页发给平台层的请求

#import "DBModel.h"

@interface WebRequestModel : DBModel

@property (nonatomic, assign) int model;
@property (nonatomic, strong) NSString *handler;
@property (nonatomic, strong) NSString *callbackId;
@property (nonatomic, strong) NSString *jsonData;

@end
