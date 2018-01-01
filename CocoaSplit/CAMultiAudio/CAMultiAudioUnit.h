//
//  CAMultiAudioUnit.h
//  CocoaSplit
//
//  Created by Zakk on 11/15/14.
//

#import <Foundation/Foundation.h>
#import <AudioUnit/AudioUnit.h>
#import <AudioToolbox/AudioToolbox.h>


//This class is for AudioUnits that we directly connect to graph members without using the AUGraph API
//Naughty, no?

@interface CAMultiAudioUnit : NSObject

@property (assign) AudioComponentDescription unitDescription;
@property (assign) AudioUnit audioUnit;
@property (strong) NSString *name;

-(instancetype)initWithSubType:(OSType)subType unitType:(OSType)unitType manufacturer:(OSType)manufacturer;

-(void)connect:(AudioUnit)toNode;
-(void)openUnit;
+(NSArray *)availableEffects;

@end
