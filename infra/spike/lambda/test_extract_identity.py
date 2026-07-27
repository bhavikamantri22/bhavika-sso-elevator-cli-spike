"""Local checks for extract_identity — not deployed with the Lambda zip."""

from handler import extract_identity

EMAIL_ARN = (
    "arn:aws:sts::931932531937:assumed-role/"
    "AWSReservedSSO_FullOrgAdmin_bb7a6d8b5397bb50/bhavika.mantri@fivexl.io"
)
NO_EMAIL_ARN = (
    "arn:aws:sts::931932531937:assumed-role/SomeRole/i-0abc123def456"
)


def main() -> None:
    assert extract_identity(EMAIL_ARN) == "bhavika.mantri@fivexl.io"
    assert extract_identity(NO_EMAIL_ARN) is None
    print("extract_identity: ok")


if __name__ == "__main__":
    main()
