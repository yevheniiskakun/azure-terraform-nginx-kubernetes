resource "random_pet" "name" {

}

resource "azurerm_resource_group" "nginx-rg" {
  name     = "${random_pet.name.id}-rg"
  location = var.location
}

resource "azurerm_kubernetes_cluster" "cluster" {
  name                = "${random_pet.name.id}-aks"
  location            = var.location
  resource_group_name = azurerm_resource_group.nginx-rg.name
  dns_prefix          = "nginxaks1"
  node_resource_group = "${random_pet.name.id}-aks-nodes"

  default_node_pool {
    name       = "default"
    node_count = 1
    vm_size    = "Standard_A2_v2"
  }

  identity {
    type = "SystemAssigned"
  }

  tags = {
    Environment = "Demo"
  }
}

# Set up kubernetes provider
provider "kubernetes" {
  host = azurerm_kubernetes_cluster.cluster.kube_config.0.host

  client_certificate     = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_certificate)
  client_key             = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.client_key)
  cluster_ca_certificate = base64decode(azurerm_kubernetes_cluster.cluster.kube_config.0.cluster_ca_certificate)
}

resource "kubernetes_deployment" "nginx" {
  metadata {
    name = "nginx-deployment"
    labels = {
      app = "nginx"
    }
  }

  spec {
    replicas = 4

    selector {
      match_labels = {
        app = "nginx"
      }
    }

    template {
      metadata {
        labels = {
          app = "nginx"
        }
      }

      spec {
        container {
          image = "nginx:latest"
          name  = "nginx"

          port {
            container_port = 80
          }
        }
      }
    }
  }
}

resource "kubernetes_service" "nginx" {
  metadata {
    name = "nginx-service"
  }

  spec {
    selector = {
      app = kubernetes_deployment.nginx.metadata[0].labels.app
    }

    port {
      port        = 80
      target_port = 80
    }

    type = "LoadBalancer"
  }
}

