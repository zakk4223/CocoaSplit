//
//  CSCIFilterConfigProxy.m
//  CocoaSplit
//
//  Created by Zakk on 4/19/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSCIFilterConfigProxy.h"

@implementation CSCIFilterConfigProxy



-(instancetype)init
{
    if (self = [super init])
    {
        self.baseDict = [NSMutableDictionary dictionary];
        self.filterType = @"";
    }
    
    return self;
}


-(void)setValue:(id)value forKeyPath:(NSString *)keyPath
{
    

    [super setValue:value forKeyPath:keyPath];
    if ([keyPath hasPrefix:@"baseDict."] && self.layerFilterName && self.baseLayer)
    {
     
        NSString *valueKey = [keyPath substringFromIndex:@"baseDict.".length];
        
        
        [self.baseLayer setValue:value forKeyPath:[NSString stringWithFormat:@"%@.%@.%@",self.filterType, self.layerFilterName, valueKey]];
    }
}

-(id)valueForKeyPath:(NSString *)keyPath
{
    id ret = [super valueForKeyPath:keyPath];
    
    id layer_val = nil;
    
    if ([keyPath hasPrefix:@"baseDict."] && self.layerFilterName && self.baseLayer)
    {
        NSString *valueKey = [keyPath substringFromIndex:@"baseDict.".length];
        layer_val = [self.baseLayer valueForKeyPath:[NSString stringWithFormat:@"%@.%@.%@", self.filterType,self.layerFilterName, valueKey]];
    }
    
    
    if (layer_val)
    {
        ret = layer_val;
    }
    
    return ret;
}

-(NSString *)bindKeyForAffineTransform:(NSObject *)transform
{
    NSString *baseBinding = nil;
    
    for (NSString *bindkey in transform.exposedBindings)
    {
        if ([bindkey isEqualToString:@"affineTransform"])
        {
            NSDictionary *bindInfo = [transform infoForBinding:bindkey];
            NSString *bindpath = bindInfo[NSObservedKeyPathKey];
            if (bindpath && [bindpath hasPrefix:@"selection."])
            {
                baseBinding = [bindpath substringFromIndex:@"selection.".length];
                [transform unbind:bindkey];
                [transform bind:bindkey toObject:self withKeyPath:[NSString stringWithFormat:@"baseDict.%@",baseBinding] options:bindInfo[NSOptionsKey]];
                
            }
        }
    }
    
    return baseBinding;
}
-(NSString *)bindKeyForVector:(NSObject *)vector
{
    NSString *baseBinding = nil;
    
    for (NSString *bindkey in vector.exposedBindings)
    {
        if ([bindkey isEqualToString:@"vector"])
        {
            NSDictionary *bindInfo = [vector infoForBinding:bindkey];
            NSString *bindpath = bindInfo[NSObservedKeyPathKey];
            if (bindpath && [bindpath hasPrefix:@"selection."])
            {
                baseBinding = [bindpath substringFromIndex:@"selection.".length];
                [vector unbind:bindkey];
                [vector bind:bindkey toObject:self withKeyPath:[NSString stringWithFormat:@"baseDict.%@",baseBinding] options:bindInfo[NSOptionsKey]];
                
            }
        }
    }
    
    return baseBinding;
}


-(void)rebindViewControls:(NSView *)forView
{
    for (NSString *b in forView.exposedBindings)
    {
        
        NSDictionary *bindingInfo = [forView infoForBinding:b];
        
        
        if (!bindingInfo)
        {
            continue;
        }
        
        NSDictionary *bindingOptions = bindingInfo[NSOptionsKey];
        
        NSString *bindPath = bindingInfo[NSObservedKeyPathKey];
        
        NSObject *boundTo = bindingInfo[NSObservedObjectKey];
        
        
        NSString *baseBinding;
        
        
        if ([bindPath hasPrefix:@"selection."])
        {
            baseBinding = [bindPath substringFromIndex:@"selection.".length];
            [forView unbind:b];
            [forView bind:b toObject:self withKeyPath:[NSString stringWithFormat:@"baseDict.%@",baseBinding] options:bindingOptions];
            
        } else if ([boundTo.className isEqualToString:@"CIMutableVector"]) {
            [self bindKeyForVector:boundTo];
        } else if ([boundTo.className isEqualToString:@"NSMutableAffineTransform"]) {
            [self bindKeyForAffineTransform:boundTo];
            
        }
    }
    
    for (NSView *subview in forView.subviews)
    {
        [self rebindViewControls:subview];
        
    }
    
    
}


@end
