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
        barHideOnSwipeGestureRecognizer.addTarget(self, action: #selector(HeadedNavigationController.toggleBars(_:)))
        barHideOnTapGestureRecognizer.addTarget(self, action: #selector(HeadedNavigationController.toggleBars(_:)))
        startingAlpha = statusBarBackground.alpha
        statusBarBackground.alpha = 0
        view.addSubview(statusBarBackground)
        UIDevice.current.beginGeneratingDeviceOrientationNotifications()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.positionStatusBarBackgroundView()

        orientationObserver = NotificationCenter.default.addObserver(forName: NSNotification.Name.UIDeviceOrientationDidChange, object: nil, queue: nil) { _ in
            UIView.animate(withDuration: 0.25, animations: {
                self.positionStatusBarBackgroundView()
            }) 
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        NotificationCenter.default.removeObserver(orientationObserver!)
        super.viewWillDisappear(animated)
    }
    
    func toggleBars(_ swipeGestureRecognizer: UISwipeGestureRecognizer) {
        self.positionStatusBarBackgroundView()

        UIView.animate(withDuration: 0.25, animations: {
            self.statusBarBackground.alpha = self.isNavigationBarHidden ? self.startingAlpha : 0
        }) 
    }
    
    func positionStatusBarBackgroundView() -> Void {
        self.statusBarBackground.frame = UIApplication.shared.statusBarFrame;
    }
}
