terraform {
    required_providers {
      okta = {
        source = "okta/okta"
        version = "<= 3.12.1"

      }
    }
}

provider "okta" {
    org_name  = "trial-7458580"
    base_url  = "okta.com"
    //I had to put the token here for a quick test
    api_token = "Generate token from Okta security page"
}

// Create SAML Application(This first app is for SSO VPN Authentication)
resource "okta_app_saml" "vpn_client_saml_app" {
  label                    = "AWS Client VPN"
  sso_url                  = "http://127.0.0.1:35001"
  recipient                = "http://127.0.0.1:35001"
  destination              = "http://127.0.0.1:35001"
  audience                 = "urn:amazon:webservices:clientvpn"
  subject_name_id_template = "$${user.userName}"
  subject_name_id_format   = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
  response_signed          = true
  signature_algorithm      = "RSA_SHA256"
  digest_algorithm         = "SHA256"
  honor_force_authn        = false
  authn_context_class_ref  = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
  accessibility_self_service = "true"

  attribute_statements {
    type         = "GROUP"
    name         = "groups"
    filter_type  = "REGEX"
    filter_value = ".*"
  }

  lifecycle {
     ignore_changes = [groups]
  }
}

// Create Another SAML Application(This second app is for Self Service login)
resource "okta_app_saml" "vpn_client_self_service_app" {
  label                    = "AWS Client VPN Self-service"
  sso_url                  = "https://self-service.clientvpn.amazonaws.com/api/auth/sso/saml"
  recipient                = "https://self-service.clientvpn.amazonaws.com/api/auth/sso/saml"
  destination              = "https://self-service.clientvpn.amazonaws.com/api/auth/sso/saml"
  audience                 = "urn:amazon:webservices:clientvpn"
  subject_name_id_template = "$${user.userName}"
  subject_name_id_format   = "urn:oasis:names:tc:SAML:1.1:nameid-format:emailAddress"
  response_signed          = true
  signature_algorithm      = "RSA_SHA256"
  digest_algorithm         = "SHA256"
  honor_force_authn        = false
  authn_context_class_ref  = "urn:oasis:names:tc:SAML:2.0:ac:classes:PasswordProtectedTransport"
  accessibility_self_service = "true"

  attribute_statements {
    type         = "GROUP"
    name         = "groups"
    filter_type  = "REGEX"
    filter_value = ".*"
  }

  lifecycle {
     ignore_changes = [groups]
  }
}

// Create a group to add users
resource "okta_group" "vpn_client_group" {
  name        = "VPN Client Group"
  description = "My Vpn users"
}

// Assign the app to a group so all users in the group can get access to app to the 
resource "okta_app_group_assignment" "assign_app_to_group" {
  app_id   = okta_app_saml.vpn_client_saml_app.id
  group_id = okta_group.vpn_client_group.id
}


// Assign the app to the group2 so all users in the group can get access to app to the 
resource "okta_app_group_assignment" "assign_app2_to_group" {
  app_id   = okta_app_saml.vpn_client_self_service_app.id
  group_id = okta_group.vpn_client_group.id
}

// Create Okta users
resource "okta_user" "user" {
  for_each = var.users

  email      = each.value.email
  first_name = each.value.first_name
  last_name  = each.value.last_name
  login      = each.value.email
  status     = "ACTIVE"
  password   = each.value.password
}

// Add users to a group
resource "okta_group_memberships" "add_users_as_group_members" {
  for_each = okta_user.user

  group_id = okta_group.vpn_client_group.id
  users    = [each.value.id]
}



