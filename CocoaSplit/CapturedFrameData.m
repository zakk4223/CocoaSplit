//
//  CapturedFrameData.m
//  CocoaSplit
//
//  Created by Zakk on 12/3/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import "CapturedFrameData.h"



@implementation CapturedFrameData


@synthesize videoFrame = _videoFrame;
@synthesize encodedSampleBuffer = _encodedSampleBuffer;
@synthesize avcodec_pkt = _avcodec_pkt;



-(instancetype) copyWithZone:(NSZone *)zone
{
    
    CapturedFrameData *copy = [[[self class] allocWithZone:zone] init];
    copy.frameNumber = self.frameNumber;
    copy.frameTime = self.frameTime;
    copy.videoFrame = self.videoFrame;
    copy.encoderData = self.encoderData;
    copy.isKeyFrame = self.isKeyFrame;
    copy.audioSamples = self.audioSamples;
    copy.videoPTS = self.videoPTS;
    copy.videoDuration = self.videoDuration;
    copy.encodedSampleBuffer = self.encodedSampleBuffer;
    copy.avcodec_pkt = self.avcodec_pkt;
    copy.avcodec_ctx = self.avcodec_ctx;
    return copy;
}


-(id)init
{
    if (self = [super init])
    {
        _videoFrame = nil;
        self.frameNumber = 0;
        //self.audioSamples = [[NSMutableArray alloc] init];
    }
    
    return self;
    
}

-(void)dealloc
{
    
    
    if (_videoFrame)
    {
        
        CVPixelBufferRelease(_videoFrame);
    }
    
    if (_encodedSampleBuffer)
    {
        CFRelease(_encodedSampleBuffer);
    }
    
    if (_avcodec_pkt)
    {
        av_free_packet(_avcodec_pkt);
        av_free(_avcodec_pkt);

    }

    
	self.audioSamples = nil;
}

-(NSInteger) encodedDataLength
{
    NSInteger ret = 0;
    
    if (self.avcodec_pkt)
    {
        ret = self.avcodec_pkt->size;
    } else if (self.encodedSampleBuffer) {
        ret = CMSampleBufferGetTotalSampleSize(self.encodedSampleBuffer);
    }
    
    return ret;
}


-(CMSampleBufferRef)encodedSampleBuffer
{
    return _encodedSampleBuffer;
}


-(void)setEncodedSampleBuffer:(CMSampleBufferRef)encodedSampleBuffer
{
    if (_encodedSampleBuffer)
    {
        CFRelease(_encodedSampleBuffer);
    }
    
    if (encodedSampleBuffer)
    {
        CFRetain(encodedSampleBuffer);
    }
    
    _encodedSampleBuffer = encodedSampleBuffer;
    
}


-(CVImageBufferRef)videoFrame
{
    return _videoFrame;
}


-(void)setVideoFrame:(CVImageBufferRef)videoFrame
{
    
    
    if (_videoFrame)
    {
        CVPixelBufferRelease(_videoFrame);
    }
    if (videoFrame)
    {
        CVPixelBufferRetain(videoFrame);
    }
    
    _videoFrame = videoFrame;
}

@end