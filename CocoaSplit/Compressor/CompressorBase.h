//
//  CompressorBase.h
//  CocoaSplit
//
//  Created by Zakk on 7/4/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoCompressor.h"
#import "CSCompressorViewControllerProtocol.h"


@class captureController;

@interface CompressorBase : NSObject <VideoCompressor, NSCoding>
{
    NSMutableArray *_audioBuffer;
    bool _reset_flag;
    dispatch_queue_t _consumerThread;
    NSMutableArray *_compressQueue;
    dispatch_semaphore_t _queueSemaphore;
}





@property (strong) NSMutableDictionary *outputs;

@property (assign) int width;
@property (assign) int height;
@property (assign) int working_width;
@property (assign) int working_height;

@property (strong) NSString *resolutionOption;

@property (strong) NSArray *arOptions;

@property (assign) bool isNew;
@property (strong) NSString *compressorType;
@property (strong) NSMutableString *name;
@property (assign) bool errored;
@property (assign) bool active;
@property (assign) float frameRate;




-(int) drainOutputBufferFrame;
-(void) reset;
-(void)reconfigureCompressor;
-(bool)needsSetup;
-(BOOL) setupResolution:(CVImageBufferRef)withFrame;
-(id <CSCompressorViewControllerProtocol>)getConfigurationView;




@end
