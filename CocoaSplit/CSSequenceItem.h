//
//  CSSequenceItem.h
//  CocoaSplit
//
//  Created by Zakk on 3/11/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "CSLayoutSequence.h"

@class CSSequenceItemViewController;

@interface CSSequenceItem : NSObject

@property (strong) NSString *itemDescription;

+(NSImage *)image;
+(NSString *)label;

-(void)executeWithSequence:(CSLayoutSequence *)sequencer usingCompletionBlock:(void (^)())completionBlock;

-(CSSequenceItemViewController *)configurationView;

-(void)updateItemDescription;

-(NSString *)generateItemScript;

@end
