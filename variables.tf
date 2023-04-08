variable "users" {
  type = map(object({
    email      = string
    first_name = string
    last_name  = string
    password   = string
  }))
  default = {
    "shola" = {
      email      = "fadaresholamatthew@gmail.com"
      first_name = "John"
      last_name  = "Smith"
      password   = "Daniel@40"
    },
    "jane" = {
      email      = "fadareshola8@gmail.com"
      first_name = "Jane"
      last_name  = "Doe"
      login      = "fadareshola8@gmail.com"
      status     = "ACTIVE"
      password   = "Password@123"
    }
  }
}
