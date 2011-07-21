#import <Cocoa/Cocoa.h>
#import <dispatch.h>

// Call this in -applicationDidFinishLaunching:
// Scans over KO_CRASH_LOG_DIRECTORY for crash logs
void KORegister() {
	static NSString *const KO_CRASH_LOG_DIRECTORY = @"~/Library/Logs/DiagnosticReports";
	
	// Look at preferences, when did we last check?
	NSDate *lastChecked = [[NSUserDefaults standardUserDefaults] objectForKey:@"KOLastChecked"];
	
	// If we've never checked before, then set the current date and stop
	if (!lastChecked) {
		[[NSUserDefaults standardUserDefaults] setObject:[NSDate date] forKey:@"KOLastChecked"];
		return;
	}
	
	// Otherwise...
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 4), dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_LOW), ^{
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
			
			NSDate *dcreated = [attrs objectForKey:];
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
		
		// Look in preferences to see if we should prompt
		BOOL shouldPrompt = ...;
		
		// OK then, let's prompt
		if (shouldPrompt && !KOPrompt(viablePaths))
			return;
		
		// We're still here. Excellent!
		for (NSString *crashLog in viablePaths) {
			KOSubmit(crashLog);
		}
	});
	
	
}

// Prompts the user for permission to submit the crash log, unless they've already given permission
BOOL KOPrompt(NSArray *crashLogs) {
	// We also want to record if we should prompt in future
	dispatch_sync(dispatch_get_main_queue(), ^{
		
	});
}

// Submits the crash log at `crashLog` to the server
void KOSubmit(NSURL *crashLog) {
	
}
