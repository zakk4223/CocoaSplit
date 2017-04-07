//
//  CSLayoutSequence.m
//  CocoaSplit
//
//  Created by Zakk on 3/11/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import "CSLayoutSequence.h"
#import "CSSequenceItem.h"

@implementation CSLayoutSequence


-(instancetype) init
{
    if (self = [super init])
    {
    }
    
    return self;
}



-(void)encodeWithCoder:(NSCoder *)aCoder
{
    [aCoder encodeObject:self.animationCode forKey:@"animationCode"];
    [aCoder encodeObject:self.name forKey:@"name"];
}

-(instancetype)initWithCoder:(NSCoder *)aDecoder
{
    if (self = [self init])
    {
        self.animationCode = [aDecoder decodeObjectForKey:@"animationCode"];
        self.name = [aDecoder decodeObjectForKey:@"name"];
        if (!self.name)
        {
            self.name = @"Unknown";
        }
    }
    
    return self;
}




-(void)cancelSequenceForLayout:(SourceLayout *)layout
{
    if (self.lastRunUUID)
    {
        [layout cancelScriptRun:self.lastRunUUID];
        self.lastRunUUID = nil;
    }
}


-(void)runSequenceForLayout:(SourceLayout *)layout withCompletionBlock:(void (^)())completionBlock withExceptionBlock:(void (^)(NSException *exception))exceptionBlock
{
    self.sourceLayout = layout;
    
    if (self.animationCode)
    {
        NSMutableString *realCode = [NSMutableString string];
        
        NSRegularExpression *method_regex = [NSRegularExpression regularExpressionWithPattern:@"def\\s+run_script" options:0 error:nil];
        
        if ([method_regex numberOfMatchesInString:_animationCode options:0 range:NSMakeRange(0, self.animationCode.length)] == 0)
        {
            [realCode appendString:@"def run_script():\n"];
            [self.animationCode enumerateLinesUsingBlock:^(NSString * _Nonnull line, BOOL * _Nonnull stop) {
                [realCode appendString:[NSString stringWithFormat:@"\t%@\n", line]];
                
            }];
        } else {
            realCode = self.animationCode.mutableCopy;
        }
        
        
        
            

        self.lastRunUUID = [self.sourceLayout runAnimationString:realCode withCompletionBlock:^{
            self.lastRunUUID = nil;
            if (completionBlock)
            {
                completionBlock();
            }
        } withExceptionBlock:^(NSException *exception) {
            self.lastRunUUID = nil;
            if (exceptionBlock)
            {
                exceptionBlock(exception);
            }
            
        }];
    }
    
}

@end
