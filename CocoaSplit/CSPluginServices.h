//
//  CSPluginServices.h
//  CocoaSplit
//
//  Created by Zakk on 11/22/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CAMultiAudioPCMPlayer.h"

@interface CSPluginServices : NSObject



+(id)sharedPluginServices;
-(CAMultiAudioPCMPlayer *)createPCMInput:(NSString *)forUID withFormat:(const AudioStreamBasicDescription *)withFormat;

@end
