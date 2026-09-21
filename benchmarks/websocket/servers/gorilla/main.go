package main

import (
    "log"
    "net/http"
    "os"

    "github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
    ReadBufferSize:  4096,
    WriteBufferSize: 4096,
    CheckOrigin: func(r *http.Request) bool { return true },
}

func main() {
    port := os.Getenv("BENCH_PORT")
    if port == "" {
        log.Fatal("BENCH_PORT is required")
    }

    http.HandleFunc("/application", func(w http.ResponseWriter, r *http.Request) {
        conn, err := upgrader.Upgrade(w, r, nil)
        if err != nil {
            return
        }
        defer conn.Close()

        for {
            kind, payload, err := conn.ReadMessage()
            if err != nil {
                return
            }
            if kind != websocket.TextMessage || len(payload) < 6 || string(payload[:6]) != "{\"op\":" {
                _ = conn.WriteControl(
                    websocket.CloseMessage,
                    websocket.FormatCloseMessage(1003, "invalid benchmark request"),
                    noDeadline(),
                )
                return
            }
            if err := conn.WriteMessage(websocket.TextMessage, []byte("{\"ok\":true}")); err != nil {
                return
            }
        }
    })

    server := &http.Server{Addr: "127.0.0.1:" + port}
    log.Fatal(server.ListenAndServe())
}

func noDeadline() (t time.Time) { return }
