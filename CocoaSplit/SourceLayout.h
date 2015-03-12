//
//  SourceLayout.h
//  CocoaSplit
//
//  Created by Zakk on 8/31/14.
//  Copyright (c) 2014 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InputSource.h"
#import "CSNotifications.h"
#import <malloc/malloc.h>


@interface SourceLayout : NSObject <NSCoding, NSKeyedUnarchiverDelegate, NSCopying>
{
    
    NSSortDescriptor *_sourceDepthSorter;
    NSSortDescriptor *_sourceUUIDSorter;
    CVPixelBufferPoolRef _cvpool;
    CVPixelBufferRef _currentPB;
    NSSize _rootSize;
    GLuint _fboTexture;
    GLuint _rFbo;
}

@property (strong) NSMutableArray *sourceList;
@property (strong) NSData *savedSourceListData;
@property (assign) bool isActive;


@property (assign) int canvas_width;
@property (assign) int canvas_height;

@property (assign) float frameRate;

@property (assign) CGLContextObj cglCtx;

@property (strong) CIContext *ciCtx;
@property (strong) NSString *name;

@property (strong) CARenderer *renderer;
@property (strong) CALayer *rootLayer;

//For self-transitions
@property (strong) CALayer *transitionLayer;
@property (strong) NSMutableArray *transitionSourceList;
@property (assign) bool transitionNeeded;

@property (strong) SourceCache *sourceCache;
@property (strong) CIFilter *compositeFilter;


-(void)deleteSource:(InputSource *)delSource;
-(void)addSource:(InputSource *)newSource;
-(InputSource *)findSource:(NSPoint)forPoint;
-(InputSource *)findSource:(NSPoint)forPoint withExtra:(float)withExtra;
-(NSArray *)sourceListOrdered;
-(void) saveSourceList;
-(void) restoreSourceList;
-(InputSource *)inputForUUID:(NSString *)uuid;
-(void)frameTick;
-(void)restoreSourceListForSelfGoLive;
-(void)mergeSourceListData:(NSData *)mergeData;



@end
