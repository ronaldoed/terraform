variable "identifier" {
    default = "wp-db"
}
variable "allocated_storage" {
    default = "8"
}
variable "engine" {
    default = "mysql"
}
variable "engine_version" {
    default = "5.7"
}
variable "instance_class" {
    default = "db.t2.small"
}
variable "db_name" {
    default = "wordpress"
}
variable "db_username" {
    default = "wordpress"
}
variable "db_password" {
    default = "wordpress"
}
