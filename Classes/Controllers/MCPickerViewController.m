/*
 Copyright (c) 2009 Jelle Vandebeeck, Simon Schoeters
 
 Permission is hereby granted, free of charge, to any person
 obtaining a copy of this software and associated documentation
 files (the "Software"), to deal in the Software without
 restriction, including without limitation the rights to use,
 copy, modify, merge, publish, distribute, sublicense, and/or sell
 copies of the Software, and to permit persons to whom the
 Software is furnished to do so, subject to the following
 conditions:
 
 The above copyright notice and this permission notice shall be
 included in all copies or substantial portions of the Software.
 
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
 EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
 OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
 NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
 HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
 WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
 FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
 OTHER DEALINGS IN THE SOFTWARE.
 
 Created by Jelle Vandebeeck on 2009.07.25.
*/

#import <Twitter/Twitter.h>

#import "MCPickerViewController.h"
#import "MCBlend.h"
#import "MCAvailableBlendsViewController.h"

static BOOL accelerationIsShaking(UIAcceleration* last, UIAcceleration* current, double threshold) {
	double deltaX = fabs(last.x - current.x);
	double deltaY = fabs(last.y - current.y);
	double deltaZ = fabs(last.z - current.z);
	return (deltaX > threshold && deltaY > threshold) || (deltaX > threshold && deltaZ > threshold) || (deltaY > threshold && deltaZ > threshold);
}

@implementation MCPickerViewController

@synthesize lastAcceleration;
@synthesize blendController;

#pragma mark Overriden methods

- (void)loadView {
	[super loadView];
	
	pickerView = [[MCPickerView alloc] initWithFrame:[[UIScreen mainScreen] applicationFrame]];
	pickerView.delegate = self;
	[pickerView viewsHidden:YES];
    
    UITapGestureRecognizer *_tapGesture = [[[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(doubleTap:)] autorelease];
    _tapGesture.numberOfTapsRequired = 2;
    [pickerView addGestureRecognizer:_tapGesture];
	
	firstScreenLoad = YES;
	[self loadPreferences];
	
	[self setView:pickerView];
}

- (void)viewWillAppear:(BOOL)animated {
	blends = [blendController yourBlends];
}

- (void)viewDidAppear:(BOOL)animated {
	if (firstScreenLoad) {
		[NSThread detachNewThreadSelector:@selector(postponedRefresh) toTarget:self withObject:nil];
		firstScreenLoad = NO;
	}
}

- (void)doubleTap:(UITapGestureRecognizer *)gesture {
    TWTweetComposeViewController *_twitter = [[TWTweetComposeViewController alloc] init];
    
    [_twitter addURL:[NSURL URLWithString:@"http://fousa.github.com/7am"]];
    [_twitter setInitialText:[NSString stringWithFormat:@"Drinking a Nespresso %@!", pickerView.blend.name]];
    
    // Show the controller
    [self presentModalViewController:_twitter animated:YES];
    
    // Called when the tweet dialog has been closed
    _twitter.completionHandler = ^(TWTweetComposeViewControllerResult result) {
        NSString *title = @"Twitter";
        NSString *message; 
        
        if (result == TWTweetComposeViewControllerResultCancelled)
            message = @"You won't be tweeting this...";
        else if (result == TWTweetComposeViewControllerResultDone)
            message = @"Enjoy your coffee!";
        
        // Show alert to see how things went...
        UIAlertView* alertView = [[UIAlertView alloc] initWithTitle:title message:message delegate:self cancelButtonTitle:@"Ok" otherButtonTitles:nil];
        [alertView show];
        
        // Dismiss the controller
        [self dismissModalViewControllerAnimated:YES];
    };
}

- (void)dealloc {
	[lastAcceleration dealloc];
	[blends dealloc];
	[pickerView dealloc];
	[super dealloc];
}

#pragma mark Delegate methods for MCPickerView

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
	if (!histeresisExcited) {
		histeresisExcited = YES;
		[self refresh];
	}
}

- (void)animationDidStop:(NSString *)animationID finished:(NSNumber *)finished context:(void *)context {
	histeresisExcited = NO;
}

#pragma mark UIAccelerometerDelegate

- (void)accelerometer:(UIAccelerometer *)accelerometer didAccelerate:(UIAcceleration *)acceleration { 
	if (shakingEnabled) {
		if (self.lastAcceleration) {
			if (!histeresisExcited && accelerationIsShaking(self.lastAcceleration, acceleration, 0.7)) {
				histeresisExcited = YES;
				[self refresh];
			}
		}
		self.lastAcceleration = acceleration;
	}
}

#pragma mark Personal methods

- (void)refresh {
	int number = (arc4random() % [blends count]);
	MCBlend *blend = (MCBlend *) [blends objectAtIndex:number];
	pickerView.blend = blend;
	
	[pickerView viewsHidden:NO];
	[pickerView flipView];
}

- (void)loadBlendSelection {
	MCAvailableBlendsViewController *availableBlendsController = [[[MCAvailableBlendsViewController alloc] init] autorelease];
	availableBlendsController.blendController = blendController;
	UINavigationController *blendsNavigationController = [[UINavigationController alloc] initWithRootViewController:availableBlendsController];
	[self.navigationController presentModalViewController:blendsNavigationController animated:YES];
}

- (void)postponedRefresh {
	NSCondition *condition = [[NSCondition alloc] init];
	[condition waitUntilDate:[NSDate dateWithTimeIntervalSinceNow:0.5]];
	[self refresh];
}

- (void)loadPreferences {
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	shakingEnabled = [defaults boolForKey:@"shaking"];
}

@end

