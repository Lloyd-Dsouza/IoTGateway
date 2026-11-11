struct RequestEnvelope<Params: Encodable>: Encodable {
    let requestId: String
    let method: String
    let params: Params
}

struct ResponseEnvelope<Payload: Decodable>: Decodable {
    let requestId: String
    let data: Payload
}

struct EmptyParams: Encodable {}
