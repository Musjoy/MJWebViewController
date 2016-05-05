//
//  WebExecuteModel.h
//  Common
//
//  Created by 黄磊 on 16/4/6.
//  Copyright © 2016年 Musjoy. All rights reserved.
//  平台层向网页层发送执行命令的model

#import "DBModel.h"

@interface WebExecuteModel : DBModel

@property (nonatomic, strong) NSString *method;             // 执行的方法
@property (nonatomic, strong) NSDictionary *data;           // 执行的数据


@end
