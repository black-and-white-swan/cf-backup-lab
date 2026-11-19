resource "cloudflare_r2_bucket" "lab" {
  account_id = var.account_id
  name       = "swan-lab-backups"
  location   = "weur"
}

resource "cloudflare_r2_bucket_lifecycle" "lab" {
  account_id  = var.account_id
  bucket_name = cloudflare_r2_bucket.lab.name

  rules = [
    {
      # Règle créée par Cloudflare avec le bucket : on la reprend pour ne pas l'écraser
      id      = "Default Multipart Abort Rule"
      enabled = true
      conditions = {
        prefix = ""
      }
      abort_multipart_uploads_transition = {
        condition = {
          type    = "Age"
          max_age = 7 * 24 * 3600 # 7 jours, en secondes
        }
      }
    },
    {
      # Notre politique de rétention : on supprime les sauvegardes de plus de 30 jours
      id      = "expire-30-jours"
      enabled = true
      conditions = {
        prefix = ""
      }
      delete_objects_transition = {
        condition = {
          type    = "Age"
          max_age = 30 * 24 * 3600 # 30 jours, en secondes
        }
      }
    },
  ]
}

resource "cloudflare_r2_bucket_lock" "lab" {
  account_id  = var.account_id
  bucket_name = cloudflare_r2_bucket.lab.name

  rules = [
    {
      # Sauvegardes immuables : ni suppression ni écrasement pendant 7 jours
      id      = "immuable-7-jours"
      enabled = true
      prefix  = ""
      condition = {
        type            = "Age"
        max_age_seconds = 7 * 24 * 3600 # 7 jours, en secondes
      }
    },
  ]
}
