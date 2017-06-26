//
//  CSInputSourceBase.h
//  CocoaSplit
//
//  Created by Zakk on 6/26/17.
//

#import <Foundation/Foundation.h>
#import "CSInputSourceProtocol.h"


@interface CSInputSourceBase : NSObject <CSInputSourceProtocol>

@property (weak) SourceLayout *sourceLayout;
@property (strong) CSInputLayer *layer;
@property (assign) bool is_live;
@property (strong) NSString *name;
@property (strong) NSString *uuid;
@property (assign) NSInteger refCount;
@property (assign) bool active;


-(void)createUUID;

@end
