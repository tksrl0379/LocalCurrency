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
    
    @IBOutlet weak var progressBar: UIProgressView!
    @IBOutlet weak var city_TableView: UITableView!
    @IBOutlet weak var progressStatus_Label: UILabel!
    
    var info: PublishSubject<NSArray> = PublishSubject()
    
    var cities = ["가평군", "고양시", "과천시", "광명시", "광주시", "구리시", "군포시", "김포시", "남양주시", "동두천시", "부천시", "성남시", "수원시", "시흥시", "안산시", "안성시", "안양시", "양주시", "양평군", "여주시", "연천군", "오산시", "용인시", "의왕시", "의정부시", "이천시", "파주시", "평택시", "포천시", "하남시", "화성시"]
    var nicknames = ["가평사랑상품권", "고양페이", "과천토리", "광명사랑화폐", "광주사랑카드", "구리사랑카드", "군포애머니", "김포페이", "땡큐페이엔", "동두천사랑카드", "부천페이", "성남사랑상품권", "수원페이", "시루", "다온", "안성사랑카드", "안양사랑페이", "양주사랑카드", "양평페이", "여주사랑카드", "연천사랑상품권", "오색전", "용인와이페이", "의왕사랑상품권", "의정부사랑카드", "이천사랑지역화폐", "파주페이", "평택사랑상품권", "포천사랑상품권", "하머니", "화성행복지역화폐"]

    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return cities.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DownloadCell", for: indexPath) as! DownloadInfoCell
        
        /* 초기에는 무조건 검은색 표시 및 상호작용 가능 */
        cell.isUserInteractionEnabled = true
        cell.cityName_Label.textColor = .black
        cell.nickName_Label.textColor = .black
        
        // 다운로드 된 지역은 회색 표시 및 상호작용 불가능
        if let selected = UserDefaults.standard.object(forKey: "selected") as? [String]{
            for city in selected{
                if cities[indexPath.row].contains(city){
                    cell.isUserInteractionEnabled = false
                    cell.cityName_Label.textColor = .lightGray
                    cell.nickName_Label.textColor = .lightGray
                }
            }
        }

        cell.cityName_Label.text = cities[indexPath.row]
        cell.nickName_Label.text = nicknames[indexPath.row]
        
        return cell
    }
    /* 특정 Cell 클릭 이벤트 처리 */
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        var selected = UserDefaults.standard.object(forKey: "selected") as? [String]
        selected?.append(cities[indexPath.row])
        UserDefaults.standard.set(selected, forKey: "selected")
        
        
        city_TableView.reloadData()
        
        self.downloadCity(cityName: cities[indexPath.row])
        
    }
    
    
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        if UserDefaults.standard.object(forKey: "selected") == nil{
                UserDefaults.standard.set([], forKey: "selected")
        }
        
        city_TableView.delegate = self
        city_TableView.dataSource = self
        city_TableView.rowHeight = 50
        
        
        progressBar.progress = 0.0
        progressBar.transform = CGAffineTransform(scaleX: 1.0, y: 2.0)
        progressStatus_Label.text = "거주중인 지역을 선택하세요"
        
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
                        
                        print(Float(cityStore.count) / Float(totNum))
                        DispatchQueue.main.async {
                            self.progressBar.setProgress(Float(cityStore.count) / Float(totNum), animated: true)
                            if self.progressBar.progress < 1{
                                self.progressStatus_Label.text = "DB 적용 중"
                            }else{
                                self.progressStatus_Label.text = "DB 적용이 완료되었습니다 !"
                            }
                            
                        }
                        
                        if cityStore.count == totNum{
                            self.info.onNext([cityStore, cityName])
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

