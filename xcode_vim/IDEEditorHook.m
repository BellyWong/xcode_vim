//
//  IDEEditor.m
//  XVim
//
//  Created by Suzuki Shuichiro on 5/1/12.
//  Copyright (c) 2012 JugglerShu.Net. All rights reserved.
//

#import "IDEEditorHook.h"
#import "IDEKit.h"
#import "IDESourceEditor.h"
#import "Hooker.h"
#import "Logger.h"
#import "XcodeVimObject.h"
#import <objc/runtime.h>

#define DID_REGISTER_OBSERVER_KEY   "xcode_call_vim.IDEEditorHook._didRegisterObserver"

@implementation IDEEditorHook
+(void)hook{
    Class c = NSClassFromString(@"IDEEditor");
    
    [Hooker hookMethod:@selector(didSetupEditor) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(didSetupEditor) ) keepingOriginalWith:@selector(didSetupEditor_)];
    
    [Hooker hookMethod:@selector(primitiveInvalidate) ofClass:c withMethod:class_getInstanceMethod([self class], @selector(primitiveInvalidate)) keepingOriginalWith:@selector(primitiveInvalidate_)];
}

- (void)didSetupEditor{
    
    IDEEditor* editor = (IDEEditor*)self;
    [editor didSetupEditor_];
    
    // For % register and to notify contents of editor is changed
    [editor addObserver:[XcodeVimObject instance] forKeyPath:@"document" options:NSKeyValueObservingOptionInitial | NSKeyValueObservingOptionNew context:nil];
    objc_setAssociatedObject(editor, DID_REGISTER_OBSERVER_KEY, [NSNumber numberWithBool:YES], OBJC_ASSOCIATION_RETAIN);
}

- (void)primitiveInvalidate {
    IDEEditor *editor = (IDEEditor *)self;
    NSNumber *didRegisterObserver = objc_getAssociatedObject(editor, DID_REGISTER_OBSERVER_KEY);
    if ([didRegisterObserver boolValue]) {
        [editor removeObserver:[XcodeVimObject instance] forKeyPath:@"document"];
    }
    
    [editor primitiveInvalidate_];
}

@end
