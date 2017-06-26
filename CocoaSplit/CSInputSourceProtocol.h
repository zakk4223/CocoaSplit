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

-(bool)isDifferentInput:(NSObject<CSInputSourceProtocol> *)from;
-(void)willDelete;
-(void)frameTick;


@end
