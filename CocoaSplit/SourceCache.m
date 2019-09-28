//
//  SourceCache.m
//  CocoaSplit
//
//  Created by Zakk on 8/30/14.
//

#import "SourceCache.h"
#import "CSCaptureBaseInternal.h"

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
        self.persistentMap = [NSMutableDictionary dictionary];
    }
    return self;
}



-(id) removePersistentSource:(NSObject <CSCaptureSourceProtocol>*)toRemove
{
    NSString *uid = nil;
    NSString *sourceKey = nil;
    
    if (toRemove.activeVideoDevice)
    {
        uid = toRemove.activeVideoDevice.uniqueID;
    }
    
    if (uid)
    {
        NSString *ofType = NSStringFromClass(toRemove.class);
        sourceKey = [NSString stringWithFormat:@"%@:%@", ofType, uid];
        [self.persistentMap removeObjectForKey:sourceKey];
    }
    return toRemove;
}


-(id) cacheSourcePersistent:(NSObject <CSCaptureSourceProtocol>*)toCache
{
    
    NSString *uid = nil;
    NSString *sourceKey = nil;
    
    
    if (toCache.activeVideoDevice)
    {
        uid = toCache.activeVideoDevice.uniqueID;
        
    }
    
    if (uid)
    {
        NSString *ofType = NSStringFromClass(toCache.class);
        sourceKey = [NSString stringWithFormat:@"%@:%@", ofType, uid];
        [self.persistentMap setObject:toCache forKey:sourceKey];
    }

    return toCache;
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
    NSObject <CSCaptureSourceProtocol> *cachedSource = [self.persistentMap objectForKey:sourceKey];

    if (!cachedSource)
    {
        cachedSource = [self.cacheMap objectForKey:sourceKey];

    }
    
    
    if (!cachedSource)
    {
        return nil;
    }
    
    
    if (!cachedSource.allowDedup)
    {
        //dedup status changed, evict from cache
        //NSLog(@"EVICT DEDUP CHANGED");
        [self.cacheMap removeObjectForKey:sourceKey];
        [self.persistentMap removeObjectForKey:sourceKey];
        return nil;
    }
    
    NSString *currentUID = nil;
    
    if (cachedSource.activeVideoDevice)
    {
        currentUID = cachedSource.activeVideoDevice.uniqueID;
    }
    
    if (!currentUID)
    {
        //NSLog(@"EVICT NO CURRENT ID");
        [self.cacheMap removeObjectForKey:sourceKey];
        [self.persistentMap removeObjectForKey:sourceKey];

        return nil;
    }
    
    if (![currentUID isEqualToString:uniqueID])
    {
        //NSLog(@"EVICT + REPLACE ID CHANGED");
        [self.cacheMap removeObjectForKey:sourceKey];
        CSCaptureBase *persistentSource = [self.persistentMap objectForKey:sourceKey];
        [self.persistentMap removeObjectForKey:sourceKey];
        NSString *newKey = [NSString stringWithFormat:@"%@:%@", ofType, currentUID];
        [self.cacheMap setObject:cachedSource forKey:newKey];
        
        if (persistentSource && persistentSource.cachePersistent)
        {
            [self.persistentMap setObject:persistentSource forKey:newKey];
        }

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
        //NSLog(@"INSERTING INTO CACHE %@", toCache);
        NSString *ofType = NSStringFromClass([toCache class]);
        NSString *sourceKey = [NSString stringWithFormat:@"%@:%@", ofType, uniqueID];
        cachedSource = toCache;
        [self.cacheMap setObject:toCache forKey:sourceKey];

    } else {
        //NSLog(@"USED CACHE %@", cachedSource);
    }
    return cachedSource;
}


@end
