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



+(id)sharedPluginServices;
-(CSPcmPlayer *)createPCMInput:(NSString *)forUID withFormat:(const AudioStreamBasicDescription *)withFormat;
-(void)removePCMInput:(CSPcmPlayer *)toRemove;

@end
