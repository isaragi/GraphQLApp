//
//  Network.swift
//  RocketReserver
//
//  Created by 五十嵐淳 on 2022/02/16.
//  Copyright © 2022 Apollo GraphQL. All rights reserved.
//

import Foundation
import Apollo
import ApolloWebSocket
import ApolloSQLite

class Network {
    static let shared = Network()
    
    private(set) lazy var apollo: ApolloClient = {
        let client = URLSessionClient()
        
        let documentsPath = NSSearchPathForDirectoriesInDomains(
            .documentDirectory,
            .userDomainMask,
            true).first!
        let documentsURL = URL(fileURLWithPath: documentsPath)
        let sqliteFileURL = documentsURL.appendingPathComponent("test_apollo_db.sqlite")
        let cache = try? SQLiteNormalizedCache(fileURL: sqliteFileURL)
        let store = ApolloStore(cache: cache ?? InMemoryNormalizedCache())
        
        let provider = NetworkInterceptorProvider(client: client, store: store)
        let url = URL(string: "https://apollo-fullstack-tutorial.herokuapp.com/graphql")!
        let transport = RequestChainNetworkTransport(interceptorProvider: provider,
                                                     endpointURL: url)
        
        let webSocket = WebSocket(url: URL(string: "wss://apollo-fullstack-tutorial.herokuapp.com/graphql")!)
        let webSocketTransport = WebSocketTransport(websocket: webSocket)
        
        let splitTransport = SplitNetworkTransport(uploadingNetworkTransport: transport,
                                                   webSocketNetworkTransport: webSocketTransport)
        
        return ApolloClient(networkTransport: splitTransport, store: store)
    }()
}
