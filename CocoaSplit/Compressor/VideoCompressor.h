//
//  VideoCompressor.h
//  streamOutput
//
//  Created by Zakk on 3/17/13.
//

#import <Foundation/Foundation.h>
#import <CoreMedia/CoreMedia.h>
#import "CapturedFrameData.h"
#import "libavformat/avformat.h"
#import "CSCompressorViewControllerProtocol.h"

//#import "OutputDestination.h"


@class CaptureController;
@class OutputDestination;
@protocol ControllerProtocol;


@protocol VideoCompressor <NSObject,NSCoding,NSCopying>

//compressFrame is expected to be non-blocking. Create a serial dispatch queue if the underlying compressor
//is blocking

-(bool)compressFrame:(CapturedFrameData *)imageBuffer;


-(bool)setupCompressor:(CapturedFrameData *)videoFrame;




@property (assign) bool isNew;
@property (strong) NSMutableString *name;
@property (strong) NSString *compressorType;
@property (assign) int width;
@property (assign) int height;
@property (strong) NSString *resolutionOption;
@property (assign) bool errored;
@property (assign) bool active;
@property (assign) float frameRate;

-(void) addOutput:(id)destination;
-(void) removeOutput:(id)destination;
-(bool) hasOutputs;
-(NSInteger) outputCount;
-(void) reset;
-(bool) validate:(NSError **)therror;
-(id <CSCompressorViewControllerProtocol>)getConfigurationView;







@end
