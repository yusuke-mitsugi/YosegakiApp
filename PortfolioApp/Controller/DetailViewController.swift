//
//  DetailViewController.swift
//  PortfolioApp
//
//  Created by Yusuke Mitsugi on 2020/05/20.
//  Copyright © 2020 Yusuke Mitsugi. All rights reserved.
//

import UIKit
import SDWebImage
import Firebase
import FirebaseDatabase


class DetailViewController: UIViewController, SelectStampDelegate, YosegakiDelegate {
    
    
    @IBOutlet weak var contentsImageView: UIImageView!
    
    var contentImage = String()
    var screenShotImage = UIImage()
    
    var stampImageView = UIImageView()
    var nameLabel = UILabel()
    var messageLabel = UILabel()
    
    var xPosition = CGFloat()
    var yPosition = CGFloat()
    
    //タッチしたビューの中心とタッチした場所の座標のズレを保持する変数
    var gapX:CGFloat = 0.0  // x座標
    var gapY:CGFloat = 0.0  // y座標
    
    
    
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        xPosition = 100
        yPosition = 300
        
        contentsImageView.frame = CGRect(x: 0,
                                         y: (view.bounds.size.height)/3,
                                         width: view.bounds.size.width,
                                         height: view.bounds.size.width)
        contentsImageView.sd_setImage(with: URL(string: contentImage), completed: nil)
        contentsImageView.layer.borderWidth = 2
        contentsImageView.layer.borderColor = UIColor.blue.cgColor
        contentsImageView.layer.shadowOffset = CGSize(width: 3, height: 3 )
        contentsImageView.contentMode = .scaleAspectFill
        
        
        stampImageView.frame = CGRect(x: 100,
                                      y: 300,
                                      width: 80,
                                      height: 80)
        nameLabel.frame = CGRect(x: 100,
                                 y: 300,
                                 width: 80,
                                 height: 80)
        messageLabel.frame = CGRect(x: 100,
                                    y: 300,
                                    width: 80,
                                    height: 80)
    }
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.navigationController?.setNavigationBarHidden(false, animated: true)
    }
    
    
    
    
    @IBAction func shareAction(_ sender: Any) {
        //スクリーンショットを撮る
        takeScreenShot()
        let item = [screenShotImage] as Any
        //DBのchildを決める
        let detailDB = Database.database().reference().child("detail").childByAutoId()
        //ストレージサーバーのURLを取得する
        let storage = Storage.storage().reference(forURL: "gs://yosegakiapp-97cab.appspot.com/")
        //フォルダを作る。フォルダの中に画像に入っていく
        let key = detailDB.child("screenShot").childByAutoId().key
        let imageRef = storage.child("screenShot").child("\(String(describing: key!)).jpeg")
        //　データ型
        var shareImageData:Data = Data()
        if contentsImageView.image != nil {
            //画像がデータ型になっている
            shareImageData = (contentsImageView.image?.jpegData(compressionQuality: 0.01))!
        }
        //最初のストレージに画像を送る段階. metaDataの中に入らないと先には進めない
        let upLoadTask = imageRef.putData(shareImageData, metadata: nil) {
            (metaData, error) in
            if error != nil {
                return
            }
            //ストレージに送った画像URLを受け取る
            imageRef.downloadURL { (url, error) in
                if url != nil {
                    //キーバリュー型でDBに送信するデータを準備をする　Stringで渡さなきゃいけない！
                    let detailInfo = [
                        "screenShot":url?.absoluteString as Any
                        ] as [String:Any]
                    //下の１行でDBに送信したという意味
                    detailDB.updateChildValues(detailInfo)
                    //これでnavigationControllerで画面遷移した時に戻るという指示
                    self.navigationController?.popViewController(animated: true)
                }
            }
        }
        //続けてください
        upLoadTask.resume()
        //アクティビティヴューに乗せてシェアする
        let activityVC = UIActivityViewController(activityItems: item as! [Any], applicationActivities: nil)
        present(activityVC, animated: true, completion: nil)
    }
    
    
    
    
    
    func takeScreenShot() {
        
        let width = CGFloat(UIScreen.main.bounds.size.width)
        let height = CGFloat(UIScreen.main.bounds.size.height/1.3)
        let size = CGSize(width: width, height: height)
        UIGraphicsBeginImageContextWithOptions(size, false, 0.0)
        //viewに書き出す
        self.view.drawHierarchy(in: view.bounds, afterScreenUpdates: true)
        screenShotImage = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
    }
    
    
    
    @IBAction func saveAction(_ sender: Any) {
        
        UIGraphicsBeginImageContextWithOptions(CGSize(width: 414, height: 414), false, 0)
        self.view.drawHierarchy(in: CGRect(x: 0,
                                           y:-100,
                                           width: view.bounds.size.width,
                                           height: view.bounds.size.height), afterScreenUpdates: true)
        let image = UIGraphicsGetImageFromCurrentImageContext()!
        UIGraphicsEndImageContext()
        UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
        saveAlert()
    }
    
    
    
    
    
    @IBAction func stampList(_ sender: Any) {
        // スタンプの可変の値を保持
        view.addSubview(stampImageView)
        self.performSegue(withIdentifier: "toStampList", sender: self)
    }
    
    
    
    @IBAction func didTapMessages() {
        
        guard let vc = storyboard?.instantiateViewController(identifier: "list") as? YosegakiListViewController else {
            return
        }
        vc.title = "Messages"
        vc.navigationItem.largeTitleDisplayMode = .never
        view.addSubview(nameLabel)
        view.addSubview(messageLabel)
        //        navigationController?.pushViewController(vc, animated: true)
        self.performSegue(withIdentifier: "toMessage", sender: self)
    }
    
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        
        if segue.identifier == "toStampList" {
            let stampVC = segue.destination as! StampChoiseViewController
            stampVC.delegate = self
        }
        if segue.identifier == "toMessage" {
            let yosegakiVC = segue.destination as! YosegakiListViewController
            yosegakiVC.delegate = self
            
        }
        //        if let vc = storyboard?.instantiateViewController(identifier: "list") as? YosegakiListViewController {
        //            vc.delegate = self
        //              }
    }
    
    
    
    //まかされたデリゲートメソッド（スタンプ）
    func selectStamp(stamp: UIImage) {
        
        let selectedImage = stamp
        //stampImageViewを初期化。スタンプの数だけUIImageViewを生成しなければいけない！
        stampImageView = UIImageView()
        stampImageView.frame = CGRect(x: xPosition, y: yPosition, width: 80, height: 80)
        stampImageView.image = selectedImage
        stampImageView.isUserInteractionEnabled = true
        contentsImageView.bringSubviewToFront(stampImageView)
        view.addSubview(stampImageView)
    }
    
    func yosegakiMessage(title: String, note: String) {
        
        let messageProfile = title
        let detailMessage = note
        nameLabel = UILabel()
        messageLabel = UILabel()
        nameLabel.text = messageProfile
        messageLabel.text = detailMessage
        nameLabel.backgroundColor = .white
        messageLabel.backgroundColor = .white
        messageLabel.layer.cornerRadius = 20
        nameLabel.frame = CGRect(x: xPosition, y: yPosition, width: 80, height: 40)
        messageLabel.frame = CGRect(x: xPosition, y: yPosition, width: 80, height: 100)
        nameLabel.isUserInteractionEnabled = true
        messageLabel.isUserInteractionEnabled = true
        contentsImageView.bringSubviewToFront(nameLabel)
        contentsImageView.bringSubviewToFront(messageLabel)
        view.addSubview(nameLabel)
        view.addSubview(messageLabel)
    }
    
    
    //    //画面上で指が動いた時に呼ばれるメソッド
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        //画面上のタッチ情報を取得
        let touchevent = touches.first!
        let location = touchevent.location(in: self.view)
        let view = touchevent.view!
        if view == self.view {
            return
        }
        let old = touchevent.previousLocation(in: contentsImageView)
        let new = touchevent.location(in: contentsImageView)
        view.frame.origin.x += (new.x - old.x)
        view.frame.origin.y += (new.y - old.y)
        //　重要
        xPosition = view.frame.origin.x
        yPosition = view.frame.origin.y
    }
    
    
    
    
    @IBAction func deleteStamp(_ sender: Any) {
        
        deleteTapped()
    }
    
    
    
    //スタンプ画像の削除
    func deleteTapped(){
        //Viewのサブビューの数が1より大きかったら実行
        if view.subviews.count > 1{
            //Viewの子ビューの最後のものを取り出す
            let lastStamp = view.subviews.last!
            //ViewからlastStampを削除する
            lastStamp.removeFromSuperview()
        }
    }
    
    
    func saveAlert() {
        let alert = UIAlertController(title: "保存完了", message: "カメラロールに保存しました", preferredStyle: .alert)
        // OKボタンを追加
        alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    
    
    
    
    
    
    
    
    
    
}
