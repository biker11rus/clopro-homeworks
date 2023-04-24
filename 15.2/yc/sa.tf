resource "yandex_iam_service_account" "sa-backet" {
  name = "sa-backet"
}

resource "yandex_resourcemanager_folder_iam_member" "sa-backet-editor" {
  folder_id = var.yandex_folder_id
  role      = "storage.editor"
  member    = "serviceAccount:${yandex_iam_service_account.sa-backet.id}"
}

resource "yandex_iam_service_account_static_access_key" "sa-backet-static-key" {
  service_account_id = yandex_iam_service_account.sa-backet.id
  description        = "static access key for object storage"
}

resource "yandex_iam_service_account" "sa-ig1" {
  name        = "sa-ig1"
  description = "service account to manage IG"
}

resource "yandex_resourcemanager_folder_iam_member" "editor" {
  folder_id = var.yandex_folder_id
  role      = "editor"
  member   = "serviceAccount:${yandex_iam_service_account.sa-ig1.id}"
}

