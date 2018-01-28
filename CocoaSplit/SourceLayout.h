//
//  SourceLayout.h
//  CocoaSplit
//
//  Created by Zakk on 8/31/14.

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "InputSource.h"
#import "CSNotifications.h"
#import <malloc/malloc.h>
#import "CSAnimationRunnerObj.h"
#import "MIKMIDI.h"
#import "CSInputSourceProtocol.h"
#import "CAMultiAudioEngine.h"
#import "CSAudioInputSource.h"



@class CSLayoutRecorder;
@class CSLayoutTransition;


@protocol SourceLayoutExport <JSExport>
@property (assign) bool doSaveSourceList;

@property (assign) bool inTransition;

@property (strong) CSLayoutTransition *transitionInfo;



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

@property (strong) NSMutableDictionary *pendingScripts;
@property (assign) bool recordingLayout;
@property (assign) bool recordLayout;
@property (weak) CSLayoutRecorder *recorder;
@property (readonly) bool hasSources;
@property (strong) CAMultiAudioEngine *audioEngine;

-(void)deleteSource:(NSObject<CSInputSourceProtocol> *)delSource;
-(void)addSource:(NSObject<CSInputSourceProtocol> *)newSource;
-(InputSource *)findSource:(NSPoint)forPoint deepParent:(bool)deepParent;
-(InputSource *)findSource:(NSPoint)forPoint withExtra:(float)withExtra deepParent:(bool)deepParent;
-(NSArray *)sourceListOrdered;
-(void) saveSourceList;
-(void) saveSourceListForExport;
-(void)restoreSourceList:(NSData *)withData;
-(NSData *)makeSaveData;

-(NSObject<CSInputSourceProtocol> *)inputForUUID:(NSString *)uuid;
-(void)frameTick;
-(InputSource *)sourceUnder:(InputSource *)source;
-(void)didBecomeVisible;
-(bool)containsInput:(InputSource *)cSource;
-(void)modifyUUID:(NSString *)uuid withBlock:(void (^)(NSObject<CSInputSourceProtocol> *input))withBlock;

-(void)mergeSourceLayout:(SourceLayout *)toMerge usingScripts:(bool)usingScripts withCompletionBlock:(void (^)(void))completionBlock;
-(void)mergeSourceLayout:(SourceLayout *)toMerge usingScripts:(bool)usingScripts;
-(void)mergeSourceLayout:(SourceLayout *)toMerge;


-(void)removeSourceLayout:(SourceLayout *)toRemove usingScripts:(bool)usingScripts;
-(void)removeSourceLayout:(SourceLayout *)toRemove;

-(bool)containsLayout:(SourceLayout *)layout;
-(void)applyAddBlock;
-(void)replaceWithSourceLayout:(SourceLayout *)layout usingScripts:(bool)usingScripts;
-(void)replaceWithSourceLayout:(SourceLayout *)layout;

-(void)clearSourceList;
-(void)setupMIDI;
-(void)updateCanvasWidth:(int)width height:(int)height;
-(NSString *)runAnimationString:(NSString *)animationCode withCompletionBlock:(void (^)(void))completionBlock withExceptionBlock:(void (^)(NSException *exception))exceptionBlock withExtraDictionary:(NSDictionary *)extraDictionary;

-(void)replaceWithSourceLayout:(SourceLayout *)layout usingScripts:(bool)usingScripts withCompletionBlock:(void (^)(void))completionBlock;
-(NSObject<CSInputSourceProtocol> *)inputForName:(NSString *)name;
-(void)cancelTransition;
-(void)cancelScriptRun:(NSString *)runUUID;
-(bool)containsLayoutNamed:(NSString *)layoutName;
-(void)mergeSourceLayoutViaScript:(SourceLayout *)layout;
-(void)replaceWithSourceLayoutViaScript:(SourceLayout *)layout withCompletionBlock:(void (^)(void))completionBlock withExceptionBlock:(void (^)(NSException *exception))exceptionBlock;
-(void)removeSourceLayoutViaScript:(SourceLayout *)layout;
-(void)sequenceThroughLayoutsViaScript:(NSArray *)sequence withCompletionBlock:(void (^)(void))completionBlock withExceptionBlock:(void (^)(NSException *exception))exceptionBlock;
-(SourceLayout *)mergedSourceLayout:(SourceLayout *)withLayout;
-(SourceLayout *)sourceLayoutWithRemoved:(SourceLayout *)withRemoved;
-(void)generateTopLevelSourceList;
-(NSString *)addLayoutFilter:(NSString *)filterName;
-(void)deleteLayoutFilter:(NSString *)filteruuid;


@end

@interface SourceLayout : NSObject <SourceLayoutExport, NSCoding, NSKeyedUnarchiverDelegate, NSKeyedArchiverDelegate, NSCopying, MIKMIDIMappableResponder, MIKMIDIResponder>
{
    
    NSSortDescriptor *_sourceDepthSorter;
    NSSortDescriptor *_sourceDepthSorterRev;
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
    bool _doingLayoutExport;
    JSVirtualMachine *_animationVirtualMachine;
    //dispatch_queue_t _animationQueue;
    
    
    
    
    
    
    
    
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

@property (strong) NSMutableDictionary *pendingScripts;
@property (assign) bool recordingLayout;
@property (assign) bool recordLayout;
@property (weak) CSLayoutRecorder *recorder;
@property (strong) CSLayoutTransition *transitionInfo;
@property (readonly) bool hasSources;
@property (strong) NSData *audioData;
@property (strong) CAMultiAudioEngine *audioEngine;

-(CSAudioInputSource *)findSourceForAudioUUID:(NSString *)audioUUID;

-(void) adjustAllInputs;
-(CAMultiAudioEngine *)restoreAudioData;
-(void)reapplyAudioSources;
-(CAMultiAudioEngine *)findAudioEngine;


@end
