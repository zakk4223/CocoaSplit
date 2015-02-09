//
//  CSCurrentTimeCapture.h
//  CSTimeCapturePlugin
//
//  Created by Zakk on 2/6/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSTextCaptureBase.h"

@interface CSCurrentTimeCapture : CSTextCaptureBase

@property (strong) NSDateFormatter *formatter;
@property (strong) NSString *format;
@property (assign) NSDateFormatterStyle timeStyle;
@property (assign) NSDateFormatterStyle dateStyle;
@property (strong) NSDictionary *styleTypeMap;


@end
