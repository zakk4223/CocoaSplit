//
//  MovieCapture.h
//  CocoaSplit
//
//  Created by Zakk on 8/26/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "CaptureBase.h"
#import <AVFoundation/AVFoundation.h>


@interface MovieCapture : CaptureBase <CaptureSessionProtocol>
{
    CVPixelBufferRef _currentFrame;
}

@property (strong) AVQueuePlayer *avPlayer;
@property (strong) AVPlayerItemVideoOutput *avOutput;
@property (strong) NSURL *currentMedia;
@property (strong) NSString *playPauseTitle;
@property (assign) double currentMovieTime;
@property (readonly) NSString *currentMovieTimeString;
@property (readonly) NSString *movieDurationString;
@property (readonly) double movieDuration;

@property (strong) id timeToken;


-(void)chooseMedia;

-(void) nextMovie;
-(void)removeQueueItems:(NSIndexSet *)movieIndexes;


@end
