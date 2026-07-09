import Darwin
import Dispatch
import Foundation

struct UDPServerError: Error, CustomStringConvertible {
    let description: String
}

/// Minimal UDP listener delivering trimmed UTF-8 datagrams on the main queue.
final class UDPServer {
    let port: UInt16
    private let socketFD: Int32
    private let source: DispatchSourceRead

    init(port: UInt16, handler: @escaping (String) -> Void) throws {
        let fd = socket(AF_INET, SOCK_DGRAM, 0)
        guard fd >= 0 else {
            throw UDPServerError(description: "could not create socket for port \(port)")
        }

        var reuse: Int32 = 1
        setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, &reuse, socklen_t(MemoryLayout<Int32>.size))

        var address = sockaddr_in()
        address.sin_len = UInt8(MemoryLayout<sockaddr_in>.size)
        address.sin_family = sa_family_t(AF_INET)
        address.sin_port = port.bigEndian
        address.sin_addr.s_addr = INADDR_ANY

        let bound = withUnsafePointer(to: &address) {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                bind(fd, $0, socklen_t(MemoryLayout<sockaddr_in>.size))
            }
        }
        guard bound == 0 else {
            close(fd)
            throw UDPServerError(description: "could not bind UDP port \(port) (already in use?)")
        }

        self.port = port
        self.socketFD = fd
        source = DispatchSource.makeReadSource(fileDescriptor: fd, queue: .main)
        source.setEventHandler { [socketFD = fd] in
            var buffer = [UInt8](repeating: 0, count: 1024)
            let count = recv(socketFD, &buffer, buffer.count, 0)
            guard count > 0,
                  let text = String(bytes: buffer[0..<count], encoding: .utf8) else { return }
            let message = text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !message.isEmpty else { return }
            handler(message)
        }
        source.setCancelHandler { [socketFD = fd] in
            close(socketFD)
        }
        source.resume()
    }

    deinit {
        source.cancel()
    }
}
