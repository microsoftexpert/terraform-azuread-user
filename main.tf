resource "azuread_user" "this" {
 # Required identity
 display_name = var.display_name
 user_principal_name = var.user_principal_name

 # Credential (write-only — never read back from Graph)
 password = var.password
 force_password_change = var.force_password_change

 # Account control
 account_enabled = var.account_enabled
 disable_password_expiration = var.disable_password_expiration
 disable_strong_password = var.disable_strong_password
 show_in_address_list = var.show_in_address_list

 # Mail and naming
 mail_nickname = var.mail_nickname
 mail = var.mail
 other_mails = var.other_mails
 given_name = var.given_name
 surname = var.surname
 onpremises_immutable_id = var.onpremises_immutable_id

 # Closed-value-set attributes
 age_group = var.age_group
 consent_provided_for_minor = var.consent_provided_for_minor

 # Organisation / job profile
 job_title = var.job_title
 company_name = var.company_name
 department = var.department
 division = var.division
 employee_id = var.employee_id
 employee_type = var.employee_type
 employee_hire_date = var.employee_hire_date
 cost_center = var.cost_center
 manager_id = var.manager_id

 # Contact details
 business_phones = var.business_phones
 mobile_phone = var.mobile_phone
 fax_number = var.fax_number

 # Address
 city = var.city
 state = var.state
 postal_code = var.postal_code
 street_address = var.street_address
 country = var.country
 office_location = var.office_location

 # Locale / licensing
 usage_location = var.usage_location
 preferred_language = var.preferred_language

 dynamic "timeouts" {
 for_each = length(keys(var.timeouts)) > 0 ? [1]: []
 content {
 create = try(var.timeouts.create, null)
 read = try(var.timeouts.read, null)
 update = try(var.timeouts.update, null)
 delete = try(var.timeouts.delete, null)
 }
 }
}
