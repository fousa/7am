//
//  main.m
//  SevenAm
//
//  Created by Jelle Vandebeeck on 18/07/09.
//  Creative commons milkcarton 2009. Some rights reserved.
//

#import <UIKit/UIKit.h>

int main(int argc, char *argv[]) {
    
    NSAutoreleasePool * pool = [[NSAutoreleasePool alloc] init];
    int retVal = UIApplicationMain(argc, argv, nil, @"SevenAmAppDelegate");
    [pool release];
    return retVal;
}