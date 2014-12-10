//
//  CSSyphonCaptureFactory.h
//  CSSyphonCapturePlugin
//
//  Created by Zakk on 12/7/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSPluginFactoryProtocol.h"


@interface CSSyphonCaptureFactory : NSObject <CSPluginFactoryProtocol>


+(NSArray *)captureSourceClasses;
+(NSArray *)streamServiceClasses;
+(NSArray *)extraPluginClasses;

@end
