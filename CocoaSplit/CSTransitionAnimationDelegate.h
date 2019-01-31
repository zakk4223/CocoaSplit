//
//  CSTransitionAnimationDelegate.h
//  CocoaSplit
//
//  Created by Zakk on 4/16/17.
//

#import <Foundation/Foundation.h>
#import <Quartz/Quartz.h>
#import "SourceLayout.h"

@interface CSTransitionAnimationDelegate : NSObject <CAAnimationDelegate>
@property (strong) NSArray *changedInputs;
@property (strong) NSArray *removedInputs;
@property (strong) NSArray *addedInputs;
@property (strong) NSArray *changeremoveInputs;

@property (strong) CAAnimation *useAnimation;
@property (strong) NSArray *useFilters;
@property (strong) NSArray *useTransitionFilters;

@property (assign) bool fullScreen;

@property (weak) SourceLayout *forLayout;

-(void)animationDidStart:(CAAnimation *)anim;
-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag;

@end
