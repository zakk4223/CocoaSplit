//
//  CSPluginServices.h
//  CocoaSplit
//
//  Created by Zakk on 11/22/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSPcmPlayer.h"

@interface CSPluginServices : NSObject



+(CSPluginServices *)sharedPluginServices;
-(CSPcmPlayer *)createPCMInput:(NSString *)forUID withFormat:(const AudioStreamBasicDescription *)withFormat;
-(void)removePCMInput:(CSPcmPlayer *)toRemove;
-(void)loadPythonClass:(NSString *)pyClass fromFile:(NSString *)fromFile withBlock:(void(^)(Class))withBlock;
-(Class)loadPythonClass:(NSString *)pyClass fromFile:(NSString *)fromFile;

@property (readonly) double currentFPS;
@property (readonly) int audioSampleRate;


@end
