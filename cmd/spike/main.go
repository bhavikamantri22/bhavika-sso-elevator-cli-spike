package main

import (
	"bytes"
	"context"
	"crypto/sha256"
	"encoding/hex"
	"fmt"
	"io"
	"log"
	"net/http"
	"time"

	v4 "github.com/aws/aws-sdk-go-v2/aws/signer/v4"
	"github.com/aws/aws-sdk-go-v2/config"
)

func main() {
	ctx := context.Background()

	cfg, err := config.LoadDefaultConfig(ctx, config.WithRegion("us-east-1"))
	if err != nil {
		log.Fatalf("load AWS config: %v", err)
	}

	creds, err := cfg.Credentials.Retrieve(ctx)
	if err != nil {
		log.Fatalf("retrieve credentials: %v", err)
	}

	const (
		url     = "https://jtm9pcym8d.execute-api.us-east-1.amazonaws.com/spike"
		service = "execute-api"
		region  = "us-east-1"
	)
	body := []byte(`{"action":"request-access","account":"931932531937"}`)

	req, err := http.NewRequestWithContext(ctx, http.MethodPost, url, bytes.NewReader(body))
	if err != nil {
		log.Fatalf("create request: %v", err)
	}
	req.Header.Set("Content-Type", "application/json")

	sum := sha256.Sum256(body)
	payloadHash := hex.EncodeToString(sum[:])

	if err := v4.NewSigner().SignHTTP(ctx, creds, req, payloadHash, service, region, time.Now().UTC()); err != nil {
		log.Fatalf("sign request: %v", err)
	}

	fmt.Printf("Credential source: %s\n", creds.Source)
	fmt.Printf("Has session token: %t\n", creds.SessionToken != "")
	fmt.Printf("POST %s\n\n", url)

	resp, err := http.DefaultClient.Do(req)
	if err != nil {
		log.Fatalf("send request: %v", err)
	}
	defer resp.Body.Close()

	respBody, err := io.ReadAll(resp.Body)
	if err != nil {
		log.Fatalf("read response: %v", err)
	}

	fmt.Printf("Status: %s\n", resp.Status)
	fmt.Printf("Body:\n%s\n", string(respBody))
}
