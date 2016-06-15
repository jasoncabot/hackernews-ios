//
//  HeadedNavigationController.swift
//  HackerNews
//
//  Created by Jason Cabot on 21/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit

class HeadedNavigationController : UINavigationController {
    @IBOutlet var statusBarBackground: UIView!
    var orientationObserver: NSObjectProtocol?
    
    var startingAlpha: CGFloat! = 1

    override func viewDidLoad() {
        super.viewDidLoad()
        barHideOnSwipeGestureRecognizer.addTarget(self, action: #selector(HeadedNavigationController.onBarsToggled(_:)))
        barHideOnTapGestureRecognizer.addTarget(self, action: #selector(HeadedNavigationController.onBarsToggled(_:)))
        startingAlpha = statusBarBackground.alpha
        statusBarBackground.alpha = 0
        view.addSubview(statusBarBackground)
        UIDevice.currentDevice().beginGeneratingDeviceOrientationNotifications()
    }
    
    override func viewWillAppear(animated: Bool) {
        super.viewWillAppear(animated)
        self.positionStatusBarBackgroundView()

        orientationObserver = NSNotificationCenter.defaultCenter().addObserverForName(UIDeviceOrientationDidChangeNotification, object: nil, queue: nil) { _ in
            UIView.animateWithDuration(0.25) {
                self.positionStatusBarBackgroundView()
            }
        }
    }
    
    override func viewWillDisappear(animated: Bool) {
        NSNotificationCenter.defaultCenter().removeObserver(orientationObserver!)
        super.viewWillDisappear(animated)
    }
    
    func onBarsToggled(swipeGestureRecognizer: UISwipeGestureRecognizer) {
        self.positionStatusBarBackgroundView()

        if let vc = self.topViewController as? OptionalToolbarViewController {
            self.toolbarHidden = navigationBarHidden || !vc.shouldDisplayToolbar()
        }

        UIView.animateWithDuration(0.25) {
            self.statusBarBackground.alpha = self.navigationBarHidden ? self.startingAlpha : 0
        }
    }
    
    func positionStatusBarBackgroundView() -> Void {
        self.statusBarBackground.frame = UIApplication.sharedApplication().statusBarFrame;
    }
}
