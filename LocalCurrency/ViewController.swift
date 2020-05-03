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

//let cities = ["안산시"]

/* 가게 정보 클래스 for Realm */
class StoreInfo: Object {
    @objc dynamic var storeName = ""
    @objc dynamic var phoneNum = ""
    @objc dynamic var lat = 0.0
    @objc dynamic var lng = 0.0
    @objc dynamic var addr = ""
    @objc dynamic var type = ""
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
    var searchInfo: PublishSubject<[String:Any]> = PublishSubject()
    
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
        
        /**************/
        //Test 카메라 초기 위도 경도 설정. 탄도항낚시슈퍼 -> 총 3개의 상점이 같은 위도 경도에 위치함
//        let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: 37.191018125, lng: 126.64571304), zoomTo: 20)
//        mapView.mapView.moveCamera(cameraUpdate)
        /**************/
        
        //mapView.mapView.touchDelegate = self
        
        /* 카메라 좌표 변경 이벤트 발생 시 데이터 받음.
         debounce: 이벤트 도착 후 0.5초 기다렸다가 더 이상 추가 이벤트가 발생하지 않으면 Data 전달 */
        moveCamera.debounce(RxTimeInterval.milliseconds(250), scheduler: ConcurrentMainScheduler.instance)
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
                let model = realm.objects(StoreInfo.self).sorted(byKeyPath: "lat") //lat정렬을 통해 묶어주기 위함.
                for store in model{
                    
                    /* 현재 화면의 위,경도 기준 반경 500m 이내의 가게들만 담음 */
                    if self.checkLatLngRange(clat: (position?.lat)!, clng: (position?.lng)!, nlat: store.lat, nlng: store.lng){
                        var tmpInfo :[String:Any] = [:]
                        tmpInfo["storeName"] = store.storeName
                        tmpInfo["phoneNum"] = store.phoneNum
                        tmpInfo["lat"] = store.lat
                        tmpInfo["lng"] = store.lng
                        
                        //                        print("TEST\n lat:: ", tmpInfo["lat"],"\tlng. ::", tmpInfo["lng"])
                        storeInfo.append(tmpInfo)
                        
                        print(tmpInfo["lat"])
                    }
                }
                // 지도에 마커 표시
                self.addMarker(mapView: mapView, json: storeInfo)
                
        }
        
        searchInfo.subscribe(onNext:{ store in
            
            for marker in self.markers{
                marker.mapView = nil
            }
            self.markers = []
            
            self.addMarker(mapView: mapView, json: [store])
            let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: store["lat"] as! Double, lng: store["lng"] as! Double), zoomTo: 17)
            
            
            mapView.mapView.moveCamera(cameraUpdate)
            
        })
        
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
        
        /*
         cmpLat, cmpLng는 다음 가게의 위도경도와 비교할 값이다. 초기화는 0.
         */
        var cmpLat = 0.0 //data들의 latlng을 비교하여 같으면 묶게 하기위한 변수.
        var cmpLng = 0.0
        
        /*한 빌딩에 존재하는 가게이름과 번호를 저장할 배열*/
        var storeNameArray : Array<String> = []
        var phoneNumeArray : Array<String> = []
        
        var storesOfbuildingDict = [String : Any]() //가게 이름, 전화번호 저장할 딕셔너리
        var storesOfbuildingArray = [[String : Any]]() // 딕서녀리를 저장할 배열
        
        // infoWindow 에 dataSource 연결
        infoWindow.dataSource = dataSource
        
        // 백그라운드 스레드
        DispatchQueue.global(qos: .default).async {
            for data in json {
                guard let data = data as? NSDictionary else {return}
                
                //이곳에서 그 전에 있는 lat&lng을 저장하여 비교한다.
                //comparedLat이 초기화일때 (0) 혹은 지금 Data의 lat과 같지 않다면 markerInfo를 초기화 시켜준다.
                //그 외에는 markerInfo에다가 추가시켜주는 방식.
                
                
                
                
                if((cmpLat == 0 && cmpLng == 0) || (cmpLat == data["lat"] as? Double && cmpLng == data["lng"] as? Double)){
                    
                    /*일단 가게 이름과 전화번호를 저장한다*/
                    
                    if let storeName = data["storeName"] as? String{
                        storesOfbuildingDict["storeName"] = storeName //딕셔너리에 가게이름 저장
                    }
                    if let phoneNum = data["phoneNum"] as? String{
                        storesOfbuildingDict["phoneNum"] = phoneNum //딕셔너리에 전화번호 저장
                    }
                    
                    /* 현재 cmpLatLng이 0일때에는 지금 위치를 저장해야하기 때문에*/
                    if(cmpLat == 0 && cmpLng == 0){
                        if let lat = data["lat"] as? Double, let lng = data["lng"] as? Double{
                            cmpLat = lat
                            cmpLng = lng
                        }
                    }
                    storesOfbuildingArray.append(storesOfbuildingDict)
                    
                    if json.count != 1{
                        continue //다음 data로 넘어간다.
                    }
                    
                }
                
                    print("딕셔너리 배열은 \(storesOfbuildingArray)")
                    
                    //배열에 있는 가게의 이름과 전화번호를 각각 해당 배열에 저장하는 과정
                    for data in storesOfbuildingArray {
                        guard let data = data as? NSDictionary else {return}
                        
                        if let storeName = data["storeName"] as? String{
                            storeNameArray.append(storeName)
                        }
                        
                        if let phoneNum = data["phoneNum"] as? String{
                            
                            phoneNumeArray.append(phoneNum)
                        }
                    }
                    
                    
                    
                    /*Handler에 저장할 __Info 변수
                     전역변수(storeNameArray,phoneNumeArray)를 쓰면 callBack메소드인 handler가 최종 저장된 값을 불러오므로 모든 가게의 정보가 같아지는 오류 발생-> 따라서 __Info에 저장하여 각 핸들러마다 고유 가게 정보들을 넣어준다.
                     */
                    
                    let storeNameArrayInfo = storeNameArray
                    let phoneNumArrayInfo = phoneNumeArray
                    
                    
                    var marker = NMFMarker()
                    
                    marker = NMFMarker(position: NMGLatLng(lat: cmpLat, lng: cmpLng))
                    
                    marker.iconImage = NMF_MARKER_IMAGE_RED
                    
                    // touchHandler: 마커마다 개별 핸들러 등록 콜백
                    marker.touchHandler = { (overlay: NMFOverlay) -> Bool in
                        
                        /*영민이가 준 옵션. 클릭시 현재 마커 제외 모두 불투명으로 변경.*/
                        for m in self.markers{
                            m.alpha = 0.1
                        }
                        marker.alpha = 1
                        
                        if let marker = overlay as? NMFMarker {
                            if marker.infoWindow == nil {
                                // 현재 마커에 정보 창이 열려있지 않을 경우 엶
                                self.alertMessage(storeNameArrayInfo, phoneNumArrayInfo)
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
                    
                    //전역변수값들 초기화
                    
                    storeNameArray = []
                    phoneNumeArray = []
                    
                    
                    storesOfbuildingArray = [[String:Any]]()
                    
                    
                    if let storeName = data["storeName"] as? String{
                        storesOfbuildingDict["storeName"] = storeName //딕셔너리에 가게이름 저장
                    }
                    if let phoneNum = data["phoneNum"] as? String{
                        storesOfbuildingDict["phoneNum"] = phoneNum //딕셔너리에 전화번호 저장
                    }
                    if let lat = data["lat"] as? Double, let lng = data["lng"] as? Double{
                        cmpLat = lat
                        cmpLng = lng
                    }
                    storesOfbuildingArray.append(storesOfbuildingDict)
                
                
                
            }
            
            DispatchQueue.main.async { [weak self] in
                // 메인 스레드
                print(self!.markers.count)
                for marker in self!.markers {
                    
                    marker.mapView = mapView.mapView
                }
            }
            
            
        }
    }
    
    /*가게이름과 가게전화번호를 변수로 받아 화면에는 가게이름을 보여주고, 해당하는 Index값을 통해 NSLog에 번호가 뜨게 함*/
    func alertMessage(_ storeNameArrayInfo: Array<String>, _ phoneNumArrayInfo: Array<String>){
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .alert)
        
        let closure = { (action: UIAlertAction!) -> Void in
            let index = alert.actions.firstIndex(of: action)
            
            if index != nil {
                NSLog("Index: \(index!) \n가게 전화번호 : \(phoneNumArrayInfo[index!])")
                if let phoneCallURL = URL(string: "tel://\(phoneNumArrayInfo[index!])") {
                    
                    let application:UIApplication = UIApplication.shared
                    
                    if (application.canOpenURL(phoneCallURL)) {
                        application.open(phoneCallURL, options: [:], completionHandler: nil)
                        
                    }
                }
                
            }
        }
        
        for field in storeNameArrayInfo {
            alert.addAction(UIAlertAction(title: field, style: .default, handler: closure))
        }
        
        alert.addAction(UIAlertAction(title: "취소", style: .cancel, handler: {(_) in }))
        
        self.present(alert, animated: false, completion: nil)
    }
    
    
    
}

