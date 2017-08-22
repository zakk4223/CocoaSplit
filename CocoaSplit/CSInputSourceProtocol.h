//
//  CSInputSourceProtocol.h
//  CocoaSplit
//
//  Created by Zakk on 6/25/17.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>
#import "CSInputLayer.h"

@class SourceLayout;

@protocol CSInputSourceProtocol <NSObject, JSExport>

@property (weak) SourceLayout *sourceLayout;
@property (strong) CSInputLayer *layer;
@property (assign) bool is_live;
@property (strong) NSString *name;
@property (strong) NSString *uuid;
@property (assign) NSInteger refCount;
@property (assign) bool active;
@property (readonly) NSImage *libraryImage;
@property (assign) float depth;
@property (strong) NSMutableArray *attachedInputs;
@property (assign) NSInteger scriptPriority;
@property (assign) bool scriptAlwaysRun;
@property (readonly) NSString *label;
@property (assign) float duration;



-(bool)isDifferentInput:(NSObject<CSInputSourceProtocol> *)from;
-(NSViewController *)configurationViewController;
//Lifecycle hooks, primarily for scripting/animation
-(void)afterAdd;
-(void)beforeDelete;
-(void)frameTick;
-(void)beforeMerge:(bool)changed;
-(void)afterMerge:(bool)changed;
-(void)beforeRemove;
-(void)beforeReplace:(bool)removing;
-(void)afterReplace;


@end
