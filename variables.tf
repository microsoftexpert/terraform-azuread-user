# ---------------------------------------------------------------------------
# Required identity
# ---------------------------------------------------------------------------

variable "display_name" {
 description = <<EOT
The name to display in the address book for the user. Required.
Updatable in place; changing it does NOT force replacement.
EOT
 type = string

 validation {
 condition = length(trimspace(var.display_name)) > 0
 error_message = "display_name must be a non-empty string."
 }
}

variable "user_principal_name" {
 description = <<EOT
The user principal name (UPN) of the user — the primary sign-in identifier,
formatted as an email address (e.g. "jdoe@contoso.com"). Required.

The domain segment must be a verified domain in the tenant (cloud-only users
only — see SCOPE.md; on-premises synced users cannot be managed by this module).

# STABLE IDENTITY (verified against hashicorp/azuread v3.9.0): the provider
# updates the UPN in place (PATCH) — it is NOT ForceNew, so a change does NOT
# destroy/recreate the user. However, treat it as a stable identity: changing a
# UPN breaks the user's sign-in, invalidates issued tokens, and orphans any
# external references (group rules, app assignments, mail routing) that key on
# the old UPN. Change it deliberately, not casually.
EOT
 type = string

 validation {
 condition = can(regex("^[^@\\s]+@[^@\\s]+\\.[^@\\s]+$", var.user_principal_name))
 error_message = "user_principal_name must be a valid UPN in email form (e.g. \"jdoe@contoso.com\") using a verified tenant domain."
 }
}

# ---------------------------------------------------------------------------
# Credential (write-only)
# ---------------------------------------------------------------------------

variable "password" {
 description = <<EOT
The initial password for the user. Required when creating a new user; may be
left null when importing an existing user (Terraform will not reset an imported
user's password unless this value is subsequently changed).

The password must satisfy the tenant password policy. Maximum length 256
characters.

# WRITE-ONLY: the Graph API never returns this value after creation. It is held
# in Terraform state — keep state encrypted. It is intentionally NOT emitted as a
# module output. Pair with force_password_change = true so the user must rotate
# it at first sign-in.
EOT
 type = string
 default = null
 sensitive = true

 validation {
 condition = var.password == null ? true: (length(var.password) >= 8 && length(var.password) <= 256)
 error_message = "password must be between 8 and 256 characters when supplied (Graph enforces additional complexity requirements from the tenant password policy)."
 }
}

# ---------------------------------------------------------------------------
# Account control (secure-by-default)
# ---------------------------------------------------------------------------

variable "account_enabled" {
 description = "Whether the account is enabled and able to sign in. Defaults to true."
 type = bool
 default = true
}

variable "force_password_change" {
 description = <<EOT
Whether the user must change their password at the next sign-in. Only takes
effect when a password is also being set/changed. Defaults to true so an
operator-provisioned initial password is rotated by the user on first use.
EOT
 type = bool
 default = true
}

variable "disable_password_expiration" {
 description = <<EOT
Whether the user's password is exempt from the tenant expiry policy.
Defaults to false — passwords expire per policy. Set to true only with a
documented exception (non-expiring passwords weaken credential hygiene).
EOT
 type = bool
 default = false
}

variable "disable_strong_password" {
 description = <<EOT
Whether the user may set a password weaker than the default policy.
Defaults to false — strong-password enforcement stays on. Enable only with a
documented exception.
EOT
 type = bool
 default = false
}

variable "show_in_address_list" {
 description = "Whether the Outlook global address list (GAL) includes this user. Defaults to true."
 type = bool
 default = true
}

# ---------------------------------------------------------------------------
# Mail and naming
# ---------------------------------------------------------------------------

variable "mail_nickname" {
 description = <<EOT
The mail alias for the user. When null, the provider defaults it to the user
name part (before the "@") of the user_principal_name.
EOT
 type = string
 default = null
}

variable "mail" {
 description = <<EOT
The SMTP address for the user.

# IMMUTABLE-ONCE-SET: this property cannot be unset once specified. It can be
# changed to another address but cannot be cleared back to null. Leave null to
# let Exchange/Graph manage it.
EOT
 type = string
 default = null
}

variable "other_mails" {
 description = "Additional email addresses for the user. Defaults to an empty list."
 type = list(string)
 default = []
}

variable "given_name" {
 description = "The given name (first name) of the user."
 type = string
 default = null
}

variable "surname" {
 description = "The user's surname (family name / last name)."
 type = string
 default = null
}

variable "onpremises_immutable_id" {
 description = <<EOT
The value used to associate an on-premises Active Directory account with this
Azure AD user object. Must be specified when using a federated domain for the
user_principal_name. Leave null for purely cloud-only users on a managed domain.
EOT
 type = string
 default = null
}

# ---------------------------------------------------------------------------
# Closed-value-set attributes (enums)
# ---------------------------------------------------------------------------

variable "age_group" {
 description = <<EOT
The age group of the user. One of: "Adult", "NotAdult", "Minor". Use null or an
empty string to leave unset.
EOT
 type = string
 default = null

 validation {
 condition = var.age_group == null ? true: contains(["Adult", "NotAdult", "Minor", ""], var.age_group)
 error_message = "age_group must be one of: Adult, NotAdult, Minor (or null / \"\" to unset)."
 }
}

variable "consent_provided_for_minor" {
 description = <<EOT
Whether consent has been obtained for minors. One of: "Granted", "Denied",
"NotRequired". Use null or an empty string to leave unset.
EOT
 type = string
 default = null

 validation {
 condition = var.consent_provided_for_minor == null ? true: contains(["Granted", "Denied", "NotRequired", ""], var.consent_provided_for_minor)
 error_message = "consent_provided_for_minor must be one of: Granted, Denied, NotRequired (or null / \"\" to unset)."
 }
}

# ---------------------------------------------------------------------------
# Organisation / job profile
# ---------------------------------------------------------------------------

variable "job_title" {
 description = "The user's job title."
 type = string
 default = null
}

variable "company_name" {
 description = "The company name the user is associated with — useful for describing the company an external user comes from."
 type = string
 default = null
}

variable "department" {
 description = "The name of the department in which the user works."
 type = string
 default = null
}

variable "division" {
 description = "The name of the division in which the user works."
 type = string
 default = null
}

variable "employee_id" {
 description = "The employee identifier assigned to the user by the organisation."
 type = string
 default = null
}

variable "employee_type" {
 description = "Captures enterprise worker type — e.g. Employee, Contractor, Consultant, Vendor."
 type = string
 default = null
}

variable "employee_hire_date" {
 description = <<EOT
The hire date of the user, formatted as an RFC3339 date string
(e.g. "2018-01-01T01:02:03Z").
EOT
 type = string
 default = null

 validation {
 condition = var.employee_hire_date == null ? true: can(formatdate("YYYY-MM-DD", var.employee_hire_date))
 error_message = "employee_hire_date must be a valid RFC3339 timestamp (e.g. \"2018-01-01T01:02:03Z\")."
 }
}

variable "cost_center" {
 description = "The cost center associated with the user."
 type = string
 default = null
}

variable "manager_id" {
 description = "The object ID of the user's manager (another azuread_user object ID)."
 type = string
 default = null
}

# ---------------------------------------------------------------------------
# Contact details
# ---------------------------------------------------------------------------

variable "business_phones" {
 description = <<EOT
Telephone numbers for the user. The Graph API allows only ONE number for this
property. Defaults to an empty list. Read-only for users synced with Azure AD
Connect (not applicable to cloud-only users managed here).
EOT
 type = list(string)
 default = []

 validation {
 condition = length(var.business_phones) <= 1
 error_message = "business_phones may contain at most one telephone number — the Graph API rejects more than one."
 }
}

variable "mobile_phone" {
 description = "The primary cellular telephone number for the user."
 type = string
 default = null
}

variable "fax_number" {
 description = "The fax number of the user."
 type = string
 default = null
}

# ---------------------------------------------------------------------------
# Address
# ---------------------------------------------------------------------------

variable "city" {
 description = "The city in which the user is located."
 type = string
 default = null
}

variable "state" {
 description = "The state or province in the user's address."
 type = string
 default = null
}

variable "postal_code" {
 description = "The postal code for the user's address (ZIP code in the United States)."
 type = string
 default = null
}

variable "street_address" {
 description = "The street address of the user's place of business."
 type = string
 default = null
}

variable "country" {
 description = "The country/region in which the user is located. Examples: \"NO\", \"JP\", \"GB\"."
 type = string
 default = null
}

variable "office_location" {
 description = "The office location in the user's place of business."
 type = string
 default = null
}

# ---------------------------------------------------------------------------
# Locale / licensing
# ---------------------------------------------------------------------------

variable "usage_location" {
 description = <<EOT
The usage location of the user as a two-letter ISO 3166 country code
(e.g. "NO", "JP", "GB"). Required before assigning licenses (legal availability
check).

# IMMUTABLE-ONCE-SET: cannot be reset to null once specified. It can be changed
# to another country code but cannot be cleared.
EOT
 type = string
 default = null

 validation {
 condition = var.usage_location == null ? true: length(var.usage_location) == 2
 error_message = "usage_location must be a two-letter ISO 3166 country code (e.g. \"US\", \"GB\")."
 }
}

variable "preferred_language" {
 description = "The user's preferred language, in ISO 639-1 notation (e.g. \"en\", \"en-US\")."
 type = string
 default = null
}

# ---------------------------------------------------------------------------
# Universal tail
# ---------------------------------------------------------------------------

variable "timeouts" {
 description = "Optional Terraform operation timeouts for this resource."
 type = object({
 create = optional(string)
 read = optional(string)
 update = optional(string)
 delete = optional(string)
 })
 default = {}
}
