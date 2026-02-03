module "greeeeeeeee" {
    source = "./modules/minecraft_server"
    server_memory = 1G
    server_version = "1.21"
    server_port =  25565
    email =  corentin.gouanvic@gmail.com
  }
module "greee2" {
    source = "./modules/minecraft_server"
    server_memory = 8G
    server_version = "1.21"
    server_port =  25566
    email =  corentin.gouanvic@gmail.com
  }
