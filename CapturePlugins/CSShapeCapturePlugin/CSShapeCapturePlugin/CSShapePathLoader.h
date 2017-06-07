//
//  CSShapePathLoader.h
//  CSShapeCapturePlugin
//
//  Created by Zakk on 7/25/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#ifndef CSShapeCapturePlugin_CSShapePathLoader_h
#define CSShapeCapturePlugin_CSShapePathLoader_h
#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>






@interface CSShapePathLoader : NSObject


-(NSDictionary *)allPaths;
-(NSString *)pathLoaderPath:(NSString *)name;
-(void)evaluateJavascriptAtPath:(NSString *)path usingContext:(JSContext *)context;



@end



#endif
