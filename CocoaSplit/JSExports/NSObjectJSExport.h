//
//  NSObjectJSExport.h
//  CocoaSplit
//
//  Created by Zakk on 6/17/17.
//  Copyright © 2017 Zakk. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <JavaScriptCore/JavaScriptCore.h>


@protocol NSObjectJSExport <JSExport>

- (id)valueForKeyPath:(NSString *)keyPath;
- (void)setValue:(id)value forKeyPath:(NSString *)keyPath;

@end
JSEXPORT_PROTO(NSObjectJSExport)
