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
#import "CSAnimationItem.h"
#import "CSAnimationRunnerObj.h"
#import "MIKMIDI.h"



@interface SourceLayout : NSObject <NSCoding, NSKeyedUnarchiverDelegate, NSCopying, MIKMIDIMappableResponder, MIKMIDIResponder>
{
    
    NSSortDescriptor *_sourceDepthSorter;
    NSSortDescriptor *_sourceUUIDSorter;
    CVPixelBufferPoolRef _cvpool;
    CVPixelBufferRef _currentPB;
    NSSize _rootSize;
    GLuint _fboTexture;
    GLuint _rFbo;
    dispatch_queue_t _animationQueue;
    
}


@property (assign) bool inTransition;
@property (strong) NSMutableArray *animationList;
@property (strong) NSIndexSet *animationIndexes;

@property (strong) CSAnimationItem *selectedAnimation;

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
-(InputSource *)findSource:(NSPoint)forPoint deepParent:(bool)deepParent;
-(InputSource *)findSource:(NSPoint)forPoint withExtra:(float)withExtra deepParent:(bool)deepParent;
-(NSArray *)sourceListOrdered;
-(void) saveSourceList;
-(void) restoreSourceList;
-(InputSource *)inputForUUID:(NSString *)uuid;
-(void)frameTick;
-(void)restoreSourceListForSelfGoLive;
-(NSObject *)mergeSourceListData:(NSData *)mergeData;
-(IBAction)runAnimations:(id)sender;
-(void)addAnimation:(NSDictionary *)animation;
-(InputSource *)sourceUnder:(InputSource *)source;




@end
