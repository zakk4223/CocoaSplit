//
//  CSLayoutSequence.h
//  CocoaSplit
//
//  Created by Zakk on 3/11/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "SourceLayout.h"

@class CSSequenceItem;

@interface CSLayoutSequence : NSObject <NSCoding>
{

}


@property (strong) NSString *name;
@property (weak) SourceLayout *sourceLayout;
@property (strong) NSString *animationCode;
@property (strong) NSString *lastRunUUID;

-(void)runSequenceForLayout:(SourceLayout *)layout withCompletionBlock:(void (^)())completionBlock withExceptionBlock:(void (^)(NSException *exception))exceptionBlock;
-(void)cancelSequenceForLayout:(SourceLayout *)layout;

@end
