//
//  F.swift
//  BilibiliLive
//
//  Created by Etan Chen on 2021/4/4.
//

import UIKit
import Alamofire
import SwiftyJSON

class FeedViewController: UIViewController, BLTabBarContentVCProtocol {
    let collectionVC = FeedCollectionViewController.create()
    var feeds = [FeedData]() {
        didSet {
            collectionVC.displayDatas = feeds.map{ DisplayData(title: $0.title, owner: $0.owner, pic: $0.pic) }
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        collectionVC.show(in: self)
        collectionVC.didSelect = {
            [weak self] idx in
            self?.goDetail(with: idx)
        }
        loadData()
    }
    
    func reloadData() {
        loadData()
    }
    
    func loadData() {
        AF.request("https://api.bilibili.com/x/web-feed/feed?ps=50&pn=1").responseJSON {
            [weak self] response in
            guard let self = self else { return }
            switch(response.result) {
            case .success(let data):
                let json = JSON(data)
                let datas = self.progrssData(json: json)
                self.feeds = datas
                
            case .failure(let error):
                print(error)
                break
            }
        }
    }
    
    func progrssData(json:JSON) -> [FeedData] {
        let datas = json["data"].arrayValue.map { data -> FeedData in
            let title = data["archive"]["title"].stringValue
            let cid = data["archive"]["cid"].intValue
            let avid = data["id"].intValue
            let owner = data["archive"]["owner"]["name"].stringValue
            let pic = data["archive"]["pic"].url!
            return FeedData(title: title, cid: cid, aid: avid, owner: owner, pic: pic)
        }
        return datas
    }
    
    func goDetail(with indexPath: IndexPath) {
        let feed = feeds[indexPath.item]
        let player = VideoPlayerViewController()
        player.aid = feed.aid
        player.cid = feed.cid
        present(player, animated: true, completion: nil)
    }
}

struct FeedData {
    let title: String
    let cid: Int
    let aid: Int
    let owner: String
    let pic: URL
}



