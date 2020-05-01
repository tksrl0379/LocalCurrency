//
//  SettingController.swift
//  LocalCurrency
//
//  Created by a1111 on 2020/05/01.
//  Copyright © 2020 SIMPARK. All rights reserved.
//

import UIKit
import RxSwift
import RxCocoa
import RealmSwift

class SettingController: UIViewController, UITableViewDelegate, UITableViewDataSource{
    
    @IBOutlet weak var city_TableView: UITableView!
    
    var info: PublishSubject<NSArray> = PublishSubject()
    
    let cities = ["가평군", "고양시", "과천시", "광명시", "광주시", "구리시", "군포시", "김포시", "남양주시", "동두천시", "부천시", "성남시", "수원시", "시흥시", "안산시", "안성시", "안양시", "양주시", "양평군", "여주시", "연천군", "오산시", "용인시", "의왕시", "의정부시", "이천시", "파주시", "평택시", "포천시", "하남시", "화성시"]

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DownloadCell", for: indexPath) as! DownloadInfoCell
        
        cell.cityName_Label.text = cities[indexPath.row]
        
        return cell
    }
    /* 특정 Cell 클릭 이벤트 처리 */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        
        self.downloadCity(cityName: cities[indexPath.row])
        
    }
    
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        city_TableView.delegate = self
        city_TableView.dataSource = self
        city_TableView.rowHeight = 50
        
        
        
        
        
        info.subscribe(onNext: { jsonAndCity in
            let realm = try! Realm()
            var objects = [StoreInfo]()
            
            let json = jsonAndCity[0] as! NSArray
            let city = jsonAndCity[1] as! String
            for data in json {
                guard let data = data as? NSDictionary else {return}
                // 넣어주는 객체(storeinfo)는 계속 새로운 객체로 갈아줘야 함. 전역으로 싱글톤처럼 못씀.
                let storeInfo = StoreInfo()
                
                //                try! realm.write {
                
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
                
                if let addr = data["REFINE_ROADNM_ADDR"] as? String{
                    storeInfo.addr = addr
                }
                
                if let type = data["INDUTYPE_NM"] as? String{
                    storeInfo.type = type
                }
                
                
                storeInfo.city = city
                
                
                if storeInfo.lat == 0.0 || storeInfo.lng == 0.0{
                    print("위도 혹은 경도 0")
                }else{
                    
                    objects.append(storeInfo)
                    
                }
                
                
            }
            
            try! realm.write {
                realm.add(objects)
            }
            
            self.compactRealm()
            
            
            
            
        })
    }
    
    func downloadCity(cityName: String){
        
        
        /* 한글을 URL을 */
        let str_url = cityName.addingPercentEncoding(withAllowedCharacters: .urlQueryAllowed)!
        let req = URLRequest(url: URL(string: "https://openapi.gg.go.kr/RegionMnyFacltStus?Type=json&KEY=a8a1f1ba57704081bed7d50952f4de61&pIndex=1&pSize=1&SIGUN_NM=\(str_url)")!)
        
        // 탭 누를 때마다 새로 생성된 subject 객체가 있어야 함. 전역으로 둘거면 totalNumber.subscribe 안에서 계속 기존 totalnumber를 bind하는 urlsession observable의 disposable 객체를 dispose해줘야함
        let totalNumber: PublishSubject<Int> = PublishSubject()
        
        URLSession.shared.rx.json(request: req)
            .map(self.checkValid)
            .bind(to: totalNumber)
        
        var cityStore : [[String:Any]] = [[String:Any]]()
        
        totalNumber.subscribe(onNext:{ totNum in
            print("총개수:\(totNum)")
            for idx in 1...(totNum/1000)+1{
                
                print(idx)
                let req = URLRequest(url: URL(string: "https://openapi.gg.go.kr/RegionMnyFacltStus?Type=json&KEY=a8a1f1ba57704081bed7d50952f4de61&pIndex=\(idx)&pSize=1000&SIGUN_NM=\(str_url)")!)
                URLSession.shared.rx.json(request: req)
                    .map(self.parseJson)
                    .bind{ json in
                        
                        if let json = json as? [[String:Any]]{
                            cityStore += json
                        }
                        print("누적개수:", cityStore.count)
                        if cityStore.count == totNum{
                            self.info.onNext([cityStore, "안산시"])
                        }
                        
                }
            }
        })
        
        
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
}
