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
import RealmSwift

/* realmswift 안될 시 product - scheme - new scheme 에서 realmswift 선택 */
/* subject 에서 onnext는 값을 넣는 역할,
 observable에서 onnext는 들어온 값을 빼는 역할 ?
 */

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

func compactRealm() {
    let defaultURL = Realm.Configuration.defaultConfiguration.fileURL!
    let defaultParentURL = defaultURL.deletingLastPathComponent()
    let compactedURL = defaultParentURL.appendingPathComponent("default-compact.realm")

    if FileManager.default.fileExists(atPath: compactedURL.path) {
        try! FileManager.default.removeItem(at: compactedURL)
    }

    if FileManager.default.fileExists(atPath: defaultURL.path) {
        autoreleasepool {
            let realm = try! Realm()
            try! realm.writeCopy(toFile: compactedURL)
        }

        try! FileManager.default.removeItem(at: defaultURL)
        try! FileManager.default.moveItem(at: compactedURL, to: defaultURL)
    }
}



class ViewController: UIViewController, NMFMapViewCameraDelegate{
    
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
        //view.addSubview(mapView)
        
        /* 현재 위치, 줌 확대, 축소 버튼 활성화 */
        mapView.showLocationButton = true
        mapView.showZoomControls = true
        
        mapView.mapView.addCameraDelegate(delegate: self) //NMFMapViewCameraDelegate Delegate 설정
        
        let cities = ["가평군", "고양시", "과천시", "광명시", "광주시", "구리시", "군포시", "김포시", "남양주시", "동두천시", "부천시", "성남시", "수원시", "시흥시", "안산시", "안성시", "안양시", "양주시", "양평군", "여주시", "연천군", "오산시", "용인시", "의왕시", "의정부시", "이천시", "파주시", "평택시", "포천시", "하남시", "화성시"]
        
        for city in cities{
            let sigun_nm = city
            
            /* 한글을 URL을 */
            let str_url = sigun_nm.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
            let req = URLRequest(url: URL(string: "https://openapi.gg.go.kr/RegionMnyFacltStus?Type=json&KEY=a8a1f1ba57704081bed7d50952f4de61&pIndex=1&pSize=1&SIGUN_NM=\(str_url)")!)
            
            // 탭 누를 때마다 새로 생성된 subject 객체가 있어야 함. 전역으로 둘거면 totalNumber.subscribe 안에서 계속 기존 totalnumber를 bind하는 urlsession observable의 disposable 객체를 dispose해줘야함
            let totalNumber: PublishSubject<Int> = PublishSubject()
            
            URLSession.shared.rx.json(request: req)
                .map(checkValid)
                .bind(to: totalNumber)
            
            
            totalNumber.subscribe(onNext:{ num in
                print("총개수:\(num)")
                for idx in 1...(num/1000)+1{
                    
                    print(idx)
                    let req = URLRequest(url: URL(string: "https://openapi.gg.go.kr/RegionMnyFacltStus?Type=json&KEY=a8a1f1ba57704081bed7d50952f4de61&pIndex=\(idx)&pSize=1000&SIGUN_NM=\(str_url)")!)
                    URLSession.shared.rx.json(request: req)
                        .map(self.parseJson)
                        .bind{ json in
                            self.info.onNext([json, city])
                            
                    }.disposed(by: self.urlDisposeBag)
                }
            })
        }
        
        
        
        
        
        
        /* 카메라 좌표 변경 시 데이터 받음 */
        moveCamera.debounce(RxTimeInterval.milliseconds(500), scheduler: ConcurrentMainScheduler.instance)
            .subscribe{position in

                // 위도 경도 정보
                let position = position.element?.target
                
                for marker in self.markers {
                    marker.mapView = nil
                }
                self.markers = []
                
                var filteredInfo : [[String:Any]] = [[:]]
                let realm = try! Realm()
                
                let model = realm.objects(StoreInfo.self)
                for a in model{
                    
                    if self.checkLatLngRange(clat: (position?.lat)!, clng: (position?.lng)!, nlat: a.lat, nlng: a.lng){
                        var tmpInfo :[String:Any] = [:]
                        tmpInfo["storeName"] = a.storeName
                        tmpInfo["phoneNum"] = a.phoneNum
                        tmpInfo["lat"] = a.lat
                        tmpInfo["lng"] = a.lng
                        
                        filteredInfo.append(tmpInfo)
                    }
                }
                self.addMarker(mapView: mapView, json: filteredInfo)
                
                
        }
        
        
        
        
        let button = UIButton(frame: CGRect(x: 100, y: 100, width: 100, height: 50))
        button.backgroundColor = .green
        button.setTitle("Test Button", for: .normal)
        
        self.view.addSubview(button)
        
        
        
        
        
        button.rx.tap.bind{ [weak self] in
            
            
        }
        
        
        
        
        info.subscribe(onNext: { jsonAndCity in
            let realm = try! Realm()
            
            
            let json = jsonAndCity[0] as! NSArray
            let city = jsonAndCity[1] as! String
            for data in json {
                guard let data = data as? NSDictionary else {return}
                // 넣어주는 객체(storeinfo)는 계속 새로운 객체로 갈아줘야 함. 전역으로 싱글톤처럼 못씀.
                let storeInfo = StoreInfo()
                
                try! realm.write {
                    
                    if let storeName = data["CMPNM_NM"] as? String{
                        storeInfo.storeName = storeName
                    }
                    if let lat = data["REFINE_WGS84_LAT"] as? String, let lng = data["REFINE_WGS84_LOGT"] as? String{

                        storeInfo.lat = Double(lat)!
                        storeInfo.lng = Double(lng)!
                    }
                    
                    
                    if let phoneNum = data["TELNO"] as? String{
                        storeInfo.phoneNum = phoneNum

                    }
                    
                    
                    var exists = false
                    let model = realm.objects(StoreInfo.self).filter("storeName = %@ AND lat = %@ AND lng = %@", storeInfo.storeName, storeInfo.lat, storeInfo.lng)
                    if model.count != 0{
                        exists = true
                    }
                    if storeInfo.phoneNum != ""{
                        let model = realm.objects(StoreInfo.self).filter("storeName = %@ AND phoneNum = %@", storeInfo.storeName, storeInfo.phoneNum)
                        if model.count != 0{
                            exists = true
                        }
                    }
                    
                    storeInfo.city = city
                    
                    
                    if storeInfo.lat == 0.0 || storeInfo.lng == 0.0{
                        print("위도 혹은 경도 0")
                    }else if exists{
                        print("이미 존재")
                    }else{
                        realm.add(storeInfo)
                        
                    }
                    
                }
                
                //                print(Realm.Configuration.defaultConfiguration.fileURL!)
                
            }
           

            self.cnt += 1
            print(self.cnt)
            
            
        }).disposed(by: disposeBag)
        
        
        
        
        
        
        let button2 = UIButton(frame: CGRect(x: 200, y: 10, width: 100, height: 50))
        button2.backgroundColor = .green
        button2.setTitle("Test Button", for: .normal)
        
        self.view.addSubview(button2)
        
        button2.rx.tap.bind{
            compactRealm()
            
//            DispatchQueue.main.async { [weak self] in
//                // 메인 스레드
//                for marker in self!.markers {
//
//                    marker.mapView = nil
//                }
//            }
        }
        
        /*
         json 데이터 타입
         {} 중괄호: 객체. 무조건 key:value 쌍
         [] 대괄호: 배열
         */
        
        
    }
    
    /*카메라 제스쳐 움직임에 따른 카메라 위치 포지션*/
    func mapView(_ mapView: NMFMapView, cameraIsChangingByReason reason: Int) { //NMFMapViewCameraDelegate프로토콜 함수
        /*비동기적으로 현재 카메라의 위치를 계속해서 프린트 해주기?*/
        print("카메라가 변경됨 : reason : \(reason)")
        let cameraPosition = mapView.cameraPosition
        moveCamera.onNext(cameraPosition)
        
        //print("카메라 위치?  ", cameraPosition) //현재 카메라 위치 파악하기.
    }
    
    func deg2rad(_ number: Double) -> Double {
        return number * .pi / 180
    }
    
    func checkLatLngRange(clat: Double, clng: Double, nlat: Double, nlng: Double)->Bool{
        
        return 0.5 > (6371 * acos(cos(deg2rad(clat)) * cos(deg2rad(nlat)) * cos(deg2rad(clng) - deg2rad(nlng)) + sin(deg2rad(clat)) * sin(deg2rad(nlat))))
        
    }
    
    
    func parseJson(json: Any)-> NSArray{
        let jsonParse = json as! [String:Any]
        let item = jsonParse["RegionMnyFacltStus"]! as! NSArray
        let storeInfo = item[1] as! NSDictionary
        let storeRow = storeInfo["row"] as! NSArray
        //        print("출력됨")
        
        return storeRow
    }
    
    func checkValid(json: Any)->Int {
        let jsonParse = json as! [String:Any]
        let item = jsonParse["RegionMnyFacltStus"]! as! NSArray
        let storeInfo = item[0] as! NSDictionary
        let rowInfo = storeInfo["head"] as! NSArray
        let infoDict = rowInfo[0] as! NSDictionary
        let totalCount = infoDict["list_total_count"] as! Int
        
        
        return totalCount
        
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


