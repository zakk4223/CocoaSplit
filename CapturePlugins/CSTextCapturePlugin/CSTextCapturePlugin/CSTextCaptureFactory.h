//
//  CSTextCaptureFactory.h
//  CSTextCapturePlugin
//
//  Created by Zakk on 12/31/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSPluginFactoryProtocol.h"


@interface CSTextCaptureFactory : NSObject <CSPluginFactoryProtocol>


+(NSArray *)captureSourceClasses;
+(NSArray *)streamServiceClasses;
+(NSArray *)extraPluginClasses;

@end
