output "state_backend" {
  value = {
    region      = var.region
    bucket_name = aws_s3_bucket.tf_state.bucket
    lock_table  = aws_dynamodb_table.tf_lock.name
  }
}