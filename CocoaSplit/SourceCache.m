//
//  SourceCache.m
//  CocoaSplit
//
//  Created by Zakk on 8/30/14.
//

#import "SourceCache.h"


@implementation SourceCache


+(SourceCache *) sharedCache
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


-(id) cacheSource:(NSObject <CSCaptureSourceProtocol>*)toCache
{
    NSString *uid = nil;
    
    if (toCache.activeVideoDevice)
    {
        uid = toCache.activeVideoDevice.uniqueID;
    }
    return [self cacheSource:toCache uniqueID:uid];
}


-(id) findCachedSourceForClass:(Class)klass uniqueID:(NSString *)uniqueID
{
    NSString *ofType = NSStringFromClass(klass);
    NSString *sourceKey = [NSString stringWithFormat:@"%@:%@", ofType, uniqueID];
    NSObject <CSCaptureSourceProtocol> *cachedSrc =  [self.cacheMap objectForKey:sourceKey];
    if (cachedSrc && !cachedSrc.allowDedup)
    {
        [self.cacheMap removeObjectForKey:sourceKey];
        return nil;
    }
    
    return cachedSrc;
}


-(id) cacheSource:(NSObject <CSCaptureSourceProtocol>*)toCache uniqueID:(NSString *)uniqueID
{
    if (!toCache.allowDedup)
    {
        return toCache;
    }
    
    if (!uniqueID)
    {
        //don't cache things with null uniqueIDs, that just means they don't have an active source yet
        return toCache;
    }
    NSString *ofType = NSStringFromClass([toCache class]);
    NSString *sourceKey = [NSString stringWithFormat:@"%@:%@", ofType, uniqueID];
    NSObject <CSCaptureSourceProtocol> *cachedSource = [self.cacheMap objectForKey:sourceKey];
    if (!cachedSource)
    {
        cachedSource = toCache;
        [self.cacheMap setObject:toCache forKey:sourceKey];
        
    } else {
        if (!cachedSource.allowDedup)
        {
            NSLog(@"EVICT CACHE");
            cachedSource = toCache;
            [self.cacheMap setObject:toCache forKey:sourceKey];
        } else {
            NSLog(@"USE CACHE %@", cachedSource);
        }
    }
    
    return cachedSource;
}


@end
