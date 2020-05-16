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
    
    
    
    var passedSearchName: String?
    var passedCity: String?
    
    @IBOutlet weak var searchStore_SearchBar: UISearchBar!
    @IBOutlet weak var StoreInfo_TableView: UITableView!
    @IBOutlet weak var searchCount_Label: UILabel!
    
    var locationManager: CLLocationManager!
    var lat: Double!
    var lng: Double!
    
    @IBOutlet weak var bar: UIView!
    
    var delegate: SendDataDelegate?

    
    var backBtn : UIButton!
    
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

//        guard let first = storyboard?.instantiateViewController(withIdentifier: "ViewController") else { return }
//        guard let second = storyboard?.instantiateViewController(withIdentifier: "FindController") else { return }

//        let tb = self.tabBarController
//
//        var firstTab = self.tabBarController?.viewControllers![0] as! ViewController
//
//
//        firstTab.searchInfo.onNext(self.shownStore[indexPath.row])
//
//        tb?.selectedIndex = 0
        
        if let controller = self.storyboard?.instantiateViewController(withIdentifier: "ViewController") as? ViewController{

            
            let transition = CATransition()
            transition.duration = 0.2
            transition.type = CATransitionType.fade
            self.navigationController?.view.layer.add(transition, forKey:nil)
            
            delegate?.sendData(data: self.shownStore[indexPath.row], search: searchStore_SearchBar.text!)



            self.navigationController?.popViewController(animated: false)
//            controller.searchInfo.onNext(self.shownStore[indexPath.row])


            
        }
        
    }

    var button = dropDownBtn()

    
    func setUpBackBtn(){
        backBtn = UIButton(frame: CGRect(x: 0, y: 0, width: 100, height: 50))
        
        if let image = UIImage(named: "back_button"){
            backBtn.setImage(image, for: .normal)
        }
        
        self.view.addSubview(backBtn)
        
        
        // 뷰 추가 후 constraint 조절
        backBtn.translatesAutoresizingMaskIntoConstraints = false
        
//        backBtn.centerXAnchor.constraint(equalTo: view.centerXAnchor).isActive = true
        
        backBtn.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20).isActive = true
        
        backBtn.leadingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.leadingAnchor, constant: 20).isActive = true
//        backBtn.trailingAnchor.constraint(equalTo: view.safeAreaLayoutGuide.trailingAnchor, constant: 130).isActive = true
        
        backBtn.widthAnchor.constraint(equalToConstant: 25).isActive = true
        backBtn.heightAnchor.constraint(equalToConstant: 25).isActive = true
        
        backBtn.rx.tap.subscribe{ event in
            let transition = CATransition()
            transition.duration = 0.2
            transition.type = CATransitionType.fade
            self.navigationController?.view.layer.add(transition, forKey:nil)
            
            self.navigationController?.popViewController(animated: false)
        }
    }
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        
        
        let rect = CGRect(origin: CGPoint(x: 0,y :0), size: CGSize(width: self.StoreInfo_TableView.bounds.size.width, height: self.StoreInfo_TableView.bounds.size.height))
        let msgLabel = UILabel(frame: rect)
        msgLabel.textColor = UIColor.lightGray
        msgLabel.text = "검색 결과가 없어요"
        msgLabel.textAlignment = .center
        StoreInfo_TableView.backgroundView = msgLabel
        
        // 뒤로가기 버튼 설정
        setUpBackBtn()
        
        bar.layer.borderColor = UIColor(red: 239, green: 239, blue: 240, alpha: 1).cgColor
        bar.layer.borderWidth = 0.7
        
        
    
        //Configure the button
        button = dropDownBtn.init(frame: CGRect(x: 0, y: 0, width: 0, height: 0))
        button.setTitle("도시 선택", for: .normal)
        button.translatesAutoresizingMaskIntoConstraints = false
        
        //Add Button to the View Controller
        self.view.addSubview(button)
        
        //button Constraints
        button.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 11.5).isActive = true
        button.leadingAnchor.constraint(equalTo: backBtn.trailingAnchor, constant: 10).isActive = true
        //button.leftAnchor.constraint(equalTo: view.rightAnchor, constant: -50).isActive = true
        
        button.widthAnchor.constraint(equalToConstant: 85).isActive = true
        button.heightAnchor.constraint(equalToConstant: 40).isActive = true
        
       
        
        
        /* 검색 결과 최초 초기화 */
        if self.searchCount_Label.text == ""{
            self.searchCount_Label.text = "총 0개의 가맹점이 검색됐어요"
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
        
        /* 검색(searchbar) UI */
        searchStore_SearchBar.backgroundImage = UIImage()
        
        
        /* 검색 Observable */
        searchStore_SearchBar.rx.text
        .orEmpty
        .debounce(RxTimeInterval.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext:{ query in
                print(query)
                let realm = try! Realm()
               
                
                self.shownStore = [[String:Any]]()
                
                let model = realm.objects(StoreInfo.self).filter("storeName CONTAINS %@ AND city = %@", query, (self.button.titleLabel?.text)!)
                for store in model{
                    var storeTmp : [String:Any] = [:]
                    storeTmp["storeName"] = store.storeName
                    storeTmp["phoneNum"] = store.phoneNum
                    storeTmp["addr"] = store.addr
                    storeTmp["type"] = store.type
                    storeTmp["lat"] = store.lat
                    storeTmp["lng"] = store.lng
                    storeTmp["distance"] = self.checkLatLngRange(clat: self.lat, clng: self.lng, nlat: store.lat, nlng: store.lng)
                    storeTmp["city"] = self.button.titleLabel?.text!
                   
                    self.shownStore.append(storeTmp)
                    
                }
                self.shownStore = self.shownStore.sorted{($0["distance"]! as! Double) < ($1["distance"]! as! Double)}
                
                self.searchCount_Label.text = "총 \(model.count)개의 가맹점이 검색됐어요"
                
                
                self.StoreInfo_TableView.reloadData()
                
            })
        
        
    }
   
    
    override func viewWillAppear(_ animated: Bool) {
        if self.passedSearchName != nil && self.passedCity != nil{
            searchStore_SearchBar.text = self.passedSearchName
            button.setTitle(passedCity, for: .normal)
            searchStore_SearchBar.becomeFirstResponder()
//            searchStore_SearchBar.sear
        }
        
        
        var selected = UserDefaults.standard.object(forKey: "selected") as? [String]

        button.dropView.dropDownOptions = selected!
        button.dropView.tableView.reloadData()
        
        
        
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

protocol dropDownProtocol {
    func dropDownPressed(string : String)
}

class dropDownBtn: UIButton, dropDownProtocol {
    
    func dropDownPressed(string: String) {
        self.setTitle(string, for: .normal)
        self.dismissDropDown()
    }
    
    var dropView = dropDownView()
    
    var height = NSLayoutConstraint()
    
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        self.backgroundColor = UIColor.systemGreen
        self.layer.cornerRadius = 15
        
        dropView = dropDownView.init(frame: CGRect.init(x: 0, y: 0, width: 0, height: 0))
        dropView.delegate = self
        dropView.translatesAutoresizingMaskIntoConstraints = false
    }
    
    override func didMoveToSuperview() {
        self.superview?.addSubview(dropView)
        self.superview?.bringSubviewToFront(dropView)
        dropView.topAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        dropView.centerXAnchor.constraint(equalTo: self.centerXAnchor).isActive = true
        dropView.widthAnchor.constraint(equalTo: self.widthAnchor).isActive = true
        height = dropView.heightAnchor.constraint(equalToConstant: 0)
    }
    
    var isOpen = false
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        if isOpen == false {
            
            isOpen = true
            
            NSLayoutConstraint.deactivate([self.height])
            
            if self.dropView.tableView.contentSize.height > 150 {
                self.height.constant = 150
            } else {
                self.height.constant = self.dropView.tableView.contentSize.height
            }
            
            
            NSLayoutConstraint.activate([self.height])
            
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
                self.dropView.layoutIfNeeded()
                self.dropView.center.y += self.dropView.frame.height / 2
            }, completion: nil)
            
        } else {
            isOpen = false
            
            NSLayoutConstraint.deactivate([self.height])
            self.height.constant = 0
            NSLayoutConstraint.activate([self.height])
            UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
                self.dropView.center.y -= self.dropView.frame.height / 2
                self.dropView.layoutIfNeeded()
            }, completion: nil)
            
        }
    }
    
    func dismissDropDown() {
        isOpen = false
        NSLayoutConstraint.deactivate([self.height])
        self.height.constant = 0
        NSLayoutConstraint.activate([self.height])
        UIView.animate(withDuration: 0.5, delay: 0, usingSpringWithDamping: 0.5, initialSpringVelocity: 0.5, options: .curveEaseInOut, animations: {
            self.dropView.center.y -= self.dropView.frame.height / 2
            self.dropView.layoutIfNeeded()
        }, completion: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

class dropDownView: UIView, UITableViewDelegate, UITableViewDataSource  {
    
    var dropDownOptions = [String]()
    
    var tableView = UITableView()
    
    var delegate : dropDownProtocol!
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        
        tableView.backgroundColor = UIColor.clear
        self.backgroundColor = UIColor.clear
        
        
        tableView.delegate = self
        tableView.dataSource = self
        
        tableView.translatesAutoresizingMaskIntoConstraints = false
        
        self.addSubview(tableView)
        
        tableView.leftAnchor.constraint(equalTo: self.leftAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: self.rightAnchor).isActive = true
        tableView.topAnchor.constraint(equalTo: self.topAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: self.bottomAnchor).isActive = true
        
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dropDownOptions.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell()
        
        cell.textLabel?.text = dropDownOptions[indexPath.row]
        cell.backgroundColor = UIColor.systemGreen
        cell.layer.cornerRadius = 15
        cell.textLabel?.textColor = UIColor.white
        cell.textLabel?.font = UIFont.systemFont(ofSize: 15)

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.delegate.dropDownPressed(string: dropDownOptions[indexPath.row])
        self.tableView.deselectRow(at: indexPath, animated: true)
    }
    
}

