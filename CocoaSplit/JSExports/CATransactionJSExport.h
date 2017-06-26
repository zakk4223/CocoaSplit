//
//  CATransactionJSExport.h
//  CocoaSplit
//
//  Created by Zakk on 6/17/17.
//


#ifndef CATransactionJSExport_h
#define CATransactionJSExport_h

#import <JavaScriptCore/JavaScriptCore.h>
#import "JSExportUtil.h"

@protocol CATransactionJSExport <JSExport>

+ (void)begin;
+ (void)commit;
+ (void)flush;
+ (void)lock;
+ (void)unlock;
+ (CFTimeInterval)animationDuration;
+ (void)setAnimationDuration:(CFTimeInterval)dur;
+ (nullable CAMediaTimingFunction *)animationTimingFunction;
+ (void)setAnimationTimingFunction:(nullable CAMediaTimingFunction *)function;
+ (BOOL)disableActions;
+ (void)setDisableActions:(BOOL)flag;
+ (nullable void (^)(void))completionBlock;
+ (void)setCompletionBlock:(nullable void (^)(void))block;
+ (void)setCompletionBlockJS:( JSValue * _Nonnull )jsvalue;
+ (nullable id)valueForKey:(NSString *_Nonnull)key;
+ (void)setValue:(nullable id)anObject forKey:(NSString *_Nonnull)key;

@end

JSEXPORT_PROTO(CATransactionJSExport)


#endif /* CATransactionJSExport_h */
