resource "cloudflare_r2_bucket" "lab" {
  account_id = var.account_id
  name       = "swan-lab-backups"
  location   = "weur"
}