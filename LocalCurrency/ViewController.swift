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
import CoreLocation



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



class ViewController: UIViewController, NMFMapViewTouchDelegate, NMFMapViewCameraDelegate, UITabBarControllerDelegate, UISearchBarDelegate, CLLocationManagerDelegate{
    
    /* FindController 와 주고받을 데이터들 */
    var searchText: String?      // 검색 단어
    var cityName: String?        // 검색 도시
    
    /* 검색 바 */
    var searchBar: UISearchBar!
    
    /* 현재 좌표 관련 변수 */
    var locationManager: CLLocationManager!
    var lat: Double!
    var lng: Double!
    
    /* 네이버 맵 관련 변수 */
    var mapView : NMFNaverMapView!
    var markers = [NMFMarker]()
    
    /* Output 담당 Subject */
    // 1. 검색 시 호출
    var searchInfo: PublishSubject<[String:Any]> = PublishSubject()
    // 2. 카메라 움직일 시 호출
    let moveCamera: PublishSubject<NMFCameraPosition> = PublishSubject()
    
    /* 정보 창 관련 변수들 */
//    let infoWindow = NMFInfoWindow() // 정보 창 객체 생성 후
//    let dataSource = NMFInfoWindowDefaultTextSource.data() // 정보 창 안에 넣을 내용 적재
    
    /* disposeBag 관련 변수 */
    //var disposeBag = DisposeBag()
    
    
    
    func setUpAxis(){
        /* 현재 좌표 받기 */
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        let coor = locationManager.location?.coordinate
        lat = coor?.latitude
        lng = coor?.longitude
//        lat = 37.361922
//        lng = 127.109459
    }
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        // Default Navigation bar 가리기 (직접 커스텀 구현함)
        self.navigationController?.isNavigationBarHidden = true
                
        /* 초기 좌표 설정 */
        setUpAxis()
        
        /* 네이버 맵 설정 */
        setUpMap()
        
        /* SearchBar 설정 */
        setUpSearchBar()
        
        /* Observable 설정 */
        setUpObservable()
        
        
        
        
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
    
    override func viewWillAppear(_ animated: Bool) {
        
        
        /* 앱을 처음 실행할 때에는 selected된 지역이 없기 때문에 설정 페이지로 들어가게 함.*/
        let selected = UserDefaults.standard.object(forKey: "selected") as? [String]
        print("selected? = \(selected)")
        
        if(selected == []){
            let tb = self.tabBarController
            tb?.selectedIndex = 2
        }
    }
    
    
    func setUpSearchBar(){
        searchBar = UISearchBar()
        searchBar.delegate = self
        
        /* UI 설정 */
        searchBar.sizeToFit()
        searchBar.searchBarStyle = .minimal
        searchBar.backgroundColor = UIColor.white
        searchBar.layer.borderColor = UIColor.lightGray.cgColor
        searchBar.layer.borderWidth = 0.5
        searchBar.layer.cornerRadius = 10
        searchBar.placeholder = "가게 정보 검색"
        searchBar.isTranslucent = false
        
        searchBar.layer.shadowColor = UIColor.black.cgColor
        searchBar.layer.shadowOpacity = 0.15
        searchBar.layer.shadowOffset = CGSize(width: 0, height: 2)
        searchBar.layer.shadowRadius = 7
        
        // 뷰 추가
        view.addSubview(searchBar)
        
        // (뷰 추가 후) Autolayout 조절
        searchBar.translatesAutoresizingMaskIntoConstraints = false
        searchBar.widthAnchor.constraint(equalToConstant: 300).isActive = true
        searchBar.heightAnchor.constraint(equalToConstant: 50).isActive = true
        
        searchBar.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 13).isActive = true
        searchBar.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 15).isActive = true
        searchBar.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: -15).isActive = true
        
    }
    
    func searchBarTextDidBeginEditing(_ searchBar: UISearchBar) {
        if let FC = self.storyboard?.instantiateViewController(withIdentifier: "FindController") as? FindController{
            
            /* Modal: Present/Dismiss (Modal 대신 Navigation 형식 채택  */
            //            controller.modalTransitionStyle = .crossDissolve
            //            controller.modalPresentationStyle = .fullScreen
            //            self.present(controller, animated: true, completion: nil)
            
            /* Navigation: Push/Pop */
            
            // 1. 전환 애니메이션
            let transition = CATransition()
            transition.duration = 0.2
            transition.type = CATransitionType.fade
            self.navigationController?.view.layer.add(transition, forKey:nil)
            
            // 2. FindController로부터 데이터 받기 위해 Delegate 설정
            FC.delegate = self
            
            // 3. FindController에게 데이터 전송
            FC.passedSearchName = searchText
            FC.passedCity = cityName
            
            self.navigationController?.pushViewController(FC, animated: false)
            
            // 키보드 내리기
            self.view.endEditing(true)
            
        }
        
    }
    
    
    func setUpMap(){
        
        /* 네이버 지도 객체 */
        mapView = NMFNaverMapView(frame: view.frame)
        view.addSubview(mapView)
        
        /* 현재 위치, 줌, 나침반, 축척 바 활성화 */
        mapView.showLocationButton = true
        mapView.showZoomControls = true
        mapView.showCompass = true
        mapView.showScaleBar = true
        
        // NMFMapViewCameraDelegate Delegate 등록
        mapView.mapView.addCameraDelegate(delegate: self)
        
        if lat != nil && lng != nil{
            let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: lat, lng: lng), zoomTo: 14)
            self.mapView.mapView.moveCamera(cameraUpdate)
        }
    }
    
    func setUpObservable(){
        
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
                        
                        storeInfo.append(tmpInfo)
                        
                    }
                }
                // 지도에 마커 표시
                self.addMarker(mapView: self.mapView, json: storeInfo)
                
        }
        
        /* FindController에서 가게리스트 클릭한 경우 호출되는 Observable */
        searchInfo.subscribe(onNext:{ store in
            
            for marker in self.markers{
                marker.mapView = nil
            }
            self.markers = []
            
            self.addMarker(mapView: self.mapView, json: [store])
            let cameraUpdate = NMFCameraUpdate(scrollTo: NMGLatLng(lat: store["lat"] as! Double, lng: store["lng"] as! Double), zoomTo: 17)
            
            
            self.mapView.mapView.moveCamera(cameraUpdate)
            
        })
        
    }
    
    /* 카메라 이동 콜백 */
    func mapView(_ mapView: NMFMapView, cameraIsChangingByReason reason: Int) { // NMFMapViewCameraDelegate 프로토콜 함수
        print("카메라가 변경됨 : reason : \(reason)")
        let cameraPosition = mapView.cameraPosition
        moveCamera.onNext(cameraPosition)
        
        
    }
    
    /* 지도 탭 콜백 */
    func mapView(_ mapView: NMFMapView, didTapMap latlng: NMGLatLng, point: CGPoint){
//        infoWindow.close()
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
//        infoWindow.dataSource = dataSource
        
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
                    
                    marker.iconImage = NMF_MARKER_IMAGE_GREEN
                    
                    // touchHandler: 마커마다 개별 핸들러 등록 콜백
                    marker.touchHandler = { (overlay: NMFOverlay) -> Bool in
                        
                        /* 클릭시 현재 마커 제외 모두 불투명으로 변경 */
                        for m in self.markers{
                            m.alpha = 0.1
                        }
                        marker.alpha = 1
                        
                        if let marker = overlay as? NMFMarker {
                            self.alertMessage(storeNameArrayInfo, phoneNumArrayInfo)

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
        alert.view.tintColor = UIColor.darkGray
        
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



extension ViewController: SendDataDelegate{
    
    /* FindController로부터 데이터를 받으면 searchInfo(subject)에게 전달 */
    func sendData(data: [String : Any], search: String) {
        
        searchInfo.onNext(data)
        if let storeName = data["storeName"] as? String{
            searchBar.text = storeName
        }
        if let city = data["city"] as? String{
            cityName = city
        }
        searchText = search
    }
    
}


