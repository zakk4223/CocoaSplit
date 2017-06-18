//
//  CATransaction+JSExtensions.h
//  CocoaSplit
//
//  Created by Zakk on 6/17/17.
//

#import <QuartzCore/QuartzCore.h>
#import <JavaScriptCore/JavaScriptCore.h>

@interface CATransaction (JSExtensions)
+ (void)setCompletionBlockJS:(JSValue *)jsvalue;

@end
