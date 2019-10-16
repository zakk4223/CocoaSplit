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
@property (strong) NSString *uuid;
@property (strong) NSString *name;

@end

@interface OutputDestinationHack : NSObject
@property (weak) SourceLayoutHack *assignedLayout;
@property (strong) NSString *compressor_name;
@property (strong) id ffmpeg_out;
@property (assign) BOOL active;
@property (assign) bool alwaysStart;

@end

@interface CapturedFrameDataHack : NSObject
@property (strong) NSMutableDictionary *pcmAudioSamples;
@property (assign) CMSampleBufferRef encodedSampleBuffer;
@end



@interface CSLayoutCapture : CSCaptureBase <CSCaptureSourceProtocol>
{
    CSPcmPlayer *_pcmPlayer;
    OutputDestinationHack *_out_dest;
    NSSize _last_frame_size;
    SourceLayoutHack *_current_layout;
    CAShapeLayer *_crop_layer;
    NSRect _last_crop_rect;
}

@property (strong) NSString *cropNamePattern;


@end
