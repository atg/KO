#import <Cocoa/Cocoa.h>
#import <dispatch/dispatch.h>

void KORegister();
BOOL KOPrompt(NSArray *crashLogs);
void KOSubmit(NSURL *crashLog);

// Call this in -applicationDidFinishLaunching:
// Scans over KO_CRASH_LOG_DIRECTORY for crash logs
void KORegister() {
	static NSString *const KO_CRASH_LOG_DIRECTORY = @"~/Library/Logs/DiagnosticReports";
	
	// Look at preferences, when did we last check?
	NSDate *lastChecked = [[NSUserDefaults standardUserDefaults] objectForKey:@"KOLastChecked"];

    [[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"KOLastChecked"];
    [[NSUserDefaults standardUserDefaults] synchronize];
	
	// If we've never checked before, then set the current date and stop
	if (!lastChecked) {
		return;
	}
	
	// Look in preferences to see if we should prompt
	__block NSInteger shouldPrompt = [[NSUserDefaults standardUserDefaults] integerForKey:@"KOShouldPrompt"];
    if (shouldPrompt <= -1)
		return;
	
	// Otherwise...
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW, 0), ^{

		NSString *directory = [KO_CRASH_LOG_DIRECTORY stringByExpandingTildeInPath];
		
		// Look in ~/Library/Logs/DiagnosticReports
		NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:directory error:NULL];
        if (![contents count])
			return;
		
		NSString *appName = [[NSRunningApplication currentApplication] localizedName];
		NSMutableArray *viablePaths = [NSMutableArray array];
		
		// Find any files that were created after the date we last checked
		for (NSString *subpath in contents) {
			// Make sure this is the right app
			if (![subpath hasPrefix:[NSString stringWithFormat:@"%@_", appName]])
				continue;
			
			// Get the date created
			NSString *path = [directory stringByAppendingPathComponent:subpath];

			NSDictionary *attrs = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:NULL];
			if (![attrs count])
				continue;
			
			NSDate *dcreated = [attrs objectForKey:NSFileCreationDate];
            
            if (!dcreated)
				continue;
			NSTimeInterval dcreatedt = [dcreated timeIntervalSinceReferenceDate];
			
			NSTimeInterval delta = [NSDate timeIntervalSinceReferenceDate] - dcreatedt;
			// Only prompt if the file was created _after_ we last checked, and it was created in the last 30 days
			if (dcreatedt > [lastChecked timeIntervalSinceReferenceDate] && dcreatedt > 1.0 && delta > 0.1 && delta < 30.0 * 24.0 * 60.0 * 60.0) 
			{
				[viablePaths addObject:path];
			}
		}
		        
		// No viable paths?
		if (![viablePaths count])
			return;
		
		// shouldPrompt == -1: never prompt, don't submit
		// shouldPrompt == 0: prompt
		// shouldPrompt == 1: never prompt, submit automatically
		
		// OK then, let's prompt
		if (shouldPrompt == 0 && !KOPrompt(viablePaths))
			return;
		
		// We don't want to prompt next time!
		shouldPrompt = 1;
		
		// We're still here. Excellent!
		for (NSString *crashLog in viablePaths) {
			KOSubmit([NSURL fileURLWithPath:crashLog isDirectory:NO]);
		}
	});
	
	
}

// Prompts the user for permission to submit the crash log, unless they've already given permission
BOOL KOPrompt(NSArray *crashLogs) {
	__block BOOL shouldSend = YES;
	
	// We also want to record if we should prompt in future
	dispatch_sync(dispatch_get_main_queue(), ^{
		
		NSInteger r = NSRunAlertPanel(@"Send crash report?", 
                                      @"Chocolat appears to have crashed the last time it was open.\nWould you like to send a crash report to the developers?\n\nCrash reports sent to Apple are not passed on to developers.",
                                      @"Send", @"Always Send", @"Don't Send");
		
		if (r == NSAlertDefaultReturn) {
			// Send
		}
		else if (r == NSAlertOtherReturn) {
			// Don't send
			shouldSend = NO;
		}
		else {
            // Always send
			[[NSUserDefaults standardUserDefaults] setInteger:1 forKey:@"KOShouldPrompt"];
			[[NSUserDefaults standardUserDefaults] synchronize];
		}		
	});
	
	return shouldSend;
}

// Submits the crash log at `crashLog` to the server
void KOSubmit(NSURL *crashLog) {
    NSURL *url = [NSURL URLWithString:[[[NSBundle mainBundle] infoDictionary] valueForKey:@"KOCrashReportServerURL"]];
    
	NSString *crashLogString = [NSString stringWithContentsOfURL:crashLog usedEncoding:NULL error:NULL];
	
	NSMutableDictionary *postItems = [NSMutableDictionary dictionary];
	[postItems setValue:@"crash" forKey:@"type"];
	[postItems setValue:[[NSRunningApplication currentApplication] localizedName] forKey:@"app"];
	[postItems setValue:[[[NSBundle mainBundle] infoDictionary] valueForKey:@"CFBundleVersion"] forKey:@"version"];
	[postItems setValue:[[NSNumber numberWithInteger:(NSInteger)[[NSDate date] timeIntervalSince1970]] stringValue] forKey:@"date"];
	[postItems setValue:crashLogString forKey:@"blob"];
	    
	NSMutableURLRequest *request = [[[NSMutableURLRequest alloc] init] autorelease];
	[request setURL:url];
	
	//POST
	NSMutableString *postString = [NSMutableString string];
	
	int i = 0;
	int postItemsCount = [postItems count];
	for (id key in postItems)
	{
		NSString *encodedValue = [NSMakeCollectable(CFURLCreateStringByAddingPercentEscapes(kCFAllocatorDefault, (CFStringRef)[postItems valueForKey:key], NULL, CFSTR("?=&+"), kCFStringEncodingUTF8)) autorelease];

		[postString appendFormat:@"%@=%@", key, encodedValue];
		
		if (i < postItemsCount - 1)
			[postString appendString:@"&"];
		i++;
	}
	
	NSData *postData = [postString dataUsingEncoding:NSUTF8StringEncoding];
	NSString *postLength = [NSString stringWithFormat:@"%d", [postData length]];
	
	[request setHTTPMethod:@"POST"];
	[request setValue:postLength forHTTPHeaderField:@"Content-Length"];
	[request setHTTPBody:postData];
	
	[NSURLConnection sendSynchronousRequest:request returningResponse:nil error:nil];
}
