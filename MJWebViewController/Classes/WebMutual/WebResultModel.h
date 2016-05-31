//
//  WebResultModel.h
//  Common
//
//  Created by 黄磊 on 16/4/6.
//  Copyright © 2016年 Musjoy. All rights reserved.
//

#import "DBModel.h"

@interface WebResultModel : DBModel

@property (nonatomic, assign) BOOL isSuccess;               // 返回该次操作的状态
@property (nonatomic, strong) NSString *callbackId;         // 回调id, 与网页交互所必须的
@property (nonatomic, strong) NSString *message;            // 改次操作返回结果的描述
@property (nonatomic, strong) NSString *data;               // 需要返回数据的json字符串

@end
