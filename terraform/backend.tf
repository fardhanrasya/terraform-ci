terraform {
  backend "s3" {
    # Nama bucket harus unik, sesuaikan dengan yang sudah dibuat
    bucket         = "fardhan-terraform-6969"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
  }
}
