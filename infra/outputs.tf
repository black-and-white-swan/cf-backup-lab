output "bucket_name" {
  value = cloudflare_r2_bucket.lab.name
}

output "bucket_location" {
  value = cloudflare_r2_bucket.lab.location
}

output "bucket_storage_class" {
  value = cloudflare_r2_bucket.lab.storage_class
}
