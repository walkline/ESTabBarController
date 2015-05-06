//
//  ESTabBarController.m
//  Pods
//
//  Created by Ezequiel Scaruli on 5/4/15.
//
//

#import "ESTabBarController.h"
#import "UIButton+ESTabBar.h"
#import "ESTabBarController+Autolayout.h"


@interface ESTabBarController ()

@property (nonatomic, weak) IBOutlet UIView *controllersContainer;
@property (nonatomic, weak) IBOutlet UIView *buttonsContainer;

@property (nonatomic, assign) NSInteger controllersAmount;
@property (nonatomic, strong) NSMutableDictionary *controllers;
@property (nonatomic, strong) NSMutableDictionary *actions;
@property (nonatomic, assign) BOOL didSetupInterface;
@property (nonatomic, strong) NSMutableArray *buttons;
@property (nonatomic, strong) NSMutableSet *highlightedButtonIndexes;
@property (nonatomic, strong) NSArray *tabIcons;
@property (nonatomic, strong) UIView *selectionIndicator;
@property (nonatomic, strong) NSLayoutConstraint *selectionIndicatorLeadingConstraint;

@end


@implementation ESTabBarController


#pragma mark - Init


- (instancetype)initWithControllersAmount:(NSInteger)controllersAmount {
    self = [self initWithNibName:@"ESTabBarController" bundle:nil];
    
    if (self != nil) {
        [self initializeWithControllersAmount:controllersAmount];
    }
    
    return self;
}


#pragma mark - UIViewController


- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self setupInterface];
    [self moveToControllerAtIndex:0 animated:NO];
}


#pragma mark - Public methods


- (void)setTabIcons:(NSArray *)tabIcons {
    NSAssert(tabIcons.count == self.controllersAmount,
             @"The amount of tab icons should be equal to the controllers amount.");
    
    _tabIcons = tabIcons;
    [self setupInterfaceIfNeeded];
}


- (void)setViewController:(UIViewController *)viewController
                  atIndex:(NSInteger)index {
    self.controllers[@(index)] = viewController;
    [self setupInterfaceIfNeeded];
}


- (void)setAction:(ESTabBarAction)action
          atIndex:(NSInteger)index {
    self.actions[@(index)] = action;
    [self setupInterfaceIfNeeded];
}


- (void)highlightButtonAtIndex:(NSInteger)index {
    [self.highlightedButtonIndexes addObject:@(index)];
    [self setupInterfaceIfNeeded];
}


#pragma mark - Action


- (void)tabButtonAction:(UIButton *)button {
    NSInteger index = [self.buttons indexOfObject:button];
    
    if (index != NSNotFound) {
        [self moveToControllerAtIndex:index animated:YES];
    }
}


#pragma mark - Private methods


- (void)initializeWithControllersAmount:(NSInteger)controllersAmount {
    NSAssert(controllersAmount > 0,
             @"The controllers amount should be greater than zero.");
    
    self.controllersAmount = controllersAmount;
    
    self.controllers = [NSMutableDictionary dictionaryWithCapacity:controllersAmount];
    self.actions = [NSMutableDictionary dictionaryWithCapacity:controllersAmount];
    
    self.highlightedButtonIndexes = [NSMutableSet set];
}


- (void)setupInterfaceIfNeeded {
    if (self.didSetupInterface) {
        // If the UI was already setup, it's necessary to update it.
        [self setupInterface];
    }
}


- (void)setupInterface {
    [self setupButtons];
    [self setupSelectionIndicator];
    self.didSetupInterface = YES;
}


- (void)setupButtons {
    // First, I remove the previous buttons. They could have an outdated image.
    for (UIButton *button in self.buttons) {
        [button removeFromSuperview];
    }
    
    self.buttons = [NSMutableArray arrayWithCapacity:self.controllersAmount];
    
    for (NSInteger i = 0; i < self.controllersAmount; i++) {
        UIButton *button = [self createButtonForIndex:i];
        
        [self.buttonsContainer addSubview:button];
        self.buttons[i] = button;
    }
    
    [self setupButtonsConstraints];
    self.buttonsContainer.backgroundColor = self.buttonsBackgroundColor ?: [UIColor lightGrayColor];
}


- (UIButton *)createButtonForIndex:(NSInteger)index {
    UIButton *button = [UIButton buttonWithType:UIButtonTypeCustom];
    
    BOOL isHighlighted = [self.highlightedButtonIndexes containsObject:@(index)];
    [button customizeForTabBarWithImage:self.tabIcons[index]
                          selectedColor:self.selectedColor ?: [UIColor blackColor]
                            highlighted:isHighlighted];
    
    [button addTarget:self
               action:@selector(tabButtonAction:)
     forControlEvents:UIControlEventTouchUpInside];
    
    return button;
}


- (void)moveToControllerAtIndex:(NSInteger)index animated:(BOOL)animated {
    UIViewController *controller = self.controllers[@(index)];
    
    if (controller != nil) {
        if (self.selectedIndex >= 0) {
            // Remove the current controller's view.
            UIViewController *currentController = self.controllers[@(self.selectedIndex)];
            [currentController.view removeFromSuperview];
        }
        
        if (![self.childViewControllers containsObject:controller]) {
            // If I haven't added the controller to the childs yet...
            [self addChildViewController:controller];
            [controller didMoveToParentViewController:self];
        }
        
        [self.view addSubview:controller.view];
        controller.view.frame = self.controllersContainer.bounds;
        
        [self moveSelectionIndicatorToIndex:index animated:animated];
        
        _selectedIndex = index;
    }
}


- (void)setupSelectionIndicator {
    if (self.selectionIndicator != nil) {
        // We already set up the selection indicator.
        return;
    }
    
    self.selectionIndicator = [[UIView alloc] init];
    self.selectionIndicator.translatesAutoresizingMaskIntoConstraints = NO;
    self.selectionIndicator.backgroundColor = self.selectedColor ?: [UIColor blackColor];
    [self.buttonsContainer addSubview:self.selectionIndicator];
    
    [self setupSelectionIndicatorConstraints];
}


- (void)moveSelectionIndicatorToIndex:(NSInteger)index animated:(BOOL)animated {
    CGFloat constant = [self.buttons[index] frame].origin.x;
    
    [self.buttonsContainer layoutIfNeeded];
    void (^animations)(void) = ^{
        self.selectionIndicatorLeadingConstraint.constant = constant;
        [self.buttonsContainer layoutIfNeeded];
    };
    
    if (animated) {
        [UIView animateWithDuration:0.25
                              delay:0.0
                            options:UIViewAnimationOptionCurveEaseIn
                         animations:animations
                         completion:nil];
    } else {
        animations();
    }
}


@end