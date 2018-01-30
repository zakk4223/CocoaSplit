//
//  SourceCache.h
//  CocoaSplit
//
//  Created by Zakk on 8/30/14.
//

#import <Foundation/Foundation.h>
#import "CSCaptureSourceProtocol.h"


@interface SourceCache : NSObject


@property (strong) NSMapTable *cacheMap;

+(SourceCache *) sharedCache;

-(id) cacheSource:(NSObject<CSCaptureSourceProtocol>*)ofType uniqueID:(NSString *)uniqueID;
-(id) cacheSource:(NSObject <CSCaptureSourceProtocol>*)toCache;
-(id) findCachedSourceForClass:(Class)klass uniqueID:(NSString *)uniqueID;


@end
