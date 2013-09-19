//
//  XcodeVimObject.m
//  xcode_vim
//
//  Created by chliu on 13-8-24.
//  Copyright (c) 2013 chliu. All rights reserved.
//

#import "XcodeVimObject.h"
#import "XVimHookManager.h"

#include <sys/types.h>
#include <sys/wait.h>
#include <signal.h>
#include <stdlib.h>
#include <stddef.h>
#include <unistd.h>
#include <spawn.h>
#include <paths.h>
#include <errno.h>
#include <crt_externs.h>

#define environ (*_NSGetEnviron())

static int launch_cmd ( const char* command  )
{
	pid_t pid;
	int pstat, err;
	struct sigaction ign, intact, quitact;
	sigset_t newsigblock, oldsigblock, defaultsig;
	posix_spawnattr_t attr;
	short flags = POSIX_SPAWN_SETSIGMASK;
	const char *argv[] = {"sh", "-c", command, NULL};
    
	if ((err = posix_spawnattr_init(&attr)) != 0) {
		errno = err;
		return -1;
	}
    
#if 0
	(void)sigemptyset(&defaultsig);
    
    
	/*
	 * Ignore SIGINT and SIGQUIT, block SIGCHLD. Remember to save
	 * existing signal dispositions.
	 */
	ign.sa_handler = SIG_IGN;
	(void)sigemptyset(&ign.sa_mask);
	ign.sa_flags = 0;
	(void)_sigaction(SIGINT, &ign, &intact);
	if (intact.sa_handler != SIG_IGN) {
		sigaddset(&defaultsig, SIGINT);
		flags |= POSIX_SPAWN_SETSIGDEF;
	}
	(void)_sigaction(SIGQUIT, &ign, &quitact);
	if (quitact.sa_handler != SIG_IGN) {
		sigaddset(&defaultsig, SIGQUIT);
		flags |= POSIX_SPAWN_SETSIGDEF;
	}
	(void)sigemptyset(&newsigblock);
	(void)sigaddset(&newsigblock, SIGCHLD);
	//(void)_sigprocmask(SIG_BLOCK, &newsigblock, &oldsigblock);
#endif
    
	(void)posix_spawnattr_setsigmask(&attr, &oldsigblock);
	if (flags & POSIX_SPAWN_SETSIGDEF) {
		(void)posix_spawnattr_setsigdefault(&attr, &defaultsig);
	}
	(void)posix_spawnattr_setflags(&attr, flags);
    
	err = posix_spawn(&pid, _PATH_BSHELL, NULL, &attr, (char *const *)argv, environ);
	(void)posix_spawnattr_destroy(&attr);
	if (err == 0) {
		fprintf (stderr, "%d\n", pid);
	} else if (err == ENOMEM || err == EAGAIN) { /* as if fork failed */
		pstat = -1;
	} else {
		pstat = W_EXITCODE(127, 0); /* couldn't exec shell */
	}
    
#if 0
	(void)_sigaction(SIGINT, &intact, NULL);
	(void)_sigaction(SIGQUIT,  &quitact, NULL);
	(void)_sigprocmask(SIG_SETMASK, &oldsigblock, NULL);
#endif
    
    return 0;
}


// XCODE shortcuts setting file:
///Applications/Xcode.app/Contents/Frameworks/IDEKit.framework/Versions/A/Resources/IDETextKeyBindingSet.plist

//put the xcode_vim.xcplugin to
// ~/Library/Application Support/Developer/Shared/Xcode/Plug-ins

long long g_currentLineNumber = 0;



@implementation NSView (Dumping)

-(void)dumpWithIndent:(NSString *)indent 
{
	NSString *clazz = NSStringFromClass([self class]);
	NSString *info = @"";

	if ([self respondsToSelector:@selector(title)]) 
    {
		NSString *title = [self performSelector:@selector(title)];
		if (title != nil && [title length] > 0)
        {
			info = [info stringByAppendingFormat:@" title=%@", title];
        }
	}

	if ([self respondsToSelector:@selector(stringValue)]) 
    {
		NSString *string = [self performSelector:@selector(stringValue)];

		if (string != nil && [string length] > 0)
        {
			info = [info stringByAppendingFormat:@" stringValue=%@", string];
        }
	}

	NSString *tooltip = [self toolTip];
	if (tooltip != nil && [tooltip length] > 0)
    {
		info = [info stringByAppendingFormat:@" tooltip=%@", tooltip];
    }
    
	NSLog(@"%@%@%@", indent, clazz, info);
    
	if ([[self subviews] count] > 0) 
    {
		NSString *subIndent = [NSString stringWithFormat:@"%@%@", 
               indent, ([indent length]/2)%2==0 ? @"| " : @": "];

		for (NSView *subview in [self subviews])
        {
			[subview dumpWithIndent:subIndent];
        }
	}
}

@end

//Many callback methods require an instance of a class to call back to, 
//so a very common technique is to create a singleton instance of your plugin 
//using code in your plugin like the following:
//
static XcodeVimObject * g_instance = nil;

@implementation XcodeVimObject

+(void)pluginDidLoad:(NSBundle *)plugin
{
	NSLog (@"This is vim Xcode plugin!");
    
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		g_instance = [[self alloc] init];
    });
}

+(XcodeVimObject *)instance
{
	return g_instance;
}

-(id)init
{
    NSBundle* app = [NSBundle mainBundle];
    NSString* identifier = [app bundleIdentifier];
    
    if( ![identifier isEqualToString:@"com.apple.dt.Xcode"] )
    {
        return nil;
    }
    
	if (self = [super init])
    {
        // Entry Point of the Plugin.
        m_documentPath = nil;
        
        [self addMenuItems];

        // Do the hooking after the App has finished launching,
        // Otherwise, we may miss some classes.
        
        // Command line window is not setuped if hook is too late.
        [XVimHookManager hookWhenPluginLoaded];
        
        NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver: [XVimHookManager class]
                               selector: @selector( hookWhenDidFinishLaunching )
                                   name: NSApplicationDidFinishLaunchingNotification
                                 object: nil];
            
#ifdef HOOK_XCODE_NOTIFY
        [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(notificationListener:)
                                                 name:nil
                                               object:nil];
#endif
    
	}
    
	return self;
}

-(void)dealloc 
{
#ifdef HOOK_XCODE_NOTIFY
	[[NSNotificationCenter defaultCenter] removeObserver:self];
#endif
    
    [m_documentPath release];
    
    [super dealloc];
}

#ifdef HOOK_XCODE_NOTIFY
-(void)notificationListener:(NSNotification *)notification
{
    if( [notification.name hasPrefix:@"IDE"] || [notification.name hasPrefix:@"DVT"] )
    {
        TRACE_LOG(@"Got notification name : %@    object : %@",
                  notification.name, NSStringFromClass([[notification object] class]));
    }
}
#endif

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if( [keyPath isEqualToString:@"document"] )
    {
        NSString *documentPath = [[[object document] fileURL] path];
        
        [m_documentPath release];
        m_documentPath = [documentPath retain];
    }
}

-(void)addMenuItems
{
	NSMenu* mainMenu = [NSApp mainMenu];
    
	// find the Edit menu and add a new item, shortcuts:ctrl+0:
    
	NSMenuItem* editMenu = [mainMenu itemWithTitle:@"Edit"];
	NSMenuItem* editByVim = [[NSMenuItem alloc] initWithTitle:@"Edit by vim" 
                                                       action:@selector(editByVim:) 
                                                keyEquivalent:@"0"];
	[editByVim setTarget:self];
    [editByVim setKeyEquivalentModifierMask: NSControlKeyMask];
    
	[[editMenu submenu] addItem:editByVim];
    [editByVim release];

}

-(void)editByVim:(id)sender
{
    //call macvim
#if 0
    NSArray* args = [NSArray arrayWithObjects:@"--servername xcode4",
                    @"--remote-silent",
                    [NSString stringWithFormat:@"+%lld", g_currentLineNumber],
                    m_documentPath,nil ];
    
    [NSTask launchedTaskWithLaunchPath:@"/Applications/MacVim.app/Contents/MacOS/MacVim"
                             arguments:args];
#else
    NSString* args = [NSString
                       stringWithFormat:@"--servername xcode4 --remote-silent +%lld \"%@\"",
                       g_currentLineNumber, m_documentPath ];
   
    launch_cmd ( [args UTF8String] );
    
#endif
    
    NSLog (@"[run macvim:%@", args);
}

//Finding a Control
//
//So, let’s say that you want to write a plugin that manipulates some control 
//within your Xcode environment. How do you get a reference to that object? 
//Well firstly, you need to see what is available.
//One way is to get a reference to the root window and walk the window hierarchy 
//dumping controls as you go. A very simple implementation is to create a category on NSView like so:

-(void)dumpWindow:(id)sender
{
	[[[NSApp mainWindow] contentView] dumpWithIndent:@""];
}


@end
