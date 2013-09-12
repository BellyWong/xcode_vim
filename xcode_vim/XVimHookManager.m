//
//  XVimHookManager.m
//  XVim
//
//  Created by Tomas Lundell on 29/04/12.
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "XVimHookManager.h"
#import "IDESourceCodeEditorHook.h"
#import "IDEEditorHook.h"

@implementation XVimHookManager

+ (void)hookWhenPluginLoaded
{
    //[IDEEditorAreaHook hook];
}

+ (void)hookWhenDidFinishLaunching
{
	//[DVTSourceTextViewHook hook];
	[IDESourceCodeEditorHook hook];
    //[DVTSourceTextScrollViewHook hook];
    [IDEEditorHook hook];
}

@end
