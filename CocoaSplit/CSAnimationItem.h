//
//  CSAnimationItem.h
//  CocoaSplit
//
//  Created by Zakk on 3/20/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import "InputSource.h"

@interface CSAnimationItem : NSObject <NSCopying, NSCoding>



@property (strong) NSString *module_name;
@property (strong) NSString *name;
@property (readonly) bool onLive;

//label -> 'whatever'
//input -> InputSource
@property (strong) NSMutableArray *inputs;


-(instancetype)initWithDictionary:(NSDictionary *)dict moduleName:(NSString *)moduleName;
-(void)purgeInputSource:(InputSource *)src;


@end
