//
//  FindController.swift
//  LocalCurrency
//
//  Created by a1111 on 2020/04/26.
//  Copyright © 2020 SIMPARK. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RealmSwift
import CoreLocation


class FindController: UIViewController, UITableViewDelegate, UITableViewDataSource, CLLocationManagerDelegate, UISearchBarDelegate, UITabBarControllerDelegate{
    
    @IBOutlet weak var searchStore_SearchBar: UISearchBar!
    @IBOutlet weak var StoreInfo_TableView: UITableView!
    @IBOutlet weak var searchCount_Label: UILabel!
    
    var locationManager: CLLocationManager!
    var lat: Double!
    var lng: Double!
    
    
    var shownStore = [[String:Any]]()

    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return shownStore.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "StoreInfoCell", for: indexPath) as! StoreInfoCell
        
        let store = self.shownStore[indexPath.row]
        
        cell.storeName_Label.text = store["storeName"] as! String
        cell.phoneNum_Label.text = store["phoneNum"] as! String
        cell.addr_Label.text = store["addr"] as! String
        cell.type_Label.text = store["type"] as! String
        cell.distance_Label.text = String(format: "%.2f", store["distance"] as! Double) + " km"

        
        return cell
    }
    
    /* 특정 Cell 클릭 이벤트 처리 */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        guard let first = storyboard?.instantiateViewController(withIdentifier: "ViewController") else { return }
        guard let second = storyboard?.instantiateViewController(withIdentifier: "FindController") else { return }

        let tb = self.tabBarController
        
        var firstTab = self.tabBarController?.viewControllers![0] as! ViewController
        
        
        firstTab.info.onNext(self.shownStore[indexPath.row])
        
        tb?.selectedIndex = 0
        
        
    }

    
    override func viewDidLoad() {
        super.viewDidLoad()
    
        /* 검색 결과 최초 초기화 */
        if self.searchCount_Label.text == ""{
            self.searchCount_Label.text = "검색 결과 총 0개의 가맹점이 검색됐어요"
        }
        
        /* 현재 좌표 받기 */
        locationManager = CLLocationManager()
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.desiredAccuracy = kCLLocationAccuracyBest
        locationManager.startUpdatingLocation()
        
        let coor = locationManager.location?.coordinate
        lat = coor?.latitude
        lng = coor?.longitude
        
        
        /* 키보드 설정: 테이블 탭하면 키보드 내려가도록 */
        let singleTapGestureRecognizer = UITapGestureRecognizer()

        singleTapGestureRecognizer.numberOfTapsRequired = 1
        singleTapGestureRecognizer.isEnabled = true
        singleTapGestureRecognizer.cancelsTouchesInView = false

        self.StoreInfo_TableView.addGestureRecognizer(singleTapGestureRecognizer)
        
        singleTapGestureRecognizer.rx.event.subscribe(onNext: { _ in
            self.view.endEditing(true)
        })
        
        
        /* 키보드 설정: 검색 버튼 탭하면 키보드 내려가도록 */
        searchStore_SearchBar.delegate = self


        /* 테이블 delegate 등록 및 설정 */
        StoreInfo_TableView.delegate = self
        StoreInfo_TableView.dataSource = self
        StoreInfo_TableView.rowHeight = 100
        
        /* 테이블 상단 채우기: 테이블 type을 grouped로 하면 상단이 공백이 됨 */
        var frame = CGRect.zero
        frame.size.height = .leastNormalMagnitude
        StoreInfo_TableView.tableHeaderView = UIView(frame: frame)
        
        /* 검색 Observable */
        searchStore_SearchBar.rx.text
        .orEmpty
        .debounce(RxTimeInterval.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext:{ query in
                print(query)
                let realm = try! Realm()
               
                
                self.shownStore = [[String:Any]]()
                let model = realm.objects(StoreInfo.self).filter("storeName CONTAINS %@ AND city = %@", query, "안산시")

                for store in model{
                    var storeTmp : [String:Any] = [:]
                    storeTmp["storeName"] = store.storeName
                    storeTmp["phoneNum"] = store.phoneNum
                    storeTmp["addr"] = store.addr
                    storeTmp["type"] = store.type
                    storeTmp["lat"] = store.lat
                    storeTmp["lng"] = store.lng
                    storeTmp["distance"] = self.checkLatLngRange(clat: self.lat, clng: self.lng, nlat: store.lat, nlng: store.lng)
                   
                    self.shownStore.append(storeTmp)
                    
                }
                self.shownStore = self.shownStore.sorted{($0["distance"]! as! Double) < ($1["distance"]! as! Double)}
                self.searchCount_Label.text = "검색 결과 총 \(model.count)개의 가맹점이 검색됐어요"
                
                self.StoreInfo_TableView.reloadData()
                
            })
        
        
    }
    
    
    // 좌표를 라디안으로 변환
    func deg2rad(_ number: Double) -> Double {
        return number * .pi / 180
    }
    
    // 좌표(위,경도) 간의 거리 측정
    func checkLatLngRange(clat: Double, clng: Double, nlat: Double, nlng: Double)->Double{
        
        return (6371 * acos(cos(deg2rad(clat)) * cos(deg2rad(nlat)) * cos(deg2rad(clng) - deg2rad(nlng)) + sin(deg2rad(clat)) * sin(deg2rad(nlat))))
    }
    
    
    /* 테이블을 제외한 나머지 부분 탭하면 키보드 내려가도록 */
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?){
        self.view.endEditing(true)
        
    }
    
    /* 검색 버튼 누르면 키보드 내려가도록 */
    func searchBarSearchButtonClicked( _ searchBar: UISearchBar)
    {
        self.view.endEditing(true)
    }

    
    
}
