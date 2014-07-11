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


-(id)init
{
    if (self = [super init])
    {
        _videoFrame = nil;
        self.frameNumber = 0;
        self.audioSamples = [[NSMutableArray alloc] init];
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
	
    for (id object in self.audioSamples)
    {
        CMSampleBufferRef audioSample = (__bridge CMSampleBufferRef)object;
        CFRelease(audioSample);
    }
    

	self.audioSamples = nil;
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
    
    CFRetain(encodedSampleBuffer);
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