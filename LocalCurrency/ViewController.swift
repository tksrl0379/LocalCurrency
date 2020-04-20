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
        
        /*
         {} 중괄호: 객체. 무조건 key:value 쌍
         [] 대괄호: 배열
         
         */
        
        let info: PublishSubject<NSArray> = PublishSubject()

        let sigun_nm = "광명시"
        
        /* 한글을 URL을 */
        let str_url = sigun_nm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        
        /*xx시에 지정된 모든 데이터들을 반복문? 혹은 어떠한 방법으로든 통해서 모두 프린트를 하는 방식을 찾기.*/
        let req = URLRequest(url: URL(string: "https://openapi.gg.go.kr/RegionMnyFacltStus?Type=json&KEY=a8a1f1ba57704081bed7d50952f4de61&pIndex=1&pSize=2&SIGUN_NM=\(str_url)")!)
        
        /* json data를 받아오면 observable에 이벤트 발생 */
        // 1. parse 메소드 실행: json 데이터 파싱
        // 2. info (subject)에게 데이터 전달
        URLSession.shared.rx.json(request: req) // observable
            .map(parse)
            .bind(to: info)
        
        
        // 3. info가 데이터를 전달받으면 이 메소드 실행됨
        info.subscribe(onNext: { storeRow in
            storeRow.forEach{
                let dict = $0 as! NSDictionary
                print(dict["CMPNM_NM"]!)
                print(dict["REFINE_WGS84_LOGT"]!)
                print(dict["REFINE_WGS84_LAT"]!)
            }
        })
        
        
        
//        let mapView = NMFNaverMapView(frame: view.frame)
//        view.addSubview(mapView)
//
//        mapView.showLocationButton = true
//        mapView.showZoomControls = true
//
//
//        addMarker(mapView: mapView)
        
        
        
        
    }
    
    func parse(json: Any)-> NSArray{
        let jsonParse = json as! [String:Any]
        let item = jsonParse["RegionMnyFacltStus"]! as! NSArray
        let storeInfo = item[1] as! NSDictionary
        let storeRow = storeInfo["row"] as! NSArray
        
        
        
        return storeRow
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

