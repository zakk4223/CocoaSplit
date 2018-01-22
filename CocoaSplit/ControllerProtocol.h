//
//  ControllerProtocol.h
//  CocoaSplit
//
//  Created by Zakk on 4/7/13.
//

#import <Foundation/Foundation.h>
#import "libavformat/avformat.h"
#import "CapturedFrameData.h"
#import <AppKit/AppKit.h>
#import "VideoCompressor.h"
#import "InputSource.h"


@protocol ControllerProtocol <NSObject>


@property int captureWidth;
@property int captureHeight;
@property (readonly) double captureFPS;
@property (readonly) int audioBitrate;
@property (readonly) int audioSamplerate;
@property (assign) BOOL captureRunning;

@property (assign) int maxOutputPending;
@property (assign) int maxOutputDropped;
@property (strong) id <VideoCompressor> selectedCompressor;
@property (strong) NSMutableDictionary *compressors;


-(void)captureOutputAudio:(id)fromDevice didOutputSampleBuffer:(CMSampleBufferRef)sampleBuffer;
-(void)newFrame;
-(void)setExtraData:(id)saveData forKey:(NSString *)forKey;
-(id)getExtraData:(NSString *)forkey;
-(CVPixelBufferRef)currentFrame;
-(double)mach_time_seconds;
-(NSColor *)statusColor;




- (void) outputEncodedData:(CapturedFrameData *)frameData;








@end
