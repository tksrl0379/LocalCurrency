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


class FindController: UIViewController, UITableViewDelegate, UITableViewDataSource{    
    
    @IBOutlet weak var searchStore_SearchBar: UISearchBar!
    @IBOutlet weak var StoreInfo_TableView: UITableView!
    @IBOutlet weak var searchCount_Label: UILabel!
    
    var shownStores = [String]()
    var shownPhoneNum = [String]()
    var shownAddr = [String]()
    var shownType = [String]()
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        return shownStores.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "StoreInfoCell", for: indexPath) as! StoreInfoCell
        
        cell.storeName_Label.text = shownStores[indexPath.row]
        cell.phoneNum_Label.text = shownPhoneNum[indexPath.row]
        cell.addr_Label.text = shownAddr[indexPath.row]
        cell.type_Label.text = shownType[indexPath.row]
        return cell
    }
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        StoreInfo_TableView.delegate = self
        StoreInfo_TableView.dataSource = self
        StoreInfo_TableView.rowHeight = 100
        
        var frame = CGRect.zero
        frame.size.height = .leastNormalMagnitude
        StoreInfo_TableView.tableHeaderView = UIView(frame: frame)
        
        searchStore_SearchBar.rx.text
        .orEmpty
        .debounce(RxTimeInterval.milliseconds(500), scheduler: MainScheduler.instance)
            .subscribe(onNext:{ query in
                print(query)
                let realm = try! Realm()
                self.shownStores = []
                self.shownPhoneNum = []
                self.shownAddr = []
                self.shownType = []
                let model = realm.objects(StoreInfo.self).filter("storeName CONTAINS %@ AND city = %@", query, "안산시")
               
                for store in model{
                    self.shownStores.append(store.storeName)
                    self.shownPhoneNum.append(store.phoneNum)
                    self.shownAddr.append(store.addr)
                    self.shownType.append(store.type)
                }
                self.searchCount_Label.text = "검색 결과 총 \(model.count)개의 가맹점이 검색됐어요"
                
                self.StoreInfo_TableView.reloadData()
                
            })
        
        
        
        /* textfield 선택 시 키보드 크기만큼 view를 올리기 위함 */
        /*
        searchStore_SearchBar.delegate = self
        //        pwd_Textfield.delegate = self
        
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillShow(_:)), name: UIResponder.keyboardWillShowNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(keyboardWillHide(_:)), name: UIResponder.keyboardWillHideNotification, object: nil)
        */
    }
    
    
    @objc func keyboardWillShow(_ sender: Notification) {
         self.view.frame.origin.y = -50 // Move view 150 points upward
    }
    
    @objc func keyboardWillHide(_ sender: Notification) {

        self.view.frame.origin.y = 0 // Move view to original position
    }
    
}
