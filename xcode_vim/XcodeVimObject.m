//
//  XcodeVimObject.m
//  xcode_vim
//
//  Created by FrankLiu on 13-8-24.
//  Copyright (c) 2013 chliu. All rights reserved.
//

#import "XcodeVimObject.h"
#import "XVimHookManager.h"

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
	NSLog (@"This is my vim Xcode plugin!");
    
	static dispatch_once_t onceToken;
	dispatch_once(&onceToken, ^{
		g_instance = [[self alloc] init];
        
        [ g_instance load];
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
        
        // Do the hooking after the App has finished launching,
        // Otherwise, we may miss some classes.
        
        // Command line window is not setuped if hook is too late.
        [XVimHookManager hookWhenPluginLoaded];
        
        NSNotificationCenter* notificationCenter = [NSNotificationCenter defaultCenter];
        [notificationCenter addObserver: [XVimHookManager class]
                               selector: @selector( hookWhenDidFinishLaunching )
                                   name: NSApplicationDidFinishLaunchingNotification
                                 object: nil];

        m_documentPath = nil;
    
        [self addMenuItems];
    
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
    NSArray* cmd = [NSArray arrayWithObjects:@"--servername xcode",
                    @"--remote-silent",
                    [NSString stringWithFormat:@"+%lld", g_currentLineNumber], m_documentPath,nil ];
    
    //NSLog (@"[run macvim:%@", cmd);
    
    [NSTask launchedTaskWithLaunchPath:@"/Applications/MacVim.app/Contents/MacOS/MacVim" arguments:cmd];

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
