//
//  CSFileStreamServiceFactory.h
//  CSFileStreamServicePlugin
//
//  Created by Zakk on 7/16/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSPluginFactoryProtocol.h"
#import "FileStreamService.h"
#import "CSFileStreamRTMPService.h"


@interface CSFileStreamServiceFactory : NSObject <CSPluginFactoryProtocol>
+(NSArray *)captureSourceClasses;
+(NSArray *)streamServiceClasses;
+(NSArray *)extraPluginClasses;

@end
