//
//  ViewController.swift
//  MiaoPaiVideo
//
//  Created by Phoebe Hu on 9/26/15.
//  Copyright (c) 2015 Phoebe Hu. All rights reserved.
//

import UIKit
import Alamofire

class ViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    var log = [String]()
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textview: UITextView!

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.dataSource = self
        tableView.delegate = self
        
        textview.text = "http://video.weibo.com/show?fid=1034:bf1a8c18f10c387770de4089b43b56a6"
        // Do any additional setup after loading the view, typically from a nib.
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return log.count
    }
    
    func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("logCell", forIndexPath: indexPath) 
        let label = cell.subviews[0].subviews[0] as! UILabel
        label.text = log[indexPath.row]
        return cell
    }
    
    func newLog(log: String, replace: Bool = false) {
        dispatch_async(dispatch_get_main_queue()) {
            print("new log \(log)")
            if replace {
                self.log[0] = log
            } else {
                self.log.insert(log, atIndex: 0)
            }
            self.tableView?.reloadData()
        }
    }
    @IBAction func addURL(sender: AnyObject) {
        print("add url")
        newLog("开始解析地址")
        guard let urlString = textview.text else {
            newLog("地址还没填")
            return
        }
        
        request(.GET, urlString).responseString { response in
          
            switch response.result {
            case let .Success(html):
                
                self.newLog("得到了一个网页")
                
                let match = html =~ "http%3A%2F%2Fus.sinaimg.cn.*vf=vshow"
                guard match.items.count == 1 else {
                    self.newLog("得到了\(match.items.count)个直播地址，不对")
                    return
                }
                self.newLog("开始破解秒拍的参数")
                let capture = match.items[0]
                print("capture = \(capture)")
                let miaopaiURL = capture
                    .replaceAll("%3A", replacement: ":")
                    .replaceAll("%2F", replacement: "/")
                    .replaceAll("%3F", replacement: "?")
                    .replaceAll("%3D", replacement: "=")
                    .replaceAll("%2C", replacement: ",")
                    .replaceAll("%26", replacement: "&")
                print("miaopai url = \(miaopaiURL)")
//                let miaopaiURL = "http://us.sinaimg.cn/" + capture[16..<capture.characters.count]
                print("miaopai = \(miaopaiURL)")
                Alamofire.request(.GET, miaopaiURL).responseString { response in
                    switch response.result {
                    case let .Success(m3u8):
                        let mp4 = m3u8 =~ ".*mp4"
                        print("mp4 = \(mp4.items)")
                        guard mp4.items.count == 1 else {
                            self.newLog("得到了 \(mp4.items.count) 个视频地址，不对")
                            return
                        }
                        let urlString = "http://us.sinaimg.cn/" + mp4.items[0]
                        print("url = \(urlString)")
                        self.newLog("开始下载视频了哦")
                        self.newLog("0")
                        var fileURL: NSURL?
                        let destination: Request.DownloadFileDestination = { args in
                            let ret = Request.suggestedDownloadDestination()(args)
                            fileURL = ret
                            return ret
                        }
                    
                        Alamofire.download(.GET, urlString, destination: destination).progress { _, read, total in
                            self.newLog("\(read) / \(total)", replace: true)
                            }.response { request, response, data, error in
                                guard nil == error else {
                                    print("error = \(error)")
                                    self.newLog("下载视频失败")
                                    guard let url = fileURL else { return }
                                    do { try NSFileManager.defaultManager().removeItemAtURL(url) }
                                    catch _ {}
                                    return
                                }
                                guard let url = fileURL else  {
                                    self.newLog("不知道下载到哪里了")
                                    return
                                }
                                self.newLog("下载好了,正在存到相册")
                                url.asMedia(.Video).saveToAlbum { success, _, _ in
                                    if success {
                                        self.newLog("存好了")
                                    } else {
                                        self.newLog("最后一步保存失败")
                                    }
                                    guard let url = fileURL else { return }
                                    do { try NSFileManager.defaultManager().removeItemAtURL(url) }
                                    catch _ {}
                                }
                        }
//                        NSURL(string: urlString)!.asMedia(.Video).saveToAlbum { success, _, error in
//                            if success {
//                                self.newLog("下载成功了，去相册里找找")
//                            } else {
//                                self.newLog("下载失败了 \(error)")
//                            }
//                            
//                        }
                    case let .Failure(error):
                        print("error = \(error)")
                        self.newLog("破解失败\(error)")
                    }
                }
            case let .Failure(error):
                self.newLog("错误: \(error)")
            }
            
        }
    }


}

