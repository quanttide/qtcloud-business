// Package config 提供集中化环境变量配置。
package config

import "os"

// Config 是服务端全部配置。
type Config struct {
	Addr string // 监听地址，默认 ":8080"
}

// Load 从环境变量加载配置，缺失时使用默认值。
func Load() *Config {
	return &Config{
		Addr: getEnv("LISTEN_ADDR", ":8080"),
	}
}

func getEnv(key, fallback string) string {
	if v := os.Getenv(key); v != "" {
		return v
	}
	return fallback
}
