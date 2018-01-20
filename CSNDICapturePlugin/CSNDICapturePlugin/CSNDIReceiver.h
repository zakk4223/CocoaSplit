//
//  CSNDIReceiver.h
//  CSNDICapturePlugin
//
//  Created by Zakk on 1/18/18.
//

#import <Foundation/Foundation.h>
#import "NDIHeaders/Processing.NDI.Lib.h"
#import "NDIVideoOutputDelegateProtocol.h"
#import "NDIAudioOutputDelegateProtocol.h"
#import "CSNDISource.h"

#import <CoreVideo/CoreVideo.h>

@interface CSNDIReceiver : NSObject
{
    NDIlib_recv_instance_t _receiver_instance;
    CSNDISource *_ndi_source;
    CVPixelBufferPoolRef _cvpool;
    NSSize _currentSize;
    dispatch_queue_t _video_output_queue;
    dispatch_queue_t _audio_output_queue;
    bool _stop_audio;
    bool _stop_video;
    bool _audio_running;
    bool _video_running;
    
    __weak NSObject<NDIVideoOutputDelegateProtocol> *_videoDelegate;
    __weak NSObject<NDIAudioOutputDelegateProtocol> *_audioDelegate;

    dispatch_queue_t _video_receive_thread;
    dispatch_queue_t _audio_receive_thread;
    
    AudioStreamBasicDescription *_asbd;
    
}

@property (assign) uint32_t videoTimeout;
@property (assign) uint32_t audioTimeout;

-(instancetype)initWithSource:(CSNDISource *)ndi_source;
-(void)registerVideoDelegate:(id<NDIVideoOutputDelegateProtocol>)delegate withQueue:(dispatch_queue_t)videoQueue;
-(void)registerAudioDelegate:(id<NDIAudioOutputDelegateProtocol>)delegate withQueue:(dispatch_queue_t)audioQueue;

-(void)removeVideoDelegate;
-(void)removeAudioDelegate;

-(void)startVideoCapture;
-(void)startAudioCapture;
-(void)stopAudioCapture;
-(void)stopVideoCapture;
-(void)startCapture;
-(void)stopCapture;

-(bool)captureVideo:(uint32_t)waitMS;

@end
