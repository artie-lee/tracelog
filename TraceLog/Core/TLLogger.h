/**
 *   TLogger.h
 *
 *   Copyright 2015 The Climate Corporation
 *   Copyright 2015 Tony Stone
 *
 *   Licensed under the Apache License, Version 2.0 (the "License");
 *   you may not use this file except in compliance with the License.
 *   You may obtain a copy of the License at
 *
 *   http://www.apache.org/licenses/LICENSE-2.0
 *
 *   Unless required by applicable law or agreed to in writing, software
 *   distributed under the License is distributed on an "AS IS" BASIS,
 *   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *   See the License for the specific language governing permissions and
 *   limitations under the License.
 *
 *   Created by Tony Stone on 3/4/15.
 */
#import <Foundation/Foundation.h>
#import "TLLogLevel.h"

/*
  WARNING:  This is a private file and nothing
  in this file should be used on it's own.  Please
  see TraceLog.h for the public interface to this.
*/

@interface TLLogger : NSObject

    //  Set the log writers to use for output.
    + (void) setWriters: (nonnull NSArray *) writers;

    // NOTE: Do not call this directly, please use the macros for all calls.
    + (void) logPrimitive: (LogLevel) level tag: (nonnull NSString *) tag file: (nonnull const char *) file function: (nonnull const char *) function lineNumber: (NSUInteger) lineNumber message: (nonnull NSString * _Nullable (^)()) message;
@end

#if DEBUG || TRACELOG_ENABLE
    #define LogIfEnabled(logLevel,tagName,format,...) [TLLogger logPrimitive: logLevel tag: tagName file: __FILE__ function: __FUNCTION__ lineNumber: __LINE__ message: ^{ return [NSString stringWithFormat: format, ##__VA_ARGS__]; }]
#else
    #define LogIfEnabled(logLevel,label, format, ...) ((void)0)
#endif
