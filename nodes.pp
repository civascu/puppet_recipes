import "gitorious"

node "default" {
  include gitorious::user
  include gitorious::depends
  include gitorious::core
  include gitorious::config
  include system::services
  include gitorious::services
  include gitorious::passenger
}
