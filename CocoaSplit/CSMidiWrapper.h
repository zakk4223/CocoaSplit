//
//  CSMidiWrapper.h
//  CocoaSplit
//
//  Created by Zakk on 5/16/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "MIKMIDI.h"


@interface CSMidiWrapper : NSObject <MIKMIDIMappingGeneratorDelegate>
{
    MIKMIDIMappingGenerator *_mapGenerator;
}

@property (strong) MIKMIDIDevice *device;
@property (strong) MIKMIDIMapping *deviceMapping;



-(instancetype)initWithDevice:(MIKMIDIDevice *)device;

+(NSArray *)getAllMidiDevices;

-(void)connect;
-(void)learnCommand:(NSString *)command forResponder:(id<MIKMIDIMappableResponder>)responder completionBlock:(void (^)(CSMidiWrapper *wrapper, NSString *command))completionBlock;
-(void)cancelLearning;
-(void)forgetCommand:(NSString *)command forResponder:(id<MIKMIDIMappableResponder>)responder;




@end
