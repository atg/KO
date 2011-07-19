# KO — The Crash Report Reporter

KO is a small Cocoa library that scans the user's crash reports directory at startup. If it finds new crash reports, it offers to submit them to the developers' server.

### Usage

#### Client

1. Add KO.m to your project/target.
2. In your Info.plist, add a key pair: `KOCrashReportServerURL` where the value is the URL where the KO crash report handler is located. E.g `http://example.com/ko/submit.php`.
3. In your `-applicationDidFinishLaunching:` method, add a call to `KORegister();`.

#### Server

1. Copy `submit.php` to your server.
2. Modify `submit.php` with credentials to your database. I strongly recommend that you create a special, restricted user account just for KO, that is only permitted to do SQL `INSERTs`. Also you should create a randomly generated password, and restrict the account to localhost (if possible).

I won't tell you how to retrive the crash reports from the server, that's up to you :).

### License

KO is so simple I hardly consider it copyrightable. But since people invariably ask about this sort of thing, KO is licensed under the [WTFPL](http://sam.zoy.org/wtfpl/).
