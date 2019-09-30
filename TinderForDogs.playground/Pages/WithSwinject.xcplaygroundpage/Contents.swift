import UIKit
import Swinject

protocol AutoMockable { }

// MARK - Models

struct DogProfile : Decodable {
    var id: String
    var name: String
    var breed: String
    var description: String
    var imageLinks: [String]
    
    init() {
        id = ""
        name = ""
        breed = ""
        description = ""
        imageLinks = []
    }
    
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

// MARK - API

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

// MARK - DogFetcher

protocol FetchesDogs : AutoMockable {
    func getDogProfiles(count: Int, completion: (([DogProfile]) -> Void)?)
    func postSwipe(direction: SwipeDirection, profileId: String, completion: ((Bool) -> Void)?)
}

class DogFetcher : AutoMockable {
    var api: Api
    
    init(api: Api) {
        self.api = api
    }
    
    func getDogProfiles(count: Int, completion: (([DogProfile]) -> Void)?) {
        var request = URLRequest(url: URL(string: "https://tinderfordogs.io/me/dogs?count=\(count)")!)
        request.httpMethod = "GET"
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.addValue("application/json", forHTTPHeaderField: "Accept")
        self.api.send(request: request) { (jsonData, response) in
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
        self.api.send(request: request) { (jsonData, response) in
            completion?(true)
        }
    }
}

// MARK - SwipeVC

class SwipeViewController : UIViewController {
    let dogFetcher: FetchesDogs
    var dogProfiles: [DogProfile] = []
    
    init(dogFetcher: FetchesDogs) {
        self.dogFetcher = dogFetcher
        
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.dogFetcher.getDogProfiles(count: 10) { dogProfiles in
            self.dogProfiles = dogProfiles
        }
    }
    
    // Reject
    func swipeLeft() {
        let profile = dogProfiles.removeFirst()
        self.dogFetcher.postSwipe(direction: .left, profileId: profile.id, completion: nil)
    }
    
    // Approve
    func swipeRight() {
        let profile = dogProfiles.removeFirst()
        self.dogFetcher.postSwipe(direction: .right, profileId: profile.id, completion: nil)
    }
}


// MARK - Swinject Stuff

class DogAssembler {
    let assembler: Assembler
    static let shared = DogAssembler()
    var resolver: Resolver {
        // Resolver -> Container cast will always succeed, they're the same object underneath.
        return (assembler.resolver as! Container).synchronize()
    }
    
    init() {
        assembler = Assembler([
            DogAssembly(),
            ])
    }
    
    public static func resolve<Service>(_ serviceType: Service.Type) -> Service? {
        return DogAssembler.shared.resolver.resolve(serviceType)
    }
}

class DogAssembly : Assembly {
    func assemble(container: Container) {
        container.register(SwipeViewController.self) { resolver in SwipeViewController(dogFetcher: resolver.resolve(FetchesDogs.self)!) }
        container.register(DogFetcher.self) { resolver in DogFetcher(api: resolver.resolve(Api.self)!) }
        container.register(Api.self) { _ in Api() }
    }
}

class MockDogFetcher : FetchesDogs {
    init() {
        
    }
    
    //MARK: - getDogProfiles
    
    var getDogProfilesCountCompletionCallsCount = 0
    var getDogProfilesCountCompletionCalled: Bool {
        return getDogProfilesCountCompletionCallsCount > 0
    }
    var getDogProfilesCountCompletionReceivedArguments: (count: Int, completion: (([DogProfile]) -> Void)?)?
    var getDogProfilesCountCompletionClosure: ((Int, (([DogProfile]) -> Void)?) -> Void)?
    
    func getDogProfiles(count: Int, completion: (([DogProfile]) -> Void)?) {
        getDogProfilesCountCompletionCallsCount += 1
        getDogProfilesCountCompletionReceivedArguments = (count: count, completion: completion)
        getDogProfilesCountCompletionClosure?(count, completion)
    }
    
    //MARK: - postSwipe
    
    var postSwipeDirectionProfileIdCompletionCallsCount = 0
    var postSwipeDirectionProfileIdCompletionCalled: Bool {
        return postSwipeDirectionProfileIdCompletionCallsCount > 0
    }
    var postSwipeDirectionProfileIdCompletionReceivedArguments: (direction: SwipeDirection, profileId: String, completion: ((Bool) -> Void)?)?
    var postSwipeDirectionProfileIdCompletionClosure: ((SwipeDirection, String, ((Bool) -> Void)?) -> Void)?
    
    func postSwipe(direction: SwipeDirection, profileId: String, completion: ((Bool) -> Void)?) {
        postSwipeDirectionProfileIdCompletionCallsCount += 1
        postSwipeDirectionProfileIdCompletionReceivedArguments = (direction: direction, profileId: profileId, completion: completion)
        postSwipeDirectionProfileIdCompletionClosure?(direction, profileId, completion)
    }
}

func testViewDidLoad() {
    let mockDogFetcher = MockDogFetcher()
    mockDogFetcher.getDogProfilesCountCompletionClosure = { (_,completion) in
        var dp1 = DogProfile()
        dp1.id = "1"
        completion?([dp1])
    }
    let vc = SwipeViewController(dogFetcher: mockDogFetcher)
    vc.viewDidLoad()
    
    assert(vc.dogProfiles.count == 1)
    assert(vc.dogProfiles[0].id == "1")
}

func testSwipeLeft() {
    let mockDogFetcher = MockDogFetcher()
    mockDogFetcher.getDogProfilesCountCompletionClosure = { (_,completion) in
        var dp1 = DogProfile()
        dp1.id = "1"
        completion?([dp1])
    }
    let vc = SwipeViewController(dogFetcher: mockDogFetcher)
    vc.viewDidLoad()
    vc.swipeLeft()
    assert(mockDogFetcher.postSwipeDirectionProfileIdCompletionReceivedArguments?.direction == .left)
}

func testSwipeRight() {
    let mockDogFetcher = MockDogFetcher()
    mockDogFetcher.getDogProfilesCountCompletionClosure = { (_,completion) in
        var dp1 = DogProfile()
        dp1.id = "1"
        completion?([dp1])
    }
    let vc = SwipeViewController(dogFetcher: mockDogFetcher)
    vc.viewDidLoad()
    vc.swipeRight()
    assert(mockDogFetcher.postSwipeDirectionProfileIdCompletionReceivedArguments?.direction == .right)
}

testViewDidLoad()
testSwipeLeft()
testSwipeRight()
print("woof")

