package main

import (
	"crypto/tls"
	"fmt"
	"math/rand"
	"net/http"
	"os"
	"strconv"
	"strings"
	"sync"
	"sync/atomic"
	"time"
)

var (
	requestCount int64
	errorCount   int64
)

// 生成随机字符串
func randomString(length int) string {
	const charset = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
	result := make([]byte, length)
	for i := range result {
		result[i] = charset[rand.Intn(len(charset))]
	}
	return string(result)
}

// 生成随机User-Agent
func randomUserAgent() string {
	browsers := []string{"Chrome", "Firefox", "Safari", "Edge"}
	osVersions := []string{
		"Windows NT 10.0; Win64; x64",
		"Windows NT 6.1; WOW64",
		"Macintosh; Intel Mac OS X 10_15_7",
		"X11; Linux x86_64",
		"iPhone; CPU iPhone OS 17_3_1 like Mac OS X",
		"Linux; Android 10; SM-G973F",
	}

	browser := browsers[rand.Intn(len(browsers))]
	os := osVersions[rand.Intn(len(osVersions))]

	switch browser {
	case "Chrome":
		major := rand.Intn(6) + 120
		minor := rand.Intn(10)
		build := rand.Intn(10000)
		return fmt.Sprintf("Mozilla/5.0 (%s) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%d.%d.%d Safari/537.36",
			os, major, minor, build)
	case "Firefox":
		major := rand.Intn(11) + 115
		return fmt.Sprintf("Mozilla/5.0 (%s; rv:%d.0) Gecko/20100101 Firefox/%d.0", os, major, major)
	case "Safari":
		version := rand.Intn(6) + 605
		webkitVersion := rand.Intn(3) + 15
		return fmt.Sprintf("Mozilla/5.0 (%s) AppleWebKit/%d.1.15 (KHTML, like Gecko) Version/%d.3.1 Safari/%d.1.15",
			os, version, webkitVersion, version)
	default: // Edge
		major := rand.Intn(6) + 120
		return fmt.Sprintf("Mozilla/5.0 (%s) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/%d.0.0.0 Safari/537.36 Edg/%d.0.0.0",
			os, major, major)
	}
}

// 生成随机请求路径
func randomPath() string {
	pathTypes := []func() string{
		func() string { return "/" + randomString(rand.Intn(8)+3) },
		func() string { return "/" + randomString(rand.Intn(6)+3) + "/" + randomString(rand.Intn(6)+3) },
		func() string { return "/api/v" + strconv.Itoa(rand.Intn(3)+1) + "/" + randomString(rand.Intn(6)+3) },
		func() string { return "/" + randomString(rand.Intn(4)+3) + ".html" },
		func() string { return "/" + randomString(rand.Intn(4)+3) + ".php" },
		func() string {
			return "/static/" + randomString(rand.Intn(6)+3) + "/" + randomString(rand.Intn(8)+3) + ".css"
		},
		func() string { return "/static/js/" + randomString(rand.Intn(8)+3) + ".js" },
		func() string { return "/images/" + randomString(rand.Intn(8)+3) + ".jpg" },
		func() string {
			return "/" + randomString(rand.Intn(6)+3) + "/" + randomString(rand.Intn(6)+3) + "/" + randomString(rand.Intn(6)+3)
		},
	}

	return pathTypes[rand.Intn(len(pathTypes))]()
}

// 生成随机IP地址
func randomIP() string {
	return fmt.Sprintf("%d.%d.%d.%d", rand.Intn(256), rand.Intn(256), rand.Intn(256), rand.Intn(256))
}

// 创建HTTP客户端
func createHTTPClient() *http.Client {
	transport := &http.Transport{
		TLSClientConfig: &tls.Config{
			InsecureSkipVerify: true, // 跳过HTTPS证书验证
		},
		MaxIdleConns:        100,
		MaxIdleConnsPerHost: 100,
		IdleConnTimeout:     90 * time.Second,
	}

	return &http.Client{
		Transport: transport,
		Timeout:   30 * time.Second,
	}
}

// 发送请求
func sendRequest(client *http.Client, baseURL string, wg *sync.WaitGroup) {
	defer wg.Done()

	// 生成随机数据
	ip := randomIP()
	userAgent := randomUserAgent()
	path := randomPath()

	// 构建完整URL
	fullURL := baseURL + path

	// 创建请求
	req, err := http.NewRequest("GET", fullURL, nil)
	if err != nil {
		atomic.AddInt64(&errorCount, 1)
		return
	}

	// 设置请求头
	req.Header.Set("X-Forwarded-For", ip)
	req.Header.Set("X-Real-IP", ip)
	req.Header.Set("X-Client-IP", ip)
	req.Header.Set("CF-Connecting-IP", ip)
	req.Header.Set("True-Client-IP", ip)
	req.Header.Set("User-Agent", userAgent)

	// 随机Accept-Language
	acceptLanguages := []string{"zh-CN,zh;q=0.9", "en-US,en;q=0.8", "ja-JP,ja;q=0.7", "ko-KR,ko;q=0.6"}
	req.Header.Set("Accept-Language", acceptLanguages[rand.Intn(len(acceptLanguages))])

	// 随机Accept
	accepts := []string{"text/html,application/xhtml+xml,application/xml;q=0.9,*/*;q=0.8", "application/json, text/plain, */*"}
	req.Header.Set("Accept", accepts[rand.Intn(len(accepts))])

	// 随机Referer
	if rand.Intn(3) == 0 {
		domains := []string{"https://www.google.com", "https://www.baidu.com", "https://github.com", "https://stackoverflow.com"}
		req.Header.Set("Referer", domains[rand.Intn(len(domains))]+"/search?q="+randomString(8))
	}

	// 发送请求
	resp, err := client.Do(req)
	if err != nil {
		atomic.AddInt64(&errorCount, 1)
		return
	}
	defer resp.Body.Close()

	// 检查HTTP状态码，只有2xx和3xx算成功
	if resp.StatusCode >= 200 && resp.StatusCode < 400 {
		atomic.AddInt64(&requestCount, 1)
	} else {
		atomic.AddInt64(&errorCount, 1)
	}
}

// 打印统计信息
func printStats(duration time.Duration) {
	ticker := time.NewTicker(5 * time.Second)
	defer ticker.Stop()

	start := time.Now()
	for {
		select {
		case <-ticker.C:
			elapsed := time.Since(start).Seconds()
			requests := atomic.LoadInt64(&requestCount)
			errors := atomic.LoadInt64(&errorCount)
			rps := float64(requests) / elapsed

			fmt.Printf("\r运行时间: %.1fs, 请求数: %d, 错误数: %d, RPS: %.1f",
				elapsed, requests, errors, rps)
		}
	}
}

func main() {
	if len(os.Args) < 4 {
		fmt.Println("用法: go run stress_test.go <URL> <并发数> <持续时间>")
		fmt.Println("示例: go run stress_test.go https://blog.gov6g.cn 100 1000s")
		os.Exit(1)
	}

	baseURL := os.Args[1]
	concurrency, err := strconv.Atoi(os.Args[2])
	if err != nil {
		fmt.Printf("无效的并发数: %v\n", err)
		os.Exit(1)
	}

	durationStr := os.Args[3]
	var duration time.Duration
	if strings.HasSuffix(durationStr, "s") {
		seconds, err := strconv.Atoi(strings.TrimSuffix(durationStr, "s"))
		if err != nil {
			fmt.Printf("无效的持续时间: %v\n", err)
			os.Exit(1)
		}
		duration = time.Duration(seconds) * time.Second
	} else if strings.HasSuffix(durationStr, "m") {
		minutes, err := strconv.Atoi(strings.TrimSuffix(durationStr, "m"))
		if err != nil {
			fmt.Printf("无效的持续时间: %v\n", err)
			os.Exit(1)
		}
		duration = time.Duration(minutes) * time.Minute
	} else {
		fmt.Printf("不支持的持续时间格式，请使用 's' (秒) 或 'm' (分钟)\n")
		os.Exit(1)
	}

	// 初始化随机数种子
	rand.Seed(time.Now().UnixNano())

	fmt.Printf("开始压测:\n")
	fmt.Printf("目标URL: %s\n", baseURL)
	fmt.Printf("并发数: %d\n", concurrency)
	fmt.Printf("持续时间: %v\n", duration)
	fmt.Printf("支持HTTPS: 是\n")
	fmt.Println("======================================")

	// 创建HTTP客户端
	client := createHTTPClient()

	// 启动统计信息打印
	go printStats(duration)

	// 创建等待组
	var wg sync.WaitGroup

	// 计算结束时间
	endTime := time.Now().Add(duration)

	// 启动压测
	for time.Now().Before(endTime) {
		for i := 0; i < concurrency; i++ {
			wg.Add(1)
			go sendRequest(client, baseURL, &wg)
		}
		time.Sleep(10 * time.Millisecond) // 控制请求频率
	}

	// 等待所有请求完成
	wg.Wait()

	// 打印最终统计
	totalTime := time.Since(time.Now().Add(-duration)).Seconds()
	totalRequests := atomic.LoadInt64(&requestCount)
	totalErrors := atomic.LoadInt64(&errorCount)
	totalAttempts := totalRequests + totalErrors
	finalRPS := float64(totalAttempts) / totalTime

	fmt.Printf("\n\n压测完成!\n")
	fmt.Printf("总运行时间: %.1fs\n", totalTime)
	fmt.Printf("总尝试数: %d\n", totalAttempts)
	fmt.Printf("成功请求: %d\n", totalRequests)
	fmt.Printf("失败请求: %d\n", totalErrors)
	fmt.Printf("平均RPS: %.1f\n", finalRPS)

	// 计算成功率，避免除零错误
	if totalAttempts > 0 {
		successRate := (float64(totalRequests) / float64(totalAttempts)) * 100
		fmt.Printf("成功率: %.2f%%\n", successRate)
	} else {
		fmt.Printf("成功率: 0.00%%\n")
	}
}
