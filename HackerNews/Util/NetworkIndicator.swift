//
//  NetworkIndicator.swift
//  HackerNews
//
//  Created by Jason Cabot on 21/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit

class NetworkIndicator {
    
    private var numberOfNetworkRequests = 0

    func displayNetworkIndicator(display:Bool) -> Void {
        dispatch_async(dispatch_get_main_queue()) { [unowned self] in
            if (display) {
                self.numberOfNetworkRequests++
            } else {
                self.numberOfNetworkRequests = max(0, self.numberOfNetworkRequests - 1)
            }
            UIApplication.sharedApplication().networkActivityIndicatorVisible = self.numberOfNetworkRequests > 0
        }
    }
}
