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

@end
