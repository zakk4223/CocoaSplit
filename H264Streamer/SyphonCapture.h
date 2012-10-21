//
//  SyphonCapture.h
//  H264Streamer
//
//  Created by Zakk on 9/7/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <Syphon/Syphon.h>
#import "CaptureSessionProtocol.h"

@interface SyphonCapture : NSObject < CaptureSessionProtocol>
{
    int _captureFPS;
    NSDictionary *_syphonServer;
    id _delegate;
    SyphonClient *_syphon_client;
    NSOpenGLContext *_cgl_ctx;
    
}


@end
