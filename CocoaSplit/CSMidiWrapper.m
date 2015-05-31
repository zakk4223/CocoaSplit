//
//  CSMidiWrapper.m
//  CocoaSplit
//
//  Created by Zakk on 5/16/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSMidiWrapper.h"

@implementation CSMidiWrapper




-(instancetype)initWithDevice:(MIKMIDIDevice *)device
{
    if (self = [super init])
    {
        self.device = device;
        self.deviceMapping = [[MIKMIDIMapping alloc] init];
        self.deviceMapping.controllerName = device.name;
        
        
    }
    
    return self;
}


+(NSArray *)getAllMidiDevices
{
    
    NSMutableArray *ret = [NSMutableArray array];
    
    NSArray *srcs = [[MIKMIDIDeviceManager sharedDeviceManager] virtualSources];
    
    for (MIKMIDISourceEndpoint *ept in srcs)
    {
        MIKMIDIDevice *vdev = [MIKMIDIDevice deviceWithVirtualEndpoints:@[ept]];
        CSMidiWrapper *wrap = [[CSMidiWrapper alloc] initWithDevice:vdev];
        if (wrap)
        {
            [ret addObject:wrap];
        }
        
    }
    
    /*
    for (MIKMIDIDevice *dev in [[MIKMIDIDeviceManager sharedDeviceManager] availableDevices])
    {
        NSLog(@"REAL DEV %@", dev);
        
        CSMidiWrapper *wrap = [[CSMidiWrapper alloc] initWithDevice:dev];
        if (wrap)
        {
            [ret addObject:wrap];
        }
    }*/
    
    return ret;
}

-(void)dispatchMidiCommand:(MIKMIDICommand *)command
{
    
    if (!self.deviceMapping || _mapGenerator)
    {
        return;
    }

    NSSet *items = [self.deviceMapping mappingItemsForMIDICommand:command];
    
    for (MIKMIDIMappingItem *item in items)
    {
        id<MIKMIDIResponder> responder = [NSApp MIDIResponderWithIdentifier:item.MIDIResponderIdentifier];
        if ([responder respondsToMIDICommand:command])
        {
            NSString *dynMethod = [NSString stringWithFormat:@"handleMIDICommand%@:", item.commandIdentifier];
            
            SEL dynSelector = NSSelectorFromString(dynMethod);
            
            if ([responder respondsToSelector:dynSelector])
            {
                NSMethodSignature *dynsig = [[responder class] instanceMethodSignatureForSelector:dynSelector];
                NSInvocation *dyninvoke = [NSInvocation invocationWithMethodSignature:dynsig];
                dyninvoke.target = responder;
                dyninvoke.selector = dynSelector;
                [dyninvoke setArgument:&command atIndex:2];
                [dyninvoke retainArguments];
                [dyninvoke invoke];
            } else {
                [responder handleMIDICommand:command forIdentifier:item.commandIdentifier];
            }
        }
    }
}


-(void)cancelLearning
{
    if (_mapGenerator)
    {
        [_mapGenerator cancelCurrentCommandLearning];
        _mapGenerator = nil;
    }
}


-(void)forgetCommand:(NSString *)command forResponder:(id<MIKMIDIMappableResponder>)responder
{
    NSSet *maps = [self.deviceMapping mappingItemsForCommandIdentifier:command responder:responder];
    if (maps)
    {
        [self.deviceMapping removeMappingItems:maps];
    }
}


-(void)learnCommand:(NSString *)command forResponder:(id<MIKMIDIMappableResponder>)responder completionBlock:(void (^)(CSMidiWrapper *wrapper, NSString *command))methodCompletionBlock
{
    
    
    _mapGenerator = [[MIKMIDIMappingGenerator alloc] initWithDevice:self.device error:nil];
    _mapGenerator.delegate = self;
    
    _mapGenerator.mapping = self.deviceMapping;
    
    __weak CSMidiWrapper *weakSelf = self;

    [_mapGenerator learnMappingForControl:responder withCommandIdentifier:command requiringNumberOfMessages:0 orTimeoutInterval:0 completionBlock:^(MIKMIDIMappingItem *mappingItem, NSArray *messages, NSError *error) {

        if (mappingItem)
        {
            weakSelf.deviceMapping = _mapGenerator.mapping;
            if ([responder respondsToSelector:@selector(additionalChannelForMIDIIdentifier:)])
            {
                NSInteger extraChannel = [responder additionalChannelForMIDIIdentifier:command];
                if (extraChannel > -1)
                {
                    MIKMIDIMappingItem *newMap = mappingItem.copy;
                    newMap.channel = extraChannel;
                    [weakSelf.deviceMapping addMappingItemsObject:newMap];
                }
            }
            if (methodCompletionBlock)
            {
                methodCompletionBlock(weakSelf, mappingItem.commandIdentifier);
            }
        }
        CSMidiWrapper *strongSelf = weakSelf;
        strongSelf->_mapGenerator = nil;
        strongSelf = nil;
    }];
}


-(MIKMIDIMappingGeneratorRemapBehavior)mappingGenerator:(MIKMIDIMappingGenerator *)generator behaviorForRemappingControlMappedWithItems:(NSSet *)mappingItems toNewResponder:(id<MIKMIDIMappableResponder>)newResponder commandIdentifier:(NSString *)commandIdentifier
{
    return MIKMIDIMappingGeneratorRemapAllowDuplicate;
}

-(BOOL)mappingGenerator:(MIKMIDIMappingGenerator *)generator shouldRemoveExistingMappingItems:(NSSet *)mappingItems forResponderBeingMapped:(id<MIKMIDIMappableResponder>)responder
{
    return NO;
}



-(void)connect
{
    NSArray *sources = [self.device.entities valueForKeyPath:@"@unionOfArrays.sources"];
    if (sources.count > 0)
    {
        MIKMIDISourceEndpoint *source = [sources objectAtIndex:0];
        __weak CSMidiWrapper *weakSelf = self;
        [[MIKMIDIDeviceManager sharedDeviceManager] connectInput:source error:nil eventHandler:^(MIKMIDISourceEndpoint *source, NSArray *commands) {
            for (MIKMIDICommand *command in commands) {
                
                if (![command isKindOfClass:[MIKMIDIChannelVoiceCommand class]]) continue;

                [weakSelf dispatchMidiCommand:command];
            }
        }];
    }

}

@end
