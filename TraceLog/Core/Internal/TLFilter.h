/**
 *   TLFilter.h
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
 *   Created by Tony Stone on 11/28/15.
 */
#import <Foundation/Foundation.h>
#import "TLLogLevel.h"

extern NSString  * _Nonnull TLFilterFailureReasonsErrorKey;

@interface TLFilter : NSObject

    + (nullable NSArray *) filtersForPattern: (nonnull NSString *) pattern;
    + (nullable NSArray *) filtersForPattern: (nonnull NSString *) pattern error: (NSError * _Nullable * _Nullable) resultError ;

    - (nonnull NSRegularExpression *) regex;
    - (nonnull NSArray *)             targets;
    - (LogLevel)                      logLevel;

    - (LogLevel) filteredLevelForTag: (nonnull NSString *) tag file: (nonnull NSString *) file function: (nonnull NSString *) function line: (nonnull NSString *) line message: (nonnull NSString *) message;
    - (BOOL) matches: (nonnull NSString *) tag file: (nonnull NSString *) file function: (nonnull NSString *) function line: (nonnull NSString *) line message: (nonnull NSString *) message;

@end
