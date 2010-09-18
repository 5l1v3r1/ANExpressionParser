//
//  ANEPExpression.m
//  ExpressionParser
//
//  Created by Alex Nichol on 9/17/10.
//  Copyright 2010 __MyCompanyName__. All rights reserved.
//

#import "ANEPExpression.h"


@implementation ANEPExpression
- (void)runOperations:(char)op alt:(char)alt {
	for (int i = 0; i < [subcomponents count]; i += 2) {
		// generate number
		if (i + 2 < [subcomponents count]) {
			ANEPNumber * number1 = [subcomponents objectAtIndex:i];
			ANEPOperator * operator = [subcomponents objectAtIndex:i+1];
			ANEPNumber * number2 = [subcomponents objectAtIndex:i+2];
			if ([number2 respondsToSelector:@selector(doubleValue)]) {
				if ([operator respondsToSelector:@selector(applyNumber:toNumber:)]) {
					if ([operator character] == op || [operator character] == alt) {
						ANEPNumber * num = [operator applyNumber:number2 toNumber:number1];
						[subcomponents removeObjectAtIndex:i+2];
						[subcomponents removeObjectAtIndex:i+1];
						[subcomponents removeObjectAtIndex:i];
						[subcomponents insertObject:num atIndex:i];
						i -= 2;
					}
				}
			}
		}
	}
}
- (ANEPNumber *)numberValue {
	// calculate number
	if (!subcomponents || [subcomponents count] <= 0) {
		return [ANEPNumber numberWithDouble:0];
	}
	[self runOperations:'*' alt:'/'];
	[self runOperations:'+' alt:'-'];
	
	return [subcomponents objectAtIndex:0];
}
- (ANEPOperator *)operatorForChar:(char)c {
	return [ANEPOperator operatorWithCharacter:c];
}
+ (ANEPExpression *)readExpression:(NSString *)str fromIndex:(int *)j variables:(NSArray *)vars {
	// process sub-expression
	NSMutableString * substr = [[[NSMutableString alloc] init] autorelease];
	int count = 1;
	for (j[0] = j[0] + 1; j[0] < [str length]; j[0] = j[0] + 1) {
		char c1 = [str characterAtIndex:j[0]];
		if (c1 == '(') count++;
		if (c1 == ')') count--;
		if (count <= 0) break;
		[substr appendFormat:@"%c", c1];
	}
	ANEPExpression * subexpr = [ANEPExpression expressionFromString:substr variables:vars];
	return subexpr;
}
+ (ANEPNumber *)readNumber:(NSString *)str fromIndex:(int *)j {
	NSMutableString * digitString = [NSMutableString new];
	for (j = j; j[0] < [str length]; j[0] = j[0] + 1) {
		char t = [str characterAtIndex:j[0]];
		if (!isdigit(t) && t != '.') {
			break;
		} else {
			[digitString appendFormat:@"%c", t];
		}
	}
	j[0] -= 1;
	return [ANEPNumber numberWithDouble:[[digitString autorelease] doubleValue]];
}
+ (ANEPVariable *)variableOfName:(NSString *)name fromArray:(NSArray *)vars {
	ANEPVariable * ret = nil;
	for (int j = 0; j < [vars count]; j++) {
		ANEPVariable * var = [vars objectAtIndex:j];
		if ([var variableName] == [name characterAtIndex:0]) {
			ret = var;
			break;
		}
	}
	return ret;
}
- (id)initWithExpression:(NSString *)str variables:(NSArray *)vars {
	if (self = [super init]) {
		subcomponents = [[NSMutableArray alloc] init];
		// loop through keywords
		BOOL lastWasNumber;
		for (int i = 0; i < [str length]; i++) {
			char c = [str characterAtIndex:i];
			ANEPOperator * operator = [self operatorForChar:c]; 
			if (!isblank((int)c)) {
				if (c == '(') {
					// process sub-expression
					
					ANEPExpression * subexpr = [ANEPExpression readExpression:str fromIndex:&i variables:vars];
					if (lastWasNumber) {
						// assume multiplication
						[subcomponents addObject:[ANEPOperator operatorWithCharacter:'*']];
					}
					if (subexpr) [subcomponents addObject:[subexpr numberValue]];
					if (subexpr) lastWasNumber = YES;
				} else if (c == ')') {
					NSLog(@"Invalid expression.");
					return nil;
				} else if (isdigit(c)) {
					ANEPNumber * _number = [ANEPExpression readNumber:(NSString *)str fromIndex:&i];
					if (_number) [subcomponents addObject:_number];
					lastWasNumber = YES;
				} else if (operator != nil) {
					[subcomponents addObject:operator];
					lastWasNumber = NO;
				} else if (isascii(c)) {
					lastWasNumber = NO;
					// either a variable or a function mame
					NSMutableString * functionName = [[NSMutableString new] autorelease];
					for (i = i; i < [str length]; i++) {
						if (!isalnum([str characterAtIndex:i]) || isblank([str characterAtIndex:i]) || isdigit([str characterAtIndex:i])) {
							i--;
							break;
						} else [functionName appendFormat:@"%c", [str characterAtIndex:i]];
					}
					if ([functionName length] == 1) {
						// it's a variable
						ANEPVariable * variable = nil;
						if (vars) {
							variable = [ANEPExpression variableOfName:functionName fromArray:vars];
						}
						lastWasNumber = NO;
						if (variable) {
							[subcomponents addObject:[variable number]];
							lastWasNumber = YES;
						}
						else return nil;
					} else {
						i ++;
						ANEPExpression * expr = [ANEPExpression readExpression:str fromIndex:&i variables:vars];
						ANEPNumber * numbr = [ANEPFunction applyFunction:functionName toNumber:[expr numberValue]];
						[subcomponents addObject:numbr];
						lastWasNumber = YES;
					}
				}
			}
		}
	}
	return self;
}
- (id)initWithNumber:(ANEPNumber *)_number {
	if (self = [super init]) {
		number = [_number retain];
	}
	return self;
}
+ (ANEPExpression *)expressionWithNumber:(ANEPNumber *)_number {
	return [[[ANEPExpression alloc] initWithNumber:_number] autorelease];
}
+ (ANEPExpression *)expressionFromString:(NSString *)str variables:(NSArray *)vars {
	return [[[ANEPExpression alloc] initWithExpression:str variables:vars] autorelease];
}
- (id)description {
	NSMutableString * str = [NSMutableString new];
	for (int i = 0; i < [subcomponents count]; i++) {
		[str appendFormat:@"%@ ", [[subcomponents objectAtIndex:i] description]];
	}
	return [str autorelease];
}
- (void)dealloc {
	[subcomponents release];
	[number release];
	[super dealloc];
}
@end