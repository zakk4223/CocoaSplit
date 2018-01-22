//
//  CapturedFrameData.h
//  CocoaSplit
//
//  Created by Zakk on 12/3/13.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>


@interface CapturedFrameData : NSObject <NSCopying>



@property long long frameNumber;
@property (assign) double frameTime;

@property CVImageBufferRef videoFrame;
@property (assign) void *encoderData;
@property (assign) BOOL isKeyFrame;


//Array of CMSampleBuffers from audio capture.
@property (retain) NSMutableArray *audioSamples;
@property (strong) NSMutableArray *pcmAudioSamples;


@property CMTime videoPTS;
@property CMTime videoDuration;
@property (assign) CMSampleBufferRef encodedSampleBuffer;

-(NSInteger) encodedDataLength;

@end
