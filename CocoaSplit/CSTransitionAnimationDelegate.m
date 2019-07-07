//
//  CSTransitionAnimationDelegate.m
//  CocoaSplit
//
//  Created by Zakk on 4/16/17.
//

#import "CSTransitionAnimationDelegate.h"
#import "InputSource.h"

@implementation CSTransitionAnimationDelegate

    
-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{

    for (InputSource *nSrc in self.addedInputs)
    {
        if (nSrc.layer)
        {
                [nSrc buildLayerConstraints];
                
        } else {
            [self.forLayout addSource:nSrc];
        }
    }
    
    for (InputSource *cSrc in self.changedInputs)
    {
        if (cSrc.layer)
        {
            [cSrc buildLayerConstraints];
        } else {
            [self.forLayout addSource:cSrc];
        }
    }

}
-(void)animationDidStart:(CAAnimation *)anim
{
    
    [CATransaction begin];

    [CATransaction begin];
    if (self.useAnimation)
    {
        CFTimeInterval duration = self.useAnimation.duration;
        [CATransaction setAnimationDuration:duration];
        
    }
    self.forLayout.rootLayer.filters = self.useFilters;
    if (self.useTransitionFilters)
    {
        self.forLayout.transitionLayer.filters = self.useTransitionFilters;
    }
    [CATransaction commit];

    
    if (self.fullScreen)
    {
        [self.forLayout.rootLayer addAnimation:self.useAnimation forKey:nil];
    }


    
    for (InputSource *nSrc in self.addedInputs)
    {
        if (self.useAnimation && !self.fullScreen)
        {
            [nSrc.layer addAnimation:self.useAnimation forKey:nil];
        }

        if (nSrc.layer)
        {
            [self.forLayout addSource:nSrc];

            nSrc.layer.hidden = NO;
        }
        

    }
    
    for (InputSource *cSrc in self.changedInputs)
    {
        if (cSrc.layer && self.useAnimation && !self.fullScreen)
        {
            [cSrc.layer addAnimation:self.useAnimation forKey:nil];
        }
        
        if (cSrc.layer)
        {
            [self.forLayout addSource:cSrc];
            cSrc.layer.hidden = NO;
        }

    }
    
    for (InputSource *cSrc in self.changeremoveInputs)
    {
        if (cSrc.layer && self.useAnimation && !self.fullScreen)
        {
            [cSrc.layer addAnimation:self.useAnimation forKey:nil];
        }
        
        if (cSrc.layer)
        {
            //cSrc.layer.hidden = YES;
            cSrc.layer.opacity = 0.0f;
        }
        
    }
    
    for (InputSource *rSrc in self.removedInputs)
    {
        if (rSrc.layer && self.useAnimation && !self.fullScreen)
        {
            [rSrc.layer addAnimation:self.useAnimation forKey:nil];
        }
        if (rSrc.layer)
        {
            //rSrc.layer.hidden = YES;
            rSrc.layer.opacity = 0.0f;
        }
    }
    [CATransaction commit];

}

/*
-(void)animationDidStop:(CAAnimation *)anim finished:(BOOL)flag
{
    NSLog(@"DELEGATE ANIMATION STOPPED");
}*/


@end
