/**
 * $Id: BFXHalveAndAdd.h 30 2008-12-15 08:26:58Z btgiles $
 *
 * Copyright (C) 2008 Ben Giles
 * btgiles@gmail.com
 * bencode.googlecode.com
 *
 * Released under the GPL, Version 3
 * License available here: http://www.gnu.org/licenses/gpl.txt
 */
 
/*
	see BFXHalveAndAdd.m for info
*/

#import <Foundation/Foundation.h>
#import <FxPlug/FxPlugSDK.h>


@interface BFXHalveAndAdd : NSObject <FxTransition>
{
	// The cached API Manager object, as passed to the -initWithAPIManager: method.
	id			_apiManager;
}

@end
