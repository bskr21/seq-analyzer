"""Ableton Live 12 Remote Script: socket worker, main-thread LOM dispatcher."""
from _Framework.ControlSurface import ControlSurface
import json
import queue
import socket
import threading
import time

from .bridge_protocol import Dispatcher, error_response

HOST = "127.0.0.1"
PORT = 9128
MAX_REQUEST = 16384


class SeqAnalyzerRemote(ControlSurface):
    def __init__(self, c_instance):
        super(SeqAnalyzerRemote, self).__init__(c_instance)
        self._closed = threading.Event()
        self._requests = queue.Queue(maxsize=8)
        self._dispatcher = Dispatcher(self.song, self._marker_factory, self._live_version)
        self._server = None
        self._thread = None
        try:
            server = socket.socket(socket.AF_INET, socket.SOCK_STREAM)
            server.setsockopt(socket.SOL_SOCKET, socket.SO_REUSEADDR, 1)
            server.bind((HOST, PORT))
            server.listen(2)
            server.settimeout(0.5)
            self._server = server
        except OSError as exc:
            try:
                server.close()
            except UnboundLocalError:
                pass
            self.log_message("SeqAnalyzer Remote port %d unavailable: %s" % (PORT, type(exc).__name__))
            return
        self._thread = threading.Thread(target=self._accept_loop, name="SeqAnalyzerBridge", daemon=True)
        self._thread.start()
        self.log_message("SeqAnalyzer Remote listening on %s:%d" % (HOST, PORT))

    @staticmethod
    def _marker_factory(seconds, beats):
        import Live
        return Live.Clip.WarpMarker(seconds, beats)

    @staticmethod
    def _live_version():
        import Live
        app = Live.Application.get_application()
        return "%s.%s.%s" % (app.get_major_version(), app.get_minor_version(),
                              app.get_bugfix_version())

    def _accept_loop(self):
        while not self._closed.is_set():
            try:
                conn, _ = self._server.accept()
            except socket.timeout:
                continue
            except OSError:
                break
            with conn:
                conn.settimeout(20)
                self._serve_connection(conn)

    def _serve_connection(self, conn):
        buffer = bytearray()
        while not self._closed.is_set():
            try:
                deadline = time.monotonic() + 20
                while b"\n" not in buffer and len(buffer) <= MAX_REQUEST:
                    remaining = deadline - time.monotonic()
                    if remaining <= 0:
                        return
                    conn.settimeout(remaining)
                    part = conn.recv(4096)
                    if not part:
                        return
                    buffer.extend(part)
                if b"\n" not in buffer:
                    self._send(conn, error_response(None, "REQUEST_TOO_LARGE", "request exceeds 16 KiB"))
                    return
                line, _, remaining = buffer.partition(b"\n")
                buffer = bytearray(remaining)
                if len(line) > MAX_REQUEST:
                    self._send(conn, error_response(None, "REQUEST_TOO_LARGE", "request exceeds 16 KiB"))
                    return
                try:
                    request = json.loads(line.decode("utf-8"))
                except (UnicodeDecodeError, ValueError):
                    response = error_response(None, "BAD_REQUEST", "invalid JSON request")
                else:
                    reply = queue.Queue(maxsize=1)
                    try:
                        self._requests.put_nowait((request, reply))
                    except queue.Full:
                        request_id = request.get("id") if isinstance(request, dict) else None
                        response = error_response(request_id, "BUSY", "main thread queue is full")
                    else:
                        try:
                            response = reply.get(timeout=15)
                        except queue.Empty:
                            request_id = request.get("id") if isinstance(request, dict) else None
                            response = error_response(request_id, "TIMEOUT_MAIN_THREAD",
                                                      "Live main thread did not respond")
                self._send(conn, response)
            except (socket.timeout, OSError):
                return

    @staticmethod
    def _send(conn, response):
        conn.sendall((json.dumps(response, allow_nan=False) + "\n").encode("utf-8"))

    def update_display(self):
        super(SeqAnalyzerRemote, self).update_display()
        # Only this callback may access Song, Track, Clip, or Live.Application.
        for _ in range(2):
            try:
                request, reply = self._requests.get_nowait()
            except queue.Empty:
                return
            response = self._dispatcher.handle(request)
            if not response["ok"]:
                self.log_message("SeqAnalyzer bridge error: %s" % response["error"]["code"])
            reply.put_nowait(response)

    def disconnect(self):
        self._closed.set()
        if self._server is not None:
            self._server.close()
        super(SeqAnalyzerRemote, self).disconnect()


def create_instance(c_instance):
    return SeqAnalyzerRemote(c_instance)
