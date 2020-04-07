//
//  CSNDICapture.h
//  CSNDICapturePlugin
//
//  Created by Zakk on 1/18/18.
//

#import "CSCaptureBase.h"
#import "NDIHeaders/Processing.NDI.Lib.h"
#import "CSNDIReceiver.h"
#import "NDIVideoOutputDelegateProtocol.h"
#import "NDIAudioOutputDelegateProtocol.h"



@interface CSNDICapture : CSCaptureBase <CSCaptureSourceProtocol, NDIVideoOutputDelegateProtocol, NDIAudioOutputDelegateProtocol>
{
    NDIlib_v3 *_ndi_dispatch;
    dispatch_queue_t _video_thread;
    dispatch_queue_t _audio_thread;

    CSNDIReceiver *_current_receiver;
    NSSize _lastSize;
    CSPcmPlayer *_pcmPlayer;
    
}



+(void *)ndi_dispatch_ptr;
+(NDIlib_find_instance_t)ndi_source_finder;


@end
