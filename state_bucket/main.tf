provider "aws" {
  region = "us-east-1"
}

resource "aws_s3_bucket" "mehlj-state" {
  bucket = "mehlj-state"

  # Enable versioning
  versioning {
    enabled = true
  }
  
  # Enable encryption
  server_side_encryption_configuration {
    rule {
      apply_server_side_encryption_by_default {
        sse_algorithm = "AES256"
      }
    }
  }
}

# Create DynamoDB table with primary key of LockID
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "mehlj_state_locks"
  billing_mode = "PAY_PER_REQUEST"
  hash_key     = "LockID"
  
  attribute {
    name = "LockID"
    type = "S"
  }
}
