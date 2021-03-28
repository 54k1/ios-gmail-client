////
////  MessageComposeViewController.swift
////  EmailClient
////
////  Created by SV on 15/02/21.
////
//
// import GoogleAPIClientForREST
// import UIKit
//
// struct SendResponse: Codable {
//    let id: String
//    let threadId: String
//    let labelIds: [String]
// }
//
// class MessageComposeViewController: UIViewController {
//    @IBOutlet var bodyTextView: UITextView!
//    @IBOutlet var toTextField: UITextField!
//    @IBOutlet var subjectTextField: UITextField!
//
//    @IBOutlet var sendMessage: UIButton!
//    @IBAction func sendMessage(_: Any) {
//        let dateFormatter = DateFormatter()
//        dateFormatter.dateFormat = "EEE, dd MMM yyyy HH:mm:ss Z"
//        let raw =
//            "Date: \(dateFormatter.string(from: Date()))\r\n" +
//            // "From:\r\n" +
//            "To: \(toTextField.text!)\r\n" +
//            "Subject: \(subjectTextField.text!) \r\n\r\n" +
//            bodyTextView.text!
//
//        let base64 = GTLREncodeWebSafeBase64(raw.data(using: String.Encoding.utf8))
//        let jsonString = """
//        {
//            \"raw\": \"\(base64!)\"
//        }
//        """
//        print(jsonString)
//        let url = URL(string: "https://gmail.googleapis.com/gmail/v1/users/me/messages/send")!
//        var request = URLRequest(url: url)
//        request.httpMethod = "POST"
//        request.httpBody = jsonString.data(using: .utf8)
//        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
//        print(request.allHTTPHeaderFields)
//        Networker.fetch(fromRequest: request) {
//            (result: NetworkerResult<SendResponse>) in
//            print(result)
//        }
//        dismiss(animated: true, completion: nil)
//    }
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//
//        // Do any additional setup after loading the view.
//    }
//
//    /*
//     // MARK: - Navigation
//
//     // In a storyboard-based application, you will often want to do a little preparation before navigation
//     override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
//         // Get the new view controller using segue.destination.
//         // Pass the selected object to the new view controller.
//     }
//     */
// }
