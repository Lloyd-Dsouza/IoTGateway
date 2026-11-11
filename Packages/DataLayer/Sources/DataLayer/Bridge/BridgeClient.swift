import Domain
import Foundation

struct BridgeClient: Sendable {
    let transport: any IoTTransport

    func call<Params: Encodable, Payload: Decodable>(
        _ method: String,
        params: Params,
        as payloadType: Payload.Type
    ) async throws -> Payload {
        let requestId = UUID().uuidString
        let request = RequestEnvelope(
            requestId: requestId,
            method: method,
            params: params
        )

        do {
            let body = try JSONEncoder().encode(request)
            let responseData = try await transport.send(body)
            let response = try JSONDecoder().decode(ResponseEnvelope<Payload>.self, from: responseData)
            guard response.requestId == requestId else {
                throw BridgeError.malformedResponse
            }
            return response.data
        } catch let error as BridgeError {
            throw ErrorMapper.toDomain(error)
        } catch let error as DomainError {
            throw error
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw DomainError.unknown
        }
    }
}
