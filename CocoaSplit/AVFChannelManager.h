//
//  AVFChannelManager.h
//  CocoaSplit
//
//  Created by Zakk on 4/6/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AVFoundation/AVFoundation.h>
#import "AVFAudioChannel.h"


@interface AVFChannelManager : NSObject



/* 
 The preview output connection is the 'master' since it always exists.
 The strategy here is to have the mixer controls bind to an instance of this class
 and then duplicate changes to those values to both the preview and data output channels.
 An instance of this class is created every time the input device changes.
 The assumption is that the entire AVCaptureSession (for audio) only has one audio input, that is connected
 to both the preview and the dataOutput
*/


@property (strong) AVCaptureOutput *previewOutput;
@property (strong) AVCaptureOutput *dataOutput;
@property (strong) NSMutableArray *channels;


-(id)initWithPreviewOutput:(AVCaptureOutput *)previewOutput;




@end
