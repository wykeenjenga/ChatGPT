//
//  ViewController.swift
//  ChatGPT
//
//  Created by Wykee on 29/01/2023.
//

import UIKit
import SwiftyJSON
import Alamofire
import JGProgressHUD
import MessageKit
import InputBarAccessoryView

class APChatViewController: MessagesViewController, MessagesDataSource{
    
    let cameraItem = InputBarButtonItem(type: .system) // 1
    @IBOutlet weak var navBarView: UIView!
    
    var backgroundTaskID = UIBackgroundTaskIdentifier.invalid
    private var AlamofireManager: Session? = {
        let configuration = URLSessionConfiguration.default
        configuration.timeoutIntervalForRequest = 20000
        let alamofireManager = Session(configuration: configuration)
        return alamofireManager
    }()
    
    private let formatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter
    }()
    
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .darkContent
    }
    
    
    // MARK: - Public propertie
    lazy var messageList: [Message] = []
    //lazy var messageList = [Message]()
    var isGroupLeftMessageDispayed = false
    var isFirstSetLoaded: Bool = false

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        messagesCollectionView = MessagesCollectionView(frame: .zero, collectionViewLayout: CustomMessagesFlowLayout())
        messagesCollectionView.register(CustomChatCell.self)
        super.viewDidLoad()
        configureMessageCollectionView()
        configureMessageInputBar()
        cameraItem.tintColor = .orange
        cameraItem.image = UIImage(named: "camera_alt_black_24pt")
//        cameraItem.addTarget(
//            self,
//            action: #selector(cameraButtonPressed), // 2
//            for: .primaryActionTriggered
//        )
        cameraItem.setSize(CGSize(width: 60, height: 30), animated: false)
        
        messageInputBar.leftStackView.alignment = .center
        messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)
        messageInputBar.setStackViewItems([cameraItem], forStack: .left, animated: false) // 3
        messageInputBar.inputTextView.isImagePasteEnabled = false
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let gradient = CAGradientLayer()
        gradient.frame = navBarView.bounds
        gradient.colors = [UIColor(named: "yellow")!.cgColor,UIColor(named: "yellowFade")!.cgColor]
        navBarView.layer.insertSublayer(gradient, at: 0)
        self.view.bringSubviewToFront(navBarView)
        messagesCollectionView.contentInset = UIEdgeInsets(top: navBarView.bounds.size.height, left: 0, bottom: messageInputBar.frame.height + 8, right: 0)
        additionalBottomInset = 24
    }
    
    private func insertNewMessage(_ message: Message, isLoadingMore: Bool = false) {
        messageList.append(message)
        
        self.getResponse(with: message.message ?? "") { json, error in
            if error == nil{
                let jsonData = """
                \(json!)
                """.data(using: .utf8)!

                let data = try? JSONDecoder().decode(APGPTModel.self, from: jsonData)

                let results = data?.choices[0].text
                let data_renspose = results!.replacingOccurrences(of: "\n\n", with: "")
                
                let date = Date()
                
                let msg = Message(id: UUID().uuidString, username: "OpenAI (Chat bot)", message: data_renspose, isUser: false, created: date)
                
                self.messageList.append(msg)
                
                self.messagesCollectionView.reloadData()
                self.messagesCollectionView.scrollToBottom(animated: self.isFirstSetLoaded)
            }

        }
        
        let isLatestMessage = messageList.firstIndex(of: message) == (messageList.count - 1)
        let shouldScrollToBottom = messagesCollectionView.isAtBottom && isLatestMessage
        let oldOffset = self.messagesCollectionView.contentSize.height - self.messagesCollectionView.contentOffset.y
        messagesCollectionView.reloadData()
        self.view.layoutIfNeeded()
        let currentOffset = self.messagesCollectionView.contentSize.height - oldOffset
        if isLoadingMore {
            messagesCollectionView.setContentOffset(CGPoint(x: 0, y: currentOffset), animated: false)
        } else {
            if shouldScrollToBottom {
                DispatchQueue.main.async {
                    self.messagesCollectionView.scrollToBottom(animated: self.isFirstSetLoaded)
                    self.isFirstSetLoaded = true
                }
            }
        }
    }
    
    //MARK: Configuration
    func configureMessageCollectionView() {
        messagesCollectionView.messagesDataSource = self
        messagesCollectionView.messageCellDelegate = self
        messagesCollectionView.messagesLayoutDelegate = self
        messagesCollectionView.messagesDisplayDelegate = self
        if let layout = messagesCollectionView.collectionViewLayout as? MessagesCollectionViewFlowLayout {
            layout.textMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.textMessageSizeCalculator.incomingAvatarSize = .zero
            layout.photoMessageSizeCalculator.outgoingAvatarSize = .zero
            layout.photoMessageSizeCalculator.incomingAvatarSize = .zero
            let edgeInsetForIncoming = UIEdgeInsets(top: 0, left: 15, bottom: 0, right: 0)
            let edgeInsetForOutgoing = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 15)
            layout.setMessageIncomingMessageTopLabelAlignment(LabelAlignment(textAlignment: .left, textInsets: edgeInsetForIncoming))
            layout.setMessageOutgoingMessageTopLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: edgeInsetForOutgoing))
            layout.setMessageIncomingMessageBottomLabelAlignment(LabelAlignment(textAlignment: .left, textInsets: edgeInsetForIncoming))
            layout.setMessageOutgoingMessageBottomLabelAlignment(LabelAlignment(textAlignment: .right, textInsets: edgeInsetForOutgoing))
            layout.sectionInset = UIEdgeInsets(top: -10, left: 0, bottom: -5, right: 0)
            layout.minimumInteritemSpacing = 0
            layout.minimumLineSpacing = 0
        }
        scrollsToBottomOnKeyboardBeginsEditing = true // default false
        maintainPositionOnKeyboardFrameChanged = true // default false
    }
    
    func configureMessageInputBar() {
        messageInputBar.delegate = self
        messageInputBar.inputTextView.tintColor = UIColor(named: "yellow")
        messageInputBar.sendButton.setTitleColor(UIColor(named: "yellow"), for: .normal)
        messageInputBar.sendButton.setTitleColor(
            UIColor.orange.withAlphaComponent(0.3),
            for: .highlighted
        )
        messageInputBar.inputTextView.layer.borderColor = UIColor(named: "yellow")?.cgColor
        messageInputBar.inputTextView.layer.borderWidth = 1.0
        messageInputBar.inputTextView.layer.cornerRadius = 12
        messageInputBar.sendButton.title = ""
        messageInputBar.sendButton.image = UIImage(systemName: "paperplane")
        messageInputBar.sendButton.setTitleColor(.brown, for: .normal)
        messageInputBar.sendButton.setTitleColor(.brown.withAlphaComponent(1.0), for: .highlighted)
        messageInputBar.backgroundView.backgroundColor = .white
        
        let image = UIImage(systemName: "mic.fill")!
        let addButton = InputBarButtonItem(frame: CGRect(origin: .zero, size: CGSize(width: image.size.width, height: image.size.height)))
        addButton.image = image
        addButton.imageView?.contentMode = .scaleAspectFit

        messageInputBar.setStackViewItems([addButton], forStack: .left, animated: false)
        messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)

        messageInputBar.leftStackView.alignment = .center //HERE
    }
    
    func initMessageBarItems() {
        let image = UIImage(systemName: "mic.fill")!
        let addButton = InputBarButtonItem(frame: CGRect(origin: .zero, size: CGSize(width: image.size.width, height: image.size.height)))
        addButton.image = image
        addButton.imageView?.contentMode = .scaleAspectFit

        messageInputBar.setStackViewItems([addButton], forStack: .left, animated: false)
        messageInputBar.setLeftStackViewWidthConstant(to: 50, animated: false)

        messageInputBar.leftStackView.alignment = .center
        
        reloadInputViews()
    }
    
    func getResponse(with text: String, completion: @escaping(JSON?, Error?) -> Void){

        let url =  "ENTER YOUR API HERE"
        let parameters = ["prompt": text] as [String : Any]
        
        DispatchQueue.main.async {
            self.backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "FNT") {
                // End the task if time expires.
                UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
                self.backgroundTaskID = UIBackgroundTaskIdentifier.invalid
            }
            
            self.AlamofireManager!.request(url, method: .post, parameters: parameters,encoding: JSONEncoding.default).responseJSON{response in
                switch(response.result) {
                case .success(_):
                    if response.value != nil{
                        let json = JSON(response.value!)
                        let data = json["response"]
                        print("Request response data==>\(data)")
                        completion(data, nil)
                    }
                    break
                case .failure(let error):
                    completion(nil, error.asAFError)
                    break
                }
                self.endBGTask()
            }
        }
    }
    
    func endBGTask(){
        // End the task assertion.
        UIApplication.shared.endBackgroundTask(self.backgroundTaskID)
        self.backgroundTaskID = UIBackgroundTaskIdentifier.invalid
    }
    
    override func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
       
       guard let messagesDataSource = messagesCollectionView.messagesDataSource else {
           fatalError("Ouch. nil data source for messages")
       }

       let message = messagesDataSource.messageForItem(at: indexPath, in: messagesCollectionView)
       if case .custom = message.kind {
           let cell = messagesCollectionView.dequeueReusableCell(CustomChatCell.self, for: indexPath)
           cell.configure(with: message, at: indexPath, and: messagesCollectionView)
           return cell
       }
       return super.collectionView(collectionView, cellForItemAt: indexPath)
   }
   
   override func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
       if indexPath.section < 10 && isFirstSetLoaded {
           DispatchQueue.global(qos: .background).async {
               //self.loadChatWithPagination()
           }
       }
   }
    
    func currentSender() -> SenderType {
        return MessageUser(senderId: "0000", displayName: "Wycliff")
    }

    func messageForItem(at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageType {
        return messageList[indexPath.section]
    }
    
    func numberOfSections(in messagesCollectionView: MessageKit.MessagesCollectionView) -> Int {
        return messageList.count
    }
    
    func cellTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        return NSAttributedString(string: MessageKitDateFormatter.shared.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 10), NSAttributedString.Key.foregroundColor: UIColor.darkGray])
    }
    
    func messageTopLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let name = message.sender.displayName
        return NSAttributedString(string: name, attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
        return nil
    }
    
    func messageBottomLabelAttributedText(for message: MessageType, at indexPath: IndexPath) -> NSAttributedString? {
        let formatter = DateFormatter()
        formatter.dateFormat = "hh:mm a"
        return NSAttributedString(string: formatter.string(from: message.sentDate), attributes: [NSAttributedString.Key.font: UIFont.preferredFont(forTextStyle: .caption1)])
    }

}


// MARK: - MessageCellDelegate

extension APChatViewController: MessageCellDelegate {

    func didTapImage(in cell: MessageCollectionViewCell) {
        print("Image tapped")
    }
}

// MARK: - MessageInputBarDelegate

extension APChatViewController: InputBarAccessoryViewDelegate {
    
    @objc
    func inputBar(_ inputBar: InputBarAccessoryView, didPressSendButtonWith text: String) {
        processInputBar(messageInputBar)
    }
    
    func processInputBar(_ inputBar: InputBarAccessoryView) {
        // Here we can parse for which substrings were autocompleted
        let attributedText = inputBar.inputTextView.attributedText!
        let range = NSRange(location: 0, length: attributedText.length)
        attributedText.enumerateAttribute(.autocompleted, in: range, options: []) { (_, range, _) in
            
            let substring = attributedText.attributedSubstring(from: range)
            let context = substring.attribute(.autocompletedContext, at: 0, effectiveRange: nil)
            print("Autocompleted: `", substring, "` with context: ", context ?? [])
        }
        
        let components = inputBar.inputTextView.components
        inputBar.inputTextView.text = String()
        inputBar.invalidatePlugins()
        // Send button activity animation
        inputBar.sendButton.startAnimating()
        inputBar.inputTextView.placeholder = "Sending..."
        // Resign first responder for iPad split view
        DispatchQueue.global(qos: .default).async {
            // fake send request task
            sleep(1)
            DispatchQueue.main.async { [weak self] in
                inputBar.sendButton.stopAnimating()
                inputBar.inputTextView.placeholder = "Ask anything..."
                self?.insertMessages(components)
                self?.messagesCollectionView.scrollToBottom(animated: true)
            }
        }
    }
    
    private func insertMessages(_ data: [Any]) {
        for component in data {
            if let str = component as? String {
                let currentDate = Date()
                let message = Message(id: "0000", username: "Wycliff", message: str, isUser: true, created: currentDate)
                insertNewMessage(message)
                //save(message)
            }
        }
    }
}

// MARK: - MessagesDisplayDelegate

extension APChatViewController: MessagesDisplayDelegate {
    
    // MARK: - Text Messages
    
    func textColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? .white : .darkText
    }
    
    func detectorAttributes(for detector: DetectorType, and message: MessageType, at indexPath: IndexPath) -> [NSAttributedString.Key: Any] {
        switch detector {
        case .hashtag, .mention: return [.foregroundColor: UIColor.blue]
        default: return MessageLabel.defaultAttributes
        }
    }
    
    func enabledDetectors(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> [DetectorType] {
        return [.url, .address, .phoneNumber, .transitInformation, .mention, .hashtag]
    }
    
    // MARK: - All Messages
    
    func backgroundColor(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> UIColor {
        return isFromCurrentSender(message: message) ? UIColor(named: "header")! : UIColor(red: 230/255, green: 230/255, blue: 230/255, alpha: 1)
    }
    
    func messageStyle(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> MessageStyle {
        
        let tail: MessageStyle.TailCorner = isFromCurrentSender(message: message) ? .bottomRight : .bottomLeft
        return .bubbleTail(tail, .curved)
    }
    
    func configureMediaMessageImageView(_ imageView: UIImageView, for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) {
        
//        let displayImage = isFromCurrentSender(message: message)
//        imageView.image = messageList[indexPath.section].image
//        if let photoLibraryURL = messageList[indexPath.section].photoLibraryURL, let image = getImageFromPhotoLib(imageUrl: photoLibraryURL) {
//            imageView.image = image
    }
}



// MARK: - MessagesLayoutDelegate

extension APChatViewController: MessagesLayoutDelegate {
  
    func cellTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        if indexPath.section >= 1 {
            let lastMessage = messageList[indexPath.section - 1]
            
            if lastMessage.created.isInSameDayOf(date: message.sentDate) {
                return 0
            }
        }
        return 18
    }
    
    func cellBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 32
    }
    
    func messageTopLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 24
    }
    
    func messageBottomLabelHeight(for message: MessageType, at indexPath: IndexPath, in messagesCollectionView: MessagesCollectionView) -> CGFloat {
        return 18
    }
}
