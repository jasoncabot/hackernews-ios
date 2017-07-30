//
//  NetworkIndicator.swift
//  HackerNews
//
//  Created by Jason Cabot on 21/02/2015.
//  Copyright (c) 2015 Jason Cabot. All rights reserved.
//

import UIKit

class NetworkIndicator {
    
    fileprivate var numberOfNetworkRequests = 0

    func displayNetworkIndicator(_ display:Bool) -> Void {
        DispatchQueue.main.async { [unowned self] in
            if (display) {
                self.numberOfNetworkRequests += 1
            } else {
                self.numberOfNetworkRequests = max(0, self.numberOfNetworkRequests - 1)
            }
            UIApplication.shared.isNetworkActivityIndicatorVisible = self.numberOfNetworkRequests > 0
        }
    }
}
