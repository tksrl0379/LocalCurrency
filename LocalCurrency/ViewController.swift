//
//  ViewController.swift
//  LocalCurrency
//
//  Created by a1111 on 2020/04/19.
//  Copyright © 2020 SIMPARK. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import NMapsMap

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let mapView = NMFNaverMapView(frame: view.frame)
        view.addSubview(mapView)
        
        mapView.showLocationButton = true
        
        let marker = NMFMarker()
        marker.position = NMGLatLng(lat: 37.5670135, lng: 126.9783740)
        marker.mapView = mapView.mapView
        
    }


}

