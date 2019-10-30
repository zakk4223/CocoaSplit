//
//  CSTimedOutputBuffer.h
//  CocoaSplit
//
//  Created by Zakk on 4/2/16.
//

#import <Foundation/Foundation.h>
#import "VideoCompressor.h"
#import "CSOutputBase.h"
#import "CSIRCompressor.h"
#import "CSLavfOutput.h"



@interface CSTimedOutputBuffer : NSObject
{
    NSMutableArray *_frameBuffer;
    float _currentBufferDuration;
    CSLavfOutput *_hlsOutput;
    int _current_file_index;
    NSString *_current_file_name;
    NSString *_previous_file_name;
    
}



@property (assign) float bufferDuration;
@property (strong) NSString *name;
@property (strong) CSIRCompressor *compressor;

-(void) writeCurrentBuffer:(NSString *)toFile;
-(void) writeCurrentBuffer:(NSString *)toFile withCompletionBlock:(void (^)(void))completionBlock;
-(void) writeCurrentBuffer:(NSString *)toFile usingDuration:(float)seconds_to_write withCompletionBlock:(void (^)(void))completionBlock;


-(instancetype) initWithCompressor:(id<VideoCompressor>)compressor;


@end
