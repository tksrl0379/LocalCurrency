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

/* subject 에서 onnext는 값을 넣는 역할,
   observable에서 onnext는 들어온 값을 빼는 역할 ?
 */

class ViewController: UIViewController {

    /* 정보 창 관련 변수들 */
    let infoWindow = NMFInfoWindow() // 정보 창 객체 생성 후
    let dataSource = NMFInfoWindowDefaultTextSource.data() // 정보 창 안에 넣을 내용 적재
    
    /* */
    var urlDisposeBag = DisposeBag()
    var disposeBag = DisposeBag()
    
    /* Output 담당 Subject */
    let info: PublishSubject<NSArray> = PublishSubject()

    
    var markers = [NMFMarker]()

    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* 네이버 지도 객체 */
        let mapView = NMFNaverMapView(frame: view.frame)
        view.addSubview(mapView)
        
        /* 현재 위치, 줌 확대, 축소 버튼 활성화 */
        mapView.showLocationButton = true
        mapView.showZoomControls = true
        
        /*
         json 데이터 타입
         {} 중괄호: 객체. 무조건 key:value 쌍
         [] 대괄호: 배열
         */
        
        // 1.
        
        
        
        /*xx시에 지정된 모든 데이터들을 반복문? 혹은 어떠한 방법으로든 통해서 모두 프린트를 하는 방식을 찾기.*/
        
        
        /* json data를 받아오면 observable에 이벤트 발생 */
        // 1. parse 메소드 실행: json 데이터 파싱
        // 2. info (subject)에게 데이터 전달
        
        let button = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 50))
        button.backgroundColor = .green
        button.setTitle("Test Button", for: .normal)
        
        self.view.addSubview(button)
        
        button.rx.tap.bind{ [weak self] in
            let sigun_nm = "안산시"
            
            /* 한글을 URL을 */
            let str_url = sigun_nm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            
            for idx in 1...20{
                let req = URLRequest(url: URL(string: "https://openapi.gg.go.kr/RegionMnyFacltStus?Type=json&KEY=a8a1f1ba57704081bed7d50952f4de61&pIndex=\(idx)&pSize=1000&SIGUN_NM=\(str_url)")!)
                
                URLSession.shared.rx.json(request: req)
                    .map(self!.parseJson)
                    .bind{ json in
                        self!.info.onNext(json)
                }.disposed(by: self!.urlDisposeBag)
                
                
            }
        }
        
        let button2 = UIButton(frame: CGRect(x: 200, y: 10, width: 100, height: 50))
        button2.backgroundColor = .green
        button2.setTitle("Test Button", for: .normal)
        
        self.view.addSubview(button2)
        
        button2.rx.tap.bind{
            DispatchQueue.main.async { [weak self] in
                // 메인 스레드
                for marker in self!.markers {
                    
                    marker.mapView = nil
                }
            }
        }
        
        
        
        // 3. info가 데이터를 전달받으면 이 메소드 실행됨
        info.subscribe(onNext: { json in
//            print(json)
            print("가나다라")
            self.addMarker(mapView: mapView, json: json)
            //urlDisposeBag.
            
            }).disposed(by: disposeBag)
        
        
        
    }
    
    func parseJson(json: Any)-> NSArray{
        let jsonParse = json as! [String:Any]
        let item = jsonParse["RegionMnyFacltStus"]! as! NSArray
        let storeInfo = item[1] as! NSDictionary
        let storeRow = storeInfo["row"] as! NSArray
        print("출력됨")
        
        return storeRow
    }
    
    
    
    /* 마커 위치 및 정보 표시 */
    func addMarker(mapView: NMFNaverMapView, json: NSArray){
        
      
        
        // infoWindow 에 dataSource 연결
        infoWindow.dataSource = dataSource
        
        // 백그라운드 스레드
        DispatchQueue.global(qos: .default).async {
            for data in json {
                guard let data = data as? NSDictionary else {return}
                
                
                var marker = NMFMarker()
                var markerInfo = ""
                
                if let lat = data["REFINE_WGS84_LAT"] as? String, let lng = data["REFINE_WGS84_LOGT"] as? String{
                    
                    marker = NMFMarker(position: NMGLatLng(lat: Double(lat)!, lng: Double(lng)!))
                }
                
                if let storeName = data["CMPNM_NM"] as? String{
                    markerInfo += storeName
                }
                if let phoneNum = data["TELNO"] as? String{
                    markerInfo += " \(phoneNum)"
                }
                
                
                
//                marker.iconImage = NMFOverlayImage(image: <#T##UIImage#>)
                // touchHandler: 마커마다 개별 핸들러 등록
                marker.touchHandler = { (overlay: NMFOverlay) -> Bool in
                    if let marker = overlay as? NMFMarker {
                        if marker.infoWindow == nil {
                            // 현재 마커에 정보 창이 열려있지 않을 경우 엶
                            self.dataSource.title = markerInfo
            
                            self.infoWindow.open(with: marker)
                        } else {
                            // 이미 현재 마커에 정보 창이 열려있을 경우 닫음
                            self.infoWindow.close()
                        }
                    }
                    return true
                };
                
                self.markers.append(marker)
            }

            DispatchQueue.main.async { [weak self] in
                // 메인 스레드
                for marker in self!.markers {
                    
                    marker.mapView = mapView.mapView
                }
            }
        }
        
        
        
        
        
    }
    
    func mapView(_ mapView: NMFMapView, didTapMap latlng: NMGLatLng, point: CGPoint) {
        infoWindow.close()
    }
    

}



/*
 
 func parseStoreInfo(storeRow: NSArray)-> [[[String:Any]]]{//[String : Array<String>]{
 //        var willShowData : [String: Array<String>] = [:]
         var willShowData : [String: String] = [:]
         
         storeRow.forEach{
             guard let dict = $0 as? NSDictionary else {return}
             
             var tmpDict: [String:Any] = [:]
             
             if let storeName = dict["CMPNM_NM"] as? String{
                 tmpDict["상호명"] = storeName
                 print(storeName)
             }
             if let phoneNum = dict["TELNO"] as? String{
                // tmpDict["정보"]
             }
             
             if let log = dict["REFINE_WGS84_LOGT"] as? String, let lat = dict["REFINE_WGS84_LAT"] as? String{

                 tmpDict["위경도"] = ["dd"]
                 
                 print(lat, log)
             }
             
             
         }
         
         return [ [["상호명":"59쌀피자"], ["위경도": [13, 15]], ["정보":"010-3030-3030"]] ]
     }
 
 
 */
