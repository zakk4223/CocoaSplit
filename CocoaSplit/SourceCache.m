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
    NSObject <CSCaptureSourceProtocol> *cachedSrc =  [self retrieveSource:klass uniqueID:uniqueID];
    return cachedSrc;
}

-(id) retrieveSource:(Class)cacheClass uniqueID:(NSString *)uniqueID
{
    
    
    if (!uniqueID)
    {
        return nil;
    }
    
    NSString *ofType = NSStringFromClass(cacheClass);
    NSString *sourceKey = [NSString stringWithFormat:@"%@:%@", ofType, uniqueID];
    NSObject <CSCaptureSourceProtocol> *cachedSource = [self.cacheMap objectForKey:sourceKey];
    if (!cachedSource)
    {
        return nil;
    }
    
    
    if (!cachedSource.allowDedup)
    {
        //dedup status changed, evict from cache
        NSLog(@"EVICT DEDUP CHANGED");
        [self.cacheMap removeObjectForKey:sourceKey];
        return nil;
    }
    
    NSString *currentUID = nil;
    
    if (cachedSource.activeVideoDevice)
    {
        currentUID = cachedSource.activeVideoDevice.uniqueID;
    }
    
    if (!currentUID)
    {
        NSLog(@"EVICT NO CURRENT ID");
        [self.cacheMap removeObjectForKey:sourceKey];
        return nil;
    }
    
    if (![currentUID isEqualToString:uniqueID])
    {
        NSLog(@"EVICT + REPLACE ID CHANGED");
        [self.cacheMap removeObjectForKey:sourceKey];
        NSString *newKey = [NSString stringWithFormat:@"%@:%@", ofType, currentUID];
        [self.cacheMap setObject:cachedSource forKey:newKey];
        return nil;
    }
    
    return cachedSource;
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
    
    NSObject <CSCaptureSourceProtocol> *cachedSource = [self retrieveSource:toCache.class uniqueID:uniqueID];

    if (!cachedSource)
    {
        NSLog(@"INSERTING INTO CACHE %@", toCache);
        NSString *ofType = NSStringFromClass([toCache class]);
        NSString *sourceKey = [NSString stringWithFormat:@"%@:%@", ofType, uniqueID];
        cachedSource = toCache;
        [self.cacheMap setObject:toCache forKey:sourceKey];

    } else {
        NSLog(@"USED CACHE %@", cachedSource);
    }
    return cachedSource;
}


@end
