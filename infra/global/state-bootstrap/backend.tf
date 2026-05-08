# Bootstrap is intentionally local on first run because the remote state bucket
# does not exist yet. After this root succeeds, migrate other roots to the S3
# backend using the bucket output from this stack.
