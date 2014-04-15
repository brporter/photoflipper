//
//  ViewController.m
//  Photobook
//
//  Created by Bryan Porter on 4/10/14.
//  Copyright (c) 2014 Bryan Porter. All rights reserved.
//

#import "ViewController.h"

@interface ViewController ()

@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
	// Do any additional setup after loading the view, typically from a nib.
    self.activityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
    self.currentImageIndex = -1;

    UISwipeGestureRecognizer *leftSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(leftSwipe:)];
    UISwipeGestureRecognizer *rightSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(rightSwipe:)];
    
    UISwipeGestureRecognizer *logoutSwipe = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(showLogOutButton:)];
    [logoutSwipe setDirection:UISwipeGestureRecognizerDirectionDown];
    [logoutSwipe setNumberOfTouchesRequired:2];
    
    [leftSwipe setDirection:UISwipeGestureRecognizerDirectionLeft];
    [rightSwipe setDirection:UISwipeGestureRecognizerDirectionRight];
    
    [[self imageView] addGestureRecognizer:leftSwipe];
    [[self imageView] addGestureRecognizer:rightSwipe];
    [[self imageView] addGestureRecognizer:logoutSwipe];
    
    [[self imageView] setUserInteractionEnabled:YES];
    [[self imageView] setHidden:true];
    
    [self setLoginView:[[FBLoginView alloc] initWithReadPermissions:@[@"basic_info",@"friends_photos"]]];
    [self.loginView setDelegate:self];
    [self.loginView setTranslatesAutoresizingMaskIntoConstraints:false];
    
    [self.view addSubview:self.loginView];
    
    // Center the FBLogin button
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.loginView attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.f constant:0.f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.loginView attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.f constant:0.f]];
    
    [self.activityIndicator setTranslatesAutoresizingMaskIntoConstraints:false];
    [self.view addSubview:[self activityIndicator]];
    
    // Center the Activity Indicator
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.activityIndicator attribute:NSLayoutAttributeCenterX relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterX multiplier:1.f constant:0.f]];
    [self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.activityIndicator attribute:NSLayoutAttributeCenterY relatedBy:NSLayoutRelationEqual toItem:self.view attribute:NSLayoutAttributeCenterY multiplier:1.f constant:0.f]];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

// receive notification when the user logs in
-(void)loginViewShowingLoggedInUser:(FBLoginView *)loginView
{
    // hide the login button
    [loginView setHidden:true];
    [loginView removeFromSuperview];
    [self.imageView setHidden:false];
    
    self.imageUrls = [[NSArray alloc] init];
    
    // Fetch Hoelzers photos
    // Like a boss
    
    [self nextImage];
    
}


-(void)requestImages:(RequestImageType)type {
    [self showLoading];
    
    NSString * requestUrl;
    
    if (type == RequestImageTypeNext) {
        requestUrl = [self nextUrl] == nil ? @"bill.hoelzer/photos" : [self nextUrl];
    } else if (type == RequestImageTypePrev) {
        requestUrl = [self prevUrl] == nil ? @"bill.hoelzer/photos" : [self prevUrl];
    }
    
    [FBRequestConnection startWithGraphPath:requestUrl completionHandler:^(FBRequestConnection *connection, id result, NSError *error) {
        if (!error) {
            // Process the requested data and set our image url to the result
            [self setImageUrls:[self generateImageUrls:result]];
            [self setNextUrl:[self generateNextUrl:result]];
            [self setPrevUrl:[self generatePrevUrl:result]];
            
            [self setCurrentImageIndex:0]; // reset our image index
            
            [self hideLoading];
            
            [self showImage:self.currentImageIndex];
        }
    }
    ];
}

-(void)nextImage {
    if ((self.currentImageIndex + 1) < [[self imageUrls] count]) {
        [self setCurrentImageIndex:++self.currentImageIndex];
        
        [self showImage:self.currentImageIndex];
    } else {
        [self requestImages:RequestImageTypeNext];
    }
}

-(void)previousImage {
    if (self.currentImageIndex > 0) {
        [self setCurrentImageIndex:--self.currentImageIndex];
    }
    
    [self showImage:self.currentImageIndex];
}

-(void)showImage:(int)imageIndex {
    [self showLoading];
    
    NSString * photoUrl = [self imageUrls][imageIndex];
    
    NSLog(@"Image URL: %@", photoUrl);
    
    // TODO: cache these!
    UIImage* imageFromUrl = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:photoUrl]]];
    
    [UIView transitionWithView:self.imageView duration:1.0f options:UIViewAnimationOptionTransitionCrossDissolve animations:^{ self.imageView.image = imageFromUrl; } completion:nil];
    
    //[[self imageView] setImage:imageFromUrl];
    
    [self hideLoading];
}

-(void)showLoading {
    [self.view bringSubviewToFront:[self activityIndicator]];
    
    [self.activityIndicator setHidden:false];
    [self.activityIndicator startAnimating];
}

-(void)hideLoading {
    [self.activityIndicator stopAnimating];
    [self.activityIndicator setHidden:true];
}

-(NSArray*)generateImageUrls:(id)photoAlbumData {
    // process the passed photoAlbumData object, generating a list of URL and sticking them
    // in the passed urlArray object
    
    NSMutableArray * photoUrls = [[NSMutableArray alloc] init];
    
    for (int dataItemIndex = 0; dataItemIndex < [photoAlbumData[@"data"] count]; dataItemIndex++) {
        
        NSString * photoUrl;
        
        // Make sure there are images in this data item :)
        if ([photoAlbumData[@"data"][dataItemIndex][@"images"] count] > 0)
        {
            // take the first image
            photoUrl = photoAlbumData[@"data"][dataItemIndex][@"images"][0][@"source"];
            [photoUrls addObject:photoUrl];
        }
    }
    
    return [photoUrls copy];
}

-(NSString*)generateNextUrl:(id)photoAlbumData {
    NSString* url = [photoAlbumData[@"paging"][@"next"] stringByReplacingOccurrencesOfString:@"https://graph.facebook.com/" withString:@""];
    
    return url;
}

-(NSString*)generatePrevUrl:(id)photoAlbumData {
    NSString* url = [photoAlbumData[@"paging"][@"previous"] stringByReplacingOccurrencesOfString:@"https://graph.facebook.com/" withString:@""];
    
    return url;
}


- (IBAction)leftSwipe:(id)sender {
    [self nextImage];
}

- (IBAction)rightSwipe:(id)sender {
    [self previousImage];
}

- (IBAction)showLogOutButton:(id)sender {
    [self.loginView setHidden:false];
    [self.imageView setHidden:true];
    
    [self.view addSubview:[self loginView]];
}

// Handle errors making login requests / invalidated session requests
-(void)loginView:(FBLoginView *)loginView handleError:(NSError *)error {
    // Show login button in case of any error - overly simplistic
    // TODO: handle the various possible error cases explicitly here
    [loginView setHidden:false];
    
    [self.view addSubview:loginView];
    [self.imageView setHidden:true];
}

@end
