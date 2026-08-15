# =====================================================================
# Конфигурация окружения DEV — маленькая прерываемая ВМ.
# Значения — плейсхолдеры; замените PLACEHOLDER_* на реальные ID.
# Секрет yc_token передавайте через TF_VAR_yc_token, не здесь.
# =====================================================================

# --- Размещение ---
cloud_id  = "PLACEHOLDER_CLOUD_ID"
folder_id = "PLACEHOLDER_FOLDER_ID_DEV"
zone      = "ru-central1-a"

# --- Параметры ВМ (маленькая) ---
name          = "future20-dev-vm"
cores         = 2
memory_gb     = 2
core_fraction = 20
preemptible   = true

# --- Диски ---
image_id           = "PLACEHOLDER_UBUNTU_IMAGE_ID"
boot_disk_size_gb  = 10
extra_disk_size_gb = 0

# --- Сеть и доступ ---
subnet_id           = "PLACEHOLDER_SUBNET_ID_DEV"
ssh_public_key_path = "~/.ssh/id_rsa.pub"

# --- Метки ---
labels = {
  environment = "dev"
  project     = "future20"
  managed_by  = "terraform"
}
