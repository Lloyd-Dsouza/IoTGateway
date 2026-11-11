//
//  ViewState.swift
//  IoTGatewayApp
//
//  Created by Lloyd on 10/11/26.
//

enum ViewState<Value> {
    case idle
    case loading
    case loaded(Value)
    case failed(String)
}
