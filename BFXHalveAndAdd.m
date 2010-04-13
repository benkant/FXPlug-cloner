/**
 * $Id: BFXHalveAndAdd.m 30 2008-12-15 08:26:58Z btgiles $
 *
 * Copyright (C) 2008 Ben Giles
 * btgiles@gmail.com
 * bencode.googlecode.com
 *
 * Released under the GPL, Version 3
 * License available here: http://www.gnu.org/licenses/gpl.txt
 */
 
/*
	This FxPlug Transition plug-in for Final Cut creates a "cloning" effect.
	The pixels from the two frames are added, and the plate image is subtracted.

	Note that the image must be RAW RGB bytes.
*/

#import "BFXHalveAndAdd.h"

#import <FxPlug/FxPlugSDK.h>
#import <stdio.h>

@implementation BFXHalveAndAdd

// our raw plate image
UInt8 dataPlate[720*576*3];

// parameter
#define kPlateLocation	1

//---------------------------------------------------------
// initWithAPIManager:
//
// This method is called when a plug-in is first loaded, and
// is a good point to conduct any checks for anti-piracy or
// system compatibility. Returning NULL means that a plug-in
// chooses not to be accessible for some reason.
//---------------------------------------------------------

- (id)initWithAPIManager:(id)apiManager;
{
	_apiManager = apiManager;
	
	return self;
}

//---------------------------------------------------------
// dealloc
//
// Override of standard NSObject dealloc. Called when plug-in
// instance is deallocated.
//---------------------------------------------------------

- (void)dealloc
{
	// Deallocate members here.
	
	[super dealloc];
}

//---------------------------------------------------------
// properties
//
// This method should return an NSDictionary defining the
// properties of the effect.
//---------------------------------------------------------

- (NSDictionary *)properties
{
	return [NSDictionary dictionaryWithObjectsAndKeys:
				[NSNumber numberWithBool: YES], kFxPropertyKey_SupportsRowBytes,
				[NSNumber numberWithBool: NO], kFxPropertyKey_SupportsR408,
				[NSNumber numberWithBool: NO], kFxPropertyKey_SupportsR4fl,
				[NSNumber numberWithBool: NO], kFxPropertyKey_MayRemapTime,
				[NSNumber numberWithInt:2], kFxPropertyKey_EquivalentSMPTEWipeCode,
				NULL];
}

//---------------------------------------------------------
// variesOverTime
//
// This method should return YES if the plug-in's output can
// vary over time even when all of its parameter values remain
// constant. Returning NO means that a rendered frame can be
// cached and reused for other frames with the same parameter
// values.
//---------------------------------------------------------

- (BOOL)variesOverTime
{
	return YES;
}

//---------------------------------------------------------
// addParameters
//
// This method is where a plug-in defines its list of parameters.
//---------------------------------------------------------

- (BOOL)addParameters
{
	id parmsApi;

	parmsApi = [_apiManager apiForProtocol:@protocol(FxParameterCreationAPI)];

	if ( parmsApi != NULL )
	{
		[parmsApi addStringParameterWithName:@"RAW plate image path"
									  parmId:kPlateLocation
								defaultValue:@""
								   parmFlags:kFxParameterFlag_NOT_ANIMATABLE];
		return YES;
	}
	else
		return NO;
}

//---------------------------------------------------------
// parameterChanged:
//
// This method will be called whenever a parameter value has changed.
// This provides a plug-in an opportunity to respond by changing the
// value or state of some other parameter.
//---------------------------------------------------------

- (BOOL)parameterChanged:(UInt32)parmId
{
	return YES;
}

//---------------------------------------------------------
// getOutputWidth:height:withInputA:withInputB:withTimeFraction:withInfo:
//
// This is where a transition defines the width and height of
// its output, given a description of its input.
//---------------------------------------------------------

- (BOOL)getOutputWidth:(UInt32 *)width
				height:(UInt32 *)height
			withInputA:(FxImageInfo)inputInfoA
			withInputB:(FxImageInfo)inputInfoB
	  withTimeFraction:(float)timeFraction
			  withInfo:(FxRenderInfo)renderInfo
{
	*height = 576;
	*width = 720;
	return YES;
	/*if ( width != NULL && height != NULL )
	{
		*width	= MAX(inputInfoA.width, inputInfoB.width);
		*height = MAX(inputInfoA.height, inputInfoB.height);
		return YES;
	}
	else
		return NO;
		*/
}

//---------------------------------------------------------
// renderOutput:withInputA:withInputB:withTimeFraction:withInfo:
//
// This method renders the plug-in's output into the given
// destination, using the given FxImage object as its image
// input, with the given render options. The plug-in may
// retrieve parameters as needed here, using the appropriate
// host APIs. The output image will either be an FxBitmap
// or an FxTexture, depending on the plug-in's capabilities,
// as declared in the frameSetup:hardware:software: method.
//---------------------------------------------------------

- (BOOL)renderOutput:(FxImage *)outputImage
		  withInputA:(FxImage *)inputImageA
		  withInputB:(FxImage *)inputImageB
	withTimeFraction:(float)timeFraction
			withInfo:(FxRenderInfo)renderInfo
{
	BOOL retval = YES;
	id parmsApi;
	static NSString *previousPlate = nil;
	NSString *plateLocation = nil;
	
	parmsApi = [_apiManager apiForProtocol:@protocol(FxParameterRetrievalAPI)];
	
	if ( parmsApi != NULL )
	{
		if ( [inputImageA imageType] == kFxImageType_TEXTURE )
		{
			// We don't do hardware
		}
		else if ( [inputImageA imageType] == kFxImageType_BITMAP )
		{
			FxBitmap *outBM = (FxBitmap *) outputImage;
			FxBitmap *inBMA = (FxBitmap *) inputImageA;
			FxBitmap *inBMB = (FxBitmap *) inputImageB;
			
			// WHAT THE FUCK. outBM height is somehow half what it should be.
			// so for now just double it.
			int height = [outBM height] * 2;
			int width = [outBM width];
			
			UInt8 *inDataA = (UInt8 *)[inBMA dataPtr];
			UInt8 *inDataB = (UInt8 *)[inBMB dataPtr];
			UInt8 *outData = (UInt8 *)[outBM dataPtr];
			
			// get the RAW plate image location
			[parmsApi getStringParameterValue:&plateLocation
									 fromParm:kPlateLocation];
			
			// check we have a plate
			if (plateLocation == @"") {
				return NO;
			}
			
			if (previousPlate != plateLocation) {
				// load the sucka
				FILE *fp;
				const char *path = [plateLocation UTF8String];
				fp = fopen(path, "rb");
				if (!fp) {
					return NO;
				}
				fread(dataPlate, width*height*3, 1, fp);
				fclose(fp);
			}
			
			UInt8 *platePointer = dataPlate;
			
			int x, y;
			for (x = 0; x < width; x++)
			{
				for (y = 0; y < height; y++)
				{
					UInt16 a_a = *inDataA++;
					UInt16 r_a = *inDataA++;
					UInt16 g_a = *inDataA++;
					UInt16 b_a = *inDataA++;
					
					UInt16 a_b = *inDataB++;
					UInt16 r_b = *inDataB++;
					UInt16 g_b = *inDataB++;
					UInt16 b_b = *inDataB++;
					
					int a, r, g, b;
					a = (a_a + a_b) / 2;
					if (a > 255) {
						a = 255;
					}
					r = (r_a + r_b) - *(platePointer++);
					if (r < 0) {
						r = 0;
					}
					if (r > 255) {
						r = 255;
					}
					g = (g_a + g_b) - *(platePointer++);
					if (g < 0) {
						g = 0;
					}
					if (g > 255) {
						g = 255;
					}
					b = (b_a + b_b) - *(platePointer++);
					if (b < 0) {
						b = 0;
					}
					if (b > 255) {
						b = 255;
					}
					*outData++ = a;
					*outData++ = r;
					*outData++ = g;
					*outData++ = b;
				}
			}
			retval = YES;
		}
		else
			retval = NO;
	}
	else
		retval = NO;

	// save the plate away for later so we don't re-read the file
	// if we don't have to.
	previousPlate = plateLocation;
	return retval;
}

//---------------------------------------------------------
// frameSetup:inputInfoA:inputInfoB:timeFraction:hardware:software:
//
// This method will be called before the host app sets up a
// render. A plug-in can indicate here whether it supports
// CPU (software) rendering, GPU (hardware) rendering, or
// both.
//---------------------------------------------------------

- (BOOL)frameSetup:(FxRenderInfo)renderInfo
		inputInfoA:(FxImageInfo)inputInfoA
		inputInfoB:(FxImageInfo)inputInfoB
	  timeFraction:(float)timeFraction
		  hardware:(BOOL *)canRenderHardware
		  software:(BOOL *)canRenderSoftware
{
	*canRenderSoftware = YES;
	*canRenderHardware = NO;

	return YES;
}

//---------------------------------------------------------
// frameCleanup
//
// This method is called when the host app is done with a frame.
// A plug-in may release any per-frame retained objects
// at this point.
//---------------------------------------------------------

- (BOOL)frameCleanup
{
	return YES;
}

@end
