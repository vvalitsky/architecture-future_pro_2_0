# =====================================================================
# Конфигурация окружения STAGE — средняя ВМ.
# Значения — плейсхолдеры; замените PLACEHOLDER_* на реальные ID.
# Секрет yc_token передавайте через TF_VAR_yc_token, не здесь.
# =====================================================================

# --- Размещение ---
cloud_id  = "PLACEHOLDER_CLOUD_ID"
folder_id = "PLACEHOLDER_FOLDER_ID_STAGE"
zone      = "ru-central1-b"

# --- Параметры ВМ (средняя) ---
name          = "future20-stage-vm"
cores         = 4
memory_gb     = 8
core_fraction = 100
preemptible   = false

# --- Диски ---
image_id           = "PLACEHOLDER_UBUNTU_IMAGE_ID"
boot_disk_size_gb  = 50
extra_disk_size_gb = 0

# --- Сеть и доступ ---
subnet_id           = "PLACEHOLDER_SUBNET_ID_STAGE"
ssh_public_key_path = "~/.ssh/id_rsa.pub"

# --- Метки ---
labels = {
  environment = "stage"
  project     = "future20"
  managed_by  = "terraform"
}
