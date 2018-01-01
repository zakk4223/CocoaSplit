//
//  CAMultiAudioEffect.h
//  CocoaSplit
//
//  Created by Zakk on 12/31/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CAMultiAudioNode.h"

@interface CAMultiAudioEffect : CAMultiAudioNode <NSCopying>
{
    NSDictionary *_auClassData;
}


@property (assign) bool bypass;

+(NSArray *)availableEffects;
-(NSArray *)effectPresets;
-(void)selectPresetNumber:(SInt32)presetNumber;

@end
