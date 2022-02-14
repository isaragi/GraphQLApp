import UIKit
import PlaygroundSupport

PlaygroundPage.current.needsIndefiniteExecution = true

let url = URL(string: "http://localhost:4000/graphql")
var request = URLRequest(url: url!)
request.httpMethod = "POST"
request.addValue("application/json; charaset=utf-8" , forHTTPHeaderField: "Content-Type")

let query = """
{
  quoteOfTheDay
  random
  rollDice(numDice: 3, numSides: 6)
  getDie(numSides: 6) {
    rollOnce
    roll(numRolls: 3)
  }
}
"""

let body = ["query": query]
request.httpBody = try! JSONSerialization.data(withJSONObject: body, options: [])
request.cachePolicy = .reloadIgnoringLocalCacheData

let task = URLSession.shared.dataTask(with: request, completionHandler: { data, response, error in
    if let error = error {
        print(error)
        return
    }
    
    guard let data = data,
          let httpResponse = response as? HTTPURLResponse,
          httpResponse.statusCode == 200 else {
        return
    }
    
    do {
        let json = try JSONSerialization.jsonObject(with: data, options: []) as? [AnyHashable: Any]
        guard let data = json?["data"] as? [AnyHashable: Any] else { return }
        print(data)
        guard let getDie = data["getDie"] else { return }
        print(getDie)
        
    } catch let e {
        print("Parse error: \(e)")
    }
})

task.resume()
