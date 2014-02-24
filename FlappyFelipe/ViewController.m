//
//  ViewController.m
//  FlappyFelipe
//
//  Created by Main Account on 2/13/14.
//  Copyright (c) 2014 Razeware LLC. All rights reserved.
//

#import "ViewController.h"
#import "MyScene.h"

@interface ViewController() <MySceneDelegate>
@end

@implementation ViewController

- (void)viewDidLoad
{
  [super viewDidLoad];
  
  // Configure the view.
  SKView * skView = (SKView *)self.view;
  skView.showsFPS = NO;
  skView.showsNodeCount = NO;
  
  // Create and configure the scene.
  SKScene * scene = [[MyScene alloc] initWithSize:skView.bounds.size state:GameStateMainMenu delegate:self];
  scene.scaleMode = SKSceneScaleModeAspectFill;
  
  // Present the scene.
  [skView presentScene:scene];
}

- (BOOL)shouldAutorotate
{
  return YES;
}

- (BOOL)prefersStatusBarHidden {
  return YES;
}

- (NSUInteger)supportedInterfaceOrientations
{
  if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPhone) {
    return UIInterfaceOrientationMaskAllButUpsideDown;
  } else {
    return UIInterfaceOrientationMaskAll;
  }
}

- (void)didReceiveMemoryWarning
{
  [super didReceiveMemoryWarning];
  // Release any cached data, images, etc that aren't in use.
}

- (void)shareString:(NSString *)string {

  UIActivityViewController *vc = [[UIActivityViewController alloc] initWithActivityItems:@[string] applicationActivities:nil];
  [self presentViewController:vc animated:YES completion:nil];

}

@end
