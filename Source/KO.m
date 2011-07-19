#import <Cocoa/Cocoa.h>
#import <dispatch.h>

// Call this in -applicationDidFinishLaunching:
void KORegister() {
	// Trigger KO at some time in the future
}

// Scans over KO_CRASH_LOG_DIRECTORY for crash logs
static NSString *const KO_CRASH_LOG_DIRECTORY = @"~/Library/Logs/DiagnosticReports";
void KOScan() {
	
}

// Prompts the user for permission to submit the crash log, unless they've already given permission
void KOPrompt(NSArray *crashLogs) {
	
}

// Submits the crash log at `crashLog` to the server
void KOSubmit(NSURL *crashLog) {
	
}
