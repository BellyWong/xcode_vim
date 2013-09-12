//
//  XVim.m
//  XVim
//
//  Created by Shuichiro Suzuki on 1/19/12.
//  Copyright 2012 JugglerShu.Net. All rights reserved.
//

// This is the main class of XVim
// The main role of XVim class is followings.
//    - create hooks.
//    - provide methods used by all over the XVim features.
//
// Hooks:
// The plugin entry point is "load" but does little thing.
// The important method after that is hook method.
// In this method we create hooks necessary for XVim initializing.
// The most important hook is hook for IDEEditorArea and DVTSourceTextView.
// These hook setup command line and intercept key input to the editors.
//
// Methods:
// XVim is a singleton instance and holds objects which can be used by all the features in XVim.
// See the implementation to know what kind of objects it has. They are not difficult to understand.
// 



#import "XVim.h"
#import "XVimHookManager.h"
#import "Logger.h"
#import "DVTSourceTextViewHook.h"

long long g_currentLineNumber = 0;


@implementation XVim

+(void)receiveNotification:(NSNotification*)notification{
    if( [notification.name hasPrefix:@"IDE"] || [notification.name hasPrefix:@"DVT"] ){
        TRACE_LOG(@"Got notification name : %@    object : %@", notification.name, NSStringFromClass([[notification object] class]));
    }
}

- (void)toggleXVim:(id)sender{
    //call macvim
    NSArray* cmd = [NSArray arrayWithObjects:@"--servername xcode",
                    @"--remote-silent",
                    [NSString stringWithFormat:@"+%lld", g_currentLineNumber], m_documentPath,nil ];
    
    //NSLog (@"[run macvim:%@", cmd);

    [NSTask launchedTaskWithLaunchPath:@"/Applications/Vim.app/Contents/MacOS/Vim" arguments:cmd];
}

- (BOOL)validateMenuItem:(NSMenuItem *)menuItem{
    return YES;
}

+ (void) load 
{ 
    NSBundle* app = [NSBundle mainBundle];
    NSString* identifier = [app bundleIdentifier];
    
    if( ![identifier isEqualToString:@"com.apple.dt.Xcode"] ){
        return;
    }
    
    // Entry Point of the Plugin.
    [Logger defaultLogger].level = LogTrace;
    
    // Add XVim menu item in "Edit"
    // I have tried to add the item into "Editor" but did not work.
    // It looks that the initialization of "Editor" menu is after loading XVim...
    NSMenu* menu = [[NSApplication sharedApplication] mainMenu];
    //NSMenuItem* item = [[[NSMenuItem alloc] init] autorelease];
    
    NSMenuItem* item = [[NSMenuItem alloc] initWithTitle:@"Edit by vim"
                                                       action:@selector(toggleXVim:)
                                                keyEquivalent:@"0"];
	[item setTarget:[XVim instance]];
    [item setKeyEquivalentModifierMask: NSControlKeyMask];
  
    NSMenuItem* editorManu = [menu itemWithTitle:@"Edit"];
    NSMenu* editorSubMenu = [editorManu submenu];
    [editorSubMenu addItem:item];
    
    // This is for reverse engineering purpose. Comment this in and log all the notifications named "IDE" or "DVT"
    //[[NSNotificationCenter defaultCenter] addObserver:[XVim class] selector:@selector(receiveNotification:) name:nil object:nil];
    
    // Do the hooking after the App has finished launching,
    // Otherwise, we may miss some classes.

    // Command line window is not setuped if hook is too late.
    [XVimHookManager hookWhenPluginLoaded];

    NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
    [notificationCenter addObserver: [XVimHookManager class]
                                  selector: @selector( hookWhenDidFinishLaunching )
                                   name: NSApplicationDidFinishLaunchingNotification
                                 object: nil];
}

+ (XVim*)instance
{
    static XVim *__instance = nil;
    static dispatch_once_t __once;
    
    dispatch_once(&__once, ^{
        // Allocate singleton instance
        __instance = [[XVim alloc] init];
        
        TRACE_LOG(@"XVim loaded");
    });
    
	return __instance;
}

//////////////////////////////
// XVim Instance Methods /////
//////////////////////////////

- (id)init
{
	if (self = [super init])
	{
        m_documentPath = nil;
	}
	return self;
}


-(void)dealloc{
	[super dealloc];
}


- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if( [keyPath isEqualToString:@"document"] )
    {
        NSString *documentPath = [[[object document] fileURL] path];
    
        [m_documentPath release];
        m_documentPath = [documentPath retain];
    }
}
    
@end
