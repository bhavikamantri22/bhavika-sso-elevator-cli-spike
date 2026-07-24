# Agent context for this repo

This is a throwaway spike to answer one question: once a request is signed with AWS SigV4, can the signer's identity be reliably extracted server-side, and does it contain an email address?

Background: this supports a proposed CLI feature for fivexl/terraform-aws-sso-elevator (see issue #171), letting people request temporary AWS access without going through Slack. SSO-based sessions carry the user's email in their assumed-role ARN automatically;plain IAM user credentials do not.

Deployment target: AWS account `sso-tooling` (931932531937) — confirmed by the team as the correct account for this spike's test infrastructure.

Language: Go. Reference implementation for SigV4 signing: https://github.com/sirob-tech/boris-mcp-cli (see its signing logic,not the MCP-specific parts).

Current goal: write a small Go program that signs an HTTP request usinglocal AWS credentials, and prints the signed request so its contents can be inspected.