output "object_id" {
 description = "The object ID of the user — the universal key consumed by group membership, role assignments, access-package resource associations, and manager_id references."
 value = azuread_user.this.object_id
}

output "id" {
 description = "The fully-qualified Terraform/Graph ID of the user (/users/<object_id>)."
 value = azuread_user.this.id
}

output "user_principal_name" {
 description = "The user principal name (UPN) — the primary sign-in identifier."
 value = azuread_user.this.user_principal_name
}

output "display_name" {
 description = "The display name of the user."
 value = azuread_user.this.display_name
}

output "mail" {
 description = "The SMTP address of the user. May be computed by Exchange/Graph when not explicitly set."
 value = azuread_user.this.mail
}

output "mail_nickname" {
 description = "The mail alias of the user (defaults to the UPN prefix when not set)."
 value = azuread_user.this.mail_nickname
}

output "account_enabled" {
 description = "Whether the account is enabled for sign-in."
 value = azuread_user.this.account_enabled
}

output "user_type" {
 description = "The user type in the directory — \"Member\" for cloud-only users created here (\"Guest\" only for invited B2B users, which are managed by tf_mod_azuread_invitation)."
 value = azuread_user.this.user_type
}

output "creation_type" {
 description = "How the account was created — null for a regular work/school account, or \"Invitation\" / \"LocalAccount\" / \"EmailVerified\" for other origins."
 value = try(azuread_user.this.creation_type, null)
}

output "im_addresses" {
 description = "Instant-message VOIP SIP addresses for the user (read-only)."
 value = try(azuread_user.this.im_addresses, [])
}

output "proxy_addresses" {
 description = "Email addresses that direct to the same mailbox as the user (read-only)."
 value = try(azuread_user.this.proxy_addresses, [])
}

output "onpremises_sync_enabled" {
 description = "Whether the user is synchronised from an on-premises directory (true), no longer synchronised (false), or never synchronised (null). Cloud-only users created here are null."
 value = try(azuread_user.this.onpremises_sync_enabled, null)
}
