//
//  NDIAudioOutputDelegateProtocol.h
//  CSNDICapturePlugin
//
//  Created by Zakk on 1/18/18.
//

#import <Foundation/Foundation.h>
#import "CAMultiAudioPCM.h"

@class CSNDIReceiver;

@protocol NDIAudioOutputDelegateProtocol <NSObject>


-(void)NDIAudioOutput:(CAMultiAudioPCM *)pcmData fromReceiver:(CSNDIReceiver *)fromReceiver;
-(void)NDIAudioOutputFormatChanged:(CSNDIReceiver *)fromReceiver;

@end
