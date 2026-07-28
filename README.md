# bhavika-sso-elevator-cli-spike

Throwaway spike for [fivexl/terraform-aws-sso-elevator#171](https://github.com/fivexl/terraform-aws-sso-elevator/issues/171).

## Why we're building this

SSO Elevator lets people request temporary AWS access, but today that request **must** go through Slack. Slack matches the requester's Slack email to their AWS SSO email to know who is asking. That works well for humans in Slack — it does **not** work if you want a CLI path that never touches Slack for submission.

A CLI was raised before in [#99](https://github.com/fivexl/terraform-aws-sso-elevator/issues/99), with the concern that it would break the auth flow because identity comes from Slack. Issue #171 proposes a way to add CLI submission **without** losing that identity guarantee: the CLI signs the request with the caller's own AWS credentials (SigV4), API Gateway verifies the signature with `AWS_IAM` auth, and Lambda reads the signer identity the same way Slack email matching does today.

**Approval stays in Slack only.** The CLI is only for submitting a request. Approving/denying, granting, revocation, and audit logging stay exactly as they are today.

## What the eventual solution builds

If this spike succeeds, the real feature would be:

1. A new IAM-authorized route on the existing SSO Elevator API Gateway
2. Identity-check logic in the access-requester Lambda (accept SSO email, reject non-SSO credentials with a clear error)
3. A small CLI that packages account / permission set / duration / reason, signs with local AWS credentials, and POSTs the request
4. The existing Slack approval pipeline unchanged after identity is established

MVP scope: single-account / permission-set requests for a person using their own credentials — not group access, not CLI approval, not agent/non-human identities.

## What this spike proves first

None of that is worth building until one open question is answered:

> Once SigV4 is verified, can we reliably extract the signer's identity in Lambda — and does it contain an email?

| Credential type | Expected result |
| --- | --- |
| SSO-based session | Assumed-role session name includes the user's email → identified like Slack does today |
| Plain IAM user / non-SSO role | No email in the signing identity → **403** with a clear error (do not guess) |

This repo is only that prototype.

## What's in this repo

- `cmd/spike` — Go client: load local AWS credentials, SigV4-sign a `POST`, send it to the test API
- `infra/spike` — temporary API Gateway HTTP API (`POST /spike`, `AWS_IAM`) + Python Lambda that logs the event, extracts identity from `requestContext.authorizer.iam.userArn`, and returns 200 or 403

Deploy target: AWS account `sso-tooling` (`931932531937`), region `us-east-1`, profile `sso-tooling`.

## Status

Experimental / throwaway. Not for production use.
