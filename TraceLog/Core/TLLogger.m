/**
 *   TLogger.m
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
#import "TLLogger.h"
#import "TLLogLevel.h"
#import "TLWriter.h"
#import "TLConsoleWriter.h"
#import "TLFilter.h"

static NSString * const ModuleLogName  = @"TraceLog";

static NSString * const LogScopeRegex = @"LOG_REGEX";

static NSString * const LogScopeTag    = @"LOG_TAG_";
static NSString * const LogScopePrefix = @"LOG_PREFIX_";
static NSString * const LogScopeAll    = @"LOG_ALL";

//
// Internal static data
//
static LogLevel       _globalLogLevel;
static NSDictionary * _loggedPrefixes;
static NSDictionary * _loggedTags;
static NSArray      * _logLevelFilters;

static NSMutableArray * _logWriters;
//
// Forward declarations
//
NSNumber * prefixLogLevelForTag(NSString * tag);

//
// Main implementation class
//
@implementation TLLogger

    + (void) initialize {

        if (self == [TLLogger class]) {
            //
            // Set the default level for initialization
            //
            _globalLogLevel  = LogLevelInfo;

            //
            // Now we must get the logWriters in place before continuing
            // in order to be able to log out initialization process.
            //
            _logWriters = [[NSMutableArray alloc] init];

            // Add the default console log writer
            _logWriters[0] = [[TLConsoleWriter alloc] init];

            //
            // If the system is enabled, we always print our initialization messages and errors.
            //
            [TLLogger logPrimitive: LogLevelInfo tag: ModuleLogName file: __FILE__ function: __FUNCTION__ lineNumber: __LINE__ message: ^{
                return [[NSMutableString alloc] initWithFormat: @"%@ is enabled, reading environment and configuring logging...", ModuleLogName];
            }];
            
            NSDictionary * environment = [[NSProcessInfo processInfo] environment];

            NSMutableDictionary * loggedPrefixes  = [[NSMutableDictionary alloc] init];
            NSMutableDictionary * loggedTags      = [[NSMutableDictionary alloc] init];
            NSMutableArray      * logLevelFilters = [[NSMutableArray alloc] init];
            
            for (NSString * variable in environment) {
                //
                // All variables and log level strings are converted
                // to upper case for comparison.
                //
                NSString * upperCaseVariable = [variable uppercaseString];

                if ([upperCaseVariable hasPrefix: LogScopeAll]) {
                    LogLevel requestedLogLevel = logLevelForString([environment[variable] uppercaseString]);
                    
                    if (requestedLogLevel != LogLevelInvalid) {
                        _globalLogLevel = requestedLogLevel;
                    } else {
                        [TLLogger logPrimitive: LogLevelError tag: ModuleLogName file: __FILE__ function: __FUNCTION__ lineNumber: __LINE__ message: ^{
                            return [NSString stringWithFormat: @"Variable '%@' has an invalid logLevel of '%@'. '%@' will be set to %@.", upperCaseVariable, environment[variable], LogScopeAll, stringForLogLevel(_globalLogLevel)];
                        }];
                    }
                    
                } else if ([upperCaseVariable hasPrefix: LogScopePrefix]) {
                    LogLevel requestedLogLevel = logLevelForString([environment[variable] uppercaseString]);
                    
                    if (requestedLogLevel != LogLevelInvalid) {
                        //
                        // Note: in order to allow for case sensitive tag prefix names, we use the variable instead of the uppercase version.
                        //
                        NSRange    logLevelScopeRange = [variable rangeOfString: LogScopePrefix];
                        NSString * logLevelScope      = [variable substringFromIndex: logLevelScopeRange.location + logLevelScopeRange.length];
                        
                        loggedPrefixes[logLevelScope] =  @(requestedLogLevel);
                    } else {
                        [TLLogger logPrimitive: LogLevelError tag: ModuleLogName file: __FILE__ function: __FUNCTION__ lineNumber: __LINE__ message: ^{
                            return [NSString stringWithFormat: @"Variable '%@' has an invalid logLevel of '%@'. '%@' will NOT be set.", upperCaseVariable, environment[variable], upperCaseVariable];
                        }];
                    }
                    
                } else if ([upperCaseVariable hasPrefix: LogScopeTag]) {
                    LogLevel requestedLogLevel = logLevelForString([environment[variable] uppercaseString]);
                    
                    if (requestedLogLevel != LogLevelInvalid) {
                        
                        //
                        // Note: in order to allow for case sensitive tag names, we use the variable instead of the uppercase version.
                        //
                        NSRange    logLevelScopeRange = [variable rangeOfString: LogScopeTag];
                        NSString * logLevelScope      = [variable substringFromIndex: logLevelScopeRange.location + logLevelScopeRange.length];
                        
                        loggedTags[logLevelScope]  = @(requestedLogLevel);
                    } else {
                        [TLLogger logPrimitive: LogLevelError tag: ModuleLogName file: __FILE__ function: __FUNCTION__ lineNumber: __LINE__ message: ^{
                            return [NSString stringWithFormat: @"Variable '%@' has an invalid logLevel of '%@'. '%@' will NOT be set.", upperCaseVariable, environment[variable], upperCaseVariable];
                        }];
                    }
                } else if ([upperCaseVariable hasPrefix: LogScopeRegex]) {
                    NSError * error = nil;
                    
                    NSArray * filters = [TLFilter filtersForPattern: environment[variable] error: &error];
                    
                    if (!error) {
                        [logLevelFilters addObjectsFromArray: filters];
                    } else {
                        NSArray * underlayingErrors = [error userInfo][TLFilterFailureReasonsErrorKey];
                        if (underlayingErrors) {
                            for (NSError * underlayingError in underlayingErrors) {
                                
                                [TLLogger logPrimitive: LogLevelError tag: ModuleLogName file: __FILE__ function: __FUNCTION__ lineNumber: __LINE__ message: ^{
                                    return [underlayingError localizedDescription];
                                }];
                            }
                        } else {
                            [TLLogger logPrimitive: LogLevelError tag: ModuleLogName file: __FILE__ function: __FUNCTION__ lineNumber: __LINE__ message: ^{
                                return [error localizedDescription];
                            }];
                        }
                    }
                }
            }
            _loggedPrefixes  = [[NSDictionary alloc] initWithDictionary: loggedPrefixes];
            _loggedTags      = [[NSDictionary alloc] initWithDictionary: loggedTags];
            _logLevelFilters = [[NSArray      alloc] initWithArray:      logLevelFilters];
            
            // Print the current configuration
            [TLLogger logPrimitive: LogLevelInfo tag: ModuleLogName file: __FILE__ function: __FUNCTION__ lineNumber: __LINE__ message: ^{
                return [NSString stringWithFormat: @"%@ has been configured with the following settings: \n%@", ModuleLogName, [TLLogger currentConfigurationString]];
            }];
        }
    }

    + (NSString *) currentConfigurationString {

        NSMutableString * loggedString = [[NSMutableString alloc] initWithString: @"{"];
        
        if ([_loggedTags count] > 0) {
            
            [loggedString appendString: @"\n\ttags: {\n"];
            
            for (NSString  * tag in [_loggedTags allKeys]) {
                NSString * logLevel = stringForLogLevel((LogLevel)[_loggedTags[tag] intValue]);
                
                [loggedString appendString: [[NSMutableString alloc] initWithFormat: @"\n%30s = %@", [tag UTF8String], logLevel]];
            }
            [loggedString appendString: @"\n\t}"];
        }
        
        if ([_loggedPrefixes count] > 0) {
            
            [loggedString appendString: @"\n\tprefix: {\n"];
            
            for (NSString  * prefix in [_loggedPrefixes allKeys]) {
                NSNumber  * logLevel = _loggedPrefixes[prefix];
                
                [loggedString appendString: [[NSMutableString alloc] initWithFormat: @"\n%30s = %@", [prefix UTF8String], stringForLogLevel((LogLevel)[logLevel intValue])]];
            }
            [loggedString appendString: @"\n\t}"];
        }
        if ([_logLevelFilters count] > 0) {
            
            [loggedString appendString: @"\n\tfilters: {\n"];
            
            for (TLFilter  * filter in _logLevelFilters) {
                
                [loggedString appendString: [filter description]];
            }
            [loggedString appendString: @"\n\t}"];
        }
        
        [loggedString appendFormat: @"\n\tglobal: {\n\n%30s = %@\n\t}\n}", "ALL", stringForLogLevel(_globalLogLevel)];
        
        return loggedString;
    }

    + (LogLevel) logLevelForContext: (NSString *) tag file: (const char *) file function: (const char *) function lineNumber: (NSUInteger) lineNumber message: (nonnull NSString * _Nullable (^) ()) message {
        
        // Set to the default global level first
        LogLevel level = _globalLogLevel;

        // Determine if there is a tag log level first
        NSNumber * tagLogLevel = _loggedTags[tag];
        
        if (tagLogLevel) {
            level = (LogLevel) [tagLogLevel intValue];
        } else {
            // Determine the prefixes log level if available
            NSNumber * prefixLogLevel = prefixLogLevelForTag(tag);

            if (prefixLogLevel) {
                level = (LogLevel) [prefixLogLevel intValue];
            }
        }

        return level;
    }

    + (BOOL) logLevelEnabled: (LogLevel) messageLevel context: (NSString *) tag file: (const char *) file function: (const char *) function lineNumber: (NSUInteger) lineNumber message: (nonnull NSString * _Nullable (^) ()) message {

        // Set to the default global level first
        LogLevel contextLevel = _globalLogLevel;

        // Determine if there is a tag log level first
        NSNumber * tagLogLevel = _loggedTags[tag];

        if (tagLogLevel) {
            contextLevel = (LogLevel) [tagLogLevel intValue];
        } else {
            // Determine the prefixes log level if available
            NSNumber * prefixLogLevel = prefixLogLevelForTag(tag);

            if (prefixLogLevel) {
                contextLevel = (LogLevel) [prefixLogLevel intValue];
            }
        }

        if (contextLevel < messageLevel) {

            for (TLFilter * filter in _logLevelFilters) {

                if (filter.logLevel > contextLevel) {
                    BOOL match = [filter matches:  tag file: [NSString stringWithUTF8String: file] function: [NSString stringWithUTF8String: function] line: @(lineNumber).stringValue message: message()];

                    if (match) {
                        contextLevel = filter.logLevel;
                    }
                }
            }
        }

        return contextLevel >= messageLevel;
    }

    + (void) logPrimitive: (LogLevel) level tag: (nonnull NSString *) tag file: (nonnull const char *) file function: (nonnull const char *) function lineNumber: (NSUInteger) lineNumber message: (nonnull NSString * _Nullable (^) ()) message {
       
        NSParameterAssert(level >= LogLevelOff && level <= LogLevelTrace4);

        if ([self logLevelEnabled: level context: tag file: file function: function lineNumber: lineNumber message: message]) {
            NSTimeInterval timestamp     = [NSDate timeIntervalSinceReferenceDate];
            NSString     * messageString = message();
            
            for (id <TLWriter> logWriter in _logWriters) {
                [logWriter log: timestamp level: level tag: tag message: messageString file: [NSString stringWithUTF8String: file] function: [NSString stringWithUTF8String: function] lineNumber: lineNumber];
            }
        }
    }

@end

//
// Low level C functions
//
NSNumber * prefixLogLevelForTag(NSString * tag) {

    for (NSString * prefix in [_loggedPrefixes allKeys]) {
        if ([tag hasPrefix: prefix]) {
            return _loggedPrefixes[prefix];
        }
    }
    return nil;
}



