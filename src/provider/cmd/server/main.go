package main

import (
	"log"
	"net/http"

	"github.com/quanttide/qtcloud-business-provider/internal/config"
)

func main() {
	cfg := config.Load()
	mux := buildRouter(cfg)
	log.Printf("qtcloud-business-provider starting on %s", cfg.Addr)
	if err := http.ListenAndServe(cfg.Addr, mux); err != nil {
		log.Fatalf("server error: %v", err)
	}
}

// buildRouter 组装路由。当前为服务骨架，仅健康检查；
// 报价 / 合同的读取通道按需立项后在此挂载（Lite 与 Site 的数据源）。
func buildRouter(cfg *config.Config) *http.ServeMux {
	mux := http.NewServeMux()

	mux.HandleFunc("GET /healthz", func(w http.ResponseWriter, _ *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("ok\n"))
	})

	return mux
}
