//
//  AppDelegate.h
//  H264Streamer
//
//  Created by Zakk on 9/2/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import <Cocoa/Cocoa.h>
#import <QTKit/QTKit.h>
#import "CaptureController.h"



@interface AppDelegate : NSObject <NSApplicationDelegate>
{
    
    
}
@property (unsafe_unretained) IBOutlet CaptureController *captureController;

@property (unsafe_unretained) IBOutlet NSWindow *window;

-(CAMultiAudioPCMPlayer *)createPCMInput:(NSString *)forUID withFormat:(AudioStreamBasicDescription *)withFormat;


@end
