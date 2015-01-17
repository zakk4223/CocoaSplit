//
//  CaptureSessionProtocol.h
//  H264Streamer
//
//  Created by Zakk on 9/7/12.
//  Copyright (c) 2012 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>

#import "CSAbstractCaptureDevice.h"
#import <AVFoundation/AVFoundation.h>
#import <Cocoa/Cocoa.h>





@protocol CSCaptureSourceProtocol

@required

//HEY YOU, DEVELOPER
//THIS IS ABSOLUTELY REQUIRED!!!! IF YOU DO CUSTOM UI FOR SETTING SOURCES
//YOU MUST CREATE A DUMMY CSAbstractCaptureDevice AND MAKE SURE uniqueID IS SET TO SOMETHING

//activeVideoDevice.uniqueID is observed for changes and source deduplication happens this way
//if you aren't using availablevideo devices/active video device just create a dummy instance
//and set uniqueID to something uniquely generated for your source. That or just don't support
//deduplication. Be that way.

@property CSAbstractCaptureDevice *activeVideoDevice;

@property (strong) NSArray *availableVideoDevices;

@property (readonly) float render_width;

@property (readonly) float render_height;

@property (strong) NSString *captureName;

@property (strong) CIContext *imageContext;

@property (assign) bool needsSourceSelection;

@property (weak) id inputSource;



//Set this to true if you don't want source sharing/deduplication. You should really have a good reason
//for this.
@property (assign) bool allowDedup;


//Set this to false if you don't want to be scaled. Instead of this source being forced to scale to the size of the input box
//it'll be cropped to it instead. This is here mostly for text capture sources, but maybe you can do something weird with it.

@property (assign) bool allowScaling;

//These are set as state changes/events happen. You can check their values in your code at anytime
//or observe them or override the setter/getter to do whatever you'd like.

//Are we selected in the UI?
@property (assign) bool isSelected;

//If the source is part of a multi-source input this flag is set when it isn't the source being displayed
@property (assign) bool isVisible;

//Your active status (active checkbox in config UI). If an input isn't active currentImage/getCurrentFrame aren't
//called. You can use this to pause timers or deallocate resources if you want.
@property (assign) bool isActive;

//TRUE if the source is in the LIVE canvas, FALSE otherwise.
//If you're handling audio via a CAMultiAudioPCMPlayer you shouldn't register a player unless you are isLive == YES
//You should also deregister it if you transition to isLive == NO. In summary: only create an audio out if you are live.
@property (assign) bool isLive;

//Set this to the name of the configuration NIB file. This is the UI that appears in the lower half of the 'Source' tab that lets the user configure input specific settings. By default this is going to be {self.className}ViewController. Override if you want to do something fancy
@property (readonly) NSString *configurationViewName;

//This is the class name of the configuration view CONTROLLER. With the combo above you can have different view controller classes and/or different NIBs depending on various conditions.
@property (readonly) NSString *configurationViewClassName;

//This is the layer that is inserted into the canvas. The inputsource container will take care of positioning and sizing. A CALayer with position set to 0,0 and the source native size is all that is required here. You can reassign this whenever you want and the layer will get replaced on the next frame render
@property (strong) CALayer *outputLayer;


//frameTick is called every render loop. You are not required to do anything here, but it may be useful for some timing/lazy rendering
-(void)frameTick;

//called before the input is removed. Allows you to clean up anything that isn't appropriate in -(void)dealloc

-(void)willDelete;


-(NSViewController *)configurationView;
+(NSString *) label;






@end
