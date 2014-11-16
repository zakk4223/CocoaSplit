//
//  CAMultiAudioUnit.h
//  CocoaSplit
//
//  Created by Zakk on 11/15/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>


//This class is for AudioUnits that we directly connect to graph members without using the AUGraph API
//Naughty, no?

@interface CAMultiAudioUnit : NSObject

@property (assign) AudioUnit audioUnit;

-(instancetype)initWithSubType:(OSType)subType unitType:(OSType)unitType;

-(void)connect:(AudioUnit)toNode;
-(void)openUnit;

@end
