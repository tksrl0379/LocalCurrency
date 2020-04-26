//
//  ViewController.swift
//  LocalCurrency
//
//  Created by a1111 on 2020/04/19.
//  Copyright © 2020 SIMPARK. All rights reserved.
//

/* realmswift 안될 시 product - scheme - new scheme 에서 realmswift 선택 */


import UIKit
import RxSwift
import RxCocoa
import NMapsMap
import RealmSwift

//let cities = ["가평군", "고양시", "과천시", "광명시", "광주시", "구리시", "군포시", "김포시", "남양주시", "동두천시", "부천시", "성남시", "수원시", "시흥시", "안산시", "안성시", "안양시", "양주시", "양평군", "여주시", "연천군", "오산시", "용인시", "의왕시", "의정부시", "이천시", "파주시", "평택시", "포천시", "하남시", "화성시"]


/* 가게 정보 클래스 for Realm */
class StoreInfo: Object {
    @objc dynamic var storeName = ""
    @objc dynamic var phoneNum = ""
    @objc dynamic var lat = 0.0
    @objc dynamic var lng = 0.0
    @objc dynamic var city = ""
    
    override static func indexedProperties() -> [String] {
        return ["city"]
    }
}

class ViewController: UIViewController, NMFMapViewTouchDelegate, NMFMapViewCameraDelegate{
    
    var cnt = 0
    
    /* 정보 창 관련 변수들 */
    let infoWindow = NMFInfoWindow() // 정보 창 객체 생성 후
    let dataSource = NMFInfoWindowDefaultTextSource.data() // 정보 창 안에 넣을 내용 적재
    
    /* */
    var urlDisposeBag = DisposeBag()
    var disposeBag = DisposeBag()
    
    /* Output 담당 Subject */
    let info: PublishSubject<NSArray> = PublishSubject()
    
    //
    let moveCamera: PublishSubject<NMFCameraPosition> = PublishSubject()
    
    var markers = [NMFMarker]()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /* 네이버 지도 객체 */
        let mapView = NMFNaverMapView(frame: view.frame)
        view.addSubview(mapView)
        
        /* 현재 위치, 줌, 나침반, 축척 바 활성화 */
        mapView.showLocationButton = true
        mapView.showZoomControls = true
        mapView.showCompass = true
        mapView.showScaleBar = true
        
        // NMFMapViewCameraDelegate Delegate 등록
        mapView.mapView.addCameraDelegate(delegate: self)
        
        //mapView.mapView.touchDelegate = self
        
        
        /* 카메라 좌표 변경 이벤트 발생 시 데이터 받음.
         debounce: 이벤트 도착 후 0.5초 기다렸다가 더 이상 추가 이벤트가 발생하지 않으면 Data 전달 */
        moveCamera.debounce(RxTimeInterval.milliseconds(500), scheduler: ConcurrentMainScheduler.instance)
            .subscribe{position in
                
                print(position)
            
                // 위도 경도 정보
                let position = position.element?.target
                
                /* 지도에 있는 Marker 삭제 */
                for marker in self.markers {
                    marker.mapView = nil
                }
                self.markers = []
                
                // 가게 정보들을 담음
                var storeInfo : [[String:Any]] = [[:]]
                
                // Realm DB 조회
                let realm = try! Realm()
                let model = realm.objects(StoreInfo.self)
                for store in model{
                    
                    /* 현재 화면의 위,경도 기준 반경 500m 이내의 가게들만 담음 */
                    if self.checkLatLngRange(clat: (position?.lat)!, clng: (position?.lng)!, nlat: store.lat, nlng: store.lng){
                        var tmpInfo :[String:Any] = [:]
                        tmpInfo["storeName"] = store.storeName
                        tmpInfo["phoneNum"] = store.phoneNum
                        tmpInfo["lat"] = store.lat
                        tmpInfo["lng"] = store.lng
                        
                        storeInfo.append(tmpInfo)
                    }
                }
                // 지도에 마커 표시
                self.addMarker(mapView: mapView, json: storeInfo)
                
                
        }
        
        
        
//        /* 테스트 용으로 만든 임시 버튼 */
//        let button = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 50))
//        button.backgroundColor = .green
//        button.setTitle("Test Button", for: .normal)
//        self.view.addSubview(button)
//
//        button.rx.tap.bind{ [weak self] in
//
//
//        }

        
        
        
        
    }
    
    
    /* 카메라 이동 콜백 */
    func mapView(_ mapView: NMFMapView, cameraIsChangingByReason reason: Int) { // NMFMapViewCameraDelegate 프로토콜 함수
        print("카메라가 변경됨 : reason : \(reason)")
        let cameraPosition = mapView.cameraPosition
        moveCamera.onNext(cameraPosition)
        
        
    }
    
    /* 지도 탭 콜백 */
    func mapView(_ mapView: NMFMapView, didTapMap latlng: NMGLatLng, point: CGPoint){
        infoWindow.close()
        print("지도 탭")
    }
    
    
    // 좌표를 라디안으로 변환
    func deg2rad(_ number: Double) -> Double {
        return number * .pi / 180
    }
    
    
    // 좌표(위,경도) 간의 거리 측정
    func checkLatLngRange(clat: Double, clng: Double, nlat: Double, nlng: Double)->Bool{
        
        return 0.5 > (6371 * acos(cos(deg2rad(clat)) * cos(deg2rad(nlat)) * cos(deg2rad(clng) - deg2rad(nlng)) + sin(deg2rad(clat)) * sin(deg2rad(nlat))))
    }
    
    
    // json 파싱
    func parseJson(json: Any)-> NSArray{
        let jsonParse = json as! [String:Any]
        let item = jsonParse["RegionMnyFacltStus"]! as! NSArray
        let storeInfo = item[1] as! NSDictionary
        let storeRow = storeInfo["row"] as! NSArray
        
        return storeRow
    }
    
   
    /* 마커 위치 및 정보 표시 */
    func addMarker(mapView: NMFNaverMapView, json: [[String:Any]]){
        
        // infoWindow 에 dataSource 연결
        infoWindow.dataSource = dataSource
        
        // 백그라운드 스레드
        DispatchQueue.global(qos: .default).async {
            for data in json {
                guard let data = data as? NSDictionary else {return}
                
                
                var marker = NMFMarker()
                
                var markerInfo = ""
                
                
                if let lat = data["lat"] as? Double, let lng = data["lng"] as? Double{
                    
                    marker = NMFMarker(position: NMGLatLng(lat: lat, lng: lng))
                }
                
                if let storeName = data["storeName"] as? String{
                    markerInfo += storeName
                }
                if let phoneNum = data["phoneNum"] as? String{
                    markerInfo += " \(phoneNum)"
                }
                
                 marker.iconImage = NMF_MARKER_IMAGE_RED
                
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
                    return false
                };
                
                // 마커 크기 조정
                marker.width = 22.5
                marker.height = 30
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
    
    
    
    
}


