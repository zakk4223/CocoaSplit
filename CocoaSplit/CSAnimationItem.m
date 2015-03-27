//
//  CSAnimationItem.m
//  CocoaSplit
//
//  Created by Zakk on 3/20/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#import "CSAnimationItem.h"

@implementation CSAnimationItem


-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.name forKey:@"name"];
    [aCoder encodeObject:self.module_name forKey:@"module_name"];
    [aCoder encodeObject:self.inputs forKey:@"inputs"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [super init])
    {
        self.name = [aDecoder decodeObjectForKey:@"name"];
        self.module_name = [aDecoder decodeObjectForKey:@"module_name"];
        self.inputs = [aDecoder decodeObjectForKey:@"inputs"];
    }
    
    return self;
}


-(instancetype)copyWithZone:(NSZone *)zone
{
    CSAnimationItem *newItem = [[CSAnimationItem allocWithZone:zone] init];
    newItem.module_name = self.module_name;
    newItem.inputs = self.inputs;
    newItem.name = self.name;
    return newItem;
}


-(instancetype)initWithDictionary:(NSDictionary *)dict moduleName:(NSString *)moduleName
{
    if (self = [super init])
    {
        
        self.module_name = moduleName;
        
        self.name = [dict objectForKey:@"name"];
        NSArray *inputNames = [dict objectForKey:@"inputs"];
        
        self.inputs = [NSMutableArray array];
        
        for (NSString *iname in inputNames)
        {
            NSMutableDictionary *inputDict = [NSMutableDictionary dictionary];
            inputDict[@"label"] = iname;
            inputDict[@"inputsource"] = [NSNull null];
            [self.inputs addObject:inputDict];
        }
    }
    
    return self;
}

@end
