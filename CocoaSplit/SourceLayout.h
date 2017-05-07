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
#import "CSAnimationRunnerObj.h"
#import "MIKMIDI.h"


@class CSLayoutRecorder;



@interface SourceLayout : NSObject <NSCoding, NSKeyedUnarchiverDelegate, NSKeyedArchiverDelegate, NSCopying, MIKMIDIMappableResponder, MIKMIDIResponder>
{
    
    NSSortDescriptor *_sourceDepthSorter;
    NSSortDescriptor *_sourceUUIDSorter;
    NSSize _rootSize;
    GLuint _fboTexture;
    GLuint _rFbo;
    dispatch_queue_t _animationQueue;
    NSMutableDictionary *_uuidMap;
    NSMutableDictionary *_uuidMapPresentation;
    bool _noSceneTransactions;
    NSMutableArray *_topLevelSourceArray;
    bool _skipRefCounting;
    
    
    
    
    
}



@property (assign) bool doSaveSourceList;

@property (assign) bool inTransition;




@property (strong) NSMutableArray *sourceList;
@property (strong) NSMutableArray *sourceListPresentation;

@property (readonly) NSArray *topLevelSourceList;

@property (strong) NSData *savedSourceListData;
@property (assign) bool isActive;


@property (assign) int canvas_width;
@property (assign) int canvas_height;

@property (assign) float frameRate;

@property (assign) CGLContextObj cglCtx;

@property (strong) NSString *name;

@property (strong) CARenderer *renderer;
@property (strong) CALayer *rootLayer;

@property (strong) SourceCache *sourceCache;
@property (strong) CIFilter *compositeFilter;

@property (weak) InputSource *layoutTimingSource;
@property (strong) NSUndoManager *undoManager;

@property (strong) NSMutableArray *containedLayouts;


@property (assign) bool in_live;
@property (assign) bool in_staging;

@property (nonatomic, copy) void (^addLayoutBlock)(SourceLayout *layout);
@property (nonatomic, copy) void (^removeLayoutBlock)(SourceLayout *layout);

@property (strong) NSString *transitionName;
@property (strong) NSString *transitionDirection;
@property (strong) CIFilter *transitionFilter;
@property (assign) float transitionDuration;
@property (assign) bool transitionFullScene;
@property (strong) NSMutableDictionary *pendingScripts;
@property (strong) NSMutableDictionary *transitionScripts;
@property (strong) NSDictionary *audioData;
@property (assign) bool recordingLayout;
@property (assign) bool recordLayout;
@property (weak) CSLayoutRecorder *recorder;







-(void)deleteSource:(InputSource *)delSource;
-(void)addSource:(InputSource *)newSource;
-(InputSource *)findSource:(NSPoint)forPoint deepParent:(bool)deepParent;
-(InputSource *)findSource:(NSPoint)forPoint withExtra:(float)withExtra deepParent:(bool)deepParent;
-(NSArray *)sourceListOrdered;
-(void) saveSourceList;
-(void)restoreSourceList:(NSData *)withData;
-(NSData *)makeSaveData;

-(InputSource *)inputForUUID:(NSString *)uuid;
-(void)frameTick;
-(NSObject *)mergeSourceListData:(NSData *)mergeData onlyAdd:(bool)onlyAdd;
-(InputSource *)sourceUnder:(InputSource *)source;
-(void)didBecomeVisible;
-(bool)containsInput:(InputSource *)cSource;
-(void)modifyUUID:(NSString *)uuid withBlock:(void (^)(InputSource *input))withBlock;

-(void)mergeSourceLayout:(SourceLayout *)toMerge withCompletionBlock:(void (^)(void))completionBlock;
-(void)mergeSourceLayout:(SourceLayout *)toMerge;

-(void)removeSourceLayout:(SourceLayout *)toRemove;
-(bool)containsLayout:(SourceLayout *)layout;
-(void)applyAddBlock;
-(void)replaceWithSourceLayout:(SourceLayout *)layout;
-(void)clearSourceList;
-(void)setupMIDI;
-(void)updateCanvasWidth:(int)width height:(int)height;
-(NSString *)runAnimationString:(NSString *)animationCode withCompletionBlock:(void (^)(void))completionBlock withExceptionBlock:(void (^)(NSException *exception))exceptionBlock withExtraDictionary:(NSDictionary *)extraDictionary;

-(void)replaceWithSourceLayout:(SourceLayout *)layout withCompletionBlock:(void (^)(void))completionBlock;
-(InputSource *)inputForName:(NSString *)name;
-(void)cancelTransition;
-(void)cancelScriptRun:(NSString *)runUUID;
-(bool)containsLayoutNamed:(NSString *)layoutName;
-(void)mergeSourceLayoutViaScript:(SourceLayout *)layout;
-(void)replaceWithSourceLayoutViaScript:(SourceLayout *)layout withCompletionBlock:(void (^)(void))completionBlock withExceptionBlock:(void (^)(NSException *exception))exceptionBlock;
-(void)removeSourceLayoutViaScript:(SourceLayout *)layout;








@end
