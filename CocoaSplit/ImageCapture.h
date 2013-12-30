//
//  ImageCapture.h
//  CocoaSplit
//
//  Created by Zakk on 12/27/13.
//  Copyright (c) 2013 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CaptureSessionProtocol.h"


@interface ImageCapture : NSObject <CaptureSessionProtocol>
{
    
    NSArray *_sourceList;
}


@property double videoCaptureFPS;
@property int width;
@property int height;
@property AbstractCaptureDevice *activeVideoDevice;
@property (weak) id videoDelegate;
@property (readonly) NSArray *availableVideoDevices;
@property (readonly) BOOL needsAdvancedVideo;

@property NSString *imageDirectory;


@property CVPixelBufferRef currentFrame;

@property (weak) id<ControllerProtocol> settingsController;


-(void) setVideoDimensions:(int)width height:(int)height;


-(CVImageBufferRef) getCurrentFrame;

- (BOOL)needsAdvancedVideo;
-(void)chooseDirectory:(id)sender;




@end
