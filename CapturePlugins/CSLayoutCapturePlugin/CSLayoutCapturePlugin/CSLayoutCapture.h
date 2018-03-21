//
//  CSLayoutCapture.h
//  CSLayoutCapturePlugin
//
//  Created by Zakk on 8/11/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSCaptureBase.h"

@interface LayoutRendererHack : NSObject
-(CVImageBufferRef)currentImg;
@end

@interface SourceLayoutHack : NSObject
@property (assign) int canvas_width;
@property (assign) int canvas_height;
@property (assign) bool isActive;
@property (strong) NSArray *sourceList;

@end

@interface AudioEngineHack : NSObject
-(void)disableAllInputs;

@end

@interface AacEncoderHack : NSObject
-(void)setupEncoderBuffer;
@property (assign) AudioStreamBasicDescription *inputASBD;
@property (assign) int sampleRate;
@property (assign) bool skipCompression;


@end

@interface AudioGraphHack : NSObject
@property (assign) AudioStreamBasicDescription *graphAsbd;
@end

@interface CSLayoutCapture : CSCaptureBase <CSCaptureSourceProtocol>
{
    LayoutRendererHack *_current_renderer;
    NSObject *_originalLayout;
    CSPcmPlayer *_pcmPlayer;
}

@end
