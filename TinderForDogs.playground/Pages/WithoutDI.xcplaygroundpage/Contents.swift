import UIKit

class Api {
    func send(request: URLRequest, completion: (([String: Any], HTTPURLResponse) -> Void)?) {
        let configuration = URLSessionConfiguration.default
        let session = URLSession(configuration: configuration)
        let dataTask = session.dataTask(with: request.url!) { data,response,error in
            guard let httpResponse = response as? HTTPURLResponse, let receivedData = data
                else {
                    print("Uh oh")
                    return
            }
            switch (httpResponse.statusCode) {
            case 200: //success response.
                if let json = try? JSONSerialization.jsonObject(with: receivedData, options: []) as? [String: Any] {
                    completion?(json, httpResponse)
                }
                break
            case 400:
                print("Whoops")
                break
            default:
                print("Oh no")
                break
            }
        }
        dataTask.resume()
    }
}

struct DogProfile : Decodable {
    var id: String
    var name: String
    var breed: String
    var description: String
    var imageLinks: [String]
    
    init(dictionary: [String: Any]) {
        self.id = dictionary["id"] as? String ?? ""
        self.name = dictionary["name"] as? String ?? ""
        self.breed = dictionary["breed"] as? String ?? ""
        self.description = dictionary["description"] as? String ?? ""
        self.imageLinks = dictionary["imageLinks"] as? [String] ?? []
    }
}

enum SwipeDirection {
    case left
    case right
}

class DogFetcher {
    func getDogProfiles(count: Int, completion: (([DogProfile]) -> Void)?) {
        var request = URLRequest(url: URL(string: "https://tinderfordogs.io/me/dogs?count=\(count)")!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        Api().send(request: request) { (jsonData, response) in
            let jsonProfiles = jsonData["profiles"] as? [[String: Any]]
            guard let dogProfiles = jsonProfiles?.map({ DogProfile(dictionary: $0) }) else {
                completion?([])
                return
            }
            completion?(dogProfiles)
        }
    }
    
    func postSwipe(direction: SwipeDirection, profileId: String, completion: ((Bool) -> Void)?) {
        var request = URLRequest(url: URL(string: "https://tinderfordogs.io/me/swipe")!)
        request.httpMethod = "POST"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        Api().send(request: request) { (jsonData, response) in
            completion?(true)
        }
    }
}

class SwipeViewController : UIViewController {
    var dogProfiles: [DogProfile] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        DogFetcher().getDogProfiles(count: 10) { dogProfiles in
            self.dogProfiles = dogProfiles
        }
    }
    
    // Reject
    func swipeLeft() {
        let profile = dogProfiles.removeFirst()
        DogFetcher().postSwipe(direction: .left, profileId: profile.id, completion: nil)
    }
    
    // Approve
    func swipeRight() {
        let profile = dogProfiles.removeFirst()
        DogFetcher().postSwipe(direction: .right, profileId: profile.id, completion: nil)
    }
}
print("woof")
