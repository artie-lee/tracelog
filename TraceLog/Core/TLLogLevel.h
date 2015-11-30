/**
 *   TLLogLevel.h
 *
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
 *   Created by Tony Stone on 11/13/15.
 */
#import <Foundation/Foundation.h>

typedef NS_ENUM(NSInteger, LogLevel) {
    LogLevelInvalid = -1,
    LogLevelOff     = 0,
    LogLevelError   = 1,
    LogLevelWarning = 2,
    LogLevelInfo    = 3,
    LogLevelTrace1  = 4,
    LogLevelTrace2  = 5,
    LogLevelTrace3  = 6,
    LogLevelTrace4  = 7
};

NSArray * validLogLevelStrings();

LogLevel logLevelForString(NSString * logLevelString);
NSString * stringForLogLevel(LogLevel logLevel);