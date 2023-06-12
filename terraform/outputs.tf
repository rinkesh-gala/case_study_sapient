output "web-url" {
  value = "https://${module.web_appvm.global-ip}.nip.io"
}