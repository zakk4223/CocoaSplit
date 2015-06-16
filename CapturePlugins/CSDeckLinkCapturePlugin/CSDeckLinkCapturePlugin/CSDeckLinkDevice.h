//
//  CSDeckLinkDevice.h
//  CSDeckLinkCapturePlugin
//
//  Created by Zakk on 6/14/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#include "DeckLinkBridge.h"


@interface CSDeckLinkDisplayMode : NSObject


-(instancetype) initWithMode:(IDeckLinkDisplayMode *)displayMode;

@property (strong) NSString *modeName;
@property (assign) IDeckLinkDisplayMode *deckLinkMode;

-(bool)containsMode:(IDeckLinkDisplayMode *)mode;

@end


@interface CSDeckLinkDevice : NSObject
{
    IDeckLink *_device;
    IDeckLinkInput *_deviceInput;
    NSHashTable *_outputs;
    uint32_t _pixelFormatValues[9];
    DeckLinkInputHandler *_inputCallbackHandler;

    
}



@property (assign) bool canDetectFormat;
@property (strong) NSString *uniqueID;
@property (strong) NSArray *displayModes;
@property (strong) CSDeckLinkDisplayMode *selectedDisplayMode;
@property (strong) NSArray *pixelFormats;
@property (strong) NSString *selectedPixelFormat;


-(instancetype) initWithDevice:(IDeckLink *)device;
-(void)registerOutput:(CSDeckLinkCapture *)output;
-(void)removeOutput:(CSDeckLinkCapture *)output;
-(void)frameArrived:(IDeckLinkVideoFrame *)frame;
-(void)setDisplayModeForName:(NSString *)name;
-(void)detectedDisplayChange:(IDeckLinkDisplayMode *)mode withFlags:(BMDDetectedVideoInputFormatFlags)flags;





@end
