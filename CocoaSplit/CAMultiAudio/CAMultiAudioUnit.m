//
//  CAMultiAudioUnit.m
//  CocoaSplit
//
//  Created by Zakk on 11/15/14.
//

#import "CAMultiAudioUnit.h"

@implementation CAMultiAudioUnit

-(instancetype)initWithSubType:(OSType)subType unitType:(OSType)unitType manufacturer:(OSType)manufacturer
{
    if (self = [super init])
    {

        _unitDescription.componentType = unitType;
        
        _unitDescription.componentSubType = subType;
        _unitDescription.componentManufacturer = manufacturer;
    }
    
    return self;
}

-(NSString *)description
{
    return self.name;
}


+(NSArray *)availableEffects
{
    
    NSMutableArray *ret = [NSMutableArray array];
    AudioComponentDescription searchDesc = {0};
    searchDesc.componentType = kAudioUnitType_Effect;
    
    AudioComponent result = NULL;
    
    while ((result = AudioComponentFindNext(result, &searchDesc)))
    {
        AudioComponentDescription resultDesc;
        AudioComponentGetDescription(result, &resultDesc);
        
        CAMultiAudioUnit *newUnit = [[CAMultiAudioUnit alloc] initWithSubType:resultDesc.componentSubType unitType:resultDesc.componentType manufacturer:resultDesc.componentManufacturer];
        CFStringRef name;
        AudioComponentCopyName(result, &name);
        newUnit.name = CFBridgingRelease(name);
        [ret addObject:newUnit];
    }
    
    return ret;
}


-(void)createUnit
{
    AudioComponent comp = {0};
    
    comp = AudioComponentFindNext(NULL, &_unitDescription);
    if (comp)
    {
        CFStringRef cName;
        
        AudioComponentCopyName(comp, &cName);
        self.name = CFBridgingRelease(cName);
        
        AudioComponentInstanceNew(comp, &_audioUnit);
    }
}


-(void)connect:(AudioUnit)toNode
{
    AudioUnitConnection conn;
    
    conn.sourceAudioUnit = _audioUnit;
    conn.sourceOutputNumber = 1;
    conn.destInputNumber = 1;
    OSStatus err;
    
    AudioStreamBasicDescription asbd = {0};
    UInt32 asbdSize = sizeof(asbd);
    
    AudioUnitGetProperty(_audioUnit, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Output, 1, &asbd, &asbdSize);

    
    err = AudioUnitSetProperty(toNode, kAudioUnitProperty_MakeConnection, kAudioUnitScope_Input, 1, &conn, sizeof(conn));
    
    err = AudioUnitSetProperty(toNode, kAudioUnitProperty_StreamFormat, kAudioUnitScope_Input, 1, &asbd, asbdSize);
    
    AudioUnitInitialize(_audioUnit);
    
    
}


-(void)openUnit
{

    if (_audioUnit)
    {
        AudioUnitInitialize(_audioUnit);
    }
    CAShow(_audioUnit);
    
    AudioOutputUnitStart(_audioUnit);
}

@end
