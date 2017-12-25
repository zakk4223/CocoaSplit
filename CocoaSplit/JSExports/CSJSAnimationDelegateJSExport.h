//
//  CSJSAnimationDelegateJSExport.h
//  CocoaSplit
//
//  Created by Zakk on 11/14/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>

@protocol CSJSAnimationDelegateJSExport <JSExport>
-(instancetype)initWithJSAnimation:(JSValue *)jsAnim;
-(void)animationDidStop:(CAAnimation *)animation finished:(BOOL)finished;
@end
