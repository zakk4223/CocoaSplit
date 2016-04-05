//
//  CSTimedOutputBuffer.h
//  CocoaSplit
//
//  Created by Zakk on 4/2/16.
//  Copyright © 2016 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "VideoCompressor.h"
#import "FFMpegTask.h"


@interface CSTimedOutputBuffer : NSObject
{
    NSMutableArray *_frameBuffer;
    FFMpegTask *_outFFMpeg;
    float _currentBufferDuration;
}


-(void) writeCurrentBuffer:(NSString *)toFile;

@property (strong) NSObject <VideoCompressor> *compressor;
@property (assign) float bufferDuration;
@property (strong) NSString *name;

@end
