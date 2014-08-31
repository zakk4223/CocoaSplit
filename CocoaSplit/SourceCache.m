//
//  SourceCache.m
//  CocoaSplit
//
//  Created by Zakk on 8/30/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import "SourceCache.h"


@implementation SourceCache


+(id) sharedCache
{
    static SourceCache *sharedCache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        
        sharedCache = [[self alloc] init];
    });
    
    return sharedCache;
}



-(instancetype) init
{
    if (self = [super init])
    {
        self.cacheMap = [NSMapTable strongToWeakObjectsMapTable];
    }
    return self;
}


-(id) cacheSource:(NSObject <CSCaptureSourceProtocol>*)toCache uniqueID:(NSString *)uniqueID
{
    
    if (!toCache.allowDedup)
    {
        return toCache;
    }
    
    
    NSString *ofType = NSStringFromClass([toCache class]);
    
    
    NSString *sourceKey = [NSString stringWithFormat:@"%@:%@", ofType, uniqueID];

    
    
    id cachedSource = [self.cacheMap objectForKey:sourceKey];
    
    if (!cachedSource)
    {
        cachedSource = toCache;
        [self.cacheMap setObject:toCache forKey:sourceKey];
        
    }
    
    return cachedSource;
}


@end
