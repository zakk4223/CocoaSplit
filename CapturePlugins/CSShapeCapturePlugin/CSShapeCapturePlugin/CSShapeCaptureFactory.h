//
//  CSShapeCaptureFactory.h
//  CSShapeCapturePlugin
//
//  Created by Zakk on 7/24/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSPluginFactoryProtocol.h"
#import "CSShapeCapture.h"

@interface CSShapeCaptureFactory : NSObject <CSPluginFactoryProtocol>

+(NSArray *)captureSourceClasses;
+(NSArray *)streamServiceClasses;
+(NSArray *)extraPluginClasses;
+(CSShapePathLoader *) sharedPathLoader;




@end
