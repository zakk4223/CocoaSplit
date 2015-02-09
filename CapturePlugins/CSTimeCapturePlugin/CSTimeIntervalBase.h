//
//  CSTimeIntervalBase.h
//  CSTimeCapturePlugin
//
//  Created by Zakk on 2/7/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSTextCaptureBase.h"
#import "NSTimeIntervalFormatter.h"


@interface CSTimeIntervalBase : CSTextCaptureBase
@property (strong) NSTimeIntervalFormatter *formatter;
@property (strong) NSDate *startDate;
@property (strong) NSDate *endDate;
@property (strong) NSString *format;
@property (strong) NSDictionary *styleTypeMap;

@end
