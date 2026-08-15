# =====================================================================
# Конфигурация окружения PROD — крупная ВМ с диском данных.
# Значения — плейсхолдеры; замените PLACEHOLDER_* на реальные ID.
# Секрет yc_token передавайте через TF_VAR_yc_token, не здесь.
# =====================================================================

# --- Размещение ---
cloud_id  = "PLACEHOLDER_CLOUD_ID"
folder_id = "PLACEHOLDER_FOLDER_ID_PROD"
zone      = "ru-central1-d"

# --- Параметры ВМ (крупная) ---
name          = "future20-prod-vm"
cores         = 8
memory_gb     = 16
core_fraction = 100
preemptible   = false

# --- Диски ---
image_id           = "PLACEHOLDER_UBUNTU_IMAGE_ID"
boot_disk_size_gb  = 100
extra_disk_size_gb = 200

# --- Сеть и доступ ---
subnet_id           = "PLACEHOLDER_SUBNET_ID_PROD"
ssh_public_key_path = "~/.ssh/id_rsa.pub"

# --- Метки ---
labels = {
  environment = "prod"
  project     = "future20"
  managed_by  = "terraform"
}
