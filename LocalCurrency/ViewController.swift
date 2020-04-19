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

    let infoWindow = NMFInfoWindow()
    let dataSource = NMFInfoWindowDefaultTextSource.data()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        
        let mapView = NMFNaverMapView(frame: view.frame)
        view.addSubview(mapView)
        
        mapView.showLocationButton = true
        mapView.showZoomControls = true
        
        
        addMarker(mapView: mapView)
        
        
        
        
    }
    
    /* 마커 위치 및 정보 표시 */
    func addMarker(mapView: NMFNaverMapView){
        
        let lats = [37.5670135, 37.5673147]
        let lngs = [126.9783740, 126.9753352]
        var tags = [["tag": "첫 번째 마크"], ["tag": "두 번째 마크"]]
        
        // infoWindow 에 dataSource 연결
        infoWindow.dataSource = dataSource
        
        // 백그라운드 스레드
        DispatchQueue.global(qos: .default).async {
            var markers = [NMFMarker]()
            for idx in 0...lats.count-1 {
                let marker = NMFMarker(position: NMGLatLng(lat: lats[idx], lng: lngs[idx]))
                
                // userInfo: 마커마다 필요한 개별 정보 등록
                marker.userInfo = tags[idx]
                
                // touchHandler: 마커마다 개별 핸들러 등록
                marker.touchHandler = { (overlay: NMFOverlay) -> Bool in
                    if let marker = overlay as? NMFMarker {
                        if marker.infoWindow == nil {
                            // 현재 마커에 정보 창이 열려있지 않을 경우 엶
                            self.dataSource.title = marker.userInfo["tag"] as! String
                            self.infoWindow.open(with: marker)
                        } else {
                            // 이미 현재 마커에 정보 창이 열려있을 경우 닫음
                            self.infoWindow.close()
                        }
                    }
                    return true
                };
                
                markers.append(marker)
            }

            DispatchQueue.main.async { [weak self] in
                // 메인 스레드
                for marker in markers {
                    
                    marker.mapView = mapView.mapView
                }
            }
        }
        
        
        
        
        
    }
    
    func mapView(_ mapView: NMFMapView, didTapMap latlng: NMGLatLng, point: CGPoint) {
        infoWindow.close()
    }


}

