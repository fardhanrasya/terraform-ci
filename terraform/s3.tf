module "s3_bucket" {
  source = "terraform-aws-modules/s3-bucket/aws"

  bucket = "fardhan-s3-bucket-686868"

  versioning = {
    enabled = true
  }
}