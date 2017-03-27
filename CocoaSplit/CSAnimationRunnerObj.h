//
//  CSAnimationRunner.h
//  CocoaSplit
//
//  Created by Zakk on 3/14/15.
//  Copyright (c) 2015 Zakk. All rights reserved.
//

#ifndef CocoaSplit_CSAnimationRunner_h
#define CocoaSplit_CSAnimationRunner_h

#import <Foundation/Foundation.h>


@interface CSAnimationRunnerObj : NSObject


-(NSDictionary *)allAnimations;

-(void)runAnimation:(NSString *)name forInput:(id)forInput withSuperlayer:(CALayer *)superLayer;
-(void)runAnimation:(NSString *)name forLayout:(id)forLayout withSuperlayer:(CALayer *)superlayer;
-(void)runAnimation:(NSString *)code forLayout:(id)forLayout;

-(NSString *)animationPath:(NSString *)name;

@end



#endif
