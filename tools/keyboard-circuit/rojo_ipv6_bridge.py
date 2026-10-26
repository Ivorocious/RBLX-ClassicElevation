"""Forward the IPv6 loopback port to the existing IPv4 Rojo server."""
import select
import socket
import threading
from datetime import datetime, timezone


def forward(client, address):
    try:
        with client, socket.create_connection(("127.0.0.1", 34872), timeout=5) as server:
            print(datetime.now(timezone.utc).isoformat(), "IPv6 loopback connection", flush=True)
            client.settimeout(None)
            server.settimeout(None)
            peers = {client: server, server: client}
            while True:
                ready, _, _ = select.select(list(peers), [], [], 30)
                for source in ready:
                    data = source.recv(65536)
                    if not data:
                        return
                    peers[source].sendall(data)
    except OSError as error:
        print(type(error).__name__, str(error), flush=True)


with socket.socket(socket.AF_INET6, socket.SOCK_STREAM) as listener:
    listener.setsockopt(socket.IPPROTO_IPV6, socket.IPV6_V6ONLY, 1)
    listener.bind(("::1", 34872))
    listener.listen(8)
    print("READY ::1:34872 -> 127.0.0.1:34872; loopback only", flush=True)
    while True:
        connection, address = listener.accept()
        threading.Thread(target=forward, args=(connection, address), daemon=True).start()
